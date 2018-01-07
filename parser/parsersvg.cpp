#include "parsersvg.h"

#include <QDebug>
#include <QRegularExpression>

ParserSVG::ParserSVG(QObject *parent) : QObject(parent)
{
    m_svgtag.append("file");
    m_svgtag.append("svg");
    m_svgtag.append("defs");
    m_svgtag.append("style");
    m_svgtag.append("pattern");
    m_svgtag.append("rect");
    m_svgtag.append("circle");
    m_svgtag.append("ellipse");
    m_svgtag.append("path");
    m_svgtag.append("g");
    m_svgtag.append("stylenode");
}

void ParserSVG::setText(const QString &text)
{
    if (text == m_text)
        return;
    m_text = text;
    //Use this to remove the last newline command
    m_text = m_text.trimmed();

    // Split by newline command
    file_text.clear();
    title_text.clear();
    style_text.clear();
    g_text.clear();
    bool isTitle = false;
    bool isStyle = false;
    bool isG = false;
    QStringList tempFile = m_text.split(QRegularExpression(">"));
    for (int i = 0; i < tempFile.size(); i++)
    {
        QString line = tempFile.at(i);

        if (line.contains("<g"))
            isG = true;
        if (line.contains("/g")){
            isG = false;
            g_text << line+">";
        }
        if (isG==true)
            g_text << line+">";

    }

    QStringList temp = m_text.split(QRegularExpression("<"));
    svg_text.clear();
    defs_text.clear();
    pattern_text.clear();
    rect_text.clear();
    circle_text.clear();
    ellipse_text.clear();
    path_text.clear();

    bool isPattern = false;
    for (int i = 0; i < temp.size(); i++)
    {
        QString line = temp.at(i);

        file_text << "<"+line;

        if (line.contains("title"))
            isTitle = true;
        if (line.contains("/title"))
            isTitle = false;
        if (isTitle==true) {
            title_text << line.replace("title>","");
        }

        if (line.contains("style"))
            isStyle = true;
        if (line.contains("/style"))
            isStyle = false;
        if (isStyle==true) {
            style_text << line.replace("style>","");
        }

        if (line.contains("pattern"))
            isPattern = true;


        if (isPattern==true) {
            pattern_text << "<"+line;
        }
        else {
            if (line.contains("svg"))
                svg_text << "<"+line;
            if (line.contains("defs"))
                defs_text << "<"+line;
            if (line.contains("rect"))
                rect_text << "<"+line;
            if (line.contains("circle"))
                circle_text << "<"+line;
            if (line.contains("ellipse"))
                ellipse_text << "<"+line;
            if (line.contains("path"))
                path_text << "<"+line;
        }

        if (line.contains("/pattern"))
            isPattern = false;

    }

    //Clean list
    for (int i = 0; i < svg_text.size(); i++)
    {
        QString line = svg_text.at(i);

        if (line.contains("</svg>"))
            svg_text.removeAt(i);

    }

//    m_text = m_text.replace("<scene>","");
//    m_text = m_text.replace("</scene>","");
//    m_text = m_text.replace("---","<hr>");
    m_stylenodes.clear();
    for(int i = 0; i<style_text.size();i++)
    setStyle(i);
    emit textChanged(m_text);
}

QString ParserSVG::getTag(QString tag,int id)
{

    QString msg;
    int len = getCount(tag);

    if(id<=len&&id>-1){
        QString element;
        if(tag=="file") {
            element = file_text.at(id);
        }
        if(tag=="svg") {
            element = svg_text.at(id);
        }
        if(tag=="defs") {
            element = defs_text.at(id);
        }
        if(tag=="title") {
            element = title_text.at(id);
        }
        if(tag=="style") {
            element = style_text.at(id);
        }
        if(tag=="pattern") {
            element = pattern_text.at(id);
        }
        if(tag=="rect") {
            element = rect_text.at(id);
        }
        if(tag=="circle") {
            element = circle_text.at(id);
        }
        if(tag=="ellipse") {
            element = ellipse_text.at(id);
        }
        if(tag=="path") {
            element = path_text.at(id);
        }
        if(tag=="g") {
            element = g_text.at(id);
        }
        if(tag=="stylenode") {
            element.append("styleClass "+m_stylenodes.at(id).styleClass+";");
            element.append("styleFill "+m_stylenodes.at(id).styleFill+";");
            element.append("styleOpacity "+m_stylenodes.at(id).styleOpacity+";");
            element.append("styleStroke "+m_stylenodes.at(id).styleStroke+";");
            element.append("styleStrokelinecap "+m_stylenodes.at(id).styleStrokelinecap+";");
            element.append("styleStrokelinejoin "+m_stylenodes.at(id).styleStrokelinejoin+";");
        }
        msg.append(QString("tag-%1 %2: %3 ")
                   .arg(len)
                   .arg(tag)
                   .arg(element));
    }
    else {
        msg.append(QString("tag-%1 No Data ")
                   .arg(len)
                   .arg(tag));

    }
    return msg;

}

