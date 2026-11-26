#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QLocale>
#include <QTemporaryDir>
#include <QtTest>

#include "backend.h"
#include "theme.h"
#include "translator.h"

class ZuluTests : public QObject {
    Q_OBJECT

private slots:
    void formatsDefaultZonesIn24And12HourModes()
    {
        QLocale::setDefault(QLocale::c());
        QTemporaryDir dir;
        Backend backend(dir.filePath("missing.json"));

        // 2026-11-26 18:05:09 UTC:
        // UTC: 18:05:09 (Nov 26)
        // Europe/London (GMT, UTC+0 in Nov): 18:05:09 (Nov 26)
        // America/New_York (EST, UTC-5 in Nov): 13:05:09 (Nov 26)
        // Asia/Tokyo (JST, UTC+9): 03:05:09 (Nov 27 -> +1d relative to Nov 26)
        const QDateTime utc(QDate(2026, 11, 26), QTime(18, 5, 9), QTimeZone::utc());
        backend.updateForUtc(utc, QDate(2026, 11, 26));

        QVERIFY(backend.use24Hour());
        QVERIFY(backend.showSeconds());

        const QVariantList zones24 = backend.zones();
        QCOMPARE(zones24.size(), 4);

        QCOMPARE(zones24[0].toMap().value("code").toString(), QString("ZULU"));
        QCOMPARE(zones24[0].toMap().value("time").toString(), QString("18:05:09"));
        QCOMPARE(zones24[0].toMap().value("dayDelta").toString(), QString(""));

        QCOMPARE(zones24[1].toMap().value("code").toString(), QString("LON"));
        QCOMPARE(zones24[1].toMap().value("time").toString(), QString("18:05:09"));

        QCOMPARE(zones24[2].toMap().value("code").toString(), QString("NYC"));
        QCOMPARE(zones24[2].toMap().value("time").toString(), QString("13:05:09"));

        QCOMPARE(zones24[3].toMap().value("code").toString(), QString("TYO"));
        QCOMPARE(zones24[3].toMap().value("time").toString(), QString("03:05:09"));
        QCOMPARE(zones24[3].toMap().value("dayDelta").toString(), QString("+1d"));

        backend.toggle24Hour();
        backend.updateForUtc(utc, QDate(2026, 11, 26));
        QVERIFY(!backend.use24Hour());

        const QVariantList zones12 = backend.zones();
        QCOMPARE(zones12[0].toMap().value("time").toString(), QString("6:05:09 PM"));
        QCOMPARE(zones12[2].toMap().value("time").toString(), QString("1:05:09 PM"));
        QCOMPARE(zones12[3].toMap().value("time").toString(), QString("3:05:09 AM"));
    }

    void togglesSecondsAndComputesNegativeDayDelta()
    {
        QLocale::setDefault(QLocale::c());
        QTemporaryDir dir;
        Backend backend(dir.filePath("missing.json"));

        const QDateTime utc(QDate(2026, 11, 26), QTime(2, 15, 30), QTimeZone::utc());
        backend.toggleSeconds();
        QVERIFY(!backend.showSeconds());

        backend.updateForUtc(utc, QDate(2026, 11, 26));
        const QVariantList zones = backend.zones();
        QCOMPARE(zones[0].toMap().value("time").toString(), QString("02:15"));
        // NYC is 21:15 on Nov 25 -> -1d relative to Nov 26
        QCOMPARE(zones[2].toMap().value("time").toString(), QString("21:15"));
        QCOMPARE(zones[2].toMap().value("dayDelta").toString(), QString("-1d"));
    }

    void loadsCustomZonesFromJson()
    {
        QLocale::setDefault(QLocale::c());
        QTemporaryDir dir;
        const QString configPath = dir.filePath("zones.json");
        write(configPath,
              R"([
                  {"zone": "Europe/Paris", "code": "PAR", "city": "Paris"},
                  {"zone": "Australia/Sydney", "code": "SYD", "city": "Sydney"}
              ])");

