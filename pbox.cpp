#include "pbox.h"

#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlFileSelector>
#include <QQuickStyle>
#include <qtwebengineglobal.h>
#include <QDebug>
#include <QFontDatabase>
#include <QDir>
#include <QStandardPaths>
#include <QSqlDatabase>
#include <QSqlError>

#include <annulusmesh.h>
#include <cubemesh.h>
#include <cylindermesh.h>
#include <parallelogrammesh.h>
#include <planemesh.h>
#include <polygonmesh.h>
#include <spheremesh.h>

#include <contactmodel.h>
#include <documenthandler.h>
#include <sqlcontactmodel.h>
#include <sqlconversationmodel.h>
#include <contactmodel.h>
#include <chatserver.h>
#include <utils.h>
#include <svgmodel.h>
#include <glmodel.h>
#include <sqlmodel.h>
#include <xmlhandler.h>
#include <pboxtreemodel.h>
#include <pboxmsgmodel.h>


static void connectToDatabase()
{
    QSqlDatabase database = QSqlDatabase::database();
    if (!database.isValid()) {
        database = QSqlDatabase::addDatabase("QSQLITE");
        if (!database.isValid())
            qFatal("Cannot add database: %s", qPrintable(database.lastError().text()));
    }

    const QDir writeDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!writeDir.mkpath("."))
        qFatal("Failed to create writable directory at %s", qPrintable(writeDir.absolutePath()));

    // Ensure that we have a writable location on all devices.
    const QString fileName = writeDir.absolutePath() + "/chat-database.sqlite3";
    // When using the SQLite driver, open() will create the SQLite database if it doesn't exist.
    database.setDatabaseName(fileName);
    if (!database.open()) {
        qFatal("Cannot open database: %s", qPrintable(database.lastError().text()));
        QFile::remove(fileName);
    }
}

static QUrl startupUrl()
{
    QUrl ret;
    QStringList args(qApp->arguments());
    args.takeFirst();
    Q_FOREACH (const QString& arg, args) {
        if (arg.startsWith(QLatin1Char('-')))
             continue;
        ret = Utils::fromUserInput(arg);
        if (ret.isValid())
            return ret;
    }
    return QUrl(QStringLiteral("qrc://html/chatclient.html"));
}


PBox::PBox(QObject *parent) : QObject(parent)
{

}

void PBox::setupPView()
{
    //Initialize the webengine
    QtWebEngine::initialize();

    //Initialize chat SQL Lite Data Model and send to QML
    qmlRegisterType<SqlContactModel>("io.qt.examples.chattutorial", 1, 0, "SqlContactModel");
    qmlRegisterType<SqlConversationModel>("io.qt.examples.chattutorial", 1, 0, "SqlConversationModel");
    connectToDatabase();

    //Initialize C++ Contact Data Model and send to QML
    qmlRegisterType<ContactModel>("Backend", 1, 0, "ContactModel");

    //Initialize C++ Document Edit Data Model and send to QML
    qmlRegisterType<DocumentHandler>("io.qt.examples.texteditor", 1, 0, "DocumentHandler");

    //Initialize C++ Gl Model and send to QML
    qmlRegisterType<GlModel>("OpenGLUnderQML", 1, 0, "GlModel");

    //Initialize C++ XML Model and send to QML
    qmlRegisterType<XmlHandler>("XmlUnderQML", 1, 0, "XmlHandler");

    //Initialize C++ SQL Model and send to QML
    qmlRegisterType<SqlModel>("SqlUnderQML", 1, 0, "SqlModel");

    //Initialize C++ SVG Model and send to QML
    qmlRegisterType<SvgModel>("SvgUnderQML", 1, 0, "SvgModel");

    //Initialize C++ SQL Tree Model and send to QML
    qmlRegisterType<PboxTreeModel>("PboxTreeUnderQML", 1, 0, "PboxTreeModel");
    //Initialize C++ SQL Tree Model Messanger and send to QML
    qmlRegisterType<PboxMsgModel>("PboxMsgUnderQML", 1, 0, "PboxMsgModel");

    //Add font files
    QFontDatabase fontDatabase;
    if (fontDatabase.addApplicationFont("://fonts/fontello.ttf") == -1)
        qWarning() << "Failed to load fontello.ttf";
    if (fontDatabase.addApplicationFont("://fonts/fontawesome-webfont.ttf") == -1)
        qWarning() << "Failed to load fontawesome-webfont.ttf";

    //Add Properties to the App
    bool isEmbedded = false;
#ifdef QTWEBENGINE_RECIPE_BROWSER_EMBEDDED
    isEmbedded = true;
#endif
    engine.rootContext()->setContextProperty(QStringLiteral("isEmbedded"), isEmbedded);

    //Setup WebPage
    Utils utils;
    engine.rootContext()->setContextProperty("utils", &utils);

    //Use selector to change between QML for different interface (touch/screentype)
    QQmlFileSelector::get(&engine)->setExtraSelectors(selectors);

    //Load the Main QML file into the engine
    //engine.load(QUrl(QStringLiteral("qrc:/qml/pages/ApplicationRoot.qml")));
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    //engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
//    if (engine.rootObjects().isEmpty())
//        return -1;

    //send webpage to QML
    QMetaObject::invokeMethod(engine.rootObjects().first(), "load", Q_ARG(QVariant, startupUrl()));


}

