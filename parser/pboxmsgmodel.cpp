#include "pboxmsgmodel.h"

#include <QDateTime>
#include <QDebug>
#include <QSqlError>
#include <QSqlRecord>
#include <QSqlQuery>

PboxMsgModel::PboxMsgModel(QObject *parent) :
    QSqlTableModel(parent)
{
    setTableView(QStringLiteral("PboxMsg"));
    setSender(QStringLiteral("PBoxTreeRoot"));
}

void PboxMsgModel::setTableView(const QString &tablename){

    setTable(tablename);
    setSort(2, Qt::DescendingOrder);
    // Ensures that the model is sorted correctly after submitting a new row.
    setEditStrategy(QSqlTableModel::OnManualSubmit);
}

QString PboxMsgModel::sender() const
{
    return m_sender;
}

void PboxMsgModel::setSender(const QString &sender)
{
    if (sender == m_sender)
        return;

    m_sender = sender;

    emit senderChanged();

}

QString PboxMsgModel::recipient() const
{
    return m_recipient;
}

void PboxMsgModel::setRecipient(const QString &recipient)
{
    if (recipient == m_recipient)
        return;

    m_recipient = recipient;

    QString send = m_sender;//QStringLiteral("PBoxTreeRoot");
    const QString filterString = QString::fromLatin1(
                "(recipient = '%1' AND author = '%2') OR (recipient = '%2' AND author='%1')").arg(m_recipient,m_sender);
    setFilter(filterString);
    select();

    emit recipientChanged();

}

QVariant PboxMsgModel::data(const QModelIndex &index, int role) const
{
    if (role < Qt::UserRole)
        return QSqlTableModel::data(index, role);

    const QSqlRecord sqlRecord = record(index.row());
    return sqlRecord.value(role - Qt::UserRole);
}

QHash<int, QByteArray> PboxMsgModel::roleNames() const
{
    QHash<int, QByteArray> names;
    names[Qt::UserRole] = "author";
    names[Qt::UserRole + 1] = "recipient";
    names[Qt::UserRole + 2] = "timestamp";
    names[Qt::UserRole + 3] = "message";
    return names;
}

void PboxMsgModel::sendMessage(const QString &recipient, const QString &message)
{
    const QString timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);

    QSqlRecord newRecord = record();
    newRecord.setValue("author", m_sender);
    newRecord.setValue("recipient", recipient);
    newRecord.setValue("timestamp", timestamp);
    newRecord.setValue("message", message);
    if (!insertRecord(rowCount(), newRecord)) {
        qWarning() << "Failed to send message:" << lastError().text();
        return;
    }

    submitAll();
}

void PboxMsgModel::refreshMessage()
{
    //submitAll();
    select();
}

void PboxMsgModel ::clearMessages(const QString &recipient)
{
    QSqlQuery query;
    QString queryString = QString::fromLatin1(
                "DELETE FROM PboxMsg WHERE (recipient = '%1' AND author = '%2') OR (recipient = '%2' AND author='%1')").arg(recipient,m_sender);
    query.exec(queryString);
    submitAll();
}

