import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.3
import Qt.labs.platform 1.0

import io.qt.examples.texteditor 1.0
import SvgUnderQML 1.0
import PboxMsgUnderQML 1.0

Page {
    id: svgwindow

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 40
        opacity: 0.3
        color: "#e0e0e0"
    }

    property string inConversationWith: "PBoxTreeRoot"
    property string inCurrentNode: "PBoxTreeRoot"

    title: docArea.docTitle

    header:ToolBar {
        leftPadding: 8

        Flow {
            id: flow
            width: parent.width

            Row {
                id: viewRow
                ToolButton {
                    id: docButton
                    text: "\uf07c" // fa-folder-open
                    font.family: "fontawesome"
                    onClicked: docArea.visible = !docArea.visible
                }
                ToolButton {
                    id: listButton
                    text: "\uf0ca" // fa-list-ul
                    font.family: "fontawesome"
                    onClicked: datalistArea.visible = !datalistArea.visible
                }
                ToolButton {
                    id: sqlButton
                    text: "\uf086" // fa-comments
                    font.family: "fontawesome"
                    onClicked: treeMsgArea.visible = !treeMsgArea.visible
                }
                ToolButton {
                    id: sqlTreeButton
                    text: "\uf1c0" // fa-database
                    font.family: "fontawesome"
                    onClicked: treeArea.visible = !treeArea.visible
                }
                ToolSeparator {
                    contentItem.visible: fileRow.y === editRow.y
                }
            }

            Row {
                id: editRow
            }

        }
    }


    PboxFile {
        id: docArea
        visible: false
    }

    PboxList {
        id: datalistArea
        visible: false
    }

    PboxMsgModel {
        id: treeMsgModel
        recipient: "PBoxTreeRoot"
    }

    ColumnLayout {
        id: treeMsgArea
        visible: false
        anchors.fill: parent

        ListView {
            id: treeMsgList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: treeMsgPane.leftPadding
            displayMarginBeginning: 40
            displayMarginEnd: 40
            verticalLayoutDirection: ListView.BottomToTop
            spacing: 12
            model: treeMsgModel

            delegate: Column {
                anchors.right: sentByMe ? parent.right : undefined
                spacing: 6

                readonly property bool sentByMe: model.recipient !== "PBoxTreeRoot"

                Row {
                    id: treeMsgRow
                    spacing: 6
                    anchors.right: sentByMe ? parent.right : undefined

                    Image {
                        id: treeMsgAvatar
                        source: !sentByMe ? "qrc:/qml/images/" + model.author.replace(" ", "_") + ".png" : ""
                    }

                    Rectangle {
                        width: Math.min(treeMsgText.implicitWidth + 24, treeMsgList.width - treeMsgAvatar.width - treeMsgRow.spacing)
                        height: treeMsgText.implicitHeight + 24
                        color: sentByMe ? "lightgrey" : "steelblue"

                        Label {
                            id: treeMsgText
                            text: model.message
                            color: sentByMe ? "black" : "white"
                            anchors.fill: parent
                            anchors.margins: 12
                            wrapMode: Label.Wrap
                        }
                    }
                }

                Label {
                    id: treeMsgTimeStamp
                    text: model.author+" at "+Qt.formatDateTime(model.timestamp, "d MMM hh:mm")
                    color: "lightgrey"
                    anchors.right: sentByMe ? parent.right : undefined
                }
            }

            ScrollBar.vertical: ScrollBar {}
        }

        Pane {
            id: treeMsgPane
            Layout.fillWidth: true

            GridLayout {
                width: parent.width
                columns: 4

                Button {
                    id: treeMsgClearButton
                    text: "\uf014" // fa-trash-o
                    font.family: "fontawesome"
                    onClicked: {
                        treeMsgModel.clearMessages(inConversationWith)
                    }
                }
                ComboBox {
                    id: treeMsgType
                    model: ["PBoxTreeRoot", "Shader", "Scene", "Vectors"]
                    onActivated: {
                        inConversationWith = currentText
                        treeMsgModel.refreshMessage()
                    }
                }
                TextArea {
                    id: treeMsgField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Compose message")
                    wrapMode: TextArea.Wrap
                }
                Button {
                    id: treeMsgSendButton
                    text: qsTr("Send")
                    enabled: treeMsgField.length > 0
                    highlighted: true
                    anchors.margins: 10
                    onClicked: {
                        treeMsgModel.sendMessage(inConversationWith, treeMsgField.text);
                        treeMsgField.text = "";
                    }
                }
            }
        }
    }

    PboxTree {
        id: treeArea
        visible: false
    }


}
