#ifndef PARTICLESYSTEM_H
#define PARTICLESYSTEM_H

#include "particle.h"

#include <QDebug>
#include <QDateTime>
#include <QImage>
#include <QObject>
#include <QVector4D>
#include <QMatrix4x4>
#include <QVector2D>

class ParticleSystem : public QObject
{
    Q_OBJECT
public:
    explicit ParticleSystem(QObject *parent = nullptr);

    void setup(float startYPos, float startXPos, int numParticles,
               float xPosRange, float yPosRange,
               float minSpeed, float speedRange) {
        this->startYPos = startYPos;
        this->startXPos = startXPos;
        this->xPosRange = xPosRange;
        this->yPosRange = yPosRange;
        this->minSpeed = minSpeed;
        this->speedRange = speedRange;
        this->numParticles = numParticles;

        particles.clear();
        for (int i = 0; i < numParticles; i++) {
            Particle *particle = new Particle();
            particle->setup(startYPos, startXPos,
                            xPosRange, yPosRange,
                            minSpeed, speedRange);
            //particle->iNameID = "Agent";
            if(i==CanvesIndex) particle->iNameID = "Canves";
            if(i==UserIndex) particle->iNameID = "User";
            if(i>=AgentStartIndex) particle->iNameID = "Agent";
            particles.append(particle);
        }

        // (year, month, day, time in seconds)
        QDateTime date = QDateTime::currentDateTime();
        int timetotal = date.time().hour() + date.time().minute() + date.time().second() + date.time().msec();
        m_shaderproperties.iMode = QVector4D(1.0,0.0,0.0,0.0);//isTexture,isSelected,ModeId
        m_shaderproperties.iResolution = QVector3D(1.0,1.0,1.0);
        m_shaderproperties.iTime = 0.0;
        m_shaderproperties.iTimeDelta = 0.0;
        m_shaderproperties.iFrame = 0;
        m_shaderproperties.iChannelTime[0] = 0.1;
        m_shaderproperties.iChannelTime[1] = 0.1;
        m_shaderproperties.iChannelTime[2] = 0.1;
        m_shaderproperties.iChannelTime[3] = 0.1;
        m_shaderproperties.iChannelResolution[0] = QVector3D(0.50,0.50,1.0);
        m_shaderproperties.iChannelResolution[1] = QVector3D(0.50,0.50,1.0);
        m_shaderproperties.iChannelResolution[2] = QVector3D(0.50,0.50,1.0);
        m_shaderproperties.iChannelResolution[3] = QVector3D(0.50,0.50,1.0);
        m_shaderproperties.iMouse = QVector4D(0.50,0.00,1.0,1.0);
        m_shaderproperties.iDate = QVector4D(date.date().year(),date.date().month(),date.date().day(),timetotal);

        mouseMode = "editLoop";

    }

    int getCount(){
        return numParticles;
    }

    void clean(){
        autocleanBuffer = false;
        cleanBuffer = true;
    }

    void autoclean(){
        autocleanBuffer = true;
        cleanBuffer = false;
    }

    QString getParticleName(int Id) {
        Particle *particle = new Particle();
        if(Id<numParticles){
            particle = particles.at(Id);
            return particle->iNameID;
        }
        else {
            return "error getting particle";
        }
    }

    int getnumSubParticles(int Id) {
        Particle *particle = new Particle();
        if(Id<numParticles){
            particle = particles.at(Id);
            return particle->getPointSize();
        }
        else {
            return -1;
        }
    }

    int getindexSubParticles(int Id) {
        Particle *particle = new Particle();
        if(Id<numParticles){
            particle = particles.at(Id);
            return particle->getPointIndex();
        }
        else {
            return -1;
        }
    }

