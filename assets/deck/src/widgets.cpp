#include "widgets.h"

#include <QClipboard>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QRegularExpression>
#include <QSaveFile>
#include <QStandardPaths>
#include <QTimeZone>
#include <algorithm>
#include <cmath>

// ============================= 01 // EPOCH =============================

EpochBackend::EpochBackend(QObject *parent) : QObject(parent) {
    m_timer.setInterval(250);
    connect(&m_timer, &QTimer::timeout, this, &EpochBackend::refresh);
    m_timer.start();
    refresh();
}

void EpochBackend::toggle24Hour() {
    m_use24Hour = !m_use24Hour;
    refresh();
}

void EpochBackend::toggleSeconds() {
    m_showSeconds = !m_showSeconds;
    refresh();
}

void EpochBackend::refresh() {
    updateForDateTime(QDateTime::currentDateTime());
}

void EpochBackend::updateForDateTime(const QDateTime &now) {
    const QLocale locale;
    const QTime t = now.time();
    const int hour12 = t.hour() % 12 == 0 ? 12 : t.hour() % 12;
    const QTime displayTime = m_use24Hour ? t : QTime(hour12, t.minute(), t.second());
    const QString timeText = locale.toString(displayTime, m_use24Hour ? "HH:mm" : "h:mm");
    const QString secondsText = locale.toString(t, "ss");
    const QString ampmText = m_use24Hour ? QString() : locale.toString(t, "AP");
    const QString dateText = locale.toString(now.date(), QLocale::LongFormat);
    const QString weekText = QStringLiteral("W%1").arg(now.date().weekNumber(), 2, 10, QChar('0'));
    const double minuteProgress = (t.second() + t.msec() / 1000.0) / 60.0;

    if (timeText == m_timeText && secondsText == m_secondsText && ampmText == m_ampmText
        && dateText == m_dateText && weekText == m_weekText
        && std::abs(minuteProgress - m_minuteProgress) < 0.005) {
        return;
    }

    m_timeText = timeText;
    m_secondsText = secondsText;
    m_ampmText = ampmText;
    m_dateText = dateText;
    m_weekText = weekText;
    m_minuteProgress = minuteProgress;
    emit changed();
}

// ============================= 02 // T-MINUS ===========================

static constexpr int kPresetMinutes[] = {25, 15, 5};

TminusBackend::TminusBackend(QObject *parent) : QObject(parent) {
    m_timer.setInterval(200);
    connect(&m_timer, &QTimer::timeout, this, &TminusBackend::tick);
}

qint64 TminusBackend::currentMs() const {
    return m_accumulatedMs + (m_running ? m_elapsed.elapsed() : 0);
}

QString TminusBackend::timeText() const {
    const qint64 ms = m_stopwatch ? currentMs() : std::max<qint64>(0, m_durationMs - currentMs());
    const qint64 totalSec = (ms + (m_stopwatch ? 0 : 999)) / 1000;
    const qint64 mins = totalSec / 60;
    const qint64 secs = totalSec % 60;
    return QStringLiteral("%1:%2").arg(mins, 2, 10, QChar('0')).arg(secs, 2, 10, QChar('0'));
}

double TminusBackend::progress() const {
    if (m_stopwatch)
        return (currentMs() % 60000) / 60000.0;
    if (m_durationMs <= 0)
        return 0.0;
    return std::clamp(double(currentMs()) / double(m_durationMs), 0.0, 1.0);
}

QString TminusBackend::presetLabel() const {
    if (m_stopwatch)
        return "STOPWATCH";
    const int mins = int(m_durationMs / 60000);
    return QStringLiteral("%1M").arg(mins, 2, 10, QChar('0'));
}

void TminusBackend::toggleRunning() {
    if (m_finished) {
        reset();
    }
    if (m_running) {
        m_accumulatedMs += m_elapsed.elapsed();
        m_running = false;
        m_timer.stop();
    } else {
        m_elapsed.start();
        m_running = true;
        m_timer.start();
    }
    emit changed();
}

void TminusBackend::reset() {
    m_running = false;
    m_finished = false;
    m_accumulatedMs = 0;
    m_timer.stop();
    emit changed();
}

void TminusBackend::selectPreset(int index) {
    m_stopwatch = false;
    m_presetIndex = std::clamp(index, 0, 2);
    m_durationMs = qint64(kPresetMinutes[m_presetIndex]) * 60 * 1000;
    reset();
}

