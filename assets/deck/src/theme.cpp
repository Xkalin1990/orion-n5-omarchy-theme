// Theme watching follows Omacut (MIT, David Heinemeier Hansson).
#include "theme.h"

#include <QColor>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QStandardPaths>
#include <cmath>

Theme::Theme(const QString &directory, QObject *parent, const QString &hyprctl)
    : QObject(parent),
      m_directory(directory.isEmpty() ? QDir::homePath() + "/.local/state/omarchy/current" : directory) {
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(80);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] { m_debounce.start(); });
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this] { m_debounce.start(); });
    connect(&m_debounce, &QTimer::timeout, this, &Theme::reload);

    m_hyprctl = !hyprctl.isEmpty() ? hyprctl
              : directory.isEmpty() && !qEnvironmentVariableIsEmpty("HYPRLAND_INSTANCE_SIGNATURE")
                  ? QStandardPaths::findExecutable("hyprctl") : QString();
    m_roundingTimeout.setSingleShot(true);
    m_roundingTimeout.setInterval(500);
    connect(&m_roundingTimeout, &QTimer::timeout, &m_roundingProcess, &QProcess::kill);
    connect(&m_roundingProcess, &QProcess::errorOccurred, this, [this] { m_roundingTimeout.stop(); });
    connect(&m_roundingProcess, &QProcess::finished, this, [this](int code, QProcess::ExitStatus status) {
        m_roundingTimeout.stop();
        const auto value = QJsonDocument::fromJson(m_roundingProcess.readAllStandardOutput()).object().value("int");
        if (code != 0 || status != QProcess::NormalExit || !value.isDouble() || value.toInt(-1) < 0)
            return;
        if (value.toInt() != m_radius) {
            m_radius = value.toInt();
            emit changed();
        }
    });
    m_roundingPoll.setInterval(1000);
    connect(&m_roundingPoll, &QTimer::timeout, this, &Theme::refreshRounding);
    if (!m_hyprctl.isEmpty())
        m_roundingPoll.start();
    reload();
}

Theme::~Theme() {
    if (m_roundingProcess.state() != QProcess::NotRunning) {
        m_roundingProcess.kill();
        m_roundingProcess.waitForFinished(1000);
    }
}

void Theme::refreshRounding() {
    if (m_hyprctl.isEmpty() || m_roundingProcess.state() != QProcess::NotRunning)
        return;
    m_roundingProcess.start(m_hyprctl, {"-j", "getoption", "decoration:rounding"});
    m_roundingTimeout.start();
}

QString Theme::readColor(const QString &contents, const QString &key, const QString &fallback) {
    const QRegularExpression expression(
        QStringLiteral(R"re(^\s*%1\s*=\s*["'](#[0-9a-fA-F]{6})["'])re").arg(QRegularExpression::escape(key)),
        QRegularExpression::MultilineOption);
    const auto match = expression.match(contents);
    return match.hasMatch() ? match.captured(1) : fallback;
}

QString Theme::readAccent(const QString &path) {
    QFile file(path);
    if (file.open(QIODevice::ReadOnly))
        return readColor(QString::fromUtf8(file.readAll()), "accent", "#FFD60A");
    return "#FFD60A";
}

QString Theme::readSystemFont() {
    const QString fcMatch = QStandardPaths::findExecutable("fc-match");
    if (fcMatch.isEmpty())
        return "monospace";
    QProcess proc;
    proc.start(fcMatch, {"monospace", "-f", "%{family}\n"});
    if (!proc.waitForFinished(500) || proc.exitCode() != 0)
        return "monospace";
    const QString line = QString::fromUtf8(proc.readAllStandardOutput()).section('\n', 0, 0).trimmed();
    const QString family = line.section(',', 0, 0).trimmed();
    return family.isEmpty() ? QString("monospace") : family;
}

QString Theme::accentForeground() const {
    const QColor c(m_accent);
    auto linear = [](double v) { return v <= .04045 ? v / 12.92 : std::pow((v + .055) / 1.055, 2.4); };
    const double luminance = .2126 * linear(c.redF()) + .7152 * linear(c.greenF()) + .0722 * linear(c.blueF());
    return luminance > .179 ? "black" : "white";
}

void Theme::reload() {
    refreshRounding();
    const auto paths = m_watcher.files() + m_watcher.directories();
    if (!paths.isEmpty())
        m_watcher.removePaths(paths);

    QString ancestor = m_directory;
    while (!QFileInfo::exists(ancestor) && ancestor != "/")
        ancestor = QFileInfo(ancestor).absolutePath();
    const QString fontconfigDir = QDir::homePath() + "/.config/fontconfig";
    QStringList candidates{ancestor, QFileInfo(ancestor).absolutePath(), m_directory,
                           m_directory + "/theme", m_directory + "/theme/colors.toml",
                           fontconfigDir, fontconfigDir + "/fonts.conf"};
    candidates.removeDuplicates();
    for (const auto &path : candidates)
        if (QFileInfo::exists(path))
            m_watcher.addPath(path);

    QString contents;
    QFile file(m_directory + "/theme/colors.toml");
    if (file.open(QIODevice::ReadOnly))
        contents = QString::fromUtf8(file.readAll());

    const auto accent = readColor(contents, "accent", "#FFD60A");
    const auto background = readColor(contents, "background", "#141615");
    const auto darkBackground = readColor(contents, "dark_background", "#0f1110");
    const auto surface = readColor(contents, "lighter_background", "#1e2220");
    const auto selection = readColor(contents, "selection", "#25332c");
    const auto foreground = readColor(contents, "foreground", "#c4ddd0");
    const auto brightForeground = readColor(contents, "bright_foreground", "#eef7f2");
    const auto muted = readColor(contents, "muted", "#54685e");
    const auto green = readColor(contents, "green", "#9ecab3");
    const auto yellow = readColor(contents, "yellow", "#e5a93c");
    const auto red = readColor(contents, "red", "#ff4526");
    const auto fontFamily = readSystemFont();

    if (accent != m_accent || background != m_background || darkBackground != m_darkBackground
        || surface != m_surface || selection != m_selection || foreground != m_foreground
        || brightForeground != m_brightForeground || muted != m_muted || green != m_green
        || yellow != m_yellow || red != m_red || fontFamily != m_fontFamily) {
        m_accent = accent;
        m_background = background;
        m_darkBackground = darkBackground;
        m_surface = surface;
        m_selection = selection;
        m_foreground = foreground;
        m_brightForeground = brightForeground;
        m_muted = muted;
        m_green = green;
        m_yellow = yellow;
        m_red = red;
        m_fontFamily = fontFamily;
        emit changed();
    }
}
