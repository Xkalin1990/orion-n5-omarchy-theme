#include <QDir>
#include <QFile>
#include <QTemporaryDir>
#include <QtTest>

#include "backend.h"
#include "theme.h"
#include "translator.h"

class SlateTests : public QObject {
    Q_OBJECT

private slots:
    void loadsExistingNote()
    {
        QTemporaryDir dir;
        const QString notePath = dir.filePath("note.md");
        write(notePath, "# Telemetry\nLine two");

        Backend backend(notePath);
        QCOMPARE(backend.text(), QString("# Telemetry\nLine two"));
        QVERIFY(backend.saved());
        QCOMPARE(backend.charCount(), 20);
        QCOMPARE(backend.lineCount(), 2);
    }

    void savesAtomicallyToTempDir()
    {
        QTemporaryDir dir;
        const QString notePath = dir.filePath("nested/note.md");

        Backend backend(notePath);
        QVERIFY(backend.text().isEmpty());
        QVERIFY(backend.saved());

        backend.setText("First log entry\nSecond line");
        QVERIFY(!backend.saved());

        backend.saveNow();
        QVERIFY(backend.saved());

        QFile savedFile(notePath);
        QVERIFY(savedFile.exists());
        QVERIFY(savedFile.open(QIODevice::ReadOnly | QIODevice::Text));
        QCOMPARE(QString::fromUtf8(savedFile.readAll()), QString("First log entry\nSecond line"));

        // Ensure no leftover temp files remain beside the target.
        const QStringList entries = QDir(dir.filePath("nested")).entryList(QDir::Files);
        QCOMPARE(entries, QStringList({"note.md"}));
    }

    void debouncedAutoSavePersistsEdits()
    {
        QTemporaryDir dir;
        const QString notePath = dir.filePath("note.md");

        Backend backend(notePath);
        backend.setText("Debounced telemetry");
        QVERIFY(!backend.saved());

        QTRY_VERIFY_WITH_TIMEOUT(backend.saved(), 1500);

        QFile savedFile(notePath);
        QVERIFY(savedFile.open(QIODevice::ReadOnly | QIODevice::Text));
        QCOMPARE(QString::fromUtf8(savedFile.readAll()), QString("Debounced telemetry"));
    }

    void computesCharAndLineCountsAndClears()
    {
        QTemporaryDir dir;
        const QString notePath = dir.filePath("note.md");

        Backend backend(notePath);
        QCOMPARE(backend.charCount(), 0);
        QCOMPARE(backend.lineCount(), 0);

        backend.setText("alpha");
        QCOMPARE(backend.charCount(), 5);
        QCOMPARE(backend.lineCount(), 1);

        backend.setText("alpha\nbeta\ngamma");
        QCOMPARE(backend.charCount(), 16);
        QCOMPARE(backend.lineCount(), 3);

        backend.clear();
        QVERIFY(backend.text().isEmpty());
        QCOMPARE(backend.charCount(), 0);
        QCOMPARE(backend.lineCount(), 0);
        QVERIFY(backend.saved());
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
        write(dir.path() + "/pt.json", R"({"Quit": "Sair", "SAVED": "SALVO"})");
        write(dir.path() + "/pt-BR.json", R"({"Quit": "Fechar"})");

        Translator translator(dir.path() + "/language", dir.path());
        QCOMPARE(translator.language(), QString("pt-BR"));
        QCOMPARE(translator.translate("Main", "Quit"), QString("Fechar"));
        QCOMPARE(translator.translate("Main", "SAVED"), QString("SALVO"));
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

QTEST_MAIN(SlateTests)
#include "slate_tests.moc"
