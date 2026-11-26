#include "deckbackend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>

DeckBackend::DeckBackend(const QString &statePath, QObject *parent)
    : QObject(parent),
      m_statePath(statePath.isEmpty() ? QDir::homePath() + "/.config/deck/state.json" : statePath) {
    load();
}

int DeckBackend::activeCount() const {
    return int(m_epoch) + int(m_tminus) + int(m_uplink)
         + int(m_signal) + int(m_slate) + int(m_zulu);
}

void DeckBackend::toggle(const QString &id) {
    if (id == "epoch") m_epoch = !m_epoch;
    else if (id == "tminus") m_tminus = !m_tminus;
    else if (id == "uplink") m_uplink = !m_uplink;
    else if (id == "signal") m_signal = !m_signal;
    else if (id == "slate") m_slate = !m_slate;
    else if (id == "zulu") m_zulu = !m_zulu;
    else return;
    save();
    emit changed();
}

void DeckBackend::setCardVisible(const QString &id, bool visible) {
    bool *slot = nullptr;
    if (id == "epoch") slot = &m_epoch;
    else if (id == "tminus") slot = &m_tminus;
    else if (id == "uplink") slot = &m_uplink;
    else if (id == "signal") slot = &m_signal;
    else if (id == "slate") slot = &m_slate;
    else if (id == "zulu") slot = &m_zulu;
    if (!slot || *slot == visible)
        return;
    *slot = visible;
    save();
    emit changed();
}

void DeckBackend::toggleAll() {
    const bool enable = activeCount() < 6;
    m_epoch = enable;
    m_tminus = enable;
    m_uplink = enable;
    m_signal = enable;
    m_slate = enable;
    m_zulu = enable;
    save();
    emit changed();
}

void DeckBackend::load() {
    QFile file(m_statePath);
    if (!file.open(QIODevice::ReadOnly))
        return;
    const QJsonObject obj = QJsonDocument::fromJson(file.readAll()).object();
    if (obj.contains("epoch")) m_epoch = obj.value("epoch").toBool(true);
    if (obj.contains("tminus")) m_tminus = obj.value("tminus").toBool(false);
    if (obj.contains("uplink")) m_uplink = obj.value("uplink").toBool(false);
    if (obj.contains("signal")) m_signal = obj.value("signal").toBool(false);
    if (obj.contains("slate")) m_slate = obj.value("slate").toBool(false);
    if (obj.contains("zulu")) m_zulu = obj.value("zulu").toBool(false);
}

void DeckBackend::save() const {
    QDir().mkpath(QFileInfo(m_statePath).absolutePath());
    QSaveFile file(m_statePath);
    if (!file.open(QIODevice::WriteOnly))
        return;
    QJsonObject obj;
    obj.insert("epoch", m_epoch);
    obj.insert("tminus", m_tminus);
    obj.insert("uplink", m_uplink);
    obj.insert("signal", m_signal);
    obj.insert("slate", m_slate);
    obj.insert("zulu", m_zulu);
    file.write(QJsonDocument(obj).toJson(QJsonDocument::Indented));
    file.commit();
}