void TminusBackend::nextPreset() {
    selectPreset((m_presetIndex + 1) % 3);
}

void TminusBackend::adjustMinutes(int delta) {
    if (m_stopwatch)
        return;
    const int mins = std::clamp(int(m_durationMs / 60000) + delta, 1, 99);
    m_durationMs = qint64(mins) * 60 * 1000;
    if (!m_running)
        m_accumulatedMs = 0;
    m_finished = false;
    emit changed();
}

void TminusBackend::toggleStopwatch() {
    m_stopwatch = !m_stopwatch;
    reset();
}

void TminusBackend::tick() {
    if (!m_stopwatch && currentMs() >= m_durationMs) {
        m_accumulatedMs = m_durationMs;
        m_running = false;
        m_finished = true;
        m_timer.stop();
        playChime();
    }
    emit changed();
}

void TminusBackend::playChime() {
    const QString sound = QDir::homePath() + "/.config/omarchy/themes/orion-n5/assets/sounds/telemetry-activate.wav";
    if (QFileInfo::exists(sound))
        QProcess::startDetached("pw-play", {sound});
}

// ============================= 03 // UPLINK ============================

UplinkBackend::UplinkBackend(bool autoPoll, QObject *parent) : QObject(parent) {
    m_targets = {
        {"1.1.1.1", "1.1.1.1", 0, false},
        {"github.com", "github.com", 443, false},
        {"localhost:3000", "127.0.0.1", 3000, false},
    };

    m_socketTimeout.setSingleShot(true);
    m_socketTimeout.setInterval(2000);
    connect(&m_socketTimeout, &QTimer::timeout, this, [this] {
        m_socket.abort();
        applyProbeResult(false, -1);
    });
    connect(&m_socket, &QTcpSocket::connected, this, [this] {
        m_socketTimeout.stop();
        const int ms = std::max(1, int(m_socketTimer.elapsed()));
        m_socket.disconnectFromHost();
        applyProbeResult(true, ms);
    });
    connect(&m_socket, &QTcpSocket::errorOccurred, this, [this] {
        if (m_socketTimeout.isActive()) {
            m_socketTimeout.stop();
            applyProbeResult(false, -1);
        }
    });
    connect(&m_pingProcess, &QProcess::finished, this, [this](int code, QProcess::ExitStatus status) {
        const QString out = QString::fromUtf8(m_pingProcess.readAllStandardOutput());
        const int ms = parsePingMs(out);
        applyProbeResult(code == 0 && status == QProcess::NormalExit, ms);
    });

    m_pollTimer.setInterval(5000);
    connect(&m_pollTimer, &QTimer::timeout, this, &UplinkBackend::refresh);
    if (autoPoll) {
        m_pollTimer.start();
        refresh();
    }
}

UplinkBackend::~UplinkBackend() {
    m_socketTimeout.stop();
    m_socket.abort();
    if (m_pingProcess.state() != QProcess::NotRunning) {
        m_pingProcess.kill();
        m_pingProcess.waitForFinished(500);
    }
}

QString UplinkBackend::targetLabel() const {
    return m_targets.isEmpty() ? QString() : m_targets.at(m_targetIndex).label;
}

QStringList UplinkBackend::targetNames() const {
    QStringList names;
    for (const auto &t : m_targets)
        names.append(t.label);
    return names;
}

QString UplinkBackend::targetsSummary() const {
    int up = 0;
    for (const auto &t : m_targets)
        if (t.up) ++up;
    return QStringLiteral("%1/%2 UP").arg(up).arg(m_targets.size());
}

void UplinkBackend::selectTarget(int index) {
    if (index < 0 || index >= m_targets.size() || index == m_targetIndex)
        return;
    m_targetIndex = index;
    m_history.clear();
    emit changed();
    refresh();
}

void UplinkBackend::cycleTarget() {
    if (m_targets.isEmpty())
        return;
    selectTarget((m_targetIndex + 1) % m_targets.size());
}

void UplinkBackend::refresh() {
    probeTarget(m_targetIndex);
}

void UplinkBackend::probeTarget(int index) {
    if (index < 0 || index >= m_targets.size())
        return;
    const Target &t = m_targets.at(index);
    if (t.port == 0) {
        if (m_pingProcess.state() != QProcess::NotRunning)
            return;
        m_pingProcess.start("ping", {"-c", "1", "-W", "1", t.host});
    } else {
        m_socket.abort();
        m_socketTimer.start();
        m_socketTimeout.start();
        m_socket.connectToHost(t.host, t.port);
    }
}