    QVector4D getParticleMode(int Id) {
        Particle *particle = new Particle();
        if(Id<numParticles){
            particle = particles.at(Id);
        }

        //getParticleMode : isTexture,isSelected,ModeId,null
        if(particle->iNameID == "Canves"){
            if(mouseMode=="editLoop"){
                return QVector4D(0.0,0.0,0.0,0.0);
                //grid,isSelected,ModeId,null
            }
            else if(mouseMode=="playLoop"){
                if(isFBOTexture)
                    return QVector4D(1.0,0.0,0.0,0.25);
                    //fragTexture,isSelected,ModeId,channelFBO
                else
                    return QVector4D(0.0,0.0,0.0,0.0);
                    //blank,isSelected,ModeId,null
            }
            else if(mouseMode=="sampleLoop"){
                return QVector4D(0.0,0.0,0.0,0.0);
                //blank,isSelected,ModeId,null
            }
            else
                return QVector4D(4.0,0.0,0.0,0.0);
                //color,isSelected,ModeId,null
        }
        else if(particle->iNameID == "User"){
            if(mouseMode=="editLoop"){
                return QVector4D(1.0,0.0,2.0,0.0);
                //white,isSelected,bezier,null
            }
            else if(mouseMode=="playLoop"){
                return QVector4D(1.0,0.0,2.0,0.0);
                //white,isSelected,bezier,null
            }
            else if(mouseMode=="sampleLoop"){
                return QVector4D(1.0,0.0,2.0,0.0);
                //white,isSelected,bezier,null
            }
            else
                return QVector4D(4.0,0.0,0.0,0.0);
                //color,isSelected,ModeId,null
        }
        else if(particle->iNameID == "Agent"){
            if(mouseMode=="editLoop"){
                return QVector4D(1.0,0.0,1.0,0.0);
                //white,isSelected,scene,null
            }
            else if(mouseMode=="playLoop"){
                return QVector4D(1.0,0.0,1.0,0.0);
                //white,isSelected,scene,null
            }
            else if(mouseMode=="sampleLoop"){
                return QVector4D(1.0,0.0,1.0,0.0);
                //white,isSelected,scene,null
            }
            else
                return QVector4D(4.0,0.0,0.0,0.0);
                //color,isSelected,ModeId,null
        }
        else
            return QVector4D(0.0,0.0,0.0,0.0);
    }

    QVector4D getParticleColor(int Id) {
        Particle *particle = new Particle();
        if(Id<numParticles){
            particle = particles.at(Id);
        }
        if(particle->iNameID == "Canves"){
            return QVector4D(0.0,1.0,0.0,1.0);
        }
        else if(particle->iNameID == "User"){
            return QVector4D(1.0,0.0,0.0,1.0);
        }
        else if(particle->iNameID == "Agent"){
            return QVector4D(0.0,0.0,1.0,1.0);
        }
        else
            return QVector4D(1.0,0.0,0.0,1.0);
    }

    QVector3D getParticleWorldPosition(int Id) {
        //        for(int i = 0; i < particles.length; i++) {
        //            Particle particle = particles.at(i);
        //            particle.getPhysics();
        //        }
        QVector3D pos;

        if(particles.at(Id)->iNameID == "Canves"){
            pos = QVector3D(0.0,
                            0.0,
                            -1.0);

        }
        else if(particles.at(Id)->iNameID == "User"){
            pos = QVector3D(0.0,
                            0.0,
                            -0.5);
//            pos = QVector3D((-0.5+pos.x())*canvesSize/userSize,
//                            (-0.5+pos.y())*-canvesSize/userSize,
//                            0.0);
        }
        else if(particles.at(Id)->iNameID == "Agent"){
            pos = QVector3D((-0.5+pos.x())*canvesSize/botSize,
                            (-0.5+pos.y())*canvesSize/botSize,
                            1.0+(0.1*(float)Id));
        }
        return pos;
    }

    QVector4D getParticleScenePosition(int Id) {

        QVector4D pos;
        if(Id<numParticles){
            pos = particles.at(Id)->getParticlePosition();
        }

        if(particles.at(Id)->iNameID == "Canves"){
            pos = QVector4D(0.0,
                            0.0,
                            -0.5,0.0);

        }
        else if(particles.at(Id)->iNameID == "User"){
            if(mouseMode=="playLoop"){
                pos = QVector4D((pos.x()),
                                (pos.y()),
                                (pos.z()),
                                (pos.w()));
            }
            else if(mouseMode=="editLoop") {
                pos = QVector4D(m_shaderproperties.iMouse.x(),
                                m_shaderproperties.iMouse.y(),
                                m_shaderproperties.iMouse.z(),
                                m_shaderproperties.iMouse.w());
            }
            else if(mouseMode=="sampleLoop") {
                pos = QVector4D((pos.x()),
                                (pos.y()),
                                (pos.z()),
                                (pos.w()));
            }
        }
        else if(particles.at(Id)->iNameID == "Agent"){
            pos = QVector4D((-0.5+pos.x())*canvesSize/botSize,
                            (-0.5+pos.y())*canvesSize/botSize,
                            1.0+(0.1*(float)Id),0.0);
        }
        return pos;
    }

    float getParticleScale(int Id) {
        Particle *particle = new Particle();
        if(Id<numParticles){
            particle = particles.at(Id);
        }
        if(particle->iNameID == "Canves"){
            return canvesSize;
        }
        else if(particle->iNameID == "User"){
            return userSize;
        }
        else if(particle->iNameID == "Agent"){
            return botSize;
        }
        else
            return 1.0;
    }

