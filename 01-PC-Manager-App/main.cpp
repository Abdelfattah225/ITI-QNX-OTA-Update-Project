#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>         // Needed for setContextProperty
#include "transfermanager.h"   // Include our new header

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Create our backend object
    TransferManager backend;

    QQmlApplicationEngine engine;

    // Bind the C++ object to the QML name "backend"
    engine.rootContext()->setContextProperty("backend", &backend);

    // Change this line:
    // const QUrl url(u"qrc:/YourProjectName/Main.qml"_qs);

    // To this exact path from your logs:
    const QUrl url(u"qrc:/qt/qml/OTA_UpdateQtApp/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
