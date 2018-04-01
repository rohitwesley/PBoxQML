import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.3
import Qt.labs.platform 1.0

import io.qt.examples.texteditor 1.0
import SvgUnderQML 1.0
import PboxMsgUnderQML 1.0

ColumnLayout {
    id: datalistArea
    visible: true
    anchors.fill: parent
    property string debuggMessage: ""
    property int currentSvgNode: -1
    property int currentsvgTypeIndex: -1
    property int currentsvgTypeId: -1
    property string currentsvgTypeName: ""

    SvgModel {
        id: svgModel
        Component.onCompleted: svgModel.load(docArea.docUrl)
        onLoaded: {
            errorDialog.text = text
            errorDialog.visible = true
        }
        onError: {
            errorDialog.text = message
            errorDialog.visible = true
        }
        onEvaluated: {
            messageField.text = text
            svgwindow.title = currentsvgTypeName + qsTr(":") + currentsvgTypeId
        }
        onTypeName: {
            currentsvgTypeName = tag
        }
    }

    ListView {
        id: svglistArea
        signal pressAndHold(int index)

        onPressAndHold: {
            currentSvgNode = index
            svgMenu.open()
        }

        width: 320
        height: 480

        focus: true
        boundsBehavior: Flickable.StopAtBounds

        //        section.property: "svgName"
        //        section.criteria: ViewSection.FirstCharacter
        //        section.delegate: SvgSectionDelegate {
        //            width: svglistArea.width
        //        }

        delegate: SvgDelegate {
            id: delegate
            width: svglistArea.width

            Connections {
                target: delegate
                onPressAndHold: svglistArea.pressAndHold(index)
            }
        }

        model: svgModel

        ScrollBar.vertical: ScrollBar { }
    }

    Menu {
        id: svgMenu

        Label {
            padding: 10
            font.bold: true
            width: parent.width
            horizontalAlignment: Qt.AlignHCenter
            text: currentSvgNode >= 0 ? datalistArea.model.get(currentSvgNode).svgName : ""
        }

        MenuSeparator {}

        MenuItem {
            text: qsTr("Edit...")
            onTriggered: svglistDialog.editSvgNode(datalistArea.model.get(currentSvgNode))
        }
        MenuItem {
            text: qsTr("Remove")
            onTriggered: datalistArea.model.remove(currentSvgNode)
        }

    }

    Pane {
        id: docpane
        Layout.fillWidth: true

        GridLayout {
            //flow: GridLayout.TopToBottom
            rows: 4
            columns: 5

            RoundButton {
                Layout.columnSpan: 1
                id: addButton
                text: "\uf055" // fa-plus-circle
                font.family: "fontawesome"
                radius: 20
                onClicked: {
                    currentSvgNode = -1
                    svglistDialog.createSvgNode()
                }
                onHoveredChanged: {
                    if(hovered)docOutput.text ="Add List"
                    else docOutput.text = debuggMessage;
                }
            }
            RoundButton {
                Layout.columnSpan: 1
                id: queryButton
                text: "\uf0b0" // fa-filter
                font.family: "fontawesome"
                radius: 20
                onClicked: {
                    svgqueryDialog.querySvgNode(docArea.docUrl)
                }
                onHoveredChanged: {
                    if(hovered)docOutput.text ="Query List"
                    else docOutput.text = debuggMessage;
                }
            }

            Label {
                Layout.columnSpan: 5
                id: docOutput
                width: docpane.width
                text: debuggMessage
                color: "black"
                anchors.margins: 12
                wrapMode: Label.Wrap
            }

        }
    }

    SvgListDialog {
        id: svglistDialog
        onFinished: {
            if (currentSvgNode === -1)
                datalistArea.model.append(svgName,
                                     svgpath,
                                     svginking,
                                     svgfillcolor,
                                     svgtexture,
                                     svglighting,
                                     svgobjectAnimation,
                                     svgpathAnimation)
            else
                datalistArea.model.set(currentSvgNode,
                                  svgName,
                                  svgpath,
                                  svginking,
                                  svgfillcolor,
                                  svgtexture,
                                  svglighting,
                                  svgobjectAnimation,
                                  svgpathAnimation)
        }
    }

    SvgQueryDialog {
        id: svgqueryDialog
        onFinished: {
            currentsvgTypeIndex = svgTypeIndex
            currentsvgTypeId = typeId
            svgModel.getType(currentsvgTypeIndex)
            svgModel.evaluateQuery(svgTypeIndex,typeId)
        }
    }


}
