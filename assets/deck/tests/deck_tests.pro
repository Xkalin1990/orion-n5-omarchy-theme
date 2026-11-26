QT += core gui quick quickcontrols2 testlib dbus network
CONFIG += c++17 testcase
TARGET = deck_tests
TEMPLATE = app

INCLUDEPATH += ../src /usr/include/LayerShellQt
LIBS += -lLayerShellQtInterface

HEADERS += ../src/deckbackend.h ../src/widgets.h ../src/theme.h ../src/translator.h
SOURCES += deck_tests.cpp ../src/deckbackend.cpp ../src/widgets.cpp ../src/theme.cpp ../src/translator.cpp
