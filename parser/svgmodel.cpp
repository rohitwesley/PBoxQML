#include "svgmodel.h"

#include <QFile>
#include <QFileInfo>
#include <QFileSelector>
#include <QQmlFile>
#include <QQmlFileSelector>
#include <QDebug>

SvgModel::SvgModel(QObject *parent ) : QAbstractListModel(parent)
{
    m_svgnodes.append({ "Felicia Patton", "Annadale Lane 2", "Knoxville" , "0368 1244494", "polka dots", "3 point lighting", "circular loop" , "path wabol" });
    m_svgnodes.append({ "Grant Crawford", "Windsor Drive 34", "Riverdale" , "0351 7826892", "polka dots", "3 point lighting", "circular loop" , "path wabol" });
    m_svgnodes.append({ "Gretchen Little", "Sunset Drive 348", "Virginia Beach" , "0343 1234991", "polka dots", "3 point lighting", "circular loop" , "path wabol" });
    m_svgnodes.append({ "Geoffrey Richards", "University Lane 54", "Trussville" , "0423 2144944", "polka dots", "3 point lighting", "circular loop" , "path wabol" });
    m_svgnodes.append({ "Henrietta Chavez", "Via Volto San Luca 3", "Piobesi Torinese" , "0399 2826994", "polka dots", "3 point lighting", "circular loop" , "path wabol" });
    m_svgnodes.append({ "Harvey Chandler", "North Squaw Creek 11", "Madisonville" , "0343 1244492", "polka dots", "3 point lighting", "circular loop" , "path wabol" });
    m_svgnodes.append({ "Miguel Gomez", "Wild Rose Street 13", "Trussville" , "0343 9826996", "polka dots", "3 point lighting", "circular loop" , "path wabol" });
    m_svgnodes.append({ "Norma Rodriguez", " Glen Eagles Street  53", "Buffalo" , "0241 5826596", "polka dots", "3 point lighting", "circular loop" , "path wabol" });
    m_svgnodes.append({ "Shelia Ramirez", "East Miller Ave 68", "Pickerington" , "0346 4844556", "polka dots", "3 point lighting", "circular loop" , "path wabol" });
    m_svgnodes.append({ "Stephanie Moss", "Piazza Trieste e Trento 77", "Roata Chiusani" , "0363 0510490", "polka dots", "3 point lighting", "circular loop" , "path wabol" });
    m_svgnodes.append({ "Eye", "circle", "calegraphy" , "#A73631", "polka dots", "3 point lighting", "circular loop" , "path wabol" });
}

int SvgModel::rowCount(const QModelIndex &) const
{
    return m_svgnodes.count();
}

QVariant SvgModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < rowCount())
        switch (role) {
        case SvgNameRole: return m_svgnodes.at(index.row()).svgName;
        case SvgPathRole: return m_svgnodes.at(index.row()).svgpath;
        case SvgInkingRole: return m_svgnodes.at(index.row()).svginking;
        case SvgFillColorRole: return m_svgnodes.at(index.row()).svgfillcolor;
        case SvgTextureRole: return m_svgnodes.at(index.row()).svgtexture;
        case SvgLightingRole: return m_svgnodes.at(index.row()).svglighting;
        case SvgObjectAnimationRole: return m_svgnodes.at(index.row()).svgobjectAnimation;
        case SvgPathAnimationRole: return m_svgnodes.at(index.row()).svgpathAnimation;
        default: return QVariant();
    }
    return QVariant();
}

QHash<int, QByteArray> SvgModel::roleNames() const
{
    static const QHash<int, QByteArray> roles {
        { SvgNameRole, "svgName" },
        { SvgPathRole, "svgpath" },
        { SvgInkingRole, "svginking" },
        { SvgFillColorRole, "svgfillcolor" },
        { SvgTextureRole, "svgtexture" },
        { SvgLightingRole, "svglighting" },
        { SvgObjectAnimationRole, "svgobjectAnimation" },
        { SvgPathAnimationRole, "svgpathAnimation" }
    };
    return roles;
}