int UplinkBackend::parsePingMs(const QString &output) {
    static const QRegularExpression re(R"re(time[=<]\s*([0-9]+(?:\.[0-9]+)?)\s*ms)re");
    const auto match = re.match(output);
    return match.hasMatch() ? std::max(1, int(std::round(match.captured(1).toDouble()))) : -1;
}

void UplinkBackend::applyProbeResult(bool ok, int ms) {
    if (m_targetIndex >= 0 && m_targetIndex < m_targets.size())
        m_targets[m_targetIndex].up = ok;
    m_online = ok;
    m_latencyMs = ok ? ms : -1;
    m_statusText = !ok ? "OFFLINE" : (ms > 150 ? "DEGRADED" : "NOMINAL");
    m_history.append(ok ? std::max(1, ms) : 0);
    while (m_history.size() > 14)
        m_history.removeFirst();
    emit changed();
}

// ============================= 04 // SIGNAL ============================

SignalBackend::SignalBackend(bool autoPoll, QObject *parent)
    : QObject(parent), m_playerctl(QStandardPaths::findExecutable("playerctl")) {
    connect(&m_metaProcess, &QProcess::finished, this, [this](int code, QProcess::ExitStatus status) {
        if (code == 0 && status == QProcess::NormalExit)
            parseMetadata(QString::fromUtf8(m_metaProcess.readAllStandardOutput()));
        else
            parseMetadata({});
    });
    m_pollTimer.setInterval(1000);
    connect(&m_pollTimer, &QTimer::timeout, this, &SignalBackend::refresh);
    if (autoPoll && !m_playerctl.isEmpty()) {
        m_pollTimer.start();
        refresh();
    }
}

SignalBackend::~SignalBackend() {
    if (m_metaProcess.state() != QProcess::NotRunning) {
        m_metaProcess.kill();
        m_metaProcess.waitForFinished(500);
    }
}

QString SignalBackend::formatSeconds(qint64 seconds) {
    if (seconds < 0) seconds = 0;
    return QStringLiteral("%1:%2").arg(seconds / 60, 2, 10, QChar('0')).arg(seconds % 60, 2, 10, QChar('0'));
}

void SignalBackend::refresh() {
    if (m_playerctl.isEmpty() || m_metaProcess.state() != QProcess::NotRunning)
        return;
    m_metaProcess.start(m_playerctl, {"metadata", "--format",
        "{{status}}|||{{title}}|||{{artist}}|||{{position}}|||{{mpris:length}}"});
}

void SignalBackend::runAction(const QString &arg) {
    if (m_playerctl.isEmpty())
        return;
    QProcess::startDetached(m_playerctl, {arg});
    QTimer::singleShot(150, this, &SignalBackend::refresh);
}

void SignalBackend::playPause() { runAction("play-pause"); }
void SignalBackend::nextTrack() { runAction("next"); }
void SignalBackend::prevTrack() { runAction("previous"); }

void SignalBackend::parseMetadata(const QString &output) {
    const QString trimmed = output.trimmed();
    const QStringList parts = trimmed.split("|||");
    if (parts.size() < 5 || (parts[0].isEmpty() && parts[1].isEmpty())) {
        if (m_hasPlayer || m_title != "NO SIGNAL") {
            m_title = "NO SIGNAL";
            m_artist = "Standby";
            m_playing = false;
            m_hasPlayer = false;
            m_progress = 0.0;
            m_positionText = "00:00";
            m_durationText = "00:00";
            emit changed();
        }
        return;
    }

    const bool playing = parts[0].compare("Playing", Qt::CaseInsensitive) == 0;
    const QString title = parts[1].isEmpty() ? "Untitled" : parts[1];
    const QString artist = parts[2].isEmpty() ? "Unknown Artist" : parts[2];
    const qint64 posUs = parts[3].toLongLong();
    const qint64 lenUs = parts[4].toLongLong();
    const double progress = lenUs > 0 ? std::clamp(double(posUs) / double(lenUs), 0.0, 1.0) : 0.0;
    const QString posText = formatSeconds(posUs / 1000000);
    const QString durText = formatSeconds(lenUs / 1000000);

    if (title == m_title && artist == m_artist && playing == m_playing && m_hasPlayer
        && std::abs(progress - m_progress) < 0.002 && posText == m_positionText && durText == m_durationText) {
        return;
    }

    m_title = title;
    m_artist = artist;
    m_playing = playing;
    m_hasPlayer = true;
    m_progress = progress;
    m_positionText = posText;
    m_durationText = durText;
    emit changed();
}