    float getParticleOpacity(int Id) {
        Particle *particle = new Particle();
        if(Id<numParticles){
            particle = particles.at(Id);
        }
        if(particle->iNameID == "Canves"){
            return 1.0;
        }
        else if(particle->iNameID == "User"){
            return 0.85;
        }
        else if(particle->iNameID == "Agent"){
            return 0.5;
        }
        else
            return 1.0;
    }

    bool isLive(int Id) {
        Particle *particle = new Particle();
        if(Id<numParticles){
            particle = particles.at(Id);
        }
        bool live;
        if(particle->iNameID == "Canves"){
            if(mouseMode=="editLoop") live = true;
            else if(mouseMode=="playLoop") live = true;
            else if(mouseMode=="sampleLoop") live = false;
        }
        else if(particle->iNameID == "User"){
            if(mouseMode=="editLoop") live = true;
            else if(mouseMode=="playLoop") live = true;
            else if(mouseMode=="sampleLoop") live = true;
        }
        else if(particle->iNameID == "Agent"){
            if(mouseMode=="editLoop") live = false;
            else if(mouseMode=="playLoop") live = true;
            else if(mouseMode=="sampleLoop") live = false;
        }
        else
            live = true;
        return live;
    }

    QMatrix4x4 getParticleOrentation(int Id) {
        Particle *particle = new Particle();
        if(Id<numParticles){
            particle = particles.at(Id);
        }
        QMatrix4x4 model;
        model.setToIdentity();
        if(particle->iNameID == "Canves"){
            model.rotate(90,1.0,0.0,0.0);
        }
        else if(particle->iNameID == "User"){
            model.rotate(90,1.0,0.0,0.0);
        }
        else if(particle->iNameID == "Agent"){
            model.rotate(90,1.0,0.0,0.0);
        }
        else
            model.rotate(0,1.0,0.0,0.0);
        return model;
    }

    QString getPlayMode() {
        return this->mouseMode;
    }

    void setPlayMode(QString mouseMode) {
        this->mouseMode = mouseMode;
        //if(mouseMode == "sampleLoop") clean();
    }

    void updatePhysics(int playIndex) {
        if(playIndex!=0){
            for(int i = 0; i < numParticles; i++) {
                Particle *particle = particles.at(i);
                if(particle->iNameID == "Canves"){
                    particle->position = QVector4D(0.0,0.0,0.0,0.0);
                }
                else if(particle->iNameID == "User"){
                    if(mouseMode=="playLoop"){
                        particle->updatePoints(playIndex);
                    }
                    else if(mouseMode=="editLoop") {
                        particle->position = m_shaderproperties.iMouse;
                    }
                    else if(mouseMode=="sampleLoop") {
                        particle->updatePoints(playIndex);
                    }
                    else {
                        particle->position = QVector4D(0.0,0.0,0.0,0.0);
                    }
                }
                else if(particle->iNameID == "Agent"){

                    particle->updatePhysics(playIndex);

                    // If this particle is completely out of sight
                    // replace it with a new one.
                    if(particle->outOfSight(xPosRange,yPosRange)) {
                        QString name = particle->iNameID;
                        Particle *newParticle = new Particle();
                        newParticle->setup(startYPos, startXPos,
                                           xPosRange, yPosRange,
                                           minSpeed, speedRange);
                        newParticle->iNameID = name;
                        particles.removeAt(i);
                        particles.insert(i,newParticle);
                    }

                }
    //            qDebug()<<i<<" Id "<<particle->iNameID
    //                   <<" : "<< particle->xpos
    //                  << ", " << particle->ypos;

            }
        }
    }

    void updateMouse(QVector3D pointer) {
        bool isClicked=false;
        if(pointer.z()==1.0) isClicked = true;
        QVector2D oldPt(m_shaderproperties.iMouse.x(),m_shaderproperties.iMouse.y());
        QVector2D newPt(pointer.x(),pointer.y());
        m_shaderproperties.iMouse.setX(newPt.x());
        m_shaderproperties.iMouse.setY(newPt.y());
        m_shaderproperties.iMouse.setZ(oldPt.x());
        m_shaderproperties.iMouse.setW(oldPt.y());
        QVector4D *newPoint = new QVector4D(m_shaderproperties.iMouse);
        if(isClicked){
            for(int i = 0; i < numParticles; i++) {
                Particle *particle = particles.at(i);
                if(particle->iNameID == "Canves"){
                }
                else if(particle->iNameID == "User"){
                    qDebug()<<"updateMouse-mouseMode: "<<mouseMode;
                    if(mouseMode=="editLoop")particle->addPoints(newPoint);
                }
                else if(particle->iNameID == "Agent"){

                }
            }
        }
    }

