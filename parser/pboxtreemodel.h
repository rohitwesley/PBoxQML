#ifndef PBOXTREEMODEL_H
#define PBOXTREEMODEL_H

#include <QDateTime>
#include <QDebug>
#include <QSqlError>
#include <QSqlRecord>
#include <QSqlQuery>
#include <QSqlTableModel>
#include <QVector4D>

static void dropPboxTables()
{
    // The table already exists; we don't need to do anything.
    QSqlQuery query;
    if (QSqlDatabase::database().tables().contains(QStringLiteral("PboxNodeType"))
            && !query.exec(
                "DROP TABLE 'PboxNodeType'")) {
        qFatal("Failed to Drop database PboxNodeType: %s", qPrintable(query.lastError().text()));
    }
    if (QSqlDatabase::database().tables().contains(QStringLiteral("PboxMsg"))
            && !query.exec(
                "DROP TABLE 'PboxMsg'")) {
        qFatal("Failed to Drop database PboxMsg: %s", qPrintable(query.lastError().text()));
    }
    if (QSqlDatabase::database().tables().contains(QStringLiteral("PboxProp"))
            && !query.exec(
                "DROP TABLE 'PboxProp'")) {
        qFatal("Failed to Drop database PboxProp: %s", qPrintable(query.lastError().text()));
    }
    if (QSqlDatabase::database().tables().contains(QStringLiteral("PboxTree"))
            && !query.exec(
                "DROP TABLE 'PboxTree'")) {
        qFatal("Failed to Drop database PboxTree: %s", qPrintable(query.lastError().text()));
    }
    qDebug()<<"Droped Tables";
    return;
}
static void createPboxNodeTypeTable()
{
    if (QSqlDatabase::database().tables().contains(QStringLiteral("PboxNodeType"))) {
        // The table already exists; we don't need to do anything.
        return;
    }

    QSqlQuery query;
    if (!query.exec(
                "CREATE TABLE IF NOT EXISTS 'PboxNodeType' ("
                "   'name' TEXT NOT NULL,"
                "   PRIMARY KEY(name)"
                ")")) {
        qFatal("Failed to query database: %s", qPrintable(query.lastError().text()));
    }

    query.exec("INSERT INTO PboxNodeType VALUES('PBoxTreeRoot')");
    query.exec("INSERT INTO PboxNodeType VALUES('Shader')");
    query.exec("INSERT INTO PboxNodeType VALUES('Scene')");
    query.exec("INSERT INTO PboxNodeType VALUES('Vectors')");
    query.exec("INSERT INTO PboxNodeType VALUES('SVG')");
    query.exec("INSERT INTO PboxNodeType VALUES('Obj')");
    query.exec("INSERT INTO PboxNodeType VALUES('Textures')");
    query.exec("INSERT INTO PboxNodeType VALUES('Tiles')");
    query.exec("INSERT INTO PboxNodeType VALUES('MoCap')");
    query.exec("INSERT INTO PboxNodeType VALUES('ImgSequemces')");
    query.exec("INSERT INTO PboxNodeType VALUES('ImgSprites')");
    query.exec("INSERT INTO PboxNodeType VALUES('ImgShots')");
    query.exec("INSERT INTO PboxNodeType VALUES('ImgScene')");
    query.exec("INSERT INTO PboxNodeType VALUES('Audio')");
    query.exec("INSERT INTO PboxNodeType VALUES('Video')");

    qDebug()<<"PboxNodeType Table Created";

}
static void createPboxMsgTable()
{
    if (QSqlDatabase::database().tables().contains(QStringLiteral("PboxMsg"))) {
        // The table already exists; we don't need to do anything.
        return;
    }

    QSqlQuery query;
    QString queryText = "CREATE TABLE IF NOT EXISTS 'PboxMsg' ("
                        "'author' TEXT NOT NULL,"
                        "'recipient' TEXT NOT NULL,"
                        "'timestamp' TEXT NOT NULL,"
                        "'message' TEXT NOT NULL,"
                        "FOREIGN KEY('author') REFERENCES PboxNodeType ( name ),"
                        "FOREIGN KEY('recipient') REFERENCES PboxNodeType ( name )"
                        ")";
    if (!query.exec(queryText)) {
        qFatal("Failed to query database: %s", qPrintable(query.lastError().text()));
    }

    query.exec("INSERT INTO PboxMsg VALUES('PBoxTreeRoot', 'PBoxTreeRoot', '2016-01-07T14:36:06', 'Hello PBoxTreeRoot!')");
    query.exec("INSERT INTO PboxMsg VALUES('Shader', 'Shader', '2016-01-07T14:36:06', 'Hello Shader!')");
    query.exec("INSERT INTO PboxMsg VALUES('Scene', 'Scene', '2016-01-07T14:36:06', 'Hello Scene!')");
    query.exec("INSERT INTO PboxMsg VALUES('Vectors', 'Vectors', '2016-01-07T14:36:06', 'Hello Vectors!')");
    query.exec("INSERT INTO PboxMsg VALUES('SVG', 'SVG', '2016-01-07T14:36:06', 'Hello SVG!')");
    query.exec("INSERT INTO PboxMsg VALUES('Obj', 'Obj', '2016-01-07T14:36:06', 'Hello Obj!')");
    query.exec("INSERT INTO PboxMsg VALUES('Textures', 'Textures', '2016-01-07T14:36:06', 'Hello Textures!')");
    query.exec("INSERT INTO PboxMsg VALUES('Tiles', 'Tiles', '2016-01-07T14:36:06', 'Hello Tiles!')");
    query.exec("INSERT INTO PboxMsg VALUES('MoCap', 'MoCap', '2016-01-07T14:36:06', 'Hello MoCap!')");
    query.exec("INSERT INTO PboxMsg VALUES('ImgSequemces', 'ImgSequences', '2016-01-07T14:36:06', 'Hello ImgSequences!')");
    query.exec("INSERT INTO PboxMsg VALUES('ImgSprites', 'ImgSprites', '2016-01-07T14:36:06', 'Hello ImgSprites!')");
    query.exec("INSERT INTO PboxMsg VALUES('ImgShots', 'ImgShots', '2016-01-07T14:36:06', 'Hello ImgShots!')");
    query.exec("INSERT INTO PboxMsg VALUES('ImgScene', 'ImgScene', '2016-01-07T14:36:06', 'Hello ImgScene!')");
    query.exec("INSERT INTO PboxMsg VALUES('Audio', 'Audio', '2016-01-07T14:36:06', 'Hello Audio!')");
    query.exec("INSERT INTO PboxMsg VALUES('Video', 'Video', '2016-01-07T14:36:06', 'Hello Video!')");

    qDebug()<<"PboxMsg Table Created";

}
static void createPboxPropTable()
{
    if (QSqlDatabase::database().tables().contains(QStringLiteral("PboxProp"))) {
        // The table already exists; we don't need to do anything.
        return;
    }

    QSqlQuery query;
    QString queryText = "CREATE TABLE IF NOT EXISTS 'PboxProp' ("
                        "   'treeId' int NOT NULL,"
                        "   'parentid' int NULL,"
                        "   'depth' int NULL,"
                        "   'pathindex' int NULL,"
                        "   'numericalmapping' TEXT NULL,"
                        "   'propTypeName' TEXT NOT NULL,"
                        "   'propName' TEXT NOT NULL,"
                        "   'propData' TEXT NULL,"
                        "   PRIMARY KEY(treeId)"
                        ")";
    if (!query.exec(queryText)) {
        qFatal("Failed to query database: %s", qPrintable(query.lastError().text()));
    }

    query.exec("INSERT INTO PboxProp VALUES(1,NULL,NULL,NULL,NULL,'Prop','PropList',NULL)");
    query.exec("INSERT INTO PboxProp VALUES(2,1,NULL,NULL,NULL,'LineText','Data','Dummy Data')");

    query.exec("INSERT INTO PboxProp VALUES(3,NULL,NULL,NULL,NULL,'ShaderProp','ShaderPropList',NULL)");
    query.exec("INSERT INTO PboxProp VALUES(4,3,NULL,NULL,NULL,'ShaderFunction','helloworld','void helloworld(){return vec3(0.2,0.6,0.3);}')");

    query.exec("INSERT INTO PboxProp VALUES(5,NULL,NULL,NULL,NULL,'SceneProp','ScenePropList',NULL)");
    query.exec("INSERT INTO PboxProp VALUES(6,5,NULL,NULL,NULL,'LineText','iNameID','BasicScene')");
    query.exec("INSERT INTO PboxProp VALUES(7,5,NULL,NULL,NULL,'LineText','iMode','QVector4D(1.0,0.0,0.0,0.0)')");//TextureId,SelectioId,ModeId
    query.exec("INSERT INTO PboxProp VALUES(8,5,NULL,NULL,NULL,'LineText','iResolution','QVector3D(1.0,1.0,1.0)')");
    query.exec("INSERT INTO PboxProp VALUES(9,5,NULL,NULL,NULL,'LineText','iTime','0.0')");
    query.exec("INSERT INTO PboxProp VALUES(10,5,NULL,NULL,NULL,'LineText','iTimeDelta','0.0')");
    query.exec("INSERT INTO PboxProp VALUES(11,5,NULL,NULL,NULL,'LineText','iFrame','0')");
    query.exec("INSERT INTO PboxProp VALUES(12,5,NULL,NULL,NULL,'LineText','iChannelTime','QVector4D(0.1,0.1,0.1,0.1)')");
    query.exec("INSERT INTO PboxProp VALUES(13,5,NULL,NULL,NULL,'LineText','iChannelResolution','QVector3D(0.50,0.50,1.0)')");
    query.exec("INSERT INTO PboxProp VALUES(14,5,NULL,NULL,NULL,'LineText','iMouse','QVector4D(0.50,0.00,1.0,1.0)')");
    // (year, month, day, time in seconds)
    QDateTime date = QDateTime::currentDateTime();
    int timetotal = date.time().hour() + date.time().minute() + date.time().second() + date.time().msec();
    QVector4D date4D = QVector4D(date.date().year(),date.date().month(),date.date().day(),timetotal);
    QString datestring = "INSERT INTO PboxProp VALUES( 15,5,NULL,NULL,NULL,'LineText','iDate', date4D )";
    query.exec(datestring);

    query.exec("INSERT INTO PboxProp VALUES(16,5,NULL,NULL,NULL,'LineText','numParticles','100')");
    query.exec("INSERT INTO PboxProp VALUES(17,5,NULL,NULL,NULL,'LineText','startXPos','0')");
    query.exec("INSERT INTO PboxProp VALUES(18,5,NULL,NULL,NULL,'LineText','startYPos','0')");
    query.exec("INSERT INTO PboxProp VALUES(19,5,NULL,NULL,NULL,'LineText','xPosRange','1.0')");
    query.exec("INSERT INTO PboxProp VALUES(20,5,NULL,NULL,NULL,'LineText','yPosRange','1.0')");
    query.exec("INSERT INTO PboxProp VALUES(21,5,NULL,NULL,NULL,'LineText','minSpeed','0.001')");
    query.exec("INSERT INTO PboxProp VALUES(22,5,NULL,NULL,NULL,'LineText','speedRange','0.01')");

    query.exec("INSERT INTO PboxProp VALUES(23,5,NULL,NULL,NULL,'LineText','canvesSize','BasicScene')");
    query.exec("INSERT INTO PboxProp VALUES(24,5,NULL,NULL,NULL,'LineText','botSize','BasicScene')");
    query.exec("INSERT INTO PboxProp VALUES(25,5,NULL,NULL,NULL,'LineText','userSize','BasicScene')");
    query.exec("INSERT INTO PboxProp VALUES(26,5,NULL,NULL,NULL,'LineText','mouseMode','editLoop')");
    query.exec("INSERT INTO PboxProp VALUES(27,5,NULL,NULL,NULL,'LineText','CanvesIndex','40.0')");
    query.exec("INSERT INTO PboxProp VALUES(28,5,NULL,NULL,NULL,'LineText','UserIndex','1')");
    query.exec("INSERT INTO PboxProp VALUES(29,5,NULL,NULL,NULL,'LineText','AgentStartIndex','2')");

    query.exec("INSERT INTO PboxProp VALUES(30,5,NULL,NULL,NULL,'Link','DefaultShader','Shader:3')");
    query.exec("INSERT INTO PboxProp VALUES(31,5,NULL,NULL,NULL,'Link','DefaultVector','Vectors:7')");
    query.exec("INSERT INTO PboxProp VALUES(32,5,NULL,NULL,NULL,'Link','DefaultImage','ImgSet:11')");

    query.exec("INSERT INTO PboxProp VALUES(33,5,NULL,NULL,NULL,'ParticleProp','ParticlePropList',NULL)");
        query.exec("INSERT INTO PboxProp VALUES(34,33,NULL,NULL,NULL,'LineText','iNameID','BasicScene')");
        query.exec("INSERT INTO PboxProp VALUES(35,33,NULL,NULL,NULL,'LineText','position','BasicScene')");
        query.exec("INSERT INTO PboxProp VALUES(36,33,NULL,NULL,NULL,'LineText','speed','BasicScene')");
        query.exec("INSERT INTO PboxProp VALUES(37,33,NULL,NULL,NULL,'LineText','points','Vectors:7')");
        query.exec("INSERT INTO PboxProp VALUES(38,33,NULL,NULL,NULL,'LineText','pointIndex','0')");

//    query.exec("INSERT INTO PboxProp VALUES(7,5,NULL,NULL,NULL,'URL','Address','https://pbox.co')");
//    query.exec("INSERT INTO PboxProp VALUES(6,3,NULL,NULL,NULL,'Data','ComputeFunction','helloworld(){}')");
//    query.exec("INSERT INTO PboxProp VALUES(7,3,NULL,NULL,NULL,'Id','Index','1')");
//    query.exec("INSERT INTO PboxProp VALUES(8,3,NULL,NULL,NULL,'Position1D','AudioSample','(0.0)')");
//    query.exec("INSERT INTO PboxProp VALUES(9,3,NULL,NULL,NULL,'Position2D','ScreenSample','(0.0,0.0)')");
//    query.exec("INSERT INTO PboxProp VALUES(10,3,NULL,NULL,NULL,'Position3D','ObjectPosition','(0.0,0.0,0.0)')");
//    query.exec("INSERT INTO PboxProp VALUES(11,3,NULL,NULL,NULL,'Color','ColorSample','(1.0,0.0,0.0,1.0)')");
//    query.exec("INSERT INTO PboxProp VALUES(12,3,NULL,NULL,NULL,'Normal','DirectionSample','(0.0,1.0,0.0)')");
    if (!query.exec(queryText)) {
        qFatal("Failed to query database: %s", qPrintable(query.lastError().text()));
    }

    qDebug()<<"PboxProp Table Created";

}
static void createPboxTreeTable()
{
    if (QSqlDatabase::database().tables().contains(QStringLiteral("PboxTree"))) {
        // The table already exists; we don't need to do anything.
        return;
    }

    QSqlQuery query;
    QString queryText = "CREATE TABLE IF NOT EXISTS 'PboxTree' ("
                        "   'treeId' int NOT NULL,"
                        "   'parentid' int NULL,"
                        "   'depth' int NULL,"
                        "   'pathindex' int NULL,"
                        "   'numericalmapping' TEXT NULL,"
                        "   'propTypeName' TEXT NOT NULL,"
                        "   'propName' TEXT NOT NULL,"
                        "   'propData' TEXT NULL,"
                        "   PRIMARY KEY(treeId)"
                        "   FOREIGN KEY('propTypeName') REFERENCES PboxNodeType ( name ),"
                        "   FOREIGN KEY('propData') REFERENCES PboxProp ( treeId )"
                        ")";
    if (!query.exec(queryText)) {
        qFatal("Failed to query database: %s", qPrintable(query.lastError().text()));
    }

    query.exec("INSERT INTO PboxTree VALUES(1,NULL,NULL,NULL,NULL,'PBoxTreeRoot','PBoxTreeRootDefault',NULL)");

    query.exec("INSERT INTO PboxTree VALUES(2,1,NULL,NULL,NULL,'List','ShaderList',NULL)");
    query.exec("INSERT INTO PboxTree VALUES(3,2,NULL,NULL,NULL,'Shader','ShaderDefault','ShaderProp:4')");

    query.exec("INSERT INTO PboxTree VALUES(4,1,NULL,NULL,NULL,'List','SceneList',NULL)");
    query.exec("INSERT INTO PboxTree VALUES(5,4,NULL,NULL,NULL,'Scene','SceneDefault','SceneProp:5')");

    query.exec("INSERT INTO PboxTree VALUES(6,1,NULL,NULL,NULL,'List','VectorList',NULL)");
    query.exec("INSERT INTO PboxTree VALUES(7,6,NULL,NULL,NULL,'Vectors','VectorsDefault',SVG:8,Obj:9)");
    query.exec("INSERT INTO PboxTree VALUES(8,6,NULL,NULL,NULL,'SVG','SVGDefault','https://pbox.co')");
    query.exec("INSERT INTO PboxTree VALUES(9,6,NULL,NULL,NULL,'Obj','ObjDefault','https://pbox.co')");

    query.exec("INSERT INTO PboxTree VALUES(10,1,NULL,NULL,NULL,'List','ImgList',NULL)");
    query.exec("INSERT INTO PboxTree VALUES(11,10,NULL,NULL,NULL,'ImgSet','ImgSetDefault','MapedTexture:12,Tiles:13,MoCap:14,ImgScene:15')");
    query.exec("INSERT INTO PboxTree VALUES(12,10,NULL,NULL,NULL,'MapedTexture','MapedTexturesDefault','https://pbox.co')");
    query.exec("INSERT INTO PboxTree VALUES(13,10,NULL,NULL,NULL,'Tiles','TilesDefault','https://pbox.co')");
    query.exec("INSERT INTO PboxTree VALUES(14,10,NULL,NULL,NULL,'MoCap','MoCapDefault','https://pbox.co')");
    query.exec("INSERT INTO PboxTree VALUES(15,10,NULL,NULL,NULL,'ImgScene','ImgSceneDefault','https://pbox.co')");
    query.exec("INSERT INTO PboxTree VALUES(16,10,NULL,NULL,NULL,'ImgSequence','ImgSequenceDefault','https://pbox.co')");
    query.exec("INSERT INTO PboxTree VALUES(17,10,NULL,NULL,NULL,'ImgSprite','ImgSpriteDefault','https://pbox.co')");

    query.exec("INSERT INTO PboxTree VALUES(18,1,NULL,NULL,NULL,'List','AudioList',NULL)");
    query.exec("INSERT INTO PboxTree VALUES(19,18,NULL,NULL,NULL,'Audio','AudioDefault','https://pbox.co')");

    query.exec("INSERT INTO PboxTree VALUES(20,1,NULL,NULL,NULL,'List','VideoList',NULL)");
    query.exec("INSERT INTO PboxTree VALUES(21,20,NULL,NULL,NULL,'Video','VideoDefault','https://pbox.co')");

    if (!query.exec(queryText)) {
        qFatal("Failed to query database: %s", qPrintable(query.lastError().text()));
    }

    qDebug()<<"PboxTree Table Created";

}

