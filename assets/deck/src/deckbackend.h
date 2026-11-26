#pragma once

#include <QObject>
#include <QString>

class DeckBackend : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool epochVisible READ epochVisible NOTIFY changed)
    Q_PROPERTY(bool tminusVisible READ tminusVisible NOTIFY changed)
    Q_PROPERTY(bool uplinkVisible READ uplinkVisible NOTIFY changed)
    Q_PROPERTY(bool signalVisible READ signalVisible NOTIFY changed)
    Q_PROPERTY(bool slateVisible READ slateVisible NOTIFY changed)
    Q_PROPERTY(bool zuluVisible READ zuluVisible NOTIFY changed)
    Q_PROPERTY(int activeCount READ activeCount NOTIFY changed)

public:
    explicit DeckBackend(const QString &statePath = {}, QObject *parent = nullptr);

    bool epochVisible() const { return m_epoch; }
    bool tminusVisible() const { return m_tminus; }
    bool uplinkVisible() const { return m_uplink; }
    bool signalVisible() const { return m_signal; }
    bool slateVisible() const { return m_slate; }
    bool zuluVisible() const { return m_zulu; }
    int activeCount() const;

    Q_INVOKABLE void toggle(const QString &id);
    Q_INVOKABLE void setCardVisible(const QString &id, bool visible);
    Q_INVOKABLE void toggleAll();

signals:
    void changed();

private:
    void load();
    void save() const;

    QString m_statePath;
    bool m_epoch = true;
    bool m_tminus = false;
    bool m_uplink = false;
    bool m_signal = false;
    bool m_slate = false;
    bool m_zulu = false;
};
