#include <QDir>
#include <QFile>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtTest>

#include "backend.h"
#include "theme.h"
#include "translator.h"

class SignalTests : public QObject {
    Q_OBJECT

private slots:
    void parsesPlayingMetadata()
    {
        Backend backend;
        QSignalSpy spy(&backend, &Backend::changed);

        backend.parseMetadata("Playing|||Midnight City|||M83|||125000000|||250000000\n");

        QVERIFY(backend.hasPlayer());
        QVERIFY(backend.playing());
        QCOMPARE(backend.title(), QString("Midnight City"));
        QCOMPARE(backend.artist(), QString("M83"));
        QCOMPARE(backend.positionText(), QString("02:05"));
        QVERIFY(qFuzzyCompare(backend.progress(), 0.5));
        QCOMPARE(spy.count(), 1);
    }

    void parsesPausedMetadata()
    {
        Backend backend;
        backend.parseMetadata("Paused|||Resonance|||HOME|||60000000|||200000000");

        QVERIFY(backend.hasPlayer());
        QVERIFY(!backend.playing());
        QCOMPARE(backend.title(), QString("Resonance"));
        QCOMPARE(backend.artist(), QString("HOME"));
        QCOMPARE(backend.positionText(), QString("01:00"));
        QVERIFY(qFuzzyCompare(backend.progress(), 0.3));
    }

    void fallsBackWhenEmptyOrNoPlayer()
    {
        Backend backend;
        backend.parseMetadata("Playing|||Track|||Artist|||30000000|||60000000");
        QVERIFY(backend.hasPlayer());
        QVERIFY(backend.playing());

        backend.parseMetadata("");
        QVERIFY(!backend.hasPlayer());
        QVERIFY(!backend.playing());
        QCOMPARE(backend.title(), QString("NO SIGNAL"));
        QCOMPARE(backend.artist(), QString("Standby"));
        QCOMPARE(backend.positionText(), QString("00:00"));
        QCOMPARE(backend.progress(), 0.0);

        backend.parseMetadata("invalid-output-without-separators");
        QVERIFY(!backend.hasPlayer());
        QCOMPARE(backend.title(), QString("NO SIGNAL"));
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
        write(dir.path() + "/pt.json", R"({"Quit": "Sair", "Play / Pause": "Reproduzir / Pausar"})");
        write(dir.path() + "/pt-BR.json", R"({"Quit": "Fechar"})");

        Translator translator(dir.path() + "/language", dir.path());
        QCOMPARE(translator.language(), QString("pt-BR"));
        QCOMPARE(translator.translate("Main", "Quit"), QString("Fechar"));
        QCOMPARE(translator.translate("Main", "Play / Pause"), QString("Reproduzir / Pausar"));
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

QTEST_MAIN(SignalTests)
#include "signal_tests.moc"
