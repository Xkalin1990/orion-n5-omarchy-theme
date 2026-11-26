#pragma once

#include <QDateTime>
#include <QElapsedTimer>
#include <QObject>
#include <QProcess>
#include <QStringList>
#include <QTcpSocket>
#include <QTimer>
#include <QVariantList>

// 01 // EPOCH — Live clock, seconds, ISO week, and localized date.
class EpochBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString timeText READ timeText NOTIFY changed)
    Q_PROPERTY(QString secondsText READ secondsText NOTIFY changed)
    Q_PROPERTY(QString ampmText READ ampmText NOTIFY changed)
    Q_PROPERTY(QString dateText READ dateText NOTIFY changed)
    Q_PROPERTY(QString weekText READ weekText NOTIFY changed)
    Q_PROPERTY(double minuteProgress READ minuteProgress NOTIFY changed)
    Q_PROPERTY(bool use24Hour READ use24Hour NOTIFY changed)
    Q_PROPERTY(bool showSeconds READ showSeconds NOTIFY changed)

public:
    explicit EpochBackend(QObject *parent = nullptr);

    QString timeText() const { return m_timeText; }
    QString secondsText() const { return m_secondsText; }
    QString ampmText() const { return m_ampmText; }
    QString dateText() const { return m_dateText; }
    QString weekText() const { return m_weekText; }
    double minuteProgress() const { return m_minuteProgress; }
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
    QString m_timeText;
    QString m_secondsText;
    QString m_ampmText;
    QString m_dateText;
    QString m_weekText;
    double m_minuteProgress = 0.0;
    bool m_use24Hour = true;
    bool m_showSeconds = true;
};

// 02 // T-MINUS — Mission countdown, Pomodoro presets, and stopwatch.
class TminusBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString timeText READ timeText NOTIFY changed)
    Q_PROPERTY(double progress READ progress NOTIFY changed)
    Q_PROPERTY(bool running READ running NOTIFY changed)
    Q_PROPERTY(QString presetLabel READ presetLabel NOTIFY changed)
    Q_PROPERTY(int presetIndex READ presetIndex NOTIFY changed)
    Q_PROPERTY(bool finished READ finished NOTIFY changed)
    Q_PROPERTY(bool stopwatch READ stopwatch NOTIFY changed)

public:
    explicit TminusBackend(QObject *parent = nullptr);

    QString timeText() const;
    double progress() const;
    bool running() const { return m_running; }
    QString presetLabel() const;
    int presetIndex() const { return m_presetIndex; }
    bool finished() const { return m_finished; }
    bool stopwatch() const { return m_stopwatch; }

    Q_INVOKABLE void toggleRunning();
    Q_INVOKABLE void reset();
    Q_INVOKABLE void nextPreset();
    Q_INVOKABLE void selectPreset(int index);
    Q_INVOKABLE void adjustMinutes(int delta);
    Q_INVOKABLE void toggleStopwatch();

signals:
    void changed();

private:
    void tick();
    void playChime();
    qint64 currentMs() const;

    QTimer m_timer;
    QElapsedTimer m_elapsed;
    int m_presetIndex = 0; // 0: 25m, 1: 15m, 2: 5m
    qint64 m_durationMs = 25 * 60 * 1000;
    qint64 m_accumulatedMs = 0;
    bool m_running = false;
    bool m_finished = false;
    bool m_stopwatch = false;
};

// 03 // UPLINK — Live connection & service beacon with latency history.
class UplinkBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString statusText READ statusText NOTIFY changed)
    Q_PROPERTY(int latencyMs READ latencyMs NOTIFY changed)
    Q_PROPERTY(bool online READ online NOTIFY changed)
    Q_PROPERTY(QString targetLabel READ targetLabel NOTIFY changed)
    Q_PROPERTY(int targetIndex READ targetIndex NOTIFY changed)
    Q_PROPERTY(QStringList targetNames READ targetNames NOTIFY changed)
    Q_PROPERTY(QVariantList history READ history NOTIFY changed)
    Q_PROPERTY(QString targetsSummary READ targetsSummary NOTIFY changed)

public:
    explicit UplinkBackend(bool autoPoll = true, QObject *parent = nullptr);
    ~UplinkBackend() override;

    QString statusText() const { return m_statusText; }
    int latencyMs() const { return m_latencyMs; }
    bool online() const { return m_online; }
    QString targetLabel() const;
    int targetIndex() const { return m_targetIndex; }
    QStringList targetNames() const;
    QVariantList history() const { return m_history; }
    QString targetsSummary() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void cycleTarget();
    Q_INVOKABLE void selectTarget(int index);

    static int parsePingMs(const QString &output);
    void applyProbeResult(bool ok, int ms);