QString ParserSVG::getTagType(int id)
{
    return  m_svgtag.at(id);
}

int ParserSVG::getCount(QString tag)
{
    if(tag=="file") {
        return file_text.length();
    }
    if(tag=="svg") {
        return svg_text.length();
    }
    if(tag=="defs") {
        return defs_text.length();
    }
    if(tag=="title") {
        return title_text.length();
    }
    if(tag=="style") {
        return style_text.length();
    }
    if(tag=="pattern") {
        return pattern_text.length();
    }
    if(tag=="rect") {
        return rect_text.length();
    }
    if(tag=="circle") {
        return circle_text.length();
    }
    if(tag=="ellipse") {
        return ellipse_text.length();
    }
    if(tag=="path") {
        return path_text.length();
    }
    if(tag=="g") {
        return g_text.length();
    }
    if(tag=="stylenode") {
        return m_stylenodes.length();
    }
    else {
        return -1;
    }

}

void ParserSVG::setStyle(int id)
{
    QString styleSet = getTag("style",id);
    QStringList splitDot = styleSet.split(QRegularExpression("\\.(?=\\D)"));//matches a dot followed by a non digit
    for (int i = 1; i < splitDot.size(); i++)
    {
        QString line = splitDot.at(i);
        QStringList splitClass = line.split(QRegularExpression("{"));

        QString className;
        if(!splitClass.empty()) className = splitClass.at(0);
        className = className.replace(",","");

        QString properties;
        QString fill = "none";
        QString opacity = "none";
        QString stroke = "none";
        QString strokelinecap = "none";
        QString strokelinejoin = "none";
        if(splitClass.size()>1){
            properties = splitClass.at(1);
            properties = properties.replace("}","");
            QStringList splitProperties = properties.split(QRegularExpression(";"));//":(?=#)"
            for (int j = 0; j < splitProperties.size(); j++)
            {
                QString tempprop = splitProperties.at(j);
                QStringList prop;
                if(prop.contains(":#")) prop = tempprop.split(QRegularExpression(":(?=#)"));
                else prop = tempprop.split(QRegularExpression(":"));

                if(prop.at(0).contains("fill")) fill = prop.at(1);
                if(prop.at(0).contains("opacity")) opacity = prop.at(1);
                if(prop.at(0).contains("stroke")) stroke = prop.at(1);
                if(prop.at(0).contains("stroke-linecap")) strokelinecap = prop.at(1);
                if(prop.at(0).contains("stroke-linejoin")) strokelinejoin = prop.at(1);
            }
        }


        //qDebug()<<"split " << i << " : "<< line <<"properties: " << properties ;
//        qDebug()<<"class " << className;
//        if(fill != "none")qDebug()<<"fill " << fill;
//        if(opacity != "none")qDebug()<<"opacity " << opacity;
//        if(stroke != "none")qDebug()<<"stroke " << stroke;
//        if(strokelinecap != "none")qDebug()<<"strokelinecap " << strokelinecap;
//        if(strokelinejoin != "none")qDebug()<<"strokelinejoin " << strokelinejoin;

        m_stylenodes.append({
                    className,
                    fill,
                    opacity,
                    stroke,
                    strokelinecap,
                    strokelinejoin});

    }


}

QStringList ParserSVG::getStyle(int id)
{
    QStringList styleproperty;
    styleproperty.append(m_stylenodes.at(id).styleClass);
    styleproperty.append(m_stylenodes.at(id).styleFill);
    styleproperty.append(m_stylenodes.at(id).styleOpacity);
    styleproperty.append(m_stylenodes.at(id).styleStroke);
    styleproperty.append(m_stylenodes.at(id).styleStrokelinecap);
    styleproperty.append(m_stylenodes.at(id).styleStrokelinejoin);
    return styleproperty;

}

