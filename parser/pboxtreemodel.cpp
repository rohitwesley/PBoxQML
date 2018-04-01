#include "pboxtreemodel.h"


PboxTreeModel::PboxTreeModel(QObject *parent) :
    QSqlTableModel(parent)
{
    setTableView(QStringLiteral("PboxTree"));
    //setTableView(QStringLiteral("PboxProp"));

}

QVariant PboxTreeModel::data(const QModelIndex &index, int role) const
{
    if (role < Qt::UserRole)
        return QSqlTableModel::data(index, role);

    const QSqlRecord sqlRecord = record(index.row());
    return sqlRecord.value(role - Qt::UserRole);
}

QHash<int, QByteArray> PboxTreeModel::roleNames() const
{
    QHash<int, QByteArray> names;
    names[Qt::UserRole] = "treeId";
    names[Qt::UserRole + 1] = "parentid";
    names[Qt::UserRole + 2] = "depth";
    names[Qt::UserRole + 3] = "pathindex";
    names[Qt::UserRole + 4] = "numericalmapping";
    names[Qt::UserRole + 5] = "propTypeName";
    names[Qt::UserRole + 6] = "propName";
    names[Qt::UserRole + 7] = "propData";
    return names;
}

void PboxTreeModel::resetTreeStructure()
{
    dropPboxTables();
    createPboxNodeTypeTable();
    createPboxMsgTable();
    createPboxPropTable();
    //selectTable(QStringLiteral("PboxProp"),"");
    //updateTreeStructure();
    createPboxTreeTable();
    //selectTable(QStringLiteral("PboxTree"),"");
    //updateTreeStructure();
}

