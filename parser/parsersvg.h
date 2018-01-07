#ifndef PARSERSVG_H
#define PARSERSVG_H


#include <QObject>
//#include <QTextDocument>

class ParserSVG : public QObject
{

    Q_OBJECT
    Q_PROPERTY(QString text MEMBER m_text NOTIFY textChanged FINAL)
public:
    explicit ParserSVG(QObject *parent = nullptr);

signals:
    void            textChanged(const QString &text);

public slots:
    void            setText(const QString &text);
    QString         getTag(QString tag,int id);
    QString         getTagType(int id);
    int             getCount(QString tag);
    void            setStyle(int id);
    QStringList     getStyle(int id);

private:
    QString         m_text;
    QList<QString>  m_svgtag;
    QStringList     file_text;
    QStringList     svg_text;
    QStringList     title_text;
    QStringList     defs_text;
    QStringList     style_text;
    QStringList     pattern_text;
    QStringList     rect_text;
    QStringList     circle_text;
    QStringList     ellipse_text;
    QStringList     path_text;
    QStringList     g_text;

    struct StyleNode {
        QString styleClass;
        QString styleFill;
        QString styleOpacity;
        QString styleStroke;
        QString styleStrokelinecap;
        QString styleStrokelinejoin;
    };

    QList<StyleNode> m_stylenodes;


};

#endif // PARSERSVG_H
