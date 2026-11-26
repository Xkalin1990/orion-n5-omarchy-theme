// deck — Orion N5 unified desktop telemetry widget pack.

#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QUrl>

#include "deckbackend.h"
#include "theme.h"
#include "translator.h"
#include "widgets.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("deck");
    app.setApplicationVersion("0.1.0");
    app.setDesktopFileName("deck");
    app.setWindowIcon(QIcon::fromTheme("deck"));

    QQuickStyle::setStyle("Material");

    Translator translator;
    app.installTranslator(&translator);

    Theme theme;
    DeckBackend deck;
    EpochBackend epoch;
    TminusBackend tminus;
    UplinkBackend uplink;
    SignalBackend signalWidget;
    SlateBackend slate;
    ZuluBackend zulu;

    QQmlApplicationEngine engine;
    QObject::connect(&translator, &Translator::changed, &engine, &QQmlEngine::retranslate);
    QObject::connect(&translator, &Translator::changed, &epoch, &EpochBackend::refresh);
    QObject::connect(&translator, &Translator::changed, &zulu, &ZuluBackend::refresh);

    engine.rootContext()->setContextProperty("translator", &translator);
    engine.rootContext()->setContextProperty("theme", &theme);
    engine.rootContext()->setContextProperty("deck", &deck);
    engine.rootContext()->setContextProperty("epochBackend", &epoch);
    engine.rootContext()->setContextProperty("tminusBackend", &tminus);
    engine.rootContext()->setContextProperty("uplinkBackend", &uplink);
    engine.rootContext()->setContextProperty("signalBackend", &signalWidget);
    engine.rootContext()->setContextProperty("slateBackend", &slate);
    engine.rootContext()->setContextProperty("zuluBackend", &zulu);

    engine.load(QUrl("qrc:/Main.qml"));
    if (engine.rootObjects().isEmpty())
        return 1;

    return app.exec();
}
