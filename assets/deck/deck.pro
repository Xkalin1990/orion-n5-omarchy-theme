QT += core gui qml quick quickcontrols2 dbus network

CONFIG += c++17 release
TARGET = deck
TEMPLATE = app

HEADERS += \
    src/deckbackend.h \
    src/widgets.h \
    src/theme.h \
    src/translator.h

SOURCES += \
    src/main.cpp \
    src/deckbackend.cpp \
    src/widgets.cpp \
    src/theme.cpp \
    src/translator.cpp

RESOURCES += src/resources.qrc
