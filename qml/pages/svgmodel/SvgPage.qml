import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.3
import Qt.labs.platform 1.0

import io.qt.examples.texteditor 1.0
import SvgUnderQML 1.0
import SqlUnderQML 1.0

Page {
    id: svgwindow

    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 40
        opacity: 0.3
        color: "#e0e0e0"
    }


    property int currentSvgNode: -1
    property int currentsvgTypeIndex: -1
    property int currentsvgTypeId: -1
    property string currentsvgTypeName: ""
    property string inConversationWith: "GlModel"

    title: svgdocument.fileName + qsTr(" SVG Node List")

    SvgListDialog {
        id: svglistDialog
        onFinished: {
            if (currentSvgNode === -1)
                svglistArea.model.append(svgName,
                                     svgpath,
                                     svginking,
                                     svgfillcolor,
                                     svgtexture,
                                     svglighting,
                                     svgobjectAnimation,
                                     svgpathAnimation)
            else
                svglistArea.model.set(currentSvgNode,
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

    FileDialog {
        id: openDialog
        fileMode: FileDialog.OpenFile
//        selectedNameFilter.index: 1
        nameFilters: ["SVG files (*.svg)", "All files (*)"]
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: svgdocument.load(file)
    }

    FileDialog {
        id: saveDialog
        fileMode: FileDialog.SaveFile
//        defaultSuffix: document.fileType
        nameFilters: openDialog.nameFilters
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: svgdocument.saveAs(file)
    }

    FileDialog {
        id: saveImageDialog
        fileMode: FileDialog.SaveFile
//        defaultSuffix: document.fileType
        nameFilters: ["PNG files (*.png)", "All files (*)"]
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: sqlModel.sendMessage(inConversationWith, "getImage:"+file);
    }

    ColorDialog {
        id: colorDialog
        currentColor: "black"
    }

    MessageDialog {
        id: errorDialog
    }

    Menu {
        id: svgMenu

        Label {
            padding: 10
            font.bold: true
            width: parent.width
            horizontalAlignment: Qt.AlignHCenter
            text: currentSvgNode >= 0 ? svglistArea.model.get(currentSvgNode).svgName : ""
        }

        MenuSeparator {}

        MenuItem {
            text: qsTr("Edit...")
            onTriggered: svglistDialog.editSvgNode(svglistArea.model.get(currentSvgNode))
        }
        MenuItem {
            text: qsTr("Remove")
            onTriggered: svglistArea.model.remove(currentSvgNode)
        }

    }

    header:ToolBar {
        leftPadding: 8

        Flow {
            id: flow
            width: parent.width

            Row {
                id: fileRow
                ToolButton {
                    id: openButton
                    text: "\uf07c" // fa-folder-open
                    font.family: "fontawesome"
                    onClicked: openDialog.open()
                }
                ToolButton {
                    id: saveButton
                    text: "\uf0c7" // fa-save
                    font.family: "fontawesome"
                    onClicked: saveDialog.open()
                }
                ToolSeparator {
                    contentItem.visible: fileRow.y === viewRow.y
                }
            }

            Row {
                id: viewRow
                ToolButton {
                    id: textButton
                    text: "\uf0f6" // fa-file-text-o
                    font.family: "fontawesome"
                    onClicked: {
                        svgtextArea.visible = true
                        svglistArea.visible = false
                        sqlArea.visible = false
                    }
                }
                ToolButton {
                    id: listButton
                    text: "\uf0ca" // fa-list-ul
                    font.family: "fontawesome"
                    onClicked: {
                        svgtextArea.visible = false
                        svglistArea.visible = true
                        sqlArea.visible = false
                    }
                }
                ToolButton {
                    id: sqlButton
                    text: "\uf1c0" // fa-database
                    font.family: "fontawesome"
                    onClicked: {
                        svgtextArea.visible = false
                        svglistArea.visible = false
                        sqlArea.visible = true
                    }
                }
                ToolSeparator {
                    contentItem.visible: fileRow.y === editRow.y
                }
            }

            Row {
                id: editRow
                ToolButton {
                    id: addButton
                    text: "\uf055" // fa-plus-circle
                    font.family: "fontawesome"
                    onClicked: {
                        currentSvgNode = -1
                        svglistDialog.createSvgNode()
                    }
                }
                ToolButton {
                    id: queryButton
                    text: "\uf0b0" // fa-filter
                    font.family: "fontawesome"
                    onClicked: {
                        svgqueryDialog.querySvgNode(svgdocument.fileUrl)
                    }
                }
            }

        }
    }

    DocumentHandler {
        id: svgdocument
        document: svgtextArea.textDocument
        cursorPosition: svgtextArea.cursorPosition
        selectionStart: svgtextArea.selectionStart
        selectionEnd: svgtextArea.selectionEnd
        textColor: colorDialog.color
        Component.onCompleted: svgdocument.load("qrc:/media/char_001.svg")
        onLoaded: {
            svgtextArea.text = text
            svgModel.load(svgdocument.fileUrl)
        }
        onError: {
            errorDialog.text = message
            errorDialog.visible = true
        }
    }

    SvgModel {
        id: svgModel
        Component.onCompleted: svgModel.load(svgdocument.fileUrl)
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

    SqlModel {
        id: sqlModel
        recipient: inConversationWith
    }

    Flickable {
        id: flickable
        flickableDirection: Flickable.VerticalFlick
        anchors.fill: parent

        TextArea.flickable: TextArea {
            id: svgtextArea
            visible: false
            textFormat: Qt.PlainText
            wrapMode: TextArea.Wrap
            focus: true
            selectByMouse: true
            persistentSelection: true
            // Different styles have different padding and background
            // decorations, but since this editor is almost taking up the
            // entire window, we don't need them.
            leftPadding: 6
            rightPadding: 6
            topPadding: 0
            bottomPadding: 0
            background: null

            MouseArea {
                acceptedButtons: Qt.RightButton
                anchors.fill: parent
                onClicked: contextMenu.open()
            }

            onLinkActivated: Qt.openUrlExternally(link)
        }

        ScrollBar.vertical: ScrollBar {}
    }

    ListView {
        id: svglistArea
        visible: false

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

    ColumnLayout {
        id: sqlArea
        visible: true
        anchors.fill: parent

        ListView {
            id: sqlList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: sqlpane.leftPadding + messageField.leftPadding
            displayMarginBeginning: 40
            displayMarginEnd: 40
            verticalLayoutDirection: ListView.BottomToTop
            spacing: 12
            model: sqlModel

            delegate: Column {
                anchors.right: sentByMe ? parent.right : undefined
                spacing: 6

                readonly property bool sentByMe: model.recipient !== "Me"

                Row {
                    id: messageRow
                    spacing: 6
                    anchors.right: sentByMe ? parent.right : undefined

                    Image {
                        id: avatar
                        source: !sentByMe ? "qrc:/qml/images/" + model.author.replace(" ", "_") + ".png" : ""
                    }

                    Rectangle {
                        width: Math.min(messageText.implicitWidth + 24, sqlList.width - avatar.width - messageRow.spacing)
                        height: messageText.implicitHeight + 24
                        color: sentByMe ? "lightgrey" : "steelblue"

                        Label {
                            id: messageText
                            text: model.message
                            color: sentByMe ? "black" : "white"
                            anchors.fill: parent
                            anchors.margins: 12
                            wrapMode: Label.Wrap
                        }
                    }
                }

                Label {
                    id: timestampText
                    text: model.author+" at "+Qt.formatDateTime(model.timestamp, "d MMM hh:mm")
                    color: "lightgrey"
                    anchors.right: sentByMe ? parent.right : undefined
                }
            }

            ScrollBar.vertical: ScrollBar {}
        }

        Pane {
            id: sqlpane
            Layout.fillWidth: true

            GridLayout {
                width: parent.width
                columns: 3

                ComboBox {
                    id: glMessangerType
                    model: ["GlModel", "StyleNode", "SvgNode"]
                    onActivated: {
                        inConversationWith = currentText
                        sqlModel.refreshMessage()
                    }
                }
                TextArea {
                    id: messageField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Compose message")
                    wrapMode: TextArea.Wrap
                }
                Button {
                    id: sendButton
                    text: qsTr("Send")
                    enabled: messageField.length > 0
                    highlighted: true
                    anchors.margins: 10
                    onClicked: {
                        sqlModel.sendMessage(inConversationWith, messageField.text);
                        messageField.text = "";
                    }
                }

                Button {
                    id: clearMessagesButton
                    text: "\uf014" // fa-trash-o
                    font.family: "fontawesome"
                    onClicked: {
                        sqlModel.clearMessages(inConversationWith)
                    }
                }
                Button {
                    id: editModeMessagesButton
                    text: "\uf044" // fa-edit
                    font.family: "fontawesome"
                    onClicked: {
                        sqlModel.sendMessage(inConversationWith, "editLoop");
                    }
                }
                Button {
                    id: playModeMessagesButton
                    text: "\uf144" // fa-play-circle
                    font.family: "fontawesome"
                    onClicked: {
                        sqlModel.sendMessage(inConversationWith, "playLoop");
                    }
                }
                Button {
                    id: sampleModeMessagesButton
                    text: "\uf04e" // fa-forward
                    font.family: "fontawesome"
                    onClicked: {
                        sqlModel.sendMessage(inConversationWith, "sampleLoop");
                    }
                }
                Button {
                    id: getImageMessagesButton
                    text: "\uf1c5" // fa-file-image
                    font.family: "fontawesome"
                    onClicked: {
                        //sqlModel.sendMessage(inConversationWith, "getImage");
                        saveImageDialog.open();
                    }
                }

            }
        }
    }


}
