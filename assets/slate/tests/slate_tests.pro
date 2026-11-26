QT += core gui quick quickcontrols2 testlib dbus
CONFIG += c++17 testcase
TARGET = slate_tests
TEMPLATE = app

INCLUDEPATH += ../src

HEADERS += ../src/backend.h ../src/theme.h ../src/translator.h
SOURCES += slate_tests.cpp ../src/backend.cpp ../src/theme.cpp ../src/translator.cpp
