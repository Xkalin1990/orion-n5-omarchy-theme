#pragma once

#include <QElapsedTimer>
#include <QObject>
#include <QPointer>
#include <QProcess>
#include <QTcpSocket>
#include <QTimer>
#include <QVariantList>
#include <QVector>

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString statusText READ statusText NOTIFY changed)
    Q_PROPERTY(int latencyMs READ latencyMs NOTIFY changed)
    Q_PROPERTY(bool online READ online NOTIFY changed)
    Q_PROPERTY(QString targetLabel READ targetLabel NOTIFY changed)
    Q_PROPERTY(QVariantList targets READ targets NOTIFY changed)
    Q_PROPERTY(QString targetsSummary READ targetsSummary NOTIFY changed)

public:
    struct Target {
        QString label;
        QString host;
        quint16 port = 443;
        bool usePing = false;
        bool up = false;
        int latencyMs = -1;
    };

    explicit Backend(const QString &configPath = {}, bool autoStart = true, QObject *parent = nullptr);
    ~Backend() override;

    QString statusText() const { return m_statusText; }
    int latencyMs() const { return m_latencyMs; }
    bool online() const { return m_online; }
    QString targetLabel() const { return m_targetLabel; }
    QVariantList targets() const;
    QString targetsSummary() const { return m_targetsSummary; }
    int activeIndex() const { return m_activeIndex; }
    int targetCount() const { return m_targets.size(); }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void cycleTarget();

    // Deterministic helpers exposed for testing state transitions without network flakiness.
    void applyTargetResult(int index, bool up, int latencyMs);
    static QVector<Target> loadTargets(const QString &configPath);
    static int parsePingLatencyMs(const QString &pingOutput);

signals:
    void changed();

private:
    struct ProbeState {
        int generation = 0;
        bool tcpDone = false;
        bool tcpUp = false;
        int tcpLatencyMs = -1;
        bool pingDone = true;
        bool pingUp = false;
        int pingLatencyMs = -1;
        QPointer<QTcpSocket> socket;
        QPointer<QTimer> tcpTimer;
        QPointer<QProcess> pingProcess;
        QPointer<QTimer> pingTimer;
    };

    void probeTarget(int index);
    void finishProbeIfReady(int index, int generation);
    void cancelActiveProbes();
    void recomputeState();

    QVector<Target> m_targets;
    QVector<ProbeState> m_probes;
    int m_activeIndex = 0;
    int m_generation = 0;

    QString m_statusText = QStringLiteral("OFFLINE");
    int m_latencyMs = -1;
    bool m_online = false;
    QString m_targetLabel;
    QString m_targetsSummary;

    QTimer m_pollTimer;
};