/*
 * based on simple tree model created in this article :
 * https://yellowpencil.com/blog/how-to-represent-a-tree-structure-numerically-in-sql-server/
*/
void PboxTreeModel::updateTreeStructure()
{

    //Check if new nodes added to the tree
    QString filterString = QString::fromLatin1("(depth IS NULL)");
    //setFilter(filterString);
    if(rowCount()>0){

        //First, set depth to 0 for root node
        filterString = QString::fromLatin1("(parentId IS NULL)");
        //Order By TreeId
        setSort(0, Qt::AscendingOrder);
        setFilter(filterString);
        select();
        for(int i=0;i<rowCount();i++){
            QSqlRecord updateRecord = record(i);
            updateRecord.setValue("depth", 0);
            if (!updateRowInTable(i, updateRecord)) {
                qWarning() << "Failed to Update RootNode depth:" << lastError().text();
                return;
            }
            else{
                select();
            }
        }

        //Calculate depth for each node in tree by putting a loop to run through all nodes of the tree
        filterString = QString::fromLatin1("");
        //Order By ParentId
        setSort(1, Qt::AscendingOrder);
        setFilter(filterString);
        select();
        int i = 0;
        while(i<rowCount()){
            QSqlRecord updateRecord = record(i);
            int treeId = updateRecord.value(updateRecord.indexOf("treeId")).toInt();
            int parentId = updateRecord.value(updateRecord.indexOf("parentId")).toInt();
            bool childdepthNull = updateRecord.value(updateRecord.indexOf("depth")).isNull();
            bool parentNull = updateRecord.value(updateRecord.indexOf("parentId")).isNull();
            //qDebug()<<"CurrentRecord: "<<treeId<<":"<<parentId;
            int pIndex = -1;
            for(int j=0;j<rowCount();j++){
                if(record(j).value(updateRecord.indexOf("treeId")).toInt()==parentId)
                    pIndex =  j;
            }
            if(!parentNull&&pIndex!=-1) {
                QSqlRecord parentRecord = record(pIndex);
                int parentdepth = parentRecord.value(parentRecord.indexOf("depth")).toInt();
                int newdepth = 1+parentdepth;
                //qDebug()<<" ParentRecord: "
                //                   <<parentRecord.value(parentRecord.indexOf("treeId")).toInt()
                //                  <<parentId<<":"<<parentdepth;

                updateRecord.setValue("depth", newdepth);
                //qDebug()<<" UpdateRecord: "<<treeId<<":"<<newdepth;
                if (!updateRowInTable(i, updateRecord)) {
                    qWarning() << "Failed to Update Depth:" << lastError().text();
                    return;
                }
                else{
                    select();
                }
            }
            i++;
        }

        //    //Set path index and numerical mapping for root node
        //    filterString = QString::fromLatin1("(parentId IS NULL)");
        //    //Order By TreeId
        //    setSort(0, Qt::AscendingOrder);
        //    setFilter(filterString);
        //    select();
        //    for(int i=0;i<rowCount();i++){
        //        QSqlRecord updateRecord = record(i);
        //        updateRecord.setValue("pathindex", 0);
        //        updateRecord.setValue("numericalMapping", QString::fromLatin1("0.0"));
        //        if (!updateRowInTable(i, updateRecord)) {
        //            qWarning() << "Failed to Update RootNode depth:" << lastError().text();
        //            return;
        //        }
        //        else{
        //            select();
        //        }
        //    }

        //Calculate path index and set it for each node (except for the root node)
        filterString = QString::fromLatin1("");
        //Order By parentId
        setSort(1, Qt::DescendingOrder);
        setFilter(filterString);
        select();
        int prevParentId = record(0).value(record(0).indexOf("parentId")).toInt();
        int prevDepth = record(0).value(record(0).indexOf("depth")).toInt();
        int prevPath = record(0).value(record(0).indexOf("pathindex")).toInt();
        int pIndex=0;
        for(int i=0;i<rowCount();i++){
            QSqlRecord updateRecord = record(i);
            int currentDepth = updateRecord.value(updateRecord.indexOf("depth")).toInt();
            int currentParentId = updateRecord.value(updateRecord.indexOf("parentId")).toInt();
            if(currentParentId == prevParentId) {
                updateRecord.setValue("pathindex", ++pIndex);
            }
            else {
                pIndex=1;
                updateRecord.setValue("pathindex", pIndex);
            }
//            if(prevDepth == currentDepth) {
//                updateRecord.setValue("pathindex", 1+prevPath);
//            }
//            else {
//                updateRecord.setValue("pathindex", 1);
//            }
            if (!updateRowInTable(i, updateRecord)) {
                qWarning() << "Failed to Update RootNode depth:" << lastError().text();
                return;
            }
            else{
                select();
            }
            //qDebug()<<"prevpropParentId: "<<prevParentId<<"PathRecord: "<<prevPath<<":"<<prevDepth<<":"<<currentDepth;
            prevPath = updateRecord.value(updateRecord.indexOf("pathindex")).toInt();
            prevParentId = updateRecord.value(updateRecord.indexOf("parentId")).toInt();
            prevDepth = currentDepth;
        }

        //Set the numerical mapping to the path index for children nodes that have depth of 1
        filterString = QString::fromLatin1("");
        //Order By Depth
        setSort(2, Qt::AscendingOrder);
        setFilter(filterString);
        select();
        for(int i=0;i<rowCount();i++){
            QSqlRecord updateRecord = record(i);
            int depthindex = updateRecord.value(updateRecord.indexOf("depth")).toInt();
            int pathindex = updateRecord.value(updateRecord.indexOf("pathindex")).toInt();
            if(depthindex==0){
                updateRecord.setValue("numericalMapping", QString::fromLatin1("0.%1").arg(pathindex));
                if (!updateRowInTable(i, updateRecord)) {
                    qWarning() << "Failed to Update RootNode depth:" << lastError().text();
                    return;
                }
                else{
                    select();
                }
            }
            //qDebug()<<"numericalMappingRecord: "<<pathindex<<":"<<depthindex;

        }

        //Calculate numerical mapping for nodes (except for the root node)
        filterString = QString::fromLatin1("");
        //Order By Depth
        setSort(2, Qt::AscendingOrder);
        setFilter(filterString);
        select();
        for(int i=0;i<rowCount();i++){
            QSqlRecord updateRecord = record(i);
            int depthindex = updateRecord.value(updateRecord.indexOf("depth")).toInt();
            int parentId = updateRecord.value(updateRecord.indexOf("parentId")).toInt();
            int pathindex = updateRecord.value(updateRecord.indexOf("pathindex")).toInt();
            int pIndex = -1;
            if(depthindex!=0){
                for(int j=0;j<rowCount();j++){
                    if(record(j).value(updateRecord.indexOf("treeId")).toInt()==parentId)
                        pIndex =  j;
                }
                QSqlRecord parentRecord = record(pIndex);
                QString parentMap = parentRecord.value(parentRecord.indexOf("numericalMapping")).toString();
                updateRecord.setValue("numericalMapping", QString::fromLatin1("%1.%2").arg(parentMap).arg(pathindex));
                if (!updateRowInTable(i, updateRecord)) {
                    qWarning() << "Failed to Update RootNode depth:" << lastError().text();
                    return;
                }
                else{
                    select();
                }
                if(depthindex==3)qDebug()<<"numericalMappingRecord: "<<pathindex<<":"<<parentMap;
            }


        }
    }

    if(submitAll()) {
        database().commit();
        //Order By Depth
        setSort(1, Qt::DescendingOrder);
        filterString = QString::fromLatin1("");
        setFilter(filterString);
        // Ensures that the model is sorted correctly after submitting a new row.
        setEditStrategy(QSqlTableModel::OnManualSubmit);
        select();
    } else {
        database().rollback();
        qDebug() << "Database Write Error" <<
                    "The database reported an error: " <<
                    lastError().text();
    }


}