        Backend backend(configPath);
        const QDateTime utc(QDate(2026, 11, 26), QTime(12, 0, 0), QTimeZone::utc());
        backend.updateForUtc(utc, QDate(2026, 11, 26));

        const QVariantList zones = backend.zones();
        QCOMPARE(zones.size(), 3);
        QCOMPARE(zones[0].toMap().value("code").toString(), QString("ZULU"));
        QCOMPARE(zones[1].toMap().value("code").toString(), QString("PAR"));
        QCOMPARE(zones[1].toMap().value("city").toString(), QString("Paris"));
        QCOMPARE(zones[2].toMap().value("code").toString(), QString("SYD"));
    }

    void themeFallsBack()
    {
        QTemporaryDir dir;
        Theme theme(dir.path());
        QCOMPARE(theme.accent(), QString("#FFD60A"));
        QCOMPARE(theme.accentForeground(), QString("black"));
        QCOMPARE(theme.background(), QString("#141615"));
        QVERIFY(!theme.fontFamily().isEmpty());
    }

    void themeReadsColors()
    {
        QTemporaryDir dir;
        QDir(dir.path()).mkpath("theme");
        write(dir.path() + "/theme/colors.toml",
              "accent = \"#112233\"\n"
              "background = \"#101214\"\n"
              "lighter_background = \"#1b1f23\"\n"
              "foreground = \"#d0d8e0\"\n"
              "bright_foreground = \"#ffffff\"\n"
              "muted = \"#607080\"\n");

        Theme theme(dir.path());
        QCOMPARE(theme.accent(), QString("#112233"));
        QCOMPARE(theme.accentForeground(), QString("white"));
        QCOMPARE(theme.background(), QString("#101214"));
        QCOMPARE(theme.surface(), QString("#1b1f23"));
        QCOMPARE(theme.foreground(), QString("#d0d8e0"));
        QCOMPARE(theme.brightForeground(), QString("#ffffff"));
        QCOMPARE(theme.muted(), QString("#607080"));
    }

    void themeFollowsHyprlandRounding()
    {
        QTemporaryDir dir;
        const QString response = dir.filePath("response.json");
        const QString command = dir.filePath("hyprctl");
        QVERIFY(writeFile(command, "#!/bin/sh\ncat '" + response.toUtf8() + "'\n"));
        QVERIFY(QFile::setPermissions(command, QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner));
        QVERIFY(writeFile(response, "{\"int\":0}"));

        Theme theme(dir.path(), nullptr, command);
        QCOMPARE(theme.radius(), 0);
        QVERIFY(writeFile(response, "{\"int\":6}"));
        QTRY_COMPARE(theme.radius(), 6);
    }

    void translatorFallsBackToEnglish()
    {
        QTemporaryDir dir;
        Translator translator(dir.path() + "/language", dir.path());
        QCOMPARE(translator.language(), QString("en"));
        QVERIFY(translator.translate("Main", "Quit").isNull());
    }

    void translatorFollowsTheLanguageFile()
    {
        QTemporaryDir dir;
        write(dir.path() + "/language", "pt-BR\n");
        write(dir.path() + "/pt.json", R"({"Quit": "Sair", "24H": "24H"})");
        write(dir.path() + "/pt-BR.json", R"({"Quit": "Fechar"})");

        Translator translator(dir.path() + "/language", dir.path());
        QCOMPARE(translator.language(), QString("pt-BR"));
        QCOMPARE(translator.translate("Main", "Quit"), QString("Fechar"));
        QCOMPARE(translator.translate("Main", "24H"), QString("24H"));
        QVERIFY(translator.translate("Main", "Missing").isNull());
    }

private:
    static bool writeFile(const QString &path, const QByteArray &contents)
    {
        QFile file(path);
        return file.open(QIODevice::WriteOnly) && file.write(contents) == contents.size();
    }

    static void write(const QString &path, const QByteArray &contents)
    {
        QVERIFY(writeFile(path, contents));
    }
};

QTEST_MAIN(ZuluTests)
#include "zulu_tests.moc"