class PboxTreeModel : public QSqlTableModel
{
    Q_OBJECT
public:
    PboxTreeModel(QObject *parent = 0);

    void setTableView(const QString &tablename);

    QVariant data(const QModelIndex &index, int role) const Q_DECL_OVERRIDE;
    QHash<int, QByteArray> roleNames() const Q_DECL_OVERRIDE;

    Q_INVOKABLE void resetTreeStructure();
    Q_INVOKABLE void updateTreeStructure();
    Q_INVOKABLE void selectTable(const QString &tableName,const QString &orderType);
    Q_INVOKABLE void selectNetworkNode(const QString &nodeIndex);
    Q_INVOKABLE QString selectPropertyNode(const QString &currentnodeIndex,const QString &nextnodeIndex);
    Q_INVOKABLE void clearMessages(const QString &recipient);
    Q_INVOKABLE void appendNode(const QString &propId,
                                const QString &propParentId,
                                const QString &propTypeName,
                                const QString &propName,
                                const QString &propData);
    Q_INVOKABLE void updateNode(const QString &propId,
                                const QString &propParentId,
                                const QString &propTypeName,
                                const QString &propName,
                                const QString &propData);

private:

};

#endif // PBOXTREEMODEL_H

/*

CREATE TABLE IF NOT EXISTS 'PboxNodeType'
  (
    'name' TEXT NOT NULL,
    PRIMARY KEY(name)
  );

    INSERT INTO PboxNodeType (name) VALUES('PBoxTreeRoot');
    INSERT INTO PboxNodeType (name) VALUES('Shader');
    INSERT INTO PboxNodeType (name) VALUES('Scene');
    INSERT INTO PboxNodeType (name) VALUES('Vectors');
    INSERT INTO PboxNodeType (name) VALUES('SVG');
    INSERT INTO PboxNodeType (name) VALUES('Obj');
    INSERT INTO PboxNodeType (name) VALUES('Textures');
    INSERT INTO PboxNodeType (name) VALUES('Tiles');
    INSERT INTO PboxNodeType (name) VALUES('MoCap');
    INSERT INTO PboxNodeType (name) VALUES('ImgSequemces');
    INSERT INTO PboxNodeType (name) VALUES('ImgSprites');
    INSERT INTO PboxNodeType (name) VALUES('ImgShots');
    INSERT INTO PboxNodeType (name) VALUES('ImgScene');
    INSERT INTO PboxNodeType (name) VALUES('Audio');
    INSERT INTO PboxNodeType (name) VALUES('Video');

CREATE TABLE IF NOT EXISTS 'PboxProp' (
    'propId' int NOT NULL,
    'parentId' int NOT NULL,
    'propName' TEXT NOT NULL,
    'propTypeName' TEXT NOT NULL,
    'propData' TEXT NULL,
    PRIMARY KEY(propId)
    );
    INSERT INTO PboxProp (propId,parentId,propName,propTypeName,propData)
    VALUES(1, 0, 'PBoxTreeRoot', 'Root', NULL );
    INSERT INTO PboxProp (propId,parentId,propName,propTypeName,propData)
    VALUES(2, 1, 'Name', 'LineText', 'Hello' );
    INSERT INTO PboxProp (propId,parentId,propName,propTypeName,propData)
    VALUES(3, 1, 'Address', 'URL', 'https://pbox.co' );
    INSERT INTO PboxProp (propId,parentId,propName,propTypeName,propData)
    VALUES(4, 1, 'ComputeFunction', 'Data', 'helloworld(){}' );
    INSERT INTO PboxProp (propId,parentId,propName,propTypeName,propData)
    VALUES(5, 1, 'Index', 'Id', '1' );
    INSERT INTO PboxProp (propId,parentId,propName,propTypeName,propData)
    VALUES(6, 1, 'AudioSample', 'Position1D', '(0.0)' );
    INSERT INTO PboxProp (propId,parentId,propName,propTypeName,propData)
    VALUES(7, 1, 'ScreenSample', 'Position2D', '(0.0,0.0)' );
    INSERT INTO PboxProp (propId,parentId,propName,propTypeName,propData)
    VALUES(8, 1, 'ObjectPosition', 'Position3D', '(0.0,0.0,0.0)' );
    INSERT INTO PboxProp (propId,parentId,propName,propTypeName,propData)
    VALUES(9, 1, 'ColorSample', 'Color', '(1.0,0.0,0.0,1.0)' );
    INSERT INTO PboxProp (propId,parentId,propName,propTypeName,propData)
    VALUES(10, 1, 'DirectionSample', 'Normal', '(0.0,1.0,0.0)' );

CREATE TABLE IF NOT EXISTS 'PboxTree'
  (
    'treeId' int NOT NULL,
    'parentId' int NULL,
    'depth' int NULL,
    'pathindex' int NULL,
    'numericalmapping' TEXT NULL,
    'author' TEXT NOT NULL,
    'propId' TEXT NULL,
    PRIMARY KEY(treeId)
    FOREIGN KEY('author') REFERENCES PboxNodeType ( name ),
    FOREIGN KEY('propId') REFERENCES PboxProp ( propId )
  );

INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(1,NULL,NULL,NULL,NULL,'PBoxTreeRoot', 1 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(2,1,NULL,NULL,NULL,'Shader', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(3,1,NULL,NULL,NULL,'Scene', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(4,1,NULL,NULL,NULL,'Vectors', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(5,4,NULL,NULL,NULL,'SVG', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(6,4,NULL,NULL,NULL,'Obj', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(7,1,NULL,NULL,NULL,'Textures', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(8,7,NULL,NULL,NULL,'Tiles', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(9,7,NULL,NULL,NULL,'MoCap', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(10,7,NULL,NULL,NULL,'ImgSequemces', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(11,10,NULL,NULL,NULL,'ImgSprites', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(12,10,NULL,NULL,NULL,'ImgShots', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(13,10,NULL,NULL,NULL,'ImgScene', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(14,1,NULL,NULL,NULL,'Audio', 2 );
INSERT INTO PboxTree (treeId, parentId, depth, pathindex, numericalmapping, author, propId)
VALUES(15,1,NULL,NULL,NULL,'Video', 2 );

SELECT * FROM PboxNodeType
ORDER BY name ASC;

SELECT * FROM PboxProp
ORDER BY propId ASC;

SELECT * FROM PboxTree
ORDER BY treeId ASC;

UPDATE PboxTree SET depth = 0
  WHERE parentId IS NULL;


UPDATE PboxTree
SET
    depth = 1
WHERE
    depth IS NULL
    AND
    parentId =
    (
    SELECT treeId
    WHERE treeId );

SELECT * FROM PboxTree
  WHERE depth IS NULL
  ORDER BY treeId ASC;

SELECT * FROM PboxTree AS Tree
ORDER BY Tree.treeId ASC;

*/