// ============================= 05 // SLATE =============================

SlateBackend::SlateBackend(const QString &notePath, QObject *parent)
    : QObject(parent),
      m_notePath(notePath.isEmpty() ? QDir::homePath() + "/.local/share/slate/note.md" : notePath) {
    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(400);
    connect(&m_saveTimer, &QTimer::timeout, this, &SlateBackend::saveNow);
    load();
}

SlateBackend::~SlateBackend() {
    if (!m_saved)
        saveNow();
}

void SlateBackend::load() {
    QFile file(m_notePath);
    if (file.open(QIODevice::ReadOnly))
        m_text = QString::fromUtf8(file.readAll());
    m_saved = true;
}

void SlateBackend::setText(const QString &text) {
    if (text == m_text)
        return;
    m_text = text;
    m_saved = false;
    m_saveTimer.start();
    emit changed();
}

int SlateBackend::lineCount() const {
    return m_text.isEmpty() ? 0 : m_text.count('\n') + 1;
}

int SlateBackend::wordCount() const {
    const QString trimmed = m_text.trimmed();
    if (trimmed.isEmpty())
        return 0;
    static const QRegularExpression ws("\\s+");
    return trimmed.split(ws, Qt::SkipEmptyParts).size();
}

void SlateBackend::saveNow() {
    m_saveTimer.stop();
    QDir().mkpath(QFileInfo(m_notePath).absolutePath());
    QSaveFile file(m_notePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(m_text.toUtf8());
        if (file.commit()) {
            m_saved = true;
            emit changed();
        }
    }
}

void SlateBackend::clear() {
    setText({});
    saveNow();
}

void SlateBackend::copyToClipboard() const {
    if (auto *cb = QGuiApplication::clipboard())
        cb->setText(m_text);
}

// ============================= 06 // ZULU ==============================

ZuluBackend::ZuluBackend(QObject *parent) : QObject(parent) {
    m_defs = {
        {"ZULU", "UTC", "UTC"},
        {"LON", "London", "Europe/London"},
        {"NYC", "New York", "America/New_York"},
        {"TYO", "Tokyo", "Asia/Tokyo"},
    };
    m_timer.setInterval(250);
    connect(&m_timer, &QTimer::timeout, this, &ZuluBackend::refresh);
    m_timer.start();
    refresh();
}

void ZuluBackend::toggle24Hour() {
    m_use24Hour = !m_use24Hour;
    refresh();
}

void ZuluBackend::toggleSeconds() {
    m_showSeconds = !m_showSeconds;
    refresh();
}

void ZuluBackend::refresh() {
    updateForUtc(QDateTime::currentDateTimeUtc(), QDate::currentDate());
}

void ZuluBackend::updateForUtc(const QDateTime &utc, const QDate &localDate) {
    const QDate refDate = localDate.isValid() ? localDate : utc.toLocalTime().date();
    const QLocale locale;
    QVariantList next;

    for (const auto &def : m_defs) {
        const QTimeZone tz(def.ianaId);
        const QDateTime zoned = tz.isValid() ? utc.toTimeZone(tz) : utc;
        const QTime t = zoned.time();
        const int hour12 = t.hour() % 12 == 0 ? 12 : t.hour() % 12;
        const QTime disp = m_use24Hour ? t : QTime(hour12, t.minute(), t.second());
        const QString fmt = m_use24Hour ? (m_showSeconds ? "HH:mm:ss" : "HH:mm")
                                        : (m_showSeconds ? "h:mm:ss" : "h:mm");
        QString timeStr = locale.toString(disp, fmt);
        if (!m_use24Hour)
            timeStr += " " + locale.toString(t, "AP");

        const qint64 delta = refDate.daysTo(zoned.date());
        const QString dayDelta = delta > 0 ? QStringLiteral("+%1d").arg(delta)
                               : delta < 0 ? QStringLiteral("%1d").arg(delta)
                               : QString();

        QVariantMap map;
        map.insert("code", def.code);
        map.insert("city", def.city);
        map.insert("time", timeStr);
        map.insert("dayDelta", dayDelta);
        next.append(map);
    }

    if (next == m_zones)
        return;
    m_zones = next;
    emit changed();
}
