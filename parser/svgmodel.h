#ifndef SVGMODEL_H
#define SVGMODEL_H

#include "parsersvg.h"

#include <QAbstractListModel>
#include <QUrl>

class SvgModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString fileName READ fileName NOTIFY fileUrlChanged)
    Q_PROPERTY(QString fileType READ fileType NOTIFY fileUrlChanged)
    Q_PROPERTY(QUrl fileUrl READ fileUrl NOTIFY fileUrlChanged)
public:
    enum SvgRole {
        SvgNameRole = Qt::DisplayRole,
        SvgPathRole = Qt::UserRole,
        SvgInkingRole,
        SvgFillColorRole,
        SvgTextureRole,
        SvgLightingRole,
        SvgObjectAnimationRole,
        SvgPathAnimationRole
    };
    Q_ENUM(SvgRole)

    SvgModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex & = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;

    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE void append(const QString &svgName,
                            const QString &svgpath,
                            const QString &svginking,
                            const QString &svgfillcolor,
                            const QString &svgtexture,
                            const QString &svglighting,
                            const QString &svgobjectAnimation,
                            const QString &svgpathAnimation);
    Q_INVOKABLE void set(int row,
                         const QString &svgName,
                         const QString &svgpath,
                         const QString &svginking,
                         const QString &svgfillcolor,
                         const QString &svgtexture,
                         const QString &svglighting,
                         const QString &svgobjectAnimation,
                         const QString &svgpathAnimation);
    Q_INVOKABLE void remove(int row);

    QString fileName() const;
    QString fileType() const;
    QUrl fileUrl() const;

public Q_SLOTS:
    void load(const QUrl &fileUrl);
    void evaluateQuery(int tagIndex,int id);
    void checkType(int tagIndex);
    void getType(int tagIndex);

Q_SIGNALS:
    void fileUrlChanged();
    void error(const QString &message);
    void loaded(const QString &text);
    void evaluated(const QString &text);
    void typeSize(int count);
    void typeName(const QString &tag);



//public slots:
//    void updateActions();

//private slots:
//    void insertChild();
//    bool insertColumn();
//    void insertRow();
//    bool removeColumn();
//    void removeRow();

private:
    struct SvgNode {
        QString svgName;
        QString svgpath;
        QString svginking;
        QString svgfillcolor;
        QString svgtexture;
        QString svglighting;
        QString svgobjectAnimation;
        QString svgpathAnimation;
    };

    QList<SvgNode> m_svgnodes;
    QUrl m_fileUrl;
    ParserSVG *m_svgparser;

    void evaluateStyleList(QStringList str);

};

#endif // SVGMODEL_H