signals:
    void changed();

private:
    struct Target {
        QString label;
        QString host;
        quint16 port;
        bool up = false;
    };

    void probeTarget(int index);

    QList<Target> m_targets;
    int m_targetIndex = 0;
    QString m_statusText = "PROBING";
    int m_latencyMs = -1;
    bool m_online = false;
    QVariantList m_history;
    QTimer m_pollTimer;
    QProcess m_pingProcess;
    QTcpSocket m_socket;
    QTimer m_socketTimeout;
    QElapsedTimer m_socketTimer;
};

// 04 // SIGNAL — Minimal MPRIS (playerctl) Now Playing strip.
class SignalBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString title READ title NOTIFY changed)
    Q_PROPERTY(QString artist READ artist NOTIFY changed)
    Q_PROPERTY(bool playing READ playing NOTIFY changed)
    Q_PROPERTY(bool hasPlayer READ hasPlayer NOTIFY changed)
    Q_PROPERTY(double progress READ progress NOTIFY changed)
    Q_PROPERTY(QString positionText READ positionText NOTIFY changed)
    Q_PROPERTY(QString durationText READ durationText NOTIFY changed)

public:
    explicit SignalBackend(bool autoPoll = true, QObject *parent = nullptr);
    ~SignalBackend() override;

    QString title() const { return m_title; }
    QString artist() const { return m_artist; }
    bool playing() const { return m_playing; }
    bool hasPlayer() const { return m_hasPlayer; }
    double progress() const { return m_progress; }
    QString positionText() const { return m_positionText; }
    QString durationText() const { return m_durationText; }

    Q_INVOKABLE void playPause();
    Q_INVOKABLE void nextTrack();
    Q_INVOKABLE void prevTrack();
    Q_INVOKABLE void refresh();

    void parseMetadata(const QString &output);

signals:
    void changed();

private:
    static QString formatSeconds(qint64 seconds);
    void runAction(const QString &arg);

    QString m_playerctl;
    QTimer m_pollTimer;
    QProcess m_metaProcess;
    QString m_title = "NO SIGNAL";
    QString m_artist = "Standby";
    bool m_playing = false;
    bool m_hasPlayer = false;
    double m_progress = 0.0;
    QString m_positionText = "00:00";
    QString m_durationText = "00:00";
};

// 05 // SLATE — Auto-saving floating telemetry scratchpad.
class SlateBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY changed)
    Q_PROPERTY(bool saved READ saved NOTIFY changed)
    Q_PROPERTY(int charCount READ charCount NOTIFY changed)
    Q_PROPERTY(int lineCount READ lineCount NOTIFY changed)
    Q_PROPERTY(int wordCount READ wordCount NOTIFY changed)

public:
    explicit SlateBackend(const QString &notePath = {}, QObject *parent = nullptr);
    ~SlateBackend() override;

    QString text() const { return m_text; }
    void setText(const QString &text);
    bool saved() const { return m_saved; }
    int charCount() const { return m_text.size(); }
    int lineCount() const;
    int wordCount() const;

    Q_INVOKABLE void saveNow();
    Q_INVOKABLE void clear();
    Q_INVOKABLE void copyToClipboard() const;

signals:
    void changed();

private:
    void load();

    QString m_notePath;
    QString m_text;
    bool m_saved = true;
    QTimer m_saveTimer;
};

// 06 // ZULU — Multi-zone mission clock strip.
class ZuluBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList zones READ zones NOTIFY changed)
    Q_PROPERTY(bool use24Hour READ use24Hour NOTIFY changed)
    Q_PROPERTY(bool showSeconds READ showSeconds NOTIFY changed)

public:
    explicit ZuluBackend(QObject *parent = nullptr);

    QVariantList zones() const { return m_zones; }
    bool use24Hour() const { return m_use24Hour; }
    bool showSeconds() const { return m_showSeconds; }

    Q_INVOKABLE void toggle24Hour();
    Q_INVOKABLE void toggleSeconds();
    Q_INVOKABLE void refresh();

    void updateForUtc(const QDateTime &utc, const QDate &localDate = {});

signals:
    void changed();

private:
    struct ZoneDef {
        QString code;
        QString city;
        QByteArray ianaId;
    };

    QList<ZoneDef> m_defs;
    QVariantList m_zones;
    bool m_use24Hour = true;
    bool m_showSeconds = false;
    QTimer m_timer;
};
