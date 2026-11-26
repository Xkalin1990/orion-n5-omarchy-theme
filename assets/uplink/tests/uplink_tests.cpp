#include <QDir>
#include <QFile>
#include <QHostAddress>
#include <QTcpServer>
#include <QTemporaryDir>
#include <QtTest>

#include "backend.h"
#include "theme.h"
#include "translator.h"

class UplinkTests : public QObject {
    Q_OBJECT

private slots:
    void statusTransitionsNominalDegradedOffline()
    {
        QTemporaryDir dir;
        Backend backend(dir.path() + "/missing.json", false);

        QCOMPARE(backend.targetCount(), 3);
        QCOMPARE(backend.statusText(), QString("OFFLINE"));
        QVERIFY(!backend.online());
        QCOMPARE(backend.latencyMs(), -1);
        QCOMPARE(backend.targetsSummary(), QString("0/3 UP"));

        backend.applyTargetResult(0, true, 14);
        QCOMPARE(backend.statusText(), QString("DEGRADED"));
        QVERIFY(backend.online());
        QCOMPARE(backend.latencyMs(), 14);
        QCOMPARE(backend.targetsSummary(), QString("1/3 UP"));

        backend.applyTargetResult(1, true, 32);
        backend.applyTargetResult(2, true, 2);
        QCOMPARE(backend.statusText(), QString("NOMINAL"));
        QVERIFY(backend.online());
        QCOMPARE(backend.targetsSummary(), QString("3/3 UP"));

        backend.applyTargetResult(0, false, -1);
        backend.applyTargetResult(1, false, -1);
        backend.applyTargetResult(2, false, -1);
        QCOMPARE(backend.statusText(), QString("OFFLINE"));
        QVERIFY(!backend.online());
        QCOMPARE(backend.latencyMs(), -1);
        QCOMPARE(backend.targetsSummary(), QString("0/3 UP"));
    }

    void cyclesTargetsAndUpdatesLatency()
    {
        QTemporaryDir dir;
        Backend backend(dir.path() + "/missing.json", false);

        backend.applyTargetResult(0, true, 11);
        backend.applyTargetResult(1, true, 45);
        backend.applyTargetResult(2, false, -1);

        QCOMPARE(backend.targetLabel(), QString("1.1.1.1"));
        QCOMPARE(backend.latencyMs(), 11);

        backend.cycleTarget();
        QCOMPARE(backend.targetLabel(), QString("github.com:443"));
        QCOMPARE(backend.latencyMs(), 45);

        backend.cycleTarget();
        QCOMPARE(backend.targetLabel(), QString("localhost:3000"));
        QCOMPARE(backend.latencyMs(), -1);

        backend.cycleTarget();
        QCOMPARE(backend.targetLabel(), QString("1.1.1.1"));
        QCOMPARE(backend.latencyMs(), 11);
    }

    void loadsCustomTargetsFromJson()
    {
        QTemporaryDir dir;
        const QString configPath = dir.path() + "/targets.json";
        write(configPath, R"([
            "8.8.8.8",
            "example.com:8443",
            {"label": "API", "host": "localhost", "port": 8080}
        ])");

        const auto targets = Backend::loadTargets(configPath);
        QCOMPARE(targets.size(), 3);
        QCOMPARE(targets[0].label, QString("8.8.8.8"));
        QCOMPARE(targets[0].host, QString("8.8.8.8"));
        QCOMPARE(targets[0].port, quint16(443));
        QCOMPARE(targets[1].label, QString("example.com:8443"));
        QCOMPARE(targets[1].port, quint16(8443));
        QCOMPARE(targets[2].label, QString("API"));
        QCOMPARE(targets[2].host, QString("127.0.0.1"));
        QCOMPARE(targets[2].port, quint16(8080));
    }

    void parsesPingLatency()
    {
        const QString sample = QStringLiteral(
            "PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.\n"
            "64 bytes from 1.1.1.1: icmp_seq=1 ttl=57 time=14.2 ms\n");
        QCOMPARE(Backend::parsePingLatencyMs(sample), 14);
        QCOMPARE(Backend::parsePingLatencyMs(QStringLiteral("time=0.8 ms")), 1);
        QCOMPARE(Backend::parsePingLatencyMs(QStringLiteral("100% packet loss")), -1);
    }

    void probesLocalTcpServer()
    {
        QTcpServer server;
        QVERIFY(server.listen(QHostAddress::LocalHost, 0));

        QTemporaryDir dir;
        const QString configPath = dir.path() + "/targets.json";
        const QByteArray json = QStringLiteral(R"([{"label": "local", "host": "127.0.0.1", "port": %1}])")
                                    .arg(server.serverPort())
                                    .toUtf8();
        write(configPath, json);

        Backend backend(configPath, true);
        QTRY_COMPARE(backend.online(), true);
        QCOMPARE(backend.statusText(), QString("NOMINAL"));
        QCOMPARE(backend.targetLabel(), QString("local"));
        QVERIFY(backend.latencyMs() >= 0);
        QCOMPARE(backend.targetsSummary(), QString("1/1 UP"));
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
        write(dir.path() + "/pt.json", R"({"Quit": "Sair", "Probe now": "Testar agora"})");
        write(dir.path() + "/pt-BR.json", R"({"Quit": "Fechar"})");

        Translator translator(dir.path() + "/language", dir.path());
        QCOMPARE(translator.language(), QString("pt-BR"));
        QCOMPARE(translator.translate("Main", "Quit"), QString("Fechar"));
        QCOMPARE(translator.translate("Main", "Probe now"), QString("Testar agora"));
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

QTEST_MAIN(UplinkTests)
#include "uplink_tests.moc"
