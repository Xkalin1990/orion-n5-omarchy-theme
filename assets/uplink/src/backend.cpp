#include "backend.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QVariantMap>
#include <cmath>

namespace {
constexpr int kPollIntervalMs = 5000;
constexpr int kProbeTimeoutMs = 2000;

QVector<Backend::Target> defaultTargets() {
    return {
        {QStringLiteral("1.1.1.1"), QStringLiteral("1.1.1.1"), 443, true, false, -1},
        {QStringLiteral("github.com:443"), QStringLiteral("github.com"), 443, false, false, -1},
        {QStringLiteral("localhost:3000"), QStringLiteral("127.0.0.1"), 3000, false, false, -1},
    };
}

Backend::Target parseTargetEntry(const QJsonValue &entry) {
    if (entry.isString()) {
        const QString raw = entry.toString().trimmed();
        if (raw.isEmpty())
            return {};
        const int colon = raw.lastIndexOf(':');
        if (colon > 0) {
            bool ok = false;
            const int port = raw.mid(colon + 1).toInt(&ok);
            if (ok && port > 0 && port <= 65535) {
                const QString host = raw.left(colon);
                return {raw, host == QLatin1String("localhost") ? QStringLiteral("127.0.0.1") : host,
                        static_cast<quint16>(port), false, false, -1};
            }
        }
        return {raw, raw, 443, true, false, -1};
    }

    if (entry.isObject()) {
        const QJsonObject obj = entry.toObject();
        const QString host = obj.value(QStringLiteral("host")).toString().trimmed();
        if (host.isEmpty())
            return {};
        const int port = obj.value(QStringLiteral("port")).toInt(443);
        const QString label = obj.value(QStringLiteral("label")).toString().trimmed();
        const bool usePing = obj.value(QStringLiteral("ping")).toBool(false);
        const QString resolvedHost = host == QLatin1String("localhost") ? QStringLiteral("127.0.0.1") : host;
        return {label.isEmpty() ? host : label, resolvedHost,
                static_cast<quint16>(qBound(1, port, 65535)), usePing, false, -1};
    }

    return {};
}
} // namespace

Backend::Backend(const QString &configPath, bool autoStart, QObject *parent)
    : QObject(parent) {
    const QString path = configPath.isEmpty()
        ? QDir::homePath() + QStringLiteral("/.config/uplink/targets.json")
        : configPath;
    m_targets = loadTargets(path);
    m_probes.resize(m_targets.size());
    recomputeState();

    m_pollTimer.setInterval(kPollIntervalMs);
    connect(&m_pollTimer, &QTimer::timeout, this, &Backend::refresh);

    if (autoStart) {
        m_pollTimer.start();
        refresh();
    }
}

Backend::~Backend() {
    m_pollTimer.stop();
    cancelActiveProbes();
}

QVector<Backend::Target> Backend::loadTargets(const QString &configPath) {
    QFile file(configPath);
    if (!file.open(QIODevice::ReadOnly))
        return defaultTargets();

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    QJsonArray array;
    if (doc.isArray()) {
        array = doc.array();
    } else if (doc.isObject()) {
        array = doc.object().value(QStringLiteral("targets")).toArray();
    }

    QVector<Target> parsed;
    for (const auto &entry : array) {
        const Target target = parseTargetEntry(entry);
        if (!target.host.isEmpty())
            parsed.append(target);
    }
    return parsed.isEmpty() ? defaultTargets() : parsed;
}

int Backend::parsePingLatencyMs(const QString &pingOutput) {
    static const QRegularExpression re(QStringLiteral(R"(time[=<]\s*([0-9]+(?:\.[0-9]+)?)\s*ms)"));
    const auto match = re.match(pingOutput);
    if (!match.hasMatch())
        return -1;
    bool ok = false;
    const double ms = match.captured(1).toDouble(&ok);
    return ok ? static_cast<int>(std::lround(ms)) : -1;
}

QVariantList Backend::targets() const {
    QVariantList list;
    list.reserve(m_targets.size());
    for (const auto &t : m_targets) {
        QVariantMap item;
        item.insert(QStringLiteral("label"), t.label);
        item.insert(QStringLiteral("host"), t.host);
        item.insert(QStringLiteral("port"), t.port);
        item.insert(QStringLiteral("up"), t.up);
        item.insert(QStringLiteral("latencyMs"), t.latencyMs);
        list.append(item);
    }
    return list;
}

void Backend::refresh() {
    cancelActiveProbes();
    ++m_generation;
    for (int i = 0; i < m_targets.size(); ++i)
        probeTarget(i);
}

void Backend::cycleTarget() {
    if (m_targets.isEmpty())
        return;
    m_activeIndex = (m_activeIndex + 1) % m_targets.size();
    recomputeState();
}

void Backend::applyTargetResult(int index, bool up, int latencyMs) {
    if (index < 0 || index >= m_targets.size())
        return;
    m_targets[index].up = up;
    m_targets[index].latencyMs = up ? latencyMs : -1;
    recomputeState();
}

