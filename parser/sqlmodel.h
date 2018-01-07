#ifndef SQLMODEL_H
#define SQLMODEL_H


#include <QSqlTableModel>

class SqlModel : public QSqlTableModel
{
    Q_OBJECT
    Q_PROPERTY(QString recipient READ recipient WRITE setRecipient NOTIFY recipientChanged)
    Q_PROPERTY(QString sender READ sender WRITE setSender NOTIFY senderChanged)

public:
    SqlModel(QObject *parent = 0);

    QString sender() const;
    void setSender(const QString &sender);

    QString recipient() const;
    void setRecipient(const QString &recipient);

    QVariant data(const QModelIndex &index, int role) const Q_DECL_OVERRIDE;
    QHash<int, QByteArray> roleNames() const Q_DECL_OVERRIDE;

    Q_INVOKABLE void sendMessage(const QString &recipient, const QString &message);
    Q_INVOKABLE void refreshMessage();
    Q_INVOKABLE void clearMessages(const QString &recipient);


signals:
    void recipientChanged();
    void senderChanged();

private:
    QString m_recipient;
    QString m_sender;

};

#endif // SQLMODEL_H
