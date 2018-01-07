#include "xmlhandler.h"

#include <QFile>
#include <QFileInfo>
#include <QQmlFile>
#include <QQmlFileSelector>
#include <QtXmlPatterns>

XmlHandler::XmlHandler(QObject *parent)
    : QObject(parent)
{

}


QString XmlHandler::fileName() const
{
    const QString filePath = QQmlFile::urlToLocalFileOrQrc(m_fileUrl);
    const QString fileName = QFileInfo(filePath).fileName();
    if (fileName.isEmpty())
        return QStringLiteral("untitled.txt");
    return fileName;
}

QString XmlHandler::fileType() const
{
    return QFileInfo(fileName()).suffix();
}

QUrl XmlHandler::fileUrl() const
{
    return m_fileUrl;
}

void XmlHandler::load(const QUrl &fileUrl)
{
    if (fileUrl == m_fileUrl)
        return;
    m_fileUrl = fileUrl;
    emit fileUrlChanged();

    QFile queryFile(QString("://xml/allRecipes.xq"));
    queryFile.open(QIODevice::ReadOnly);
    const QString queryString(QString::fromLatin1(queryFile.readAll()));
    emit loaded(queryString);

}


void XmlHandler::evaluateQuery(int index)
{
    QFile queryFile(QString("://xml/allRecipes.xq"));
    queryFile.open(QIODevice::ReadOnly);
    const QString query(QString::fromLatin1(queryFile.readAll()));

    evaluate(query);
}

void XmlHandler::evaluate(const QString &str)
{
    QQmlEngine *engine = qmlEngine(this);
    if (!engine) {
        qWarning() << "evaluate() called before XmlHandler has QQmlEngine";
        return;
    }

    const QUrl path = QQmlFileSelector::get(engine)->selector()->select(m_fileUrl);
    const QString fileName = QQmlFile::urlToLocalFileOrQrc(path);
    if (QFile::exists(fileName)) {
        QFile sourceDocument(fileName);
        if (sourceDocument.open(QIODevice::ReadOnly)) {
            QByteArray outArray;
            QBuffer buffer(&outArray);
            buffer.open(QIODevice::ReadWrite);

            QXmlQuery query;
            query.bindVariable("inputDocument", &sourceDocument);
            query.setQuery(str);
            if (!query.isValid())
                return;

            QXmlFormatter formatter(query, &buffer);
            if (!query.evaluateTo(&formatter))
                return;

            buffer.close();

            qDebug() << "query:" << outArray;
            evaluated(QString::fromUtf8(outArray.constData()));
        }
        else {
            evaluated("error");
        }
    }
    else {
        evaluated("error");
    }
}
