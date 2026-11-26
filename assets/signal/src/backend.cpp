#include "backend.h"

#include <QStringList>
#include <QtGlobal>

namespace {
constexpr auto kPlayerctlBin = "/usr/bin/playerctl";
constexpr auto kMetadataFormat = "{{status}}|||{{title}}|||{{artist}}|||{{position}}|||{{mpris:length}}";
} // namespace

Backend::Backend(QObject *parent) : QObject(parent) {
    connect(&m_metaProcess, &QProcess::finished, this,
            [this](int exitCode, QProcess::ExitStatus exitStatus) {
                if (exitCode != 0 || exitStatus != QProcess::NormalExit) {
                    parseMetadata(QString());
                    return;
                }
                parseMetadata(QString::fromUtf8(m_metaProcess.readAllStandardOutput()));
            });
    connect(&m_metaProcess, &QProcess::errorOccurred, this, [this] {
        parseMetadata(QString());
    });

    connect(&m_actionProcess, &QProcess::finished, this, [this] {
        refresh();
    });

    m_pollTimer.setInterval(1000);
    connect(&m_pollTimer, &QTimer::timeout, this, &Backend::refresh);
    m_pollTimer.start();

    refresh();
}

Backend::~Backend() {
    if (m_metaProcess.state() != QProcess::NotRunning) {
        m_metaProcess.kill();
        m_metaProcess.waitForFinished(1000);
    }
    if (m_actionProcess.state() != QProcess::NotRunning) {
        m_actionProcess.kill();
        m_actionProcess.waitForFinished(1000);
    }
}

void Backend::parseMetadata(const QString &output) {
    QString nextTitle = "NO SIGNAL";
    QString nextArtist = "Standby";
    bool nextPlaying = false;
    bool nextHasPlayer = false;
    double nextProgress = 0.0;
    QString nextPositionText = "00:00";

    const QString trimmed = output.trimmed();
    if (!trimmed.isEmpty()) {
        const QStringList parts = trimmed.split("|||");
        if (parts.size() >= 5 && !parts[0].trimmed().isEmpty()) {
            const QString status = parts[0].trimmed();
            nextHasPlayer = true;
            nextPlaying = (status.compare("Playing", Qt::CaseInsensitive) == 0);

            const QString rawTitle = parts[1].trimmed();
            const QString rawArtist = parts[2].trimmed();
            nextTitle = rawTitle.isEmpty() ? QString("NO SIGNAL") : rawTitle;
            nextArtist = rawArtist.isEmpty() ? QString("Standby") : rawArtist;

            bool posOk = false;
            qint64 posUs = parts[3].trimmed().toLongLong(&posOk);
            if (!posOk || posUs < 0)
                posUs = 0;

            bool lenOk = false;
            qint64 lenUs = parts[4].trimmed().toLongLong(&lenOk);
            if (!lenOk || lenUs <= 0)
                lenUs = 0;

            nextProgress = (lenUs > 0)
                ? qBound(0.0, static_cast<double>(posUs) / static_cast<double>(lenUs), 1.0)
                : 0.0;

            const qint64 totalSec = posUs / 1000000;
            nextPositionText = QString("%1:%2")
                .arg(totalSec / 60, 2, 10, QChar('0'))
                .arg(totalSec % 60, 2, 10, QChar('0'));
        }
    }

    if (nextTitle != m_title || nextArtist != m_artist || nextPlaying != m_playing
        || nextHasPlayer != m_hasPlayer || !qFuzzyCompare(nextProgress + 1.0, m_progress + 1.0)
        || nextPositionText != m_positionText) {
        m_title = nextTitle;
        m_artist = nextArtist;
        m_playing = nextPlaying;
        m_hasPlayer = nextHasPlayer;
        m_progress = nextProgress;
        m_positionText = nextPositionText;
        emit changed();
    }
}

void Backend::runAction(const QString &command) {
    if (m_actionProcess.state() != QProcess::NotRunning)
        return;
    m_actionProcess.start(kPlayerctlBin, {command});
}

void Backend::playPause() {
    runAction("play-pause");
}

void Backend::nextTrack() {
    runAction("next");
}

void Backend::prevTrack() {
    runAction("previous");
}

void Backend::refresh() {
    if (m_metaProcess.state() != QProcess::NotRunning)
        return;
    m_metaProcess.start(kPlayerctlBin, {"metadata", "--format", kMetadataFormat});
}