void PBox::setupPModel()
{
    ChatServer server(1234);
}

void PBox::setupPCompute()
{


    //cgl::AnnulusMesh *mesh2 = new cgl::AnnulusMesh(6,3,16);
    //cgl::CubeMesh *mesh2 = new cgl::CubeMesh(1,1,1);
    //cgl::CylinderMesh *mesh2 = new cgl::CylinderMesh(1,16,1);
    //TODO cgl::ParallelogramMesh *mesh2 = new cgl::ParallelogramMesh(1,2,20);
    //TODO cgl::PlaneMesh *mesh2 = new cgl::PlaneMesh(2,3,4,5);
    //cgl::PolygonMesh *mesh2 = new cgl::PolygonMesh(1,5);
    cgl::SphereMesh *mesh2 = new cgl::SphereMesh(1,16);
    //cgl::TorusMesh *mesh2 = new cgl::TorusMesh(1,4,16);
    //cgl::TriangleMesh *mesh2 = new cgl::TriangleMesh(1,4,cgl::TriangleMesh::ISOC);
    //cgl::TriangleMesh *mesh2 = new cgl::TriangleMesh(1,4,cgl::TriangleMesh::RECT);
    //cgl::TriangleMesh *mesh2 = new cgl::TriangleMesh(1,4,cgl::TriangleMesh::GEN);
    //cgl::TubeMesh *mesh2 = new cgl::TubeMesh(2,1,8,10);
    mesh2->setObjectName("Point");
    //mesh2->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/light_fragment.fsh");
    mesh2->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_0_boilerplate.fsh");
    mesh2->setTextureImage("://media/textures/wood.jpg");
    mesh2->setOpacity(0.75);
    mesh2->scale(1.0);
    mesh2->translate(3,3,0);
    //view.scene()->addMesh(mesh2);

    QString meshfile;
    //meshfile = "://models/test.obj";
    //meshfile = "://models/obj_triangle_cube.obj";
    meshfile = "://models/obj_triangle_plane.obj";
    mesh = new cgl::ModelMesh(meshfile);
    //mesh = new cgl::ModelMesh("://models/test.obj");
    //mesh->setDebug(true);
    mesh->setObjectName("Canves");
//    mesh->setObjectName("Basic");
//    mesh->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/light_fragment.fsh");
//    mesh->setObjectName("Boilerplate");
    mesh->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_0_boilerplate.fsh");
//    mesh->setObjectName("BSpline");
//    mesh->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_0_bSpline.fsh");
//    mesh->setObjectName("TextureBasic");
//    mesh->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_1_texturebasic.fsh");
//    mesh->setObjectName("2DBasic");
//    mesh->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_2_raymarch2dbasic.fsh");
//    mesh->setObjectName("3DBasic");
//    mesh->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_3_raymarch3dbasic.fsh");
//    mesh->setObjectName("Terrain");
//    mesh->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_4_raymarchterrain.fsh");
//    mesh->setObjectName("Ocean");
//    mesh->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_5_raymarchocean.fsh");
//    mesh->setObjectName("Volume");
//    mesh->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_6_raymarchvolume.fsh");
//    mesh->setObjectName("Particles");
//    mesh->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_7_particles.fsh");
//    mesh->setObjectName("HUD");
//    mesh->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_8_hud.fsh");
    mesh->setTextureImage("://media/textures/tex16.png");
    //mesh->setTextureImage("://media/textures/tex04.png");
    //mesh->setTextureImage("://media/textures/damier.png");
    //mesh->setTextureImage("://media/textures/HUD_001_HUD_1x1.png");
    mesh->setOpacity(0.75);
    mesh->scale(40.0);
    mesh->rotate(90,1.0,0.0,0.0);
    mesh->translate(0,0,0);
    view.scene()->addMesh(mesh);

//    agent = new cgl::ModelMesh(meshfile);
//    agent->setObjectName("Agent");
//    agent->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_0_boilerplate.fsh");
//    //agent->setTextureImage("://media/textures/tex16.png");
//    agent->setTextureImage("://media/textures/tex04.png");
//    //agent->setTextureImage("://media/textures/damier.png");
//    //agent->setTextureImage("://media/textures/HUD_001_HUD_1x1.png");
//    agent->setOpacity(0.75);
//    agent->scale(1.0);
//    agent->rotate(90,1.0,0.0,0.0);
//    agent->translate(0,0,0);
//    view.scene()->addMesh(agent);

//    user = new cgl::ModelMesh(meshfile);
//    user->setObjectName("User");
//    user->setCustomShaders("://shaders/light_vertex.vsh", "://shaders/fs_0_boilerplate.fsh");
//    //user->setTextureImage("://media/textures/tex16.png");
//    user->setTextureImage("://media/textures/tex04.png");
//    //user->setTextureImage("://media/textures/damier.png");
//    //user->setTextureImage("://media/textures/HUD_001_HUD_1x1.png");
//    user->setOpacity(0.75);
//    user->scale(1.0);
//    user->rotate(90,1.0,0.0,0.0);
//    user->translate(0,0,0);
//    view.scene()->addMesh(user);

    view.show();

}