void Backend::probeTarget(int index) {
    if (index < 0 || index >= m_targets.size())
        return;

    const int gen = m_generation;
    const Target &target = m_targets[index];
    ProbeState &state = m_probes[index];
    state.generation = gen;
    state.tcpDone = false;
    state.tcpUp = false;
    state.tcpLatencyMs = -1;
    state.pingUp = false;
    state.pingLatencyMs = -1;

    // Non-blocking TCP connect with a 2s timeout.
    auto *socket = new QTcpSocket(this);
    auto *tcpTimer = new QTimer(this);
    tcpTimer->setSingleShot(true);
    tcpTimer->setInterval(kProbeTimeoutMs);
    state.socket = socket;
    state.tcpTimer = tcpTimer;

    auto elapsed = QSharedPointer<QElapsedTimer>::create();
    elapsed->start();

    auto completeTcp = [this, index, gen, socket, tcpTimer](bool up, int ms) {
        if (index >= m_probes.size() || m_probes[index].generation != gen)
            return;
        if (m_probes[index].tcpDone)
            return;
        m_probes[index].tcpDone = true;
        m_probes[index].tcpUp = up;
        m_probes[index].tcpLatencyMs = ms;
        tcpTimer->stop();
        socket->abort();
        socket->deleteLater();
        tcpTimer->deleteLater();
        finishProbeIfReady(index, gen);
    };

    connect(socket, &QTcpSocket::connected, this, [completeTcp, elapsed]() {
        completeTcp(true, static_cast<int>(elapsed->elapsed()));
    });
    connect(socket, &QTcpSocket::errorOccurred, this, [completeTcp](QAbstractSocket::SocketError) {
        completeTcp(false, -1);
    });
    connect(tcpTimer, &QTimer::timeout, this, [completeTcp]() {
        completeTcp(false, -1);
    });

    tcpTimer->start();
    socket->connectToHost(target.host, target.port);

    // Optional ICMP ping for accurate RTT on targets like 1.1.1.1.
    const QString pingBin = target.usePing ? QStandardPaths::findExecutable(QStringLiteral("ping")) : QString();
    if (pingBin.isEmpty()) {
        state.pingDone = true;
        return;
    }

    state.pingDone = false;
    auto *proc = new QProcess(this);
    auto *pingTimer = new QTimer(this);
    pingTimer->setSingleShot(true);
    pingTimer->setInterval(kProbeTimeoutMs);
    state.pingProcess = proc;
    state.pingTimer = pingTimer;

    auto completePing = [this, index, gen, proc, pingTimer](bool up, int ms) {
        if (index >= m_probes.size() || m_probes[index].generation != gen)
            return;
        if (m_probes[index].pingDone)
            return;
        m_probes[index].pingDone = true;
        m_probes[index].pingUp = up;
        m_probes[index].pingLatencyMs = ms;
        pingTimer->stop();
        proc->deleteLater();
        pingTimer->deleteLater();
        finishProbeIfReady(index, gen);
    };

    connect(proc, &QProcess::finished, this, [completePing, proc](int exitCode, QProcess::ExitStatus status) {
        if (status == QProcess::NormalExit && exitCode == 0) {
            const int ms = parsePingLatencyMs(QString::fromUtf8(proc->readAllStandardOutput()));
            completePing(true, ms);
        } else {
            completePing(false, -1);
        }
    });
    connect(proc, &QProcess::errorOccurred, this, [completePing](QProcess::ProcessError) {
        completePing(false, -1);
    });
    connect(pingTimer, &QTimer::timeout, this, [proc, completePing]() {
        if (proc->state() != QProcess::NotRunning)
            proc->kill();
        completePing(false, -1);
    });

    pingTimer->start();
    proc->start(pingBin, {QStringLiteral("-c"), QStringLiteral("1"), QStringLiteral("-W"), QStringLiteral("1"), target.host});
}

void Backend::finishProbeIfReady(int index, int generation) {
    if (index < 0 || index >= m_probes.size())
        return;
    const ProbeState &state = m_probes[index];
    if (state.generation != generation || !state.tcpDone || !state.pingDone)
        return;

    const bool up = state.tcpUp || state.pingUp;
    int ms = -1;
    if (state.pingUp && state.pingLatencyMs >= 0)
        ms = state.pingLatencyMs;
    else if (state.tcpUp)
        ms = state.tcpLatencyMs;

    applyTargetResult(index, up, ms);
}

void Backend::cancelActiveProbes() {
    for (auto &state : m_probes) {
        if (state.tcpTimer) {
            state.tcpTimer->stop();
            state.tcpTimer->deleteLater();
        }
        if (state.socket) {
            state.socket->abort();
            state.socket->deleteLater();
        }
        if (state.pingTimer) {
            state.pingTimer->stop();
            state.pingTimer->deleteLater();
        }
        if (state.pingProcess) {
            if (state.pingProcess->state() != QProcess::NotRunning) {
                state.pingProcess->kill();
                state.pingProcess->waitForFinished(200);
            }
            state.pingProcess->deleteLater();
        }
        state.tcpDone = true;
        state.pingDone = true;
    }
}

void Backend::recomputeState() {
    int upCount = 0;
    for (const auto &t : m_targets) {
        if (t.up)
            ++upCount;
    }

    const int total = m_targets.size();
    if (total == 0 || upCount == 0) {
        m_online = false;
        m_statusText = tr("OFFLINE");
    } else if (upCount < total) {
        m_online = true;
        m_statusText = tr("DEGRADED");
    } else {
        m_online = true;
        m_statusText = tr("NOMINAL");
    }

    if (!m_targets.isEmpty()) {
        m_activeIndex = qBound(0, m_activeIndex, m_targets.size() - 1);
        m_targetLabel = m_targets[m_activeIndex].label;
        m_latencyMs = m_targets[m_activeIndex].latencyMs;
    } else {
        m_targetLabel.clear();
        m_latencyMs = -1;
    }

    m_targetsSummary = tr("%1/%2 UP").arg(upCount).arg(total);
    emit changed();
}
