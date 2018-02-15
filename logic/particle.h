#ifndef PARTICLE_H
#define PARTICLE_H

#include <QDebug>
#include <QImage>
#include <QObject>
#include <QVector3D>
#include <QVector4D>

class Particle : public QObject
{
    Q_OBJECT
public:
    explicit Particle(QObject *parent = nullptr);

    void setup(float startYPos, float startXPos,
               float xPosRange, float yPosRange,
               float minSpeed, float speedRange)
    {
        position.setX(startXPos + ((float)randInt(0,100)*xPosRange/100.0));
        position.setY(startYPos);// + ((float)randInt(0,100)*yPosRange/100.0);

        this->speed = minSpeed + ((float)randInt(0,100)*speedRange/100.0);
//        QVector4D *newPoint;
//        newPoint = new QVector4D(0.0,0.0,0.0,0.0);
//        points.append(newPoint);
//        newPoint = new QVector4D(1.0,0.0,0.0,0.0);
//        points.append(newPoint);
//        newPoint = new QVector4D(0.0,1.0,0.0,0.0);
//        points.append(newPoint);
//        newPoint = new QVector4D(0.5,0.5,0.0,0.0);
//        points.append(newPoint);
    }

    int randInt(int low, int high)
    {
        // Random number between low and high
        return qrand() % ((high + 1) - low) + low;
    }

    void updatePhysics(float distChange)
    {

        position.setY(position.y()+(distChange * speed));
    }

    void addPoints(QVector4D *newPoint)
    {

        qDebug()<<"addPoints-pointIndex: "<<pointIndex;
        //append point only if index is at the end of list
        if(pointIndex <= -1) {
            points.append(newPoint);
            pointIndex = points.size()-1;
        }
        else if(points.at(points.size()-1) != newPoint) {
            points.append(newPoint);
            pointIndex = points.size()-1;
        }
        qDebug()<<"addPoints: "<<newPoint->x()<<","<<newPoint->y();
        qDebug()<<"addPoints-new-pointIndex: "<<pointIndex;
    }

    int getPointSize()
    {
        return points.size();
    }

    int getPointIndex()
    {
        return pointIndex;
    }

    QVector4D* getPoints(int pointIndex)
    {
        qDebug()<<"getPoints-pointIndex: "<<pointIndex;
        if(pointIndex < points.size() && pointIndex>-1) {
            QVector4D *pt;
            pt = points.at(pointIndex);
            //qDebug()<<"getPoint: "<<pt;
            return pt;
        }
        else
            return nullptr;
    }

    void updatePoints(int indexInc)
    {
        //qDebug()<<"updatePoints-pointIndex: "<<pointIndex <<" indexInc: "<<indexInc<<" points.size(): "<<points.size();
        int newIndex = pointIndex+indexInc;

        if(points.size()==0){
            //point list is empty
            pointIndex = -1;
        }
        else if(newIndex<points.size()&&newIndex>-1){
            pointIndex = newIndex;
            position = *points.at(pointIndex);
        }
        else if(indexInc>0){
            //reset index to start of point list update sequence is in play mode
            pointIndex = 0;
            position = *points.at(pointIndex);
        }
        else if(indexInc<0){
            //reset index to end of point list update sequence is in rewind mode
            pointIndex = points.size()-1;
            position = *points.at(pointIndex);
        }
        //qDebug()<<"updatePoints: "<<xpos<<","<<ypos;
        //qDebug()<<"updatePoints-new-pointIndex: "<<pointIndex;
    }

    QVector4D getParticlePosition()
    {
        return position;
    }

    bool outOfSight(float xPosRange, float yPosRange)
    {
        return (position.y() >= yPosRange || position.x() >= xPosRange);//-1 * bitmap.height();
    }

signals:

public slots:

public:


    QString                 iNameID;
    //float                     xpos;
    //float                     ypos;
    QVector4D               position;
    float                   speed;
    QList<QVector4D*>       points;
    int                     pointIndex=-1;

};

#endif // PARTICLE_H
