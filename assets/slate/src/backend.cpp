#include "backend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSaveFile>
#include <QStandardPaths>

Backend::Backend(const QString &notePath, QObject *parent)
    : QObject(parent)
    , m_notePath(notePath.isEmpty() ? defaultNotePath() : notePath)
{
    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(400);
    connect(&m_saveTimer, &QTimer::timeout, this, &Backend::saveNow);

    load();
}

Backend::~Backend()
{
    if (!m_saved)
        saveNow();
}

QString Backend::defaultNotePath()
{
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    if (dataDir.isEmpty())
        dataDir = QDir::homePath() + "/.local/share";
    return dataDir + "/slate/note.md";
}

void Backend::load()
{
    QFile file(m_notePath);
    if (!file.exists() || !file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    m_text = QString::fromUtf8(file.readAll());
    m_saved = true;
}

void Backend::setText(const QString &text)
{
    if (m_text == text)
        return;

    m_text = text;
    emit textChanged();

    if (m_saved) {
        m_saved = false;
        emit savedChanged();
    }

    m_saveTimer.start();
}

int Backend::lineCount() const
{
    if (m_text.isEmpty())
        return 0;
    return m_text.count('\n') + 1;
}

void Backend::saveNow()
{
    m_saveTimer.stop();

    const QFileInfo info(m_notePath);
    if (!info.dir().mkpath("."))
        return;

    // Write to a sibling temporary file and atomically rename into place.
    QSaveFile file(m_notePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return;

    const QByteArray utf8 = m_text.toUtf8();
    if (file.write(utf8) != utf8.size()) {
        file.cancelWriting();
        return;
    }

    if (!file.commit())
        return;

    if (!m_saved) {
        m_saved = true;
        emit savedChanged();
    }
}

void Backend::clear()
{
    setText(QString());
    saveNow();
}
