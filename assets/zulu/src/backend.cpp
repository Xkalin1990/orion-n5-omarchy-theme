#include "backend.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QTimeZone>
#include <QVariantMap>

namespace {

QVector<ZoneSpec> defaultZoneSpecs() {
    return {
        {"UTC", QStringLiteral("ZULU"), QStringLiteral("UTC")},
        {"Europe/London", QStringLiteral("LON"), QStringLiteral("London")},
        {"America/New_York", QStringLiteral("NYC"), QStringLiteral("New York")},
        {"Asia/Tokyo", QStringLiteral("TYO"), QStringLiteral("Tokyo")},
    };
}

} // namespace

Backend::Backend(const QString &configPath, QObject *parent)
    : QObject(parent),
      m_configPath(configPath.isEmpty() ? QDir::homePath() + QStringLiteral("/.config/zulu/zones.json") : configPath),
      m_zoneSpecs(loadZoneSpecs(m_configPath)) {
    // Poll at 250ms so second boundaries never visibly stutter or skip.
    m_timer.setInterval(250);
    connect(&m_timer, &QTimer::timeout, this, &Backend::refresh);
    m_timer.start();
    refresh();
}

QVector<ZoneSpec> Backend::loadZoneSpecs(const QString &configPath) {
    QFile file(configPath);
    if (!file.open(QIODevice::ReadOnly))
        return defaultZoneSpecs();

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isArray())
        return defaultZoneSpecs();

    QVector<ZoneSpec> parsed;
    bool hasUtc = false;
    for (const QJsonValue &entry : doc.array()) {
        if (!entry.isObject())
            continue;
        const QJsonObject obj = entry.toObject();
        const QByteArray ianaId = obj.value(QStringLiteral("zone")).toString().trimmed().toUtf8();
        if (ianaId.isEmpty() || !QTimeZone(ianaId).isValid())
            continue;

        QString code = obj.value(QStringLiteral("code")).toString().trimmed().toUpper();
        if (code.isEmpty())
            code = QString::fromUtf8(ianaId).section(QLatin1Char('/'), -1).left(3).toUpper();

        QString city = obj.value(QStringLiteral("city")).toString().trimmed();
        if (city.isEmpty())
            city = QString::fromUtf8(ianaId).section(QLatin1Char('/'), -1).replace(QLatin1Char('_'), QLatin1Char(' '));

        if (ianaId == "UTC" || ianaId == "Etc/UTC" || code == QStringLiteral("ZULU"))
            hasUtc = true;

        parsed.append({ianaId, code, city});
    }

    if (parsed.isEmpty())
        return defaultZoneSpecs();

    if (!hasUtc)
        parsed.prepend({"UTC", QStringLiteral("ZULU"), QStringLiteral("UTC")});

    return parsed;
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
    updateForUtc(QDateTime::currentDateTimeUtc());
}

void Backend::updateForUtc(const QDateTime &utc, const QDate &referenceDate) {
    const QDateTime utcTime = utc.timeSpec() == Qt::UTC ? utc : utc.toUTC();
    const QDate localDate = referenceDate.isValid() ? referenceDate : utcTime.toLocalTime().date();
    const QLocale locale;

    QVariantList nextZones;
    nextZones.reserve(m_zoneSpecs.size());

    for (const ZoneSpec &spec : m_zoneSpecs) {
        const QTimeZone tz(spec.ianaId);
        const QDateTime zoned = utcTime.toTimeZone(tz.isValid() ? tz : QTimeZone::utc());
        const QTime t = zoned.time();

        QString timeText;
        if (m_use24Hour) {
            timeText = locale.toString(t, m_showSeconds ? QStringLiteral("HH:mm:ss") : QStringLiteral("HH:mm"));
        } else {
            const int hour12 = t.hour() % 12 == 0 ? 12 : t.hour() % 12;
            const QTime displayTime(hour12, t.minute(), t.second());
            const QString hm = locale.toString(displayTime, m_showSeconds ? QStringLiteral("h:mm:ss") : QStringLiteral("h:mm"));
            const QString ap = locale.toString(t, QStringLiteral("AP"));
            timeText = ap.isEmpty() ? hm : hm + QLatin1Char(' ') + ap;
        }

        const qint64 days = localDate.daysTo(zoned.date());
        const QString dayDelta = days == 0
            ? QString()
            : (days > 0 ? QStringLiteral("+%1d").arg(days) : QStringLiteral("%1d").arg(days));

        QVariantMap item;
        item.insert(QStringLiteral("code"), spec.code);
        item.insert(QStringLiteral("city"), spec.city);
        item.insert(QStringLiteral("time"), timeText);
        item.insert(QStringLiteral("dayDelta"), dayDelta);
        nextZones.append(item);
    }

    if (nextZones == m_zones && m_use24Hour == m_lastUse24Hour && m_showSeconds == m_lastShowSeconds)
        return;

    m_zones = nextZones;
    m_lastUse24Hour = m_use24Hour;
    m_lastShowSeconds = m_showSeconds;
    emit changed();
}