QVariantMap SvgModel::get(int row) const
{
    const SvgNode svgNode = m_svgnodes.value(row);
    return {
        {"svgName", svgNode.svgName},
        {"svgpath", svgNode.svgpath},
        {"svginking", svgNode.svginking},
        {"svgfillcolor", svgNode.svgfillcolor},
        {"svgtexture", svgNode.svgtexture},
        {"svglighting", svgNode.svglighting},
        {"svgobjectAnimation", svgNode.svgobjectAnimation},
        {"svgpathAnimation", svgNode.svgpathAnimation}
    };
}

void SvgModel::append(const QString &svgName,
                      const QString &svgpath,
                      const QString &svginking,
                      const QString &svgfillcolor,
                      const QString &svgtexture,
                      const QString &svglighting,
                      const QString &svgobjectAnimation,
                      const QString &svgpathAnimation)
{
    int row = 0;
    while (row < m_svgnodes.count() && svgName > m_svgnodes.at(row).svgName)
        ++row;
    beginInsertRows(QModelIndex(), row, row);
    m_svgnodes.insert(row, { svgName,
                             svgpath,
                             svginking,
                             svgfillcolor ,
                             svgtexture ,
                             svglighting ,
                             svgobjectAnimation ,
                             svgpathAnimation});
    endInsertRows();
}

void SvgModel::set(int row, const QString &svgName,
                   const QString &svgpath,
                   const QString &svginking,
                   const QString &svgfillcolor,
                   const QString &svgtexture,
                   const QString &svglighting,
                   const QString &svgobjectAnimation,
                   const QString &svgpathAnimation)
{
    if (row < 0 || row >= m_svgnodes.count())
        return;

    m_svgnodes.replace(row, { svgName,
                              svgpath,
                              svginking,
                              svgfillcolor ,
                              svgtexture ,
                              svglighting ,
                              svgobjectAnimation ,
                              svgpathAnimation });
    dataChanged(index(row, 0), index(row, 0), { SvgNameRole,
                                                SvgPathRole,
                                                SvgInkingRole,
                                                SvgFillColorRole,
                                                SvgTextureRole,
                                                SvgLightingRole,
                                                SvgObjectAnimationRole,
                                                SvgPathAnimationRole });
}

void SvgModel::remove(int row)
{
    if (row < 0 || row >= m_svgnodes.count())
        return;

    beginRemoveRows(QModelIndex(), row, row);
    m_svgnodes.removeAt(row);
    endRemoveRows();
}

QString SvgModel::fileName() const
{
    const QString filePath = QQmlFile::urlToLocalFileOrQrc(m_fileUrl);
    const QString fileName = QFileInfo(filePath).fileName();
    if (fileName.isEmpty())
        return QStringLiteral("untitled.txt");
    return fileName;
}

QString SvgModel::fileType() const
{
    return QFileInfo(fileName()).suffix();
}

QUrl SvgModel::fileUrl() const
{
    return m_fileUrl;
}

