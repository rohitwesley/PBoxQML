#ifndef XMLHANDLER_H
#define XMLHANDLER_H


#include <QObject>
#include <QUrl>

class XmlHandler : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString fileName READ fileName NOTIFY fileUrlChanged)
    Q_PROPERTY(QString fileType READ fileType NOTIFY fileUrlChanged)
    Q_PROPERTY(QUrl fileUrl READ fileUrl NOTIFY fileUrlChanged)

public:
    explicit XmlHandler(QObject *parent = nullptr);

    QString fileName() const;
    QString fileType() const;
    QUrl fileUrl() const;

public Q_SLOTS:
    void load(const QUrl &fileUrl);
    void evaluateQuery(int index);

Q_SIGNALS:
    void fileUrlChanged();
    void loaded(const QString &text);
    void evaluated(const QString &text);

private:
    void evaluate(const QString &str);
    QUrl m_fileUrl;


};

#endif // XMLHANDLER_H
