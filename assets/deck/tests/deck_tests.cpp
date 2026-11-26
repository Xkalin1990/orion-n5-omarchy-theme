#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QLocale>
#include <QTemporaryDir>
#include <QtTest>

#include "deckbackend.h"
#include "theme.h"
#include "translator.h"
#include "widgets.h"

class DeckTests : public QObject {
    Q_OBJECT

private slots:
    void deckTogglesAndPersistsState()
    {
        QTemporaryDir dir;
        const QString path = dir.filePath("state.json");
        {
            DeckBackend deck(path);
            QVERIFY(deck.epochVisible());
            QCOMPARE(deck.activeCount(), 1);
            deck.toggle("tminus");
            deck.toggle("zulu");
            QCOMPARE(deck.activeCount(), 3);
            deck.setCardVisible("epoch", false);
            QCOMPARE(deck.activeCount(), 2);
        }
        DeckBackend reloaded(path);
        QVERIFY(!reloaded.epochVisible());
        QVERIFY(reloaded.tminusVisible());
        QVERIFY(reloaded.zuluVisible());
        reloaded.toggleAll();
        QCOMPARE(reloaded.activeCount(), 6);
        reloaded.toggleAll();
        QCOMPARE(reloaded.activeCount(), 0);
    }

    void epochFormatsTimeAndWeek()
    {
        QLocale::setDefault(QLocale::c());
        EpochBackend epoch;
        const QDateTime dt(QDate(2026, 11, 26), QTime(14, 5, 30));
        epoch.updateForDateTime(dt);
        QCOMPARE(epoch.timeText(), QString("14:05"));
        QCOMPARE(epoch.secondsText(), QString("30"));
        QCOMPARE(epoch.weekText(), QString("W48"));
        QVERIFY(epoch.minuteProgress() > 0.49 && epoch.minuteProgress() < 0.51);

        epoch.toggle24Hour();
        epoch.updateForDateTime(dt);
        QCOMPARE(epoch.timeText(), QString("2:05"));
    }

    void tminusPresetsAndAdjust()
    {
        TminusBackend tminus;
        QCOMPARE(tminus.timeText(), QString("25:00"));
        tminus.selectPreset(2);
        QCOMPARE(tminus.timeText(), QString("05:00"));
        tminus.adjustMinutes(2);
        QCOMPARE(tminus.timeText(), QString("07:00"));
        tminus.toggleStopwatch();
        QCOMPARE(tminus.presetLabel(), QString("STOPWATCH"));
        QCOMPARE(tminus.timeText(), QString("00:00"));
    }

    void uplinkParsesPingAndHistory()
    {
        QCOMPARE(UplinkBackend::parsePingMs("64 bytes from 1.1.1.1: icmp_seq=1 ttl=57 time=13.7 ms"), 14);
        UplinkBackend uplink(false);
        uplink.applyProbeResult(true, 18);
        QCOMPARE(uplink.statusText(), QString("NOMINAL"));
        QCOMPARE(uplink.latencyMs(), 18);
        QCOMPARE(uplink.history().size(), 1);
        uplink.applyProbeResult(false, -1);
        QCOMPARE(uplink.statusText(), QString("OFFLINE"));
        QCOMPARE(uplink.history().size(), 2);
    }

    void signalParsesMetadata()
    {
        SignalBackend sig(false);
        sig.parseMetadata("Playing|||Orbital Drift|||Orion N5|||60000000|||180000000");
        QVERIFY(sig.hasPlayer());
        QVERIFY(sig.playing());
        QCOMPARE(sig.title(), QString("Orbital Drift"));
        QCOMPARE(sig.positionText(), QString("01:00"));
        QCOMPARE(sig.durationText(), QString("03:00"));

        sig.parseMetadata("");
        QVERIFY(!sig.hasPlayer());
        QCOMPARE(sig.title(), QString("NO SIGNAL"));
    }

    void slateLoadsAndSavesAtomically()
    {
        QTemporaryDir dir;
        const QString notePath = dir.filePath("note.md");
        {
            SlateBackend slate(notePath);
            slate.setText("Orion N5\nTelemetry log");
            QCOMPARE(slate.lineCount(), 2);
            QCOMPARE(slate.wordCount(), 4);
            slate.saveNow();
            QVERIFY(slate.saved());
        }
        SlateBackend reloaded(notePath);
        QCOMPARE(reloaded.text(), QString("Orion N5\nTelemetry log"));
    }

    void zuluFormatsZones()
    {
        QLocale::setDefault(QLocale::c());
        ZuluBackend zulu;
        zulu.updateForUtc(QDateTime(QDate(2026, 11, 26), QTime(14, 0, 0), QTimeZone::utc()), QDate(2026, 11, 26));
        QCOMPARE(zulu.zones().size(), 4);
        QCOMPARE(zulu.zones().first().toMap().value("code").toString(), QString("ZULU"));
        QCOMPARE(zulu.zones().first().toMap().value("time").toString(), QString("14:00"));
    }

    void themeReadsColorsAndFallback()
    {
        QTemporaryDir dir;
        Theme fallback(dir.path());
        QCOMPARE(fallback.accent(), QString("#FFD60A"));
        QVERIFY(!fallback.fontFamily().isEmpty());

        QDir(dir.path()).mkpath("theme");
        QFile f(dir.path() + "/theme/colors.toml");
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write("accent = \"#ff5a1f\"\ngreen = \"#9ecab3\"\n");
        f.close();

        Theme loaded(dir.path());
        QCOMPARE(loaded.accent(), QString("#ff5a1f"));
        QCOMPARE(loaded.green(), QString("#9ecab3"));
    }
};

QTEST_MAIN(DeckTests)
#include "deck_tests.moc"
