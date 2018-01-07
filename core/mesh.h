#ifndef MESH_H
#define MESH_H

#include <QImage>
#include <QMatrix4x4>
#include <QObject>
#include <QOpenGLBuffer>
#include <QOpenGLVertexArrayObject>

#include "mesh.h"
#include "vertex.h"
#include "material.h"

class QOpenGLShaderProgram;
class QOpenGLTexture;
namespace cgl {
class Mesh : public QObject
{
    Q_OBJECT

public:
    Mesh(QObject *parent = 0);
    Mesh(const Mesh &mesh);
    ~Mesh();

    void                    addVertex(const Vertex &ver) { mVertices.append(ver); }
    void                    addVertex(const QVector<Vertex>& ver) {mVertices.append(ver);}
    void                    addMaterial(const Material& material) {mMaterials.append(material);}
    void                    clearVertices(){mVertices.clear();}
    void                    bind();
    void                    create();
    bool                    hasIndices() const { return mIndices.isEmpty(); }
    int                     indicesCount() const { return mIndices.count(); }
    bool                    isInside(QVector3D pointer) const { qDebug() << pointer << "Implement for" << objectName(); return false;}
    GLenum                  mode() const { return mMode; }
    QMatrix4x4              modelMatrix() const { return mModelMatrix; }
    void                    release();
    void                    rotate(float angle, float x, float y, float z) { mModelMatrix.rotate(angle, x, y, z); }
    void                    scale(float x, float y, float z) {mModelMatrix.scale(x,y,z);}
    void                    scale(float f) { mModelMatrix.scale(f);}
    void                    setShaders(const QString &vertexFile, const QString &fragmentFile, const QString& geometryFile = QString());
    void                    setCustomShaders(const QString &vertexFile, const QString &fragmentFile, const QString& geometryFile = QString());
    void                    setDefaultShaders();
    void                    setTextureImage(const QString filename) {setTextureImage(QImage(filename));}
    void                    setTextureImage(const QImage &image);
    void                    setOpacity(float alpha) {mOpacity = alpha;}
    float                   opacity() const {return mOpacity;}
    QOpenGLShaderProgram    *shaderProgram() const { return mShaderProgram; }
    void                    translate(float x, float y, float z) { mModelMatrix.translate(x, y, z); }
    Vertex&                 vertex(int index)  { return mVertices[index];}
    QVector<Vertex>         vertices() const { return mVertices; }
    int                     verticesCount() const { return mVertices.count(); }
    void                    setMode(GLenum mode) { mMode = mode;}
    void                    resetTransform() { mModelMatrix.setToIdentity(); }
    void                    setDebug(bool enable = true);
    QImage                  textureImage() const { return mTextureImage; }
    void test();

protected:
    virtual void            makeMesh(){;}
    void                    computeNormal();

private:
    bool                        mDebugView;             // allows to visualize meshes
    bool                        mCustomShader = false;  // use custom shader
    QString                     mfshName,mvshName;
    QOpenGLBuffer               mIndexBuffer;           // the indexes to the verices in graphic card
    QVector<GLuint>             mIndices;               // the indices list
    GLenum                      mMode;                  // drawing mode to connect vertices
    QMatrix4x4                  mModelMatrix;           // the model matrix
    QOpenGLShaderProgram        *mShaderProgram;        // the shadder program
    QOpenGLTexture              *mTexture;              // texture od the mesh
    QImage                      mTextureImage;          // image of the texture
    QOpenGLVertexArrayObject    mVao;                   // the buffer that stores object data in graphic card
    QOpenGLBuffer               mVertexBuffer;          // the buffer that holds the lis of vertices in graphic card
    QVector<Vertex>             mVertices;              // list of vertexes for this mesh
    QVector<Material>           mMaterials;             // what is this ?
    float                       mOpacity;               // what is this ?


};

}
#endif // MESH_H
