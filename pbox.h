#ifndef PBOX_H
#define PBOX_H

#include <QObject>

#include <QQmlApplicationEngine>
#include <modelmesh.h>
#include <view.h>

class PBox : public QObject
{
    Q_OBJECT
public:
    explicit PBox(QObject *parent = nullptr);

    void setupPView();
    void setupPModel();
    void setupPCompute();

    QStringList selectors;
signals:

private:

    cgl::View                   view;
    cgl::ModelMesh              *mesh;
    cgl::ModelMesh              *agent;
    cgl::ModelMesh              *user;
    QQmlApplicationEngine       engine;

};

#endif // PBOX_H
