#pragma once

#include <QFileSystemWatcher>
#include <QObject>
#include <QProcess>
#include <QTimer>

class Theme : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString accent READ accent NOTIFY changed)
    Q_PROPERTY(QString accentForeground READ accentForeground NOTIFY changed)
    Q_PROPERTY(QString background READ background NOTIFY changed)
    Q_PROPERTY(QString surface READ surface NOTIFY changed)
    Q_PROPERTY(QString foreground READ foreground NOTIFY changed)
    Q_PROPERTY(QString brightForeground READ brightForeground NOTIFY changed)
    Q_PROPERTY(QString muted READ muted NOTIFY changed)
    Q_PROPERTY(QString fontFamily READ fontFamily NOTIFY changed)
    Q_PROPERTY(int radius READ radius NOTIFY changed)

public:
    explicit Theme(const QString &currentDirectory = {}, QObject *parent = nullptr, const QString &hyprctl = {});
    ~Theme() override;

    QString accent() const { return m_accent; }
    QString accentForeground() const;
    QString background() const { return m_background; }
    QString surface() const { return m_surface; }
    QString foreground() const { return m_foreground; }
    QString brightForeground() const { return m_brightForeground; }
    QString muted() const { return m_muted; }
    QString fontFamily() const { return m_fontFamily; }
    int radius() const { return m_radius; }

    static QString readAccent(const QString &path);
    static QString readColor(const QString &contents, const QString &key, const QString &fallback);
    static QString readSystemFont();

signals:
    void changed();

private:
    void reload();
    void refreshRounding();

    QString m_directory;
    QString m_accent = "#FFD60A";
    QString m_background = "#141615";
    QString m_surface = "#1e2220";
    QString m_foreground = "#c4ddd0";
    QString m_brightForeground = "#eef7f2";
    QString m_muted = "#54685e";
    QString m_fontFamily = "monospace";
    QFileSystemWatcher m_watcher;
    QTimer m_debounce;
    QString m_hyprctl;
    int m_radius = 0;
    QProcess m_roundingProcess;
    QTimer m_roundingPoll, m_roundingTimeout;
};