    void updateResolution(QSize size)
    {
        m_shaderproperties.iResolution = QVector3D(size.width(),size.height(),1.0);
        //qDebug()<< "iResolution: " << m_shaderproperties.iResolution;
    }

    void updateScene(int playIndex)
    {

        if(playIndex!=0){

            // (year, month, day, time in seconds)
            QDateTime date = QDateTime::currentDateTime();
            int timetotal = date.time().hour() + date.time().minute() + date.time().second() + date.time().msec();
            if((m_shaderproperties.iFrame+playIndex)%120==0) m_shaderproperties.iTime += playIndex;
            m_shaderproperties.iTimeDelta = timetotal-m_shaderproperties.iDate.w();
            m_shaderproperties.iFrame += playIndex;
            m_shaderproperties.iChannelTime[0] = 0.1;
            m_shaderproperties.iChannelTime[1] = 0.1;
            m_shaderproperties.iChannelTime[2] = 0.1;
            m_shaderproperties.iChannelTime[3] = 0.1;
            m_shaderproperties.iChannelResolution[0] = QVector3D(0.50,0.50,1.0);
            m_shaderproperties.iChannelResolution[1] = QVector3D(0.50,0.50,1.0);
            m_shaderproperties.iChannelResolution[2] = QVector3D(0.50,0.50,1.0);
            m_shaderproperties.iChannelResolution[3] = QVector3D(0.50,0.50,1.0);
            m_shaderproperties.iDate = QVector4D(date.date().year(),date.date().month(),date.date().day(),timetotal);

    //        if(m_shaderproperties.iFrame%30==0) {
    //            qDebug() << "iMode(isTexture,isSelected,ModeId,null)" << m_shaderproperties.iMode;
    //            qDebug() << "iResolution" << m_shaderproperties.iResolution;
    //            qDebug() << "iTime" << m_shaderproperties.iTime;
    //            qDebug() << "iTimeDelta" << m_shaderproperties.iTimeDelta;
    //            qDebug() << "iFrame" << m_shaderproperties.iFrame;
    //            //qDebug() << "iChannelTime" << m_shaderproperties.iChannelTime;
    //            //qDebug() << "iChannelResolution" << m_shaderproperties.iChannelResolution;
    //            qDebug() << "iMouse" << m_shaderproperties.iMouse;
    //            qDebug() << "iDate" << m_shaderproperties.iDate;
    //        }
            updatePhysics(playIndex);
        }

    }

signals:

public slots:

public:
    QList<Particle*> particles;
    float startYPos;
    float startXPos;
    float xPosRange;
    float yPosRange;
    float minSpeed;
    float speedRange;
    int numParticles;
    float canvesSize = 40.0;
    float botSize = 2.0;
    float userSize = 40.0;
    bool autocleanBuffer = false;
    bool cleanBuffer = false;
    QString mouseMode;
    int CanvesIndex = 0;
    int UserIndex = 1;
    int AgentStartIndex = 2;
    bool isFBOTexture = false;   // got frame as texture

    struct ShaderProperties {
        QString                 iNameID;
        QVector4D               iMode;                  // mode values
        //float                 iFrameRate;             // average FPS.
        QVector3D               iResolution;            // viewport resolution (in pixels)
        int                     iTime;                  // shader playback time (in seconds)[seconds(+fracs) since the shader (re)started.]
        float                   iTimeDelta;             // render time (in seconds)[duration since the previous frame.]
        int                     iFrame;                 // shader playback frame[frames since the shader (re)started.]
        float                   iChannelTime[4];        // channel playback time (in seconds)
        QVector3D               iChannelResolution[4];  // channel resolution (in pixels)
        QVector4D               iMouse;                 // mouse pixel coords. xy: current (if MLB down), zw: click
        //samplerXX             iChannel0..3;             // input channel. XX = 2D/Cube
        QVector4D               iDate;                  // (year, month, day, time in seconds)[year-1, month-1, day, seconds(+fracs) since midnight.]
        //float                 iSampleRate;            // sound sample rate (i.e., 44100)
    };

    //QList<ShaderProperties>   m_shaderproperties;
    ShaderProperties            m_shaderproperties;

};

#endif // PARTICLESYSTEM_H
