/*
  Copyright (C) 2015 Alexander Ladygin
  Contact: Alexander Ladygin <fake.ae@gmail.com>
  All rights reserved.

  This file is part of Harbour-vk-music.

  Harbour-vk-music is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Harbour-vk-music is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Harbour-vk-music.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include "utils.h"
#include "downloadmanager.h"
#include "audioplayerhelper.h"
#include <QtSql/QSqlDatabase>

static QFile logFile;

static QObject *audioplayerhelper_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    AudioPlayerHelper *audioplayerhelper = new AudioPlayerHelper();
    return audioplayerhelper;
}

void myMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg) {

    QByteArray localMsg = msg.toUtf8();

    QString stringType;
    switch (type) {
    case QtDebugMsg:
        stringType = "D";
        break;
    case QtWarningMsg:
        stringType = "W";
        break;
    case QtCriticalMsg:
        stringType = "C";
        break;
    case QtFatalMsg:
        stringType = "Fatal";
        break;
    default:
        stringType = "Unknown";
    }

    QString logString = QString("[%1] %2:%3 - %4\n")
            .arg(stringType)
            .arg(context.function)
            .arg(context.line)
            .arg(localMsg.constData());

//    if (!logFile.isOpen()) {
//        logFile.open(QIODevice::Append | QIODevice::Text | QIODevice::WriteOnly);
//    }
//    QTextStream stream(&logFile);
//    stream << logString;

    QTextStream stderrStream(stderr, QIODevice::WriteOnly);
    stderrStream<<logString;

    if (type == QtFatalMsg) {
        abort();
    }
}

int main(int argc, char *argv[])
{

    QGuiApplication *app(SailfishApp::application(argc, argv));
    QCoreApplication::setOrganizationName("harbour-vk-music");
    QCoreApplication::setApplicationName("harbour-vk-music");
    QQuickView *view(SailfishApp::createView());


    qmlRegisterType<DownloadManager>("harbour.vk.music.downloadmanager", 1, 0, "DownloadManager");
    qmlRegisterSingletonType<AudioPlayerHelper>("harbour.vk.music.audioplayerhelper", 1, 0, "AudioPlayerHelper", audioplayerhelper_provider);

    Utils *utils = new Utils();
    view->rootContext()->setContextProperty("Utils", utils);

    logFile.setFileName(utils->getDefaultCacheDirPath() + "/trace.log");

    qInstallMessageHandler(myMessageOutput);

    view->setSource(SailfishApp::pathTo("qml/harbour-vk-music.qml"));
    view->show();

    //find db file
//    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE");

//    return 0;
    return app->exec();
}