void PboxTreeModel::setTableView(const QString &tablename){

    setTable(tablename);
    setSort(0, Qt::DescendingOrder);
    // Ensures that the model is sorted correctly after submitting a new row.
    setEditStrategy(QSqlTableModel::OnManualSubmit);
    select();

    setHeaderData(0, Qt::Horizontal, QObject::tr("treeId"));
    setHeaderData(1, Qt::Horizontal, QObject::tr("parentid"));
    setHeaderData(2, Qt::Horizontal, QObject::tr("depth"));
    setHeaderData(3, Qt::Horizontal, QObject::tr("pathindex"));
    setHeaderData(4, Qt::Horizontal, QObject::tr("numericalmapping"));
    setHeaderData(5, Qt::Horizontal, QObject::tr("propTypeName"));
    setHeaderData(6, Qt::Horizontal, QObject::tr("propName"));
    setHeaderData(7, Qt::Horizontal, QObject::tr("propData"));

}

void PboxTreeModel::selectTable(const QString &tableName,const QString &orderType)
{
    setTableView(tableName);
    if(orderType=="parentid")setSort(1, Qt::DescendingOrder);
    else if(orderType=="depth")setSort(2, Qt::DescendingOrder);
    else if(orderType=="pathindex")setSort(3, Qt::DescendingOrder);
    else if(orderType=="numericalmapping")setSort(4, Qt::DescendingOrder);
    else setSort(0, Qt::DescendingOrder);
    QString filterString = QString::fromLatin1("");
    setFilter(filterString);
    select();
}

void PboxTreeModel::selectNetworkNode(const QString &nodeIndex)
{
    int treeIndex = nodeIndex.toInt();
    //First, set depth to 0 for root node
    QString filterString = QString::fromLatin1("(treeId IS %1)").arg(treeIndex);
    //Order By TreeId
    setSort(0, Qt::AscendingOrder);
    setFilter(filterString);
    select();
    int depth;QString name,nMap;
    for(int i=0;i<rowCount();i++){
        QSqlRecord updateRecord = record(i);
        depth = updateRecord.value(updateRecord.indexOf("depth")).toInt();
        name = updateRecord.value(updateRecord.indexOf("propTypeName")).toString();
        nMap = updateRecord.value(updateRecord.indexOf("numericalmapping")).toString();
    }
    //set how far down the node depth you want to go
    int subdepth = depth + 4;
    //subdepth = depth;
    filterString = QString::fromLatin1("((numericalmapping LIKE '%1' OR numericalmapping LIKE '%2')"
                                       "AND(depth >=%3 AND depth <=%4))")
            .arg(nMap).arg(nMap+".%")
            .arg(depth).arg(subdepth);
    setFilter(filterString);
    //Order By TreeId
    setSort(0, Qt::DescendingOrder);
    select();
    //qDebug()<<name<<":"<<treeIndex<<":"<<nMap<<" depth:"<<depth<<":"<<filterString;
}

