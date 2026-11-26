#include "deckbackend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMargins>
#include <QRect>
#include <QSaveFile>
#include <QTimer>
#include <algorithm>

#include <LayerShellQt/Window>

DeckBackend::DeckBackend(const QString &statePath, QObject *parent)
    : QObject(parent),
      m_statePath(statePath.isEmpty() ? QDir::homePath() + "/.config/deck/state.json" : statePath) {
    m_positions.insert("deck", QPoint(36, 124));
    m_reloadDebounce.setSingleShot(true);
    m_reloadDebounce.setInterval(80);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] { m_reloadDebounce.start(); });
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this] { m_reloadDebounce.start(); });
    connect(&m_reloadDebounce, &QTimer::timeout, this, &DeckBackend::reloadFromDisk);
    load();
    armWatcher();
    QTimer::singleShot(120, this, &DeckBackend::arrangeAll);
}

int DeckBackend::activeCount() const {
    return int(m_epoch) + int(m_tminus) + int(m_uplink)
         + int(m_signal) + int(m_slate) + int(m_zulu) + int(m_sys);
}

bool DeckBackend::isCardVisible(const QString &id) const {
    if (id == "epoch") return m_epoch;
    if (id == "tminus") return m_tminus;
    if (id == "uplink") return m_uplink;
    if (id == "signal") return m_signal;
    if (id == "slate") return m_slate;
    if (id == "zulu") return m_zulu;
    if (id == "sys") return m_sys;
    return false;
}

void DeckBackend::registerLayerWindow(QWindow *window, const QString &id) {
    if (!window || id.isEmpty())
        return;
    m_windows.insert(id, window);
    if (!m_positions.contains(id))
        m_positions.insert(id, QPoint(36, 180));
    applyLayerProps(window, id);
    if (id != "deck" && isCardVisible(id))
        arrangeCard(id);
}

void DeckBackend::applyLayerProps(QWindow *window, const QString &id) {
    if (!window || qEnvironmentVariable("QT_QPA_PLATFORM") == "offscreen")
        return;
    auto *lsw = LayerShellQt::Window::get(window);
    if (!lsw)
        return;
    lsw->setLayer(LayerShellQt::Window::LayerBottom);
    lsw->setAnchors(LayerShellQt::Window::Anchors(
        LayerShellQt::Window::AnchorTop | LayerShellQt::Window::AnchorLeft));
    lsw->setExclusiveZone(0);
    lsw->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
    lsw->setScope(QStringLiteral("orion-deck"));
    const QPoint pos = m_positions.value(id, QPoint(36, 124));
    lsw->setMargins(QMargins(pos.x(), pos.y(), 0, 0));
}

void DeckBackend::setWindowMargin(const QString &id, const QPoint &pos) {
    const QPoint clamped(std::max(0, pos.x()), std::max(0, pos.y()));
    m_positions.insert(id, clamped);
    auto win = m_windows.value(id);
    if (!win || qEnvironmentVariable("QT_QPA_PLATFORM") == "offscreen")
        return;
    if (auto *lsw = LayerShellQt::Window::get(win)) {
        lsw->setMargins(QMargins(clamped.x(), clamped.y(), 0, 0));
        win->setPosition(clamped);
        win->requestUpdate();
    }
}

void DeckBackend::moveWindowBy(QWindow *window, const QString &id, int dx, int dy) {
    if (!window || (dx == 0 && dy == 0))
        return;
    m_windows.insert(id, window);
    const QPoint cur = m_positions.value(id, QPoint(36, 124));
    const QPoint next(std::max(0, cur.x() + dx), std::max(0, cur.y() + dy));
    const QPoint actualDelta = next - cur;
    if (actualDelta.isNull())
        return;
    setWindowMargin(id, next);

    // Dragging the top deck bar moves the entire visible widget stack together.
    if (id == "deck") {
        static const QStringList kCards = {"epoch", "tminus", "uplink", "signal", "slate", "sys", "zulu"};
        for (const QString &card : kCards) {
            if (!isCardVisible(card))
                continue;
            const QPoint cardPos = m_positions.value(card, QPoint(36, 180));
            setWindowMargin(card, cardPos + actualDelta);
        }
    }
}

void DeckBackend::toggle(const QString &id) {
    if (id == "epoch")       m_epoch  = !m_epoch;
    else if (id == "tminus") m_tminus = !m_tminus;
    else if (id == "uplink") m_uplink = !m_uplink;
    else if (id == "signal") m_signal = !m_signal;
    else if (id == "slate")  m_slate  = !m_slate;
    else if (id == "zulu")   m_zulu   = !m_zulu;
    else if (id == "sys")    m_sys    = !m_sys;
    else return;
    save();
    emit changed();
    QTimer::singleShot(40, this, &DeckBackend::arrangeAll);
}

