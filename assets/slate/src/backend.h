#pragma once

#include <QObject>
#include <QString>
#include <QTimer>

// Manages the scratchpad note on disk, exposing its text, save state, and
// live character/line counts to QML with debounced atomic persistence.
class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)
    Q_PROPERTY(bool saved READ saved NOTIFY savedChanged)
    Q_PROPERTY(int charCount READ charCount NOTIFY textChanged)
    Q_PROPERTY(int lineCount READ lineCount NOTIFY textChanged)

public:
    explicit Backend(const QString &notePath = {}, QObject *parent = nullptr);
    ~Backend() override;

    QString text() const { return m_text; }
    void setText(const QString &text);

    bool saved() const { return m_saved; }
    int charCount() const { return m_text.size(); }
    int lineCount() const;

    QString notePath() const { return m_notePath; }

    Q_INVOKABLE void saveNow();
    Q_INVOKABLE void clear();

signals:
    void textChanged();
    void savedChanged();

private:
    void load();
    static QString defaultNotePath();

    QString m_notePath;
    QString m_text;
    bool m_saved = true;
    QTimer m_saveTimer;
};
