#include <QDir>
#include <QFile>
#include <QTemporaryDir>
#include <QtTest>

#include "backend.h"
#include "theme.h"
#include "translator.h"

class TminusTests : public QObject {
    Q_OBJECT

private slots:
    void countdownTracksProgressAndFinishes()
    {
        Backend backend;
        backend.setSoundEnabled(false);

        QCOMPARE(backend.presetLabel(), QString("25M"));
        QCOMPARE(backend.timeText(), QString("25:00"));
        QCOMPARE(backend.progress(), 0.0);
        QVERIFY(!backend.running());
        QVERIFY(!backend.finished());

        backend.toggleRunning();
        QVERIFY(backend.running());

        // Advance 12.5 minutes (halfway through 25:00).
        backend.advanceMs(750 * 1000);
        QCOMPARE(backend.timeText(), QString("12:30"));
        QVERIFY(qAbs(backend.progress() - 0.5) < 0.001);
        QVERIFY(!backend.finished());

        // Advance remaining 12.5 minutes to 00:00.
        backend.advanceMs(750 * 1000);
        QCOMPARE(backend.timeText(), QString("00:00"));
        QCOMPARE(backend.progress(), 1.0);
        QVERIFY(!backend.running());
        QVERIFY(backend.finished());
    }

    void pauseAndResumePreserveRemainingTime()
    {
        Backend backend;
        backend.setSoundEnabled(false);

        backend.toggleRunning();
        QVERIFY(backend.running());
        backend.advanceMs(60 * 1000);
        QCOMPARE(backend.timeText(), QString("24:00"));

        // Pause
        backend.toggleRunning();
        QVERIFY(!backend.running());
        QCOMPARE(backend.timeText(), QString("24:00"));

        // Resume and advance another minute
        backend.toggleRunning();
        QVERIFY(backend.running());
        backend.advanceMs(60 * 1000);
        QCOMPARE(backend.timeText(), QString("23:00"));
    }

    void resetRestoresPresetDuration()
    {
        Backend backend;
        backend.setSoundEnabled(false);

        backend.nextPreset(); // 15M
        QCOMPARE(backend.presetLabel(), QString("15M"));
        QCOMPARE(backend.timeText(), QString("15:00"));

        backend.toggleRunning();
        backend.advanceMs(900 * 1000);
        QVERIFY(backend.finished());
        QCOMPARE(backend.timeText(), QString("00:00"));

        backend.reset();
        QVERIFY(!backend.running());
        QVERIFY(!backend.finished());
        QCOMPARE(backend.timeText(), QString("15:00"));
        QCOMPARE(backend.progress(), 0.0);
    }

    void cyclesPresetsAndSupportsStopwatchAndMinuteAdjustment()
    {
        Backend backend;
        backend.setSoundEnabled(false);

        QCOMPARE(backend.presetLabel(), QString("25M"));
        backend.nextPreset();
        QCOMPARE(backend.presetLabel(), QString("15M"));
        QCOMPARE(backend.timeText(), QString("15:00"));

        backend.nextPreset();
        QCOMPARE(backend.presetLabel(), QString("05M"));
        QCOMPARE(backend.timeText(), QString("05:00"));

        backend.adjustMinutes(2);
        QCOMPARE(backend.timeText(), QString("07:00"));
        backend.adjustMinutes(-10); // clamped to 01:00
        QCOMPARE(backend.timeText(), QString("01:00"));

        backend.nextPreset();
        QCOMPARE(backend.presetLabel(), QString("25M"));
        QCOMPARE(backend.timeText(), QString("25:00"));

        backend.toggleStopwatch();
        QVERIFY(backend.stopwatch());
        QCOMPARE(backend.presetLabel(), QString("STOPWATCH"));
        QCOMPARE(backend.timeText(), QString("00:00"));
        backend.advanceMs(65 * 1000);
        QCOMPARE(backend.timeText(), QString("01:05"));
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
        write(dir.path() + "/pt.json", R"({"Quit": "Sair", "Preset": "Predefinição"})");
        write(dir.path() + "/pt-BR.json", R"({"Quit": "Fechar"})");

        Translator translator(dir.path() + "/language", dir.path());
        QCOMPARE(translator.language(), QString("pt-BR"));
        QCOMPARE(translator.translate("Main", "Quit"), QString("Fechar"));
        QCOMPARE(translator.translate("Main", "Preset"), QString("Predefinição"));
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

QTEST_MAIN(TminusTests)
#include "tminus_tests.moc"
