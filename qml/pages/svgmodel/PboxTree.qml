import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

import PboxTreeUnderQML 1.0

ColumnLayout {
    id: treeArea
    visible: true
    anchors.fill: parent
    property string inTableName: "PboxTree"
    property string inCurrentNode: "PBoxTreeRoot"
    property string debugTable: treeModel.rowCount()

    PboxTreeModel {
        id: treeModel
    }

    ListView {
        id: treeList
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: treepane.leftPadding + treepane.leftPadding
        displayMarginBeginning: 40
        displayMarginEnd: 40
        verticalLayoutDirection: ListView.BottomToTop
        spacing: 12
        model: treeModel
        
        delegate: Column {
            Layout.fillWidth: true
            //anchors.fill: parent//anchors.right: sentByMe ? parent.right : undefined
            spacing: 6
            
            readonly property bool sentByMe: inCurrentNode != model.treeId
            property variant currenttreeModel: model
            
            Row {
                id: treemessageRow
                spacing: 6
                anchors.right: sentByMe ? parent.right : undefined
                
                Rectangle {
                    width: 48 * model.depth
                    height: 12
                    color: "steelblue"
                    radius: 20
                }

                RoundButton {
                    id: nodeSelectButton
                    text: sentByMe ? "\uf204" : "\uf205" // fa-toggle-off : fa-toggle-on
                    font.family: "fontawesome"
                    radius: 20
                    onClicked: {
                        treeList.currentIndex = index;
                        inCurrentNode = model.treeId;
                        debugTable = "Selected "+inCurrentNode+" Node";
                    }
                }

                Rectangle {
                    width: treeidText.implicitWidth + 24
                    height: treeidText.implicitHeight + 24
                    color: sentByMe ? "lightgrey" : "steelblue"
                    radius: 20

                    Label {
                        id: treeidText
                        text: model.treeId
                        color: sentByMe ? "black" : "white"
                        anchors.fill: parent
                        anchors.margins: 12
                        wrapMode: Label.Wrap
                    }
                }

                Rectangle {
                    width: parentidText.implicitWidth + 24
                    height: parentidText.implicitHeight + 24
                    color: sentByMe ? "lightgrey" : "steelblue"
                    radius: 20
                    
                    Label {
                        id: parentidText
                        text: model.parentid
                        color: sentByMe ? "black" : "white"
                        anchors.fill: parent
                        anchors.margins: 12
                        wrapMode: Label.Wrap
                    }
                }
                
                Rectangle {
                    width: depthText.implicitWidth + 24
                    height: depthText.implicitHeight + 24
                    color: sentByMe ? "lightgrey" : "steelblue"
                    visible: showNodeMap
                    
                    Label {
                        id: depthText
                        text: model.depth
                        color: sentByMe ? "black" : "white"
                        anchors.fill: parent
                        anchors.margins: 12
                        wrapMode: Label.Wrap
                    }
                }
                
                Rectangle {
                    width: pathindexText.implicitWidth + 24
                    height: pathindexText.implicitHeight + 24
                    color: sentByMe ? "lightgrey" : "steelblue"
                    visible: showNodeMap
                    
                    Label {
                        id: pathindexText
                        text: model.pathindex
                        color: sentByMe ? "black" : "white"
                        anchors.fill: parent
                        anchors.margins: 12
                        wrapMode: Label.Wrap
                    }
                }
                
                Rectangle {
                    width: nmapText.implicitWidth + 24
                    height: nmapText.implicitHeight + 24
                    color: sentByMe ? "lightgrey" : "steelblue"
                    visible: showNodeMap
                    
                    Label {
                        id: nmapText
                        text: model.numericalmapping
                        color: sentByMe ? "black" : "white"
                        anchors.fill: parent
                        anchors.margins: 12
                        wrapMode: Label.Wrap
                    }
                }
                
                Rectangle {
                    width: propTypeNameText.implicitWidth + 24
                    height: propTypeNameText.implicitHeight + 24
                    color: sentByMe ? "lightgrey" : "steelblue"
                    radius: 10
                    
                    Label {
                        id: propTypeNameText
                        text: (model.pathindex ? model.pathindex : "NULL")+":"+model.propTypeName
                        color: sentByMe ? "black" : "white"
                        anchors.fill: parent
                        anchors.margins: 12
                        wrapMode: Label.Wrap
                    }
                }

                Rectangle {
                    width: treeList.width/7
                    height: propNameText.implicitHeight + 24
                    color: sentByMe ? "lightgrey" : "steelblue"

                    Label {
                        id: propNameText
                        text: model.propName
                        color: sentByMe ? "black" : "white"
                        anchors.fill: parent
                        anchors.margins: 12
                        wrapMode: Label.Wrap
                    }
                }

                Rectangle {
                    width: treeList.width/7
                    height: propDataText.implicitHeight + 24
                    color: sentByMe ? "lightgrey" : "steelblue"

                    Label {
                        id: propDataText
                        text: model.propData
                        color: sentByMe ? "black" : "white"
                        anchors.fill: parent
                        anchors.margins: 12
                        wrapMode: Label.Wrap
                    }
                }
                
                RoundButton {
                    id: nodeAddNodeButton
                    text: "\uf044" // fa-edit
                    font.family: "fontawesome"
                    radius: 20
                    onClicked: {
                        debugTable = "Edit Node" ;
                        dialogShader.editNode(model);
                    }
                }
                RoundButton {
                    id: nodeAddChildButton
                    text: "\uf0fe" // fa-plus-square
                    font.family: "fontawesome"
                    radius: 20
                    onClicked: {
                        debugTable = "Add Child Node" ;
                        dialogShader.createNode(model);
                    }
                }
                
            }
        }
        
        ScrollBar.vertical: ScrollBar {}
    }

    Pane {
        id: treepane
        Layout.fillWidth: true

        GridLayout {
            //flow: GridLayout.TopToBottom
            rows: 4
            columns: 5

            RoundButton {
                Layout.columnSpan: 1
                id: treeShowTableButton
                text: "\uf0db" // fa-columns
                font.family: "fontawesome"
                radius: 20
                onClicked: {
                    inTableName = "PboxTree";
                    treeModel.selectTable(inTableName,"treeId");
                    debugTable = "treeId Tree Node";
                }
            }
            RoundButton {
                Layout.columnSpan: 1
                id: treeShowParentButton
                text: "\uf1ae" // fa-child
                font.family: "fontawesome"
                radius: 20
                onClicked: {
                    treeModel.selectTable(inTableName,"parentid");
                    debugTable = "parentid Tree Node";
                }
            }
            RoundButton {
                Layout.columnSpan: 1
                id: treeShowDepthButton
                text: "\uf0cb" // fa-list-ol
                font.family: "fontawesome"
                radius: 20
                onClicked: {
                    treeModel.selectTable(inTableName,"depth");
                    debugTable = "Depth Tree Node";
                }
            }
            RoundButton {
                Layout.columnSpan: 1
                id: treeShowPathIndexButton
                text: "\uf0cb" // fa-list-ol
                font.family: "fontawesome"
                radius: 20
                onClicked: {
                    treeModel.selectTable(inTableName,"pathindex");
                    debugTable = "pathindex Tree Node";
                }
            }
            RoundButton {
                Layout.columnSpan: 1
                id: treeShowNetworkButton
                text: "\uf0e8" // fa-sitemap
                font.family: "fontawesome"
                radius: 20
                onClicked: {
                    //treeModel.selectNetworkNode("0.0");
                    treeModel.selectTable(inTableName,"numericalmapping");
                    debugTable = "numericalmapping Tree Node";
                }
            }

            RoundButton {
                Layout.columnSpan: 1
                id: treeChangeTableButton
                text: "\uf0ce" // fa-table
                font.family: "fontawesome"
                radius: 20
                onClicked: {
                    if(inTableName=="PboxTree")
                        inTableName = "PboxProp";
                    else
                        inTableName = "PboxTree";
                    treeModel.selectTable(inTableName,"numericalmapping");
                    debugTable = inTableName+" Tree Node Table Selected.";
                }
            }
            RoundButton {
                Layout.columnSpan: 1
                id: treeUpdateButton
                text: "\uf279" // fa-map
                font.family: "fontawesome"
                radius: 20
                onClicked: {
                    treeModel.updateTreeStructure();
                    debugTable = inTableName+" map Updated.";
                }
            }
            RoundButton {
                Layout.columnSpan: 1
                id: treeClearButton
                text: "\uf021" // fa-sync "\uf014" // fa-trash
                font.family: "fontawesome"
                radius: 20
                onClicked: {
                    treeModel.resetTreeStructure();
                    debugTable = inTableName+" has been reset.";
                }
            }
            RoundButton {
                Layout.columnSpan: 1
                id: treeShowMapButton
                text: "\uf279" // fa-map
                font.family: "fontawesome"
                radius: 20
                onClicked: {
                    showNodeMap = !showNodeMap;
                    if(showNodeMap)
                        debugTable = "Show Tree Map Details";
                    else
                        debugTable = "Hide Tree Map Details";
                }
            }
            RoundButton {
                id: nodePropButton
                text: "\uf126"// fa-code-branch
                font.family: "fontawesome"
                radius: 20
                onClicked: {
                    inCurrentNode = treeList.currentItem.currenttreeModel.treeId;
                    debugTable = treeList.currentItem.currenttreeModel.propData;
                    inTableName = treeModel.selectPropertyNode(inCurrentNode,debugTable);
                    debugTable = inTableName + ":" + debugTable;
                }
            }

            Label {
                Layout.columnSpan: 5
                id: treeSelected
                width: treepane.width
                text: debugTable
                color: "black"
                anchors.margins: 12
                wrapMode: Label.Wrap
            }

        }
    }

    DialogShader {
        id: dialogShader
        onFinished: {
            if (propId == -1){
                treeModel.appendNode(propId,
                                     propParentId,
                                     propTypeName,
                                     propName,
                                     propData)
            }
            else {
                treeModel.updateNode(propId,
                                     propParentId,
                                     propTypeName,
                                     propName,
                                     propData)
            }
        }

    }

}
