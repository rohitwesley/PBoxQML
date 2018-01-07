#ifndef GLMODEL_H
#define GLMODEL_H

#include "objectmodel.h"
#include "parsersvg.h"
#include "sqlmodel.h"

#include <QOpenGLFunctions>
#include <QOpenGLShaderProgram>
#include <QQuickItem>
#include <QQuickWindow>


class GlRenderer : public QObject, protected QOpenGLFunctions
{
    Q_OBJECT
public:
    GlRenderer() : m_t(0), m_program(0) { }
    ~GlRenderer();

    void setT(qreal t) { m_t = t; }
    void setViewportSize(const QSize &size) { m_viewportSize = size; }
    void setWindow(QQuickWindow *window) { m_window = window; }

public slots:
    void paint();

private:
    QSize m_viewportSize;
    qreal m_t;
    QOpenGLShaderProgram *m_program;
    QQuickWindow *m_window;
};


class GlModel : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(qreal t READ t WRITE setT NOTIFY tChanged)
    Q_PROPERTY(QString play READ play WRITE setPlay NOTIFY playChanged)

public:
    GlModel();

    qreal t() const { return m_t; }
    void setT(qreal t);

    QString play() const { return m_play; }
    void setPlay(QString play);

    void sendMessage(QString message);

signals:
    void tChanged();
    void playChanged();
    void sqlChanged();

public slots:
    void sync();
    void cleanup();

private slots:
    void handleWindowChanged(QQuickWindow *win);

private:
    qreal m_t;
    QString m_play = "GlModel";//"TextureList";
    GlRenderer *m_renderer;
    SqlModel m_glSqlQuery;
    ObjectModel obj;

};

#endif // GLMODEL_H
