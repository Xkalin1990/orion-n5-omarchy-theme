#include "backend.h"

#include <QDir>
#include <QFileInfo>
#include <QProcess>

namespace {
struct Preset {
    int minutes;
    const char *label;
};

constexpr Preset kPresets[] = {
    {25, "25M"},
    {15, "15M"},
    {5, "05M"},
};
constexpr int kPresetCount = sizeof(kPresets) / sizeof(kPresets[0]);
constexpr qint64 kMinDurationMs = 60 * 1000;
constexpr qint64 kMaxDurationMs = 99 * 60 * 1000;
} // namespace

Backend::Backend(QObject *parent) : QObject(parent) {
    m_timer.setInterval(250);
    connect(&m_timer, &QTimer::timeout, this, &Backend::tick);
}

QString Backend::formatSeconds(qint64 totalSeconds) {
    const qint64 mins = totalSeconds / 60;
    const qint64 secs = totalSeconds % 60;
    return QStringLiteral("%1:%2")
        .arg(mins, 2, 10, QLatin1Char('0'))
        .arg(secs, 2, 10, QLatin1Char('0'));
}

qint64 Backend::currentElapsedMs() const {
    return m_accumulatedMs + (m_running ? m_elapsed.elapsed() : 0);
}

QString Backend::timeText() const {
    if (m_stopwatch)
        return formatSeconds(currentElapsedMs() / 1000);

    const qint64 remMs = qMax<qint64>(0, m_durationMs - currentElapsedMs());
    const qint64 totalSec = remMs > 0 ? (remMs + 999) / 1000 : 0;
    return formatSeconds(totalSec);
}

double Backend::progress() const {
    if (m_stopwatch || m_durationMs <= 0)
        return 0.0;
    const qint64 remMs = qMax<qint64>(0, m_durationMs - currentElapsedMs());
    return qBound(0.0, double(m_durationMs - remMs) / double(m_durationMs), 1.0);
}

QString Backend::presetLabel() const {
    if (m_stopwatch)
        return tr("STOPWATCH");
    return tr(kPresets[m_presetIndex].label);
}

void Backend::toggleRunning() {
    if (m_running) {
        m_accumulatedMs += m_elapsed.elapsed();
        m_running = false;
        m_timer.stop();
    } else {
        if (!m_stopwatch && m_finished) {
            m_accumulatedMs = 0;
            m_finished = false;
        }
        m_elapsed.start();
        m_running = true;
        m_timer.start();
    }
    emit changed();
}

void Backend::reset() {
    m_running = false;
    m_timer.stop();
    m_accumulatedMs = 0;
    m_finished = false;
    if (!m_stopwatch)
        m_durationMs = qint64(kPresets[m_presetIndex].minutes) * 60 * 1000;
    emit changed();
}

void Backend::nextPreset() {
    if (m_stopwatch) {
        m_stopwatch = false;
        m_presetIndex = 0;
    } else {
        m_presetIndex = (m_presetIndex + 1) % kPresetCount;
    }
    m_running = false;
    m_timer.stop();
    m_accumulatedMs = 0;
    m_finished = false;
    m_durationMs = qint64(kPresets[m_presetIndex].minutes) * 60 * 1000;
    emit changed();
}

void Backend::adjustMinutes(int delta) {
    if (m_stopwatch || delta == 0)
        return;

    const qint64 deltaMs = qint64(delta) * 60 * 1000;
    const qint64 currentRem = qMax<qint64>(0, m_durationMs - currentElapsedMs());
    const qint64 newRem = qBound(kMinDurationMs, currentRem + deltaMs, kMaxDurationMs);

    if (m_running)
        m_elapsed.start();
    m_accumulatedMs = 0;
    m_durationMs = newRem;
    m_finished = false;
    emit changed();
}

void Backend::toggleStopwatch() {
    m_stopwatch = !m_stopwatch;
    m_running = false;
    m_timer.stop();
    m_accumulatedMs = 0;
    m_finished = false;
    if (!m_stopwatch)
        m_durationMs = qint64(kPresets[m_presetIndex].minutes) * 60 * 1000;
    emit changed();
}

void Backend::advanceMs(qint64 ms) {
    m_accumulatedMs += ms;
    if (!m_stopwatch && m_durationMs - currentElapsedMs() <= 0) {
        m_accumulatedMs = m_durationMs;
        m_running = false;
        m_timer.stop();
        if (!m_finished) {
            m_finished = true;
            playFinishSound();
        }
    }
    emit changed();
}

void Backend::refresh() {
    emit changed();
}

void Backend::tick() {
    if (!m_stopwatch && m_running && m_durationMs - currentElapsedMs() <= 0) {
        m_accumulatedMs = m_durationMs;
        m_running = false;
        m_timer.stop();
        if (!m_finished) {
            m_finished = true;
            playFinishSound();
        }
    }
    emit changed();
}

void Backend::playFinishSound() const {
    if (!m_soundEnabled)
        return;
    const QString path = QDir::homePath() + "/.config/omarchy/themes/orion-n5/assets/sounds/telemetry-activate.wav";
    if (QFileInfo::exists(path))
        QProcess::startDetached("pw-play", {path});
}
