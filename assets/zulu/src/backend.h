#pragma once

#include <QByteArray>
#include <QDate>
#include <QDateTime>
#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVector>

struct ZoneSpec {
    QByteArray ianaId;
    QString code;
    QString city;
};

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList zones READ zones NOTIFY changed)
    Q_PROPERTY(bool use24Hour READ use24Hour NOTIFY changed)
    Q_PROPERTY(bool showSeconds READ showSeconds NOTIFY changed)

public:
    explicit Backend(const QString &configPath = {}, QObject *parent = nullptr);

    QVariantList zones() const { return m_zones; }
    bool use24Hour() const { return m_use24Hour; }
    bool showSeconds() const { return m_showSeconds; }

    Q_INVOKABLE void toggle24Hour();
    Q_INVOKABLE void toggleSeconds();
    Q_INVOKABLE void refresh();

    void updateForUtc(const QDateTime &utc, const QDate &referenceDate = {});

    static QVector<ZoneSpec> loadZoneSpecs(const QString &configPath);

signals:
    void changed();

private:
    QString m_configPath;
    QVector<ZoneSpec> m_zoneSpecs;
    QTimer m_timer;
    QVariantList m_zones;
    bool m_use24Hour = true;
    bool m_showSeconds = true;
    bool m_lastUse24Hour = true;
    bool m_lastShowSeconds = true;
};
