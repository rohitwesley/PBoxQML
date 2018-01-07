#include "glmodel.h"

#include <QDebug>

GlModel::GlModel()
    : m_t(0)
    , m_renderer(0)
{


    //int GLVsM = 2, GLVsm = 1;// GL:2.1, GLSL:120
    //int GLVsM = 3, GLVsm = 2;// GL:3.2, GLSL:150
    int GLVsM = 3, GLVsm = 3;// GL:3.3, GLSL:330
    QSurfaceFormat format;
    format.setMajorVersion(GLVsM);
    format.setMinorVersion(GLVsm);
    format.setProfile(QSurfaceFormat::CoreProfile);
    format.setSamples(4);
    format.setDepthBufferSize(24);
    QSurfaceFormat::setDefaultFormat(format);
    connect(this, &QQuickItem::windowChanged, this, &GlModel::handleWindowChanged);
}

void GlModel::setT(qreal t)
{
    if (t == m_t)
        return;
    m_t = t;
    emit tChanged();
    if (window())
        window()->update();
}

void GlModel::handleWindowChanged(QQuickWindow *win)
{
    if (win) {
        connect(win, &QQuickWindow::beforeSynchronizing, this, &GlModel::sync, Qt::DirectConnection);
        connect(win, &QQuickWindow::sceneGraphInvalidated, this, &GlModel::cleanup, Qt::DirectConnection);

        // If we allow QML to do the clearing, they would clear what we paint
        // and nothing would show.

        win->setClearBeforeRendering(false);
    }
}

void GlModel::cleanup()
{
    if (m_renderer) {
        delete m_renderer;
        m_renderer = 0;
    }
}

void GlModel::setPlay(QString play)
{
    m_play = play;
    sendMessage("Processed "+m_play+" Frame..");
    //sendMessage("Error Processing Frame..");
    emit playChanged();
}

void GlModel::sendMessage(QString message)
{
    m_glSqlQuery.setSender(m_play);
    m_glSqlQuery.setRecipient("Me");
    m_glSqlQuery.sendMessage(m_glSqlQuery.recipient(),message);
    emit sqlChanged();
}

void GlModel::sync()
{
    if (!m_renderer) {
        m_renderer = new GlRenderer();
        connect(window(), &QQuickWindow::beforeRendering, m_renderer, &GlRenderer::paint, Qt::DirectConnection);
    }
    m_renderer->setViewportSize(window()->size() * window()->devicePixelRatio());
    m_renderer->setT(m_t);
    m_renderer->setWindow(window());
}

GlRenderer::~GlRenderer()
{
    delete m_program;
}

void GlRenderer::paint()
{
    if (!m_program) {
        initializeOpenGLFunctions();

        m_program = new QOpenGLShaderProgram();
        QString vertexFile;
        QString fragmentFile;
        // GL:2.1, GLSL:120
        vertexFile.append("#version 120""\n"
                    "attribute highp vec4 vertices;""\n"
                    "varying highp vec2 coords;""\n"
                    "void main() {""\n"
                    "    gl_Position = vertices;""\n"
                    "    coords = vertices.xy;""\n"
                    "}");
        fragmentFile.append("#version 120""\n"
                    "uniform lowp float t;""\n"
                    "varying highp vec2 coords;""\n"
                    "void main() {""\n"
                    "    lowp float i = 1. - (pow(abs(coords.x), 4.) + pow(abs(coords.y), 4.));""\n"
                    "    i = smoothstep(t - 0.8, t + 0.8, i);""\n"
                    "    i = floor(i * 20.) / 20.;""\n"
                    "    gl_FragColor = vec4(coords * .5 + .5, i, i);""\n"
                    "}");

//        // GL:3.3, GLSL:330
//        vertexFile.append("#version 330""\n"
//                          "in vec4 vertices;""\n"
//                          "out vec2 coords;""\n"
//                          "void main() {""\n"
//                          "    gl_Position = vertices;""\n"
//                          "    coords = vertices.xy;""\n"
//                          "}" );
//        fragmentFile.append("#version 330""\n"
//                            "uniform float t;""\n"
//                            "in vec2 coords;""\n"
//                            "out vec4 outputF;""\n"
//                            "void main() {""\n"
//                            "    lowp float i = 1. - (pow(abs(coords.x), 4.) + pow(abs(coords.y), 4.));""\n"
//                            "    i = smoothstep(t - 0.8, t + 0.8, i);""\n"
//                            "    i = floor(i * 20.) / 20.;""\n"
//                            "    outputF = vec4(coords * .5 + .5, i, i);""\n"
//                            "}");

        m_program->addCacheableShaderFromSourceCode(QOpenGLShader::Vertex,vertexFile);
        m_program->addCacheableShaderFromSourceCode(QOpenGLShader::Fragment,fragmentFile);

        m_program->bindAttributeLocation("vertices", 0);
        m_program->link();

    }

    m_program->bind();

    m_program->enableAttributeArray(0);

    float values[] = {
        -1, -1,
        1, -1,
        -1, 1,
        1, 1
    };
    m_program->setAttributeArray(0, GL_FLOAT, values, 2);
    m_program->setUniformValue("t", (float) m_t);

    glViewport(0, 0, m_viewportSize.width(), m_viewportSize.height());

    glDisable(GL_DEPTH_TEST);

    //qDebug()<<"m_t"<<m_t;
    //if(m_t>0.5) {
        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT);
    //}

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    m_program->disableAttributeArray(0);
    m_program->release();

    // Not strictly needed for this example, but generally useful for when
    // mixing with raw OpenGL.
    m_window->resetOpenGLState();
}
