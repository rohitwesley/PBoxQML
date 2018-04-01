#include "pbox.h"

#include <QGuiApplication>


int main(int argc, char *argv[])
{

    //QGuiApplication::setAttribute(Qt::AA_UseOpenGLES);
    //Set GuiApplication as we are not using Qt widgets else set QApplication
    QGuiApplication::setApplicationName("Pandoras Box");
    QGuiApplication::setOrganizationName("TecRT");
#if defined(Q_OS_WIN)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#else
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);

    PBox pandora;

    //Use selector to change between QML for different interface (touch/screentype)
    //TODO check the significance of this
#ifdef QT_EXTRA_FILE_SELECTOR
    pandora.selectors += QT_EXTRA_FILE_SELECTOR;
#else
    if (app.arguments().contains("-touch"))
        pandora.selectors += "touch";
#endif

    pandora.setupPModel();
    pandora.setupPView();
    pandora.setupPCompute();

    return app.exec();
}
