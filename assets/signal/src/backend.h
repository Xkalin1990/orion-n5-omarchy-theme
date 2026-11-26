#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QTimer>

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString title READ title NOTIFY changed)
    Q_PROPERTY(QString artist READ artist NOTIFY changed)
    Q_PROPERTY(bool playing READ playing NOTIFY changed)
    Q_PROPERTY(bool hasPlayer READ hasPlayer NOTIFY changed)
    Q_PROPERTY(double progress READ progress NOTIFY changed)
    Q_PROPERTY(QString positionText READ positionText NOTIFY changed)

public:
    explicit Backend(QObject *parent = nullptr);
    ~Backend() override;

    QString title() const { return m_title; }
    QString artist() const { return m_artist; }
    bool playing() const { return m_playing; }
    bool hasPlayer() const { return m_hasPlayer; }
    double progress() const { return m_progress; }
    QString positionText() const { return m_positionText; }

    void parseMetadata(const QString &output);

    Q_INVOKABLE void playPause();
    Q_INVOKABLE void nextTrack();
    Q_INVOKABLE void prevTrack();
    Q_INVOKABLE void refresh();

signals:
    void changed();

private:
    void runAction(const QString &command);

    QString m_title = "NO SIGNAL";
    QString m_artist = "Standby";
    bool m_playing = false;
    bool m_hasPlayer = false;
    double m_progress = 0.0;
    QString m_positionText = "00:00";

    QTimer m_pollTimer;
    QProcess m_metaProcess;
    QProcess m_actionProcess;
};
