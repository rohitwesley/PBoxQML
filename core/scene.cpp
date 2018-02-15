#include <QDateTime>
#include <QOpenGLContext>
#include <QOpenGLFunctions>
#include <QOpenGLShaderProgram>
#include <QOpenGLTexture>

#include "scene.h"
namespace cgl {
//===================================================================
Scene::Scene(QObject *parent) :
    QObject(parent),
    mContext(0),
    mDebug(false),
    mCamera(new Camera()),
    m_Fbo(0)
{

    // Add default light... Otherwise black screen !
    addLight(new Light(5,5,5));
    reset();

}

//===================================================================
void Scene::createMeshes()
{
    // creates the drawing for all meshes in the graphic card
    if(!mContext) {
        qFatal("Scene::createMeshes ---> no QOpenGLContext defined");
        exit(QtFatalMsg);
    }
    foreach (Mesh *mesh, mMeshes) {
        mesh->setDefaultShaders();
        mesh->create();
        //        mesh->setTexture(mesh->textureImage());
    }
}

void Scene::reset()
{
    camera()->reset();
    logicSystem.setup(0,0,100,
                      1.0,1.0,
                      0.001,0.01);
    logicSystem.autoclean();
    qDebug()<<"reset Scene";
    isManulaPlay = false;
}

void Scene::autoclean()
{
    logicSystem.autoclean();
    qDebug()<<"on AutoClean";
}

void Scene::clean()
{
    logicSystem.clean();
    qDebug()<<"clean Canvas";
}

void Scene::setPlayMode(QString playMode)
{
    logicSystem.setPlayMode(playMode);

    //Reset FrameBuffer
    if(m_Fbo->isValid()) {
        m_Fbo->release();
    }
    // Initialize the buffers and renderer
    QOpenGLFramebufferObjectFormat format;
    format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
    format.setMipmap(false);
    format.setSamples(16);
    format.setTextureTarget(GL_TEXTURE_2D);
    //format.setInternalTextureFormat(GL_RGBA32F_ARB);
    m_Fbo = new QOpenGLFramebufferObject(m_size, format);
}

void Scene::updateScene(int playMode)
{
    if(playMode==0)isManulaPlay = !isManulaPlay;
    logicSystem.updateScene(playMode);
}

void Scene::renderScene(Mesh *mesh,int id)
{

    //foreach (Mesh *mesh, mMeshes) {
    QOpenGLShaderProgram *prg = mesh->shaderProgram();
    prg->bind();
    mesh->bind();

    QMatrix4x4 ModelViewProjectionMatrix = mProjection * mView * mesh->modelMatrix();

    // Apply light uniform value
    if (!mLights.isEmpty())
    {

        //           QVector3D np =   mProjection* mView * mLights.first()->position();
        QVector3D np =   ModelViewProjectionMatrix* mLights.first()->position();
        //             QVector3D np =   mLights.first()->position();
        prg->setUniformValue("light.position",np);
        prg->setUniformValue("light.ambient",  mLights.first()->colorVector());
    }

    prg->setUniformValueArray("modelviewprojectionMatrix", &ModelViewProjectionMatrix, 1);
    prg->setUniformValue("opacity", mesh->opacity());


    // object active
    if(!has_texture) {
        mTexture.clear();
        for(int tex=0;tex<4;tex++){
            QImage mTextureImage;
            if(tex==0)mTextureImage.load("://media/textures/wood.jpg");
            if(tex==1)mTextureImage.load("://media/textures/tex11.png");
            if(tex==2)mTextureImage.load("://media/textures/mat_normals.jpg");
            if(tex==3)mTextureImage.load("://media/textures/damier.png");
            QOpenGLTexture* tempText  = new QOpenGLTexture(mTextureImage);
            tempText->create();
            mTexture.append(tempText);

            //SAFE_DELETE(m_GLTexture);
            //m_GLTexture = new QOpenGLTexture(QOpenGLTexture::Target::Target2DArray);
            Sceneimage.load("://media/textures/wood.jpg");
            m_GLTexture = new QOpenGLTexture(Sceneimage);
            m_GLTexture->create();

        }
        has_texture = true;
    }
    else {
        for(int tex=0;tex<4;tex++){
            if (mTexture.at(tex)->isCreated()){
                // Use texture unit 'tex' which contains the object texture
                mTexture.at(tex)->bind(tex);
                prg->setUniformValue("iChannel"+tex, tex);
            }
        }
    }

    qDebug()<<" isRec: "<<isRec;
    //if(isFBOReady)
    if(logicSystem.isFBOTexture) {
        // Use texture unit 4 which contains the object texture
        m_GLTexture->bind(4);
        prg->setUniformValue("fragFBOTexture", 4);
    }

    prg->setUniformValue("iMode", logicSystem.getParticleMode(id));
    prg->setUniformValue("iColor", logicSystem.getParticleColor(id));
    // viewport resolution (in pixels)
    //QVector3D iRez = QVector3D(0.50,0.50,1.0);
    prg->setUniformValue("iResolution", logicSystem.m_shaderproperties.iResolution);
    // shader playback time (in seconds)
    //float iTime = 0.1;
    prg->setUniformValue("iTime", logicSystem.m_shaderproperties.iTime);
    // render time (in seconds)
    //float iTimeDelta = 1.0;
    prg->setUniformValue("iTimeDelta", logicSystem.m_shaderproperties.iTimeDelta);
    // shader playback frame
    //int iFrame = 0;
    prg->setUniformValue("iFrame", logicSystem.m_shaderproperties.iFrame);
    // channel playback time (in seconds)
    //float iChannelTime = 0.1;
    prg->setUniformValue("iChannelTime[0]", logicSystem.m_shaderproperties.iChannelTime[0]);
    prg->setUniformValue("iChannelTime[1]", logicSystem.m_shaderproperties.iChannelTime[1]);
    prg->setUniformValue("iChannelTime[2]", logicSystem.m_shaderproperties.iChannelTime[2]);
    prg->setUniformValue("iChannelTime[3]", logicSystem.m_shaderproperties.iChannelTime[3]);
    // channel resolution (in pixels)
    //QVector3D iChannelResolution = QVector3D(0.50,0.50,1.0);
    prg->setUniformValue("iChannelResolution[0]", logicSystem.m_shaderproperties.iChannelResolution[0]);
    prg->setUniformValue("iChannelResolution[1]", logicSystem.m_shaderproperties.iChannelResolution[1]);
    prg->setUniformValue("iChannelResolution[2]", logicSystem.m_shaderproperties.iChannelResolution[2]);
    prg->setUniformValue("iChannelResolution[3]", logicSystem.m_shaderproperties.iChannelResolution[3]);
    // mouse pixel coords. xy: current (if MLB down), zw: click
    //QVector4D iMouse = QVector4D(0.50,0.00,1.0,1.0);
    prg->setUniformValue("iMouse", logicSystem.m_shaderproperties.iMouse);
    //QVector4D iPosition = QVector4D(0.50,0.00,1.0,1.0);
    //if(logicSystem.getParticleName(id)=="User")qDebug()<<"iPosition: "<<logicSystem.getParticleScenePosition(id);
    prg->setUniformValue("iPosition", logicSystem.getParticleScenePosition(id));
    // (year, month, day, time in seconds)
    //QDateTime date = QDateTime::currentDateTime();
    //QVector4D iDate = QVector4D(date.date().year(),date.date().month(),date.date().day(),date.time().second());
    prg->setUniformValue("iDate", logicSystem.m_shaderproperties.iDate);

    if (mesh->hasIndices())
        mContext->functions()->glDrawArrays(mesh->mode(), 0, mesh->verticesCount());
    else
        mContext->functions()->glDrawElements(mesh->mode(), mesh->indicesCount(), GL_UNSIGNED_INT, 0);
    mesh->release();

    //}

}

void Scene::saveScene(QString imgfileName)
{
    if (m_Fbo){
        if(m_Fbo->isValid()){
            QImage image;
            GLenum internalFormat = m_Fbo->format().internalTextureFormat();
            bool hasAlpha = internalFormat == GL_RGBA || internalFormat == GL_BGRA
                    || internalFormat == GL_RGBA8;
            if (internalFormat == GL_BGRA) {
                image = QImage(m_Fbo->size(), hasAlpha ? QImage::Format_ARGB32 : QImage::Format_RGB32);
                mContext->functions()->glReadPixels(0, 0, m_Fbo->size().width(),
                                          m_Fbo->size().height(), GL_BGRA, GL_UNSIGNED_BYTE, image.bits());
            } else if ((internalFormat == GL_RGBA) || (internalFormat == GL_RGBA8)) {
                image = QImage(m_Fbo->size(), hasAlpha ? QImage::Format_RGBA8888 : QImage::Format_RGBX8888);
                mContext->functions()->glReadPixels(0, 0, m_Fbo->size().width(),
                                          m_Fbo->size().height(), GL_RGBA, GL_UNSIGNED_BYTE, image.bits());
            } else {
                qDebug() << "OpenGlOffscreenSurface::grabFramebuffer() - Unsupported framebuffer format"
                         << internalFormat << "!";
            }
            image = image.mirrored();
            if(!image.isNull()){
                image.save(imgfileName);
                qDebug() << "fileName: " << imgfileName;
            }

            qDebug()<<"New fragFBOTexture created at "<<imgfileName;
        }
        else
            qDebug()<<"Error Creating Image "<<imgfileName;
    }

}

void Scene::initFBO()
{
    if (!m_Fbo) {
        // Initialize the buffers and renderer
        QOpenGLFramebufferObjectFormat format;
        format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
        format.setMipmap(false);
        format.setSamples(16);
        format.setTextureTarget(GL_TEXTURE_2D);
        //format.setInternalTextureFormat(GL_RGBA32F_ARB);
        m_Fbo = new QOpenGLFramebufferObject(m_size, format);
    }
    else if(logicSystem.getPlayMode()=="sampleLoop"){
        //m_Fbo->bind();
        m_Fbo->bindDefault();
    }
    else {

        m_Fbo->bindDefault();
    }


    mContext->functions()->glDisable(GL_CULL_FACE);
    mContext->functions()->glEnable(GL_DEPTH_TEST);
    mContext->functions()->glEnable(GL_STENCIL_TEST);
    mContext->functions()->glEnable(GL_ALPHA_TEST);
    mContext->functions()->glEnable(GL_BLEND);
    mContext->functions()->glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    mContext->functions()->glClear(GL_DEPTH_BUFFER_BIT |
                                   GL_STENCIL_BUFFER_BIT);
    if(logicSystem.cleanBuffer||logicSystem.autocleanBuffer) {
        mContext->functions()->glClear(GL_COLOR_BUFFER_BIT);
        logicSystem.cleanBuffer = false;// screen is cleared reset cleaning state
    }

    isFBOReady = false;
    if(!isManulaPlay)updateScene(1);

}

//===================================================================
void Scene::drawTexture()
{

    //TODO render to texture
    //rend scene here
    Mesh *meshSprite;
    foreach (Mesh *mesh, mMeshes) {
        meshSprite = mesh;
        //for(int i = logicSystem.getCount()-1; i > -1; i--)
        for(int i = 0; i < logicSystem.getCount(); i++)
        {
            //qDebug()<<"Object: "<<logicSystem.getParticleName(i) << ":" << i;
            if(logicSystem.isLive(i)){
                meshSprite->resetMatrix();
                meshSprite->setOpacity(logicSystem.getParticleOpacity(i));
                meshSprite->scale(logicSystem.getParticleScale(i));
                meshSprite->translate(logicSystem.getParticleWorldPosition(i).x(),
                                logicSystem.getParticleWorldPosition(i).y(),
                                logicSystem.getParticleWorldPosition(i).z());
                meshSprite->rotate(logicSystem.getParticleOrentation(i));
                renderScene(meshSprite,i);
            }
        }
    }

    //mContext->functions()->glFlush();
    //m_Fbo->release();
    isFBOReady = true;
    //qDebug()<<"rendered texture ready";
    //qSwap(m_Fbo, m_displayFbo);

}

void Scene::draw()
{
    // draw all the objects in the scene
    if(!mContext) {
        qFatal("Scene::createMeshes ---> no QOpenGLContext defined");
        exit(QtFatalMsg);
    }

    initFBO();

    if(logicSystem.getPlayMode()=="playLoop" && isRec) {
        m_GLTexture->destroy();
        m_GLTexture->create();
        int index  = logicSystem.getindexSubParticles(logicSystem.UserIndex);
        QString imgfileName;
        if(isManulaPlay)
            imgfileName = QString::fromLatin1("/Users/TecRT/Desktop/dump/renders/image_%1\.png").arg(logicSystem.getParticleName(logicSystem.UserIndex));
        else
            imgfileName = QString::fromLatin1("/Users/TecRT/Desktop/dump/renders/image_000%1_%2\.png").arg(index).arg(logicSystem.getParticleName(logicSystem.UserIndex));
        Sceneimage.load(imgfileName);
        //m_GLTexture->setMinificationFilter(QOpenGLTexture::Nearest);
        //m_GLTexture->setMagnificationFilter(QOpenGLTexture::Nearest);
        // m_GLTexture->setSize(m_width,m_height,1 );
        //m_GLTexture->setWrapMode(QOpenGLTexture::ClampToEdge);
        m_GLTexture->setData(Sceneimage);
        logicSystem.isFBOTexture = true;   // got frame as texture
    }
    else {
        logicSystem.isFBOTexture = false;   // got frame as texture
    }

    drawTexture();

    if(logicSystem.getPlayMode()=="sampleLoop"){
        if(isFBOReady){
            int index  = logicSystem.getindexSubParticles(logicSystem.UserIndex);
            QString imgfileName;
            if(isManulaPlay)
                imgfileName = QString::fromLatin1("/Users/TecRT/Desktop/dump/renders/image_%1\.png").arg(logicSystem.getParticleName(logicSystem.UserIndex));
            else
                imgfileName = QString::fromLatin1("/Users/TecRT/Desktop/dump/renders/image_000%1_%2\.png").arg(index).arg(logicSystem.getParticleName(logicSystem.UserIndex));
            saveScene(imgfileName);
            //if manual play save current image else save all images till end of loop
            //then get back to play mode.
            qDebug()<<" SampleLoop Index: " << index;
            if(index<=0||isManulaPlay) {
                setPlayMode("playLoop");
                isRec = true;
            }
        }
    }


}

//===================================================================
void Scene::setView(float width, float height)
{
    // scale all meshes in the scen
    m_size.setWidth(width);
    m_size.setHeight(height);
    logicSystem.updateResolution(m_size);
    verticalAngle = 45.0;
    float aspectRatio = m_size.width() / m_size.height();//aspect ratio
    setPerspective(verticalAngle, aspectRatio, 0.001, 100.0f);
    setOrtho(-logicSystem.canvesSize/2,logicSystem.canvesSize/2,
             -logicSystem.canvesSize/2,logicSystem.canvesSize/2,
             -1000.0, 1000.0);
    lookAt(camera()->position(), camera()->position() + camera()->target(), camera()->up());
}

//===================================================================
void Scene::scale(float updown)
{
    // scale all meshes in the scen
    for(int index = 0; index < mMeshes.size(); index++)
        mMeshes.at(index)->scale(updown, updown, updown);
}

//===================================================================
void Scene::lookAt(const QVector3D &eye, const QVector3D &center, const QVector3D &up)
{
    // position the camera
    mView.setToIdentity();
    mView.lookAt(eye, center, up);
}

//===================================================================
void Scene::setOrtho(float left, float right, float bottom, float top, float nearPlane, float farPlane)
{
    // set orthogonal view
    mProjection.setToIdentity();
    mProjection.ortho(left, right, bottom, top, nearPlane, farPlane);
}

//===================================================================
void Scene::setPerspective(float verticalAngle, float aspectRatio, float nearPlane, float farPlane)
{
    // set the perspective view
    mProjection.setToIdentity();
    mProjection.perspective(verticalAngle, aspectRatio, nearPlane, farPlane);
}

//===================================================================
QString Scene::whereIs(QVector3D pointer)
{
    // checks in which mesh the pointer is
    bool select = false;
    QVector3D uvpointer = pointer;//+ QVector3D(-0.5,-0.5,0.5); // change coordinates form -0.5:0.5 to 0:1
    logicSystem.updateMouse(uvpointer);
    for(int index = 0; index < meshes().size(); index++) {
        if (meshes().at(index)->isInside(pointer)){
            select = true;
            return meshes().at(index)->objectName();
        }
    }
    return "OUTSIDE";
}

//===================================================================
void Scene::setDebug(bool enable)
{
    // set debug mode for all meshes in the scene to view normals

    mDebug = enable;
    foreach (Mesh * mesh, meshes())
        mesh->setDebug(mDebug);
}

}