void SvgModel::load(const QUrl &fileUrl)
{
    if (fileUrl == m_fileUrl)
        return;

    QQmlEngine *engine = qmlEngine(this);
    if (!engine) {
        qWarning() << "load() called before DocumentHandler has QQmlEngine";
        return;
    }

    QString filePath = fileUrl.toLocalFile();
    bool isSvg = QFileInfo(filePath).suffix().contains(QLatin1String("svg"));
    const QUrl path = QQmlFileSelector::get(engine)->selector()->select(fileUrl);
    const QString fileName = QQmlFile::urlToLocalFileOrQrc(path);
    if (QFile::exists(fileName)) {
        QFile file(fileName);
        if (file.open(QFile::ReadOnly)) {
            QByteArray data = file.readAll();

            m_fileUrl = fileUrl;
            emit fileUrlChanged();
            m_svgparser = new ParserSVG();
            m_svgparser->setText(data);

            QString svgMessage;
            svgMessage.append(QStringLiteral("SVG").arg(m_svgparser->getCount("file")));
            svgMessage.append(QStringLiteral("\nfile LineCount:  %1 ").arg(m_svgparser->getCount("file")));
            svgMessage.append(QStringLiteral("\nsvg:  %1 ").arg(m_svgparser->getCount("svg")));
            svgMessage.append(QStringLiteral("\ndefs:  %1 ").arg(m_svgparser->getCount("defs")));
            svgMessage.append(QStringLiteral("\ntitle:  %1 ").arg(m_svgparser->getCount("title")));
            svgMessage.append(QStringLiteral("\nstyle:  %1 ").arg(m_svgparser->getCount("style")));
            svgMessage.append(QStringLiteral("\npattern:  %1 ").arg(m_svgparser->getCount("pattern")));
            svgMessage.append(QStringLiteral("\nrect:  %1 ").arg(m_svgparser->getCount("rect")));
            svgMessage.append(QStringLiteral("\ncircle:  %1 ").arg(m_svgparser->getCount("circle")));
            svgMessage.append(QStringLiteral("\nellipse:  %1 ").arg(m_svgparser->getCount("ellipse")));
            svgMessage.append(QStringLiteral("\npath:  %1 ").arg(m_svgparser->getCount("path")));
            svgMessage.append(QStringLiteral("\nGroups:  %1 ").arg(m_svgparser->getCount("g")));
            svgMessage.append(QStringLiteral("\nStylenode:  %1 ").arg(m_svgparser->getCount("stylenode")));
            //qDebug()<< "SVG Groups: " << m_svgparser->getCount("g");
            emit loaded(svgMessage);
            isSvg =true;
        }
    }
    if(!isSvg){

        emit error("Error on Loading SVG File....");
    }

}

void SvgModel::checkType(int tagIndex)
{
    QString tag = m_svgparser->getTagType(tagIndex);
    emit typeSize(m_svgparser->getCount(tag));
}

void SvgModel::getType(int tagIndex)
{
    QString tag = m_svgparser->getTagType(tagIndex);
    emit typeName(tag);
}

void SvgModel::evaluateQuery(int tagIndex,int id)
{
    QString tag = m_svgparser->getTagType(tagIndex);
    if(m_svgparser && id<=m_svgparser->getCount(tag)){
        QString svgQuery = m_svgparser->getTag(tag,id-1);
        if(tag=="stylenode"){
            QStringList styleproperty = m_svgparser->getStyle(id-1);
            evaluateStyleList(styleproperty);
        }
        emit evaluated(svgQuery);
    }
    else {
        emit error("Error on Querying SVG Type....");
    }
}

void SvgModel::evaluateStyleList(QStringList str)
{
    qDebug()<<"str " << str;
    if(str.size()>0){
        beginResetModel();
        m_svgnodes.clear();
        endResetModel();
        for(int id = 0; id< m_svgparser->getCount("stylenode"); id++){
            QStringList stylesvg = m_svgparser->getStyle(id);
            //use append if u want to reorder by svgName
//            append(stylesvg.at(0),//svgName:styleClass
//                   "",//svgpath:
//                   stylesvg.at(3)+";"+stylesvg.at(4)+";"+stylesvg.at(5),//svginking:styleStroke + styleStrokelinecap + styleStrokelinejoin
//                   stylesvg.at(1)+";"+stylesvg.at(2),//svgfillcolor:styleFill + styleOpacity
//                   "" ,//svgtexture:
//                   "" ,//svglighting:
//                   "" ,//svgobjectAnimation:
//                   "");//svgpathAnimation:
            //else directly update
            beginInsertRows(QModelIndex(), id, id);
            m_svgnodes.insert(id, {
                                  stylesvg.at(0),//svgName:styleClass
                                  "",//svgpath:
                                  stylesvg.at(3)+";"+stylesvg.at(4)+";"+stylesvg.at(5),//svginking:styleStroke + styleStrokelinecap + styleStrokelinejoin
                                  stylesvg.at(1)+";"+stylesvg.at(2),//svgfillcolor:styleFill + styleOpacity
                                  "" ,//svgtexture:
                                  "" ,//svglighting:
                                  "" ,//svgobjectAnimation:
                                  ""//svgpathAnimation:
                              });
            endInsertRows();
        }
    }

}