QString PboxTreeModel::selectPropertyNode(const QString &currentnodeIndex,const QString &nextnodeIndex)
{
    QStringList propIndex = nextnodeIndex.split(":");
    qDebug()<<" currentnodeIndex: "<< currentnodeIndex;
    qDebug()<<" nextnodeIndex: "<< propIndex;

    QString tablename = "PboxProp";
    if(propIndex.at(0)=="SceneProp") {
        selectTable("PboxProp","numericalmapping");
        selectNetworkNode(propIndex.at(1));
    }
    if(propIndex.at(0)=="ShaderProp") {
        selectTable("PboxProp","numericalmapping");
        selectNetworkNode(propIndex.at(1));
    }
    tablename = "PboxTree";
    if(propIndex.at(0)=="Shader") {
        selectTable("PboxTree","numericalmapping");
        selectNetworkNode(propIndex.at(1));
    }
    if(propIndex.at(0)=="") {
        selectNetworkNode(currentnodeIndex);
    }
    return(tablename);

}

void PboxTreeModel::clearMessages(const QString &recipient)
{
    //    QSqlQuery query;
    //    QString queryString = QString::fromLatin1(
    //                "DELETE FROM PboxTree WHERE (recipient = '%1' AND propTypeName = '%2') OR (recipient = '%2' AND propTypeName='%1')").arg(tableName);
    //    query.exec(queryString);
    //    submitAll();
}

void PboxTreeModel::appendNode(const QString &propId,
                                  const QString &propParentId,
                                  const QString &propTypeName,
                                  const QString &propName,
                                  const QString &propData) {
    const QString timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);
    QString filterString = QString::fromLatin1("");
    setFilter(filterString);
    select();
    //we only get tota rows selected
    //TODO get totle rows in table for better seriallising
    qDebug()<<"append propId: "<<rowCount()+1<<"propParentId: "<<propParentId<<"propTypeName: "<<propTypeName<<"propName: "<<propName<<"propData: "<<propData;
    QSqlRecord newRecord = record();
    newRecord.setValue("treeId", rowCount()+1);
    newRecord.setValue("parentid", propParentId);
    //newRecord.setValue("depth", propId);
    //newRecord.setValue("pathindex", propId);
    //newRecord.setValue("numericalmapping", propId);
    newRecord.setValue("propTypeName", propTypeName);
    newRecord.setValue("propName", propName);
    newRecord.setValue("propData", propData);
    if (!insertRecord(rowCount(), newRecord)) {
        qWarning() << "Failed to send message:" << lastError().text();
        return;
    }
    else{
        if(submitAll()) {
            database().commit();
            updateTreeStructure();
        } else {
            database().rollback();
            qDebug() << "Database Write Error" <<
                        "The database reported an error: " <<
                        lastError().text();
        }

    }


}

void PboxTreeModel::updateNode(const QString &propId,
                                  const QString &propParentId,
                                  const QString &propTypeName,
                                  const QString &propName,
                                  const QString &propData) {

    qDebug()<<"update propId: "<<propId<<"propParentId: "<<propParentId<<"propTypeName: "<<propTypeName<<"propName: "<<propName<<"propData: "<<propData;
    //Check if new nodes added to the tree
    QString filterString = QString::fromLatin1("(treeId IS %1)").arg(propId);
    setFilter(filterString);
    select();
    for(int i=0;i<rowCount();i++){
        QSqlRecord updateRecord = record(i);
        //updateRecord.setValue("treeId", propId);
        //updateRecord.setValue("parentid", propParentId);
        //updateRecord.setValue("depth", propId);
        //updateRecord.setValue("pathindex", propId);
        //updateRecord.setValue("numericalmapping", propId);
        updateRecord.setValue("propTypeName", propTypeName);
        updateRecord.setValue("propName", propName);
        updateRecord.setValue("propData", propData);
        if (!updateRowInTable(i, updateRecord)) {
            qWarning() << "Failed to Update RootNode depth:" << lastError().text();
            return;
        }
        else{
            select();
        }
    }

}
