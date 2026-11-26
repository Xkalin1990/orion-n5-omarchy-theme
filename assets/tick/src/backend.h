#pragma once

#include <QDateTime>
#include <QObject>
#include <QTimer>

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString timeText READ timeText NOTIFY changed)
    Q_PROPERTY(QString secondsText READ secondsText NOTIFY changed)
    Q_PROPERTY(QString ampmText READ ampmText NOTIFY changed)
    Q_PROPERTY(QString dateText READ dateText NOTIFY changed)
    Q_PROPERTY(bool use24Hour READ use24Hour NOTIFY changed)
    Q_PROPERTY(bool showSeconds READ showSeconds NOTIFY changed)

public:
    explicit Backend(QObject *parent = nullptr);

    QString timeText() const { return m_timeText; }
    QString secondsText() const { return m_secondsText; }
    QString ampmText() const { return m_ampmText; }
    QString dateText() const { return m_dateText; }
    bool use24Hour() const { return m_use24Hour; }
    bool showSeconds() const { return m_showSeconds; }

    Q_INVOKABLE void toggle24Hour();
    Q_INVOKABLE void toggleSeconds();
    Q_INVOKABLE void refresh();

    void updateForDateTime(const QDateTime &now);

signals:
    void changed();

private:
    QTimer m_timer;
    QDateTime m_lastShown;
    QString m_timeText;
    QString m_secondsText;
    QString m_ampmText;
    QString m_dateText;
    bool m_use24Hour = true;
    bool m_showSeconds = true;
};
