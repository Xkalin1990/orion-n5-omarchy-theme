#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QLocale>
#include <QTemporaryDir>
#include <QtTest>

#include "backend.h"
#include "theme.h"
#include "translator.h"

class TickTests : public QObject {
    Q_OBJECT

private slots:
    void formatsTimeIn24And12HourModes()
    {
        QLocale::setDefault(QLocale::c());
        Backend backend;
        const QDateTime dt(QDate(2026, 11, 26), QTime(14, 5, 9));
        backend.updateForDateTime(dt);

        QVERIFY(backend.use24Hour());
        QCOMPARE(backend.timeText(), QString("14:05"));
        QCOMPARE(backend.secondsText(), QString("09"));
        QVERIFY(backend.ampmText().isEmpty());

        backend.toggle24Hour();
        backend.updateForDateTime(dt);
        QVERIFY(!backend.use24Hour());
        QCOMPARE(backend.timeText(), QString("2:05"));
        QCOMPARE(backend.secondsText(), QString("09"));
        QVERIFY(!backend.ampmText().isEmpty());
    }

    void togglesSecondsVisibility()
    {
        Backend backend;
        QVERIFY(backend.showSeconds());
        backend.toggleSeconds();
        QVERIFY(!backend.showSeconds());
        backend.toggleSeconds();
        QVERIFY(backend.showSeconds());
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

QTEST_MAIN(TickTests)
#include "tick_tests.moc"
