#pragma once

#include <QFileSystemWatcher>
#include <QHash>
#include <QObject>
#include <QPoint>
#include <QPointer>
#include <QString>
#include <QTimer>
#include <QWindow>

class DeckBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool epochVisible READ epochVisible NOTIFY changed)
    Q_PROPERTY(bool tminusVisible READ tminusVisible NOTIFY changed)
    Q_PROPERTY(bool uplinkVisible READ uplinkVisible NOTIFY changed)
    Q_PROPERTY(bool signalVisible READ signalVisible NOTIFY changed)
    Q_PROPERTY(bool slateVisible READ slateVisible NOTIFY changed)
    Q_PROPERTY(bool zuluVisible READ zuluVisible NOTIFY changed)
    Q_PROPERTY(bool sysVisible READ sysVisible NOTIFY changed)
    Q_PROPERTY(bool compact READ compact NOTIFY changed)
    Q_PROPERTY(int activeCount READ activeCount NOTIFY changed)

public:
    explicit DeckBackend(const QString &statePath = {}, QObject *parent = nullptr);

    bool epochVisible() const { return m_epoch; }
    bool tminusVisible() const { return m_tminus; }
    bool uplinkVisible() const { return m_uplink; }
    bool signalVisible() const { return m_signal; }
    bool slateVisible() const { return m_slate; }
    bool zuluVisible() const { return m_zulu; }
    bool sysVisible() const { return m_sys; }
    bool compact() const { return m_compact; }
    int activeCount() const;

    Q_INVOKABLE void registerLayerWindow(QWindow *window, const QString &id);
    Q_INVOKABLE void moveWindowBy(QWindow *window, const QString &id, int dx, int dy);
    Q_INVOKABLE void toggle(const QString &id);
    Q_INVOKABLE void setCardVisible(const QString &id, bool visible);
    Q_INVOKABLE void toggleAll();
    Q_INVOKABLE void toggleCompact();
    Q_INVOKABLE void setCompact(bool compact);
    Q_INVOKABLE void arrangeCard(const QString &id);
    Q_INVOKABLE void arrangeAll();

signals:
    void changed();

private:
    void load();
    void reloadFromDisk();
    void armWatcher();
    void save() const;
    void applyLayerProps(QWindow *window, const QString &id);
    void setWindowMargin(const QString &id, const QPoint &pos);
    bool isCardVisible(const QString &id) const;

    QString m_statePath;
    QFileSystemWatcher m_watcher;
    QTimer m_reloadDebounce;
    QHash<QString, QPointer<QWindow>> m_windows;
    QHash<QString, QPoint> m_positions;
    bool m_epoch = true;
    bool m_tminus = false;
    bool m_uplink = false;
    bool m_signal = false;
    bool m_slate = false;
    bool m_zulu = false;
    bool m_sys = false;
    bool m_compact = false;
};
