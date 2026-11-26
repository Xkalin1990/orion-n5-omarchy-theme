#include "backend.h"

#include <QLocale>

Backend::Backend(QObject *parent) : QObject(parent) {
    // Poll at 250ms so second boundaries never visibly stutter or skip.
    m_timer.setInterval(250);
    connect(&m_timer, &QTimer::timeout, this, &Backend::refresh);
    m_timer.start();
    refresh();
}

void Backend::toggle24Hour() {
    m_use24Hour = !m_use24Hour;
    refresh();
}

void Backend::toggleSeconds() {
    m_showSeconds = !m_showSeconds;
    refresh();
}

void Backend::refresh() {
    updateForDateTime(QDateTime::currentDateTime());
}

void Backend::updateForDateTime(const QDateTime &now) {
    const QLocale locale;
    const QTime t = now.time();
    const int hour12 = t.hour() % 12 == 0 ? 12 : t.hour() % 12;
    const QTime displayTime = m_use24Hour ? t : QTime(hour12, t.minute(), t.second());
    const QString timeFormat = m_use24Hour ? "HH:mm" : "h:mm";
    const QString timeText = locale.toString(displayTime, timeFormat);
    const QString secondsText = locale.toString(t, "ss");
    const QString ampmText = m_use24Hour ? QString() : locale.toString(t, "AP");
    const QString dateText = locale.toString(now.date(), QLocale::LongFormat);

    if (timeText == m_timeText && secondsText == m_secondsText
        && ampmText == m_ampmText && dateText == m_dateText
        && m_lastShown.isValid()) {
        return;
    }

    m_lastShown = now;
    m_timeText = timeText;
    m_secondsText = secondsText;
    m_ampmText = ampmText;
    m_dateText = dateText;
    emit changed();
}
