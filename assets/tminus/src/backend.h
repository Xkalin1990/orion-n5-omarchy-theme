#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QTimer>

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString timeText READ timeText NOTIFY changed)
    Q_PROPERTY(double progress READ progress NOTIFY changed)
    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(QString presetLabel READ presetLabel NOTIFY changed)
    Q_PROPERTY(bool finished READ finished NOTIFY changed)
    Q_PROPERTY(bool stopwatch READ stopwatch NOTIFY changed)

public:
    explicit Backend(QObject *parent = nullptr);

    QString timeText() const;
    double progress() const;
    bool running() const { return m_running; }
    QString presetLabel() const;
    bool finished() const { return m_finished; }
    bool stopwatch() const { return m_stopwatch; }

    Q_INVOKABLE void toggleRunning();
    Q_INVOKABLE void reset();
    Q_INVOKABLE void nextPreset();
    Q_INVOKABLE void adjustMinutes(int delta);
    Q_INVOKABLE void toggleStopwatch();

    void advanceMs(qint64 ms);
    void setSoundEnabled(bool enabled) { m_soundEnabled = enabled; }

public slots:
    void refresh();

signals:
    void changed();

private:
    void tick();
    qint64 currentElapsedMs() const;
    void playFinishSound() const;
    static QString formatSeconds(qint64 totalSeconds);

    QTimer m_timer;
    QElapsedTimer m_elapsed;
    qint64 m_durationMs = 25 * 60 * 1000;
    qint64 m_accumulatedMs = 0;
    int m_presetIndex = 0;
    bool m_running = false;
    bool m_stopwatch = false;
    bool m_finished = false;
    bool m_soundEnabled = true;
};
