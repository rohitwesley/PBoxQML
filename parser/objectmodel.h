#ifndef OBJECTMODEL_H
#define OBJECTMODEL_H


#include <QAbstractListModel>
#include <QVector3D>
#include <QVector4D>

class ObjectModel : public QObject
{
    Q_OBJECT
public:
    ObjectModel(QObject *parent = nullptr);

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

    struct StyleNode {
        QString styleClass;
        QString styleFill;
        QString styleOpacity;
        QString styleStroke;
        QString styleStrokelinecap;
        QString styleStrokelinejoin;
    };

    struct ShaderProp {
        QList<StyleNode>   m_stylenodes;
        QList<SvgNode> m_svgnodes;
        float       opacity;
        bool        selected;
        QVector3D   iResolution;
        int         iTime;
        float       iTimeDelta;
        int         iFrame;
        float       iChannelTime[4];
        QVector3D   iChannelResolution[4];
        QVector4D   iMouse;
        QVector4D   iDate;
    };

    QList<ShaderProp> m_shaderProp;
};

#endif // OBJECTMODEL_H