void DeckBackend::setCardVisible(const QString &id, bool visible) {
    bool *slot = nullptr;
    if (id == "epoch") slot = &m_epoch;
    else if (id == "tminus") slot = &m_tminus;
    else if (id == "uplink") slot = &m_uplink;
    else if (id == "signal") slot = &m_signal;
    else if (id == "slate") slot = &m_slate;
    else if (id == "zulu") slot = &m_zulu;
    else if (id == "sys") slot = &m_sys;
    if (!slot || *slot == visible)
        return;
    *slot = visible;
    save();
    emit changed();
    QTimer::singleShot(40, this, &DeckBackend::arrangeAll);
}

void DeckBackend::toggleAll() {
    const bool enable = activeCount() < 7;
    m_epoch = enable;
    m_tminus = enable;
    m_uplink = enable;
    m_signal = enable;
    m_slate = enable;
    m_zulu = enable;
    m_sys = enable;
    save();
    emit changed();
    if (enable)
        QTimer::singleShot(50, this, &DeckBackend::arrangeAll);
}

void DeckBackend::toggleCompact() {
    setCompact(!m_compact);
}

void DeckBackend::setCompact(bool compact) {
    if (m_compact == compact)
        return;
    m_compact = compact;
    save();
    emit changed();
    QTimer::singleShot(50, this, &DeckBackend::arrangeAll);
}

void DeckBackend::arrangeCard(const QString &) {
    arrangeAll();
}

void DeckBackend::arrangeAll() {
    const QPoint barPos = m_positions.value("deck", QPoint(36, 124));
    const int barH = 42;
    const int gap = 12;
    const int colW = m_compact ? 300 : 374;
    const int startX = barPos.x();
    const int startY = barPos.y() + barH + gap;

    // Even 2-column grid order: standard-height cards first, tall cards paired,
    // full-width Zulu strip cleanly spanning both columns.
    static const QStringList kGridOrder = {"epoch", "tminus", "uplink", "signal", "sys", "slate", "zulu"};

    int col = 0;
    int curY = startY;
    int rowH = 0;

    for (const QString &id : kGridOrder) {
        if (!isCardVisible(id))
            continue;
        auto w = m_windows.value(id);
        if (!w)
            continue;
        applyLayerProps(w, id);

        const bool fullSpan = (id == "zulu");
        if (fullSpan && col != 0) {
            curY += rowH + gap;
            col = 0;
            rowH = 0;
        }

        const int x = startX + col * (colW + gap);
        setWindowMargin(id, QPoint(x, curY));
        rowH = std::max(rowH, w->height());

        if (fullSpan || col == 1) {
            curY += rowH + gap;
            col = 0;
            rowH = 0;
        } else {
            col = 1;
        }
    }
}

void DeckBackend::armWatcher() {
    const auto paths = m_watcher.files() + m_watcher.directories();
    if (!paths.isEmpty())
        m_watcher.removePaths(paths);
    const QString dir = QFileInfo(m_statePath).absolutePath();
    if (QFileInfo::exists(dir))
        m_watcher.addPath(dir);
    if (QFileInfo::exists(m_statePath))
        m_watcher.addPath(m_statePath);
}

void DeckBackend::reloadFromDisk() {
    armWatcher();
    const bool prevEpoch = m_epoch, prevTminus = m_tminus, prevUplink = m_uplink;
    const bool prevSignal = m_signal, prevSlate = m_slate, prevZulu = m_zulu;
    const bool prevSys = m_sys, prevCompact = m_compact;
    load();
    if (prevEpoch != m_epoch || prevTminus != m_tminus || prevUplink != m_uplink
        || prevSignal != m_signal || prevSlate != m_slate || prevZulu != m_zulu
        || prevSys != m_sys || prevCompact != m_compact) {
        emit changed();
        QTimer::singleShot(60, this, &DeckBackend::arrangeAll);
    }
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
    if (obj.contains("sys")) m_sys = obj.value("sys").toBool(false);
    if (obj.contains("compact")) m_compact = obj.value("compact").toBool(false);
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
    obj.insert("sys", m_sys);
    obj.insert("compact", m_compact);
    file.write(QJsonDocument(obj).toJson(QJsonDocument::Indented));
    file.commit();
}
