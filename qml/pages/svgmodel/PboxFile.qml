import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.3
import Qt.labs.platform 1.0

import io.qt.examples.texteditor 1.0
ColumnLayout {
    id: docArea
    visible: true
    anchors.fill: parent
    property string docTitle: document.fileName + " - Text Editor Example"
    property string docUrl: document.fileUrl
    property string docType: "Text"
    property string imgUrl: imgArea.source
    property string debuggMessage: ""

    DocumentHandler {
        id: document
        document: textArea.textDocument
        cursorPosition: textArea.cursorPosition
        selectionStart: textArea.selectionStart
        selectionEnd: textArea.selectionEnd
        textColor: colorDialog.color
        Component.onCompleted: document.load("qrc:/html/texteditor.html")
        onLoaded: {
            textArea.text = text
        }
        onError: {
            errorDialog.text = message
            errorDialog.visible = true
        }
    }

    Flickable {
        id: flickable
        flickableDirection: Flickable.VerticalFlick
        Layout.fillWidth: true
        Layout.fillHeight: true
        anchors.fill: parent
        Layout.margins: docpane.leftPadding + docpane.leftPadding

        TextArea.flickable: TextArea {
            id: textArea
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

    Pane {
        id: paneImage
        Layout.fillWidth: true
        Layout.fillHeight: true
        anchors.fill: parent
        Layout.margins: docpane.leftPadding + docpane.leftPadding
        spacing: 12

        Image {
            id: imgArea
            width: paneImage.availableWidth / 2
            height: paneImage.availableHeight / 2
            anchors.centerIn: parent
//            anchors.verticalCenterOffset: -50
            fillMode: Image.PreserveAspectFit
            source: "qrc:/media/images/qt-logo.png"
        }

        Label {
            text: "Qt Quick Controls 2 provides a set of controls that can be used to build complete interfaces in Qt Quick."
            anchors.margins: 20
            anchors.top: imgArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            horizontalAlignment: Label.AlignHCenter
            verticalAlignment: Label.AlignVCenter
            wrapMode: Label.Wrap
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
                id: openButton
                text: "\uf0f6" // fa-file-text-o
                font.family: "fontawesome"
                radius: 20
                onClicked: openDialog.open()
                onHoveredChanged: {
                    if(hovered)docOutput.text ="Open Text File"
                    else docOutput.text = debuggMessage;
                }
            }
            RoundButton {
                Layout.columnSpan: 1
                id: openImgButton
                text: "\uf03e" // fa-image
                font.family: "fontawesome"
                radius: 20
                onClicked: openImgDialog.open()
                onHoveredChanged: {
                    if(hovered)docOutput.text ="Open Image File"
                    else docOutput.text = debuggMessage;
                }
            }
            RoundButton {
                Layout.columnSpan: 1
                id: openImgLayerButton
                text: "\uf302" // fa-images
                font.family: "fontawesome"
                radius: 20
                onClicked: openImgLayerDialog.open()
                onHoveredChanged: {
                    if(hovered)docOutput.text ="Open Image Set File"
                    else docOutput.text = debuggMessage;
                }
            }
            RoundButton {
                Layout.columnSpan: 1
                id: openSVGButton
                text: "\uf1fe" // fa-chart-area
                font.family: "fontawesome"
                radius: 20
                onClicked: openSVGDialog.open()
                onHoveredChanged: {
                    if(hovered)docOutput.text ="Open SVG File"
                    else docOutput.text = debuggMessage;
                }
            }
            RoundButton {
                Layout.columnSpan: 1
                id: openShaderButton
                text: "\uf121" // fa-code
                font.family: "fontawesome"
                radius: 20
                onClicked: openShaderDialog.open()
                onHoveredChanged: {
                    if(hovered)docOutput.text ="Open Shader File"
                    else docOutput.text = debuggMessage;
                }
            }

            RoundButton {
                Layout.columnSpan: 1
                id: saveButton
                text: "\uf0c7" // fa-save
                font.family: "fontawesome"
                radius: 20
                onClicked: saveDialog.open()
                onHoveredChanged: {
                    if(hovered)docOutput.text ="Save Text File";
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

    FileDialog {
        id: openDialog
        fileMode: FileDialog.OpenFile
        //        selectedNameFilter.index: 1
        nameFilters: ["Text files (*.txt)", "HTML files (*.html *.htm)", "Image files (*.jpg *.png)", "All files (*)"]
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            paneImage.visible = false;
            document.load(file);
            docType = "Text";
            debuggMessage = docType+":"+file;
        }
    }
    FileDialog {
        id: openImgDialog
        fileMode: FileDialog.OpenFile
        //        selectedNameFilter.index: 1
        nameFilters: ["Image files (*.jpg *.png)", "All files (*)"]
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            paneImage.visible = true;
            imgArea.source = file;
            docType = "Image";
            debuggMessage = docType+":"+file;
        }
    }
    FileDialog {
        id: openImgLayerDialog
        fileMode: FileDialog.OpenFile
        //        selectedNameFilter.index: 1
        nameFilters: ["Image Layer files (*.exr *.psd)", "All files (*)"]
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            paneImage.visible = true;
            imgArea.source = file;
            docType = "ImageSet";
            debuggMessage = docType+":"+file;
        }
    }
    FileDialog {
        id: openSVGDialog
        fileMode: FileDialog.OpenFile
        //        selectedNameFilter.index: 1
        nameFilters: ["Object files (*.svg *.obj)", "All files (*)"]
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            paneImage.visible = false;
            document.load(file);
            docType = "Object";
            debuggMessage = docType+":"+file;
        }
    }
    FileDialog {
        id: openShaderDialog
        fileMode: FileDialog.OpenFile
        //        selectedNameFilter.index: 1
        nameFilters: ["Shader files (*.fs *.glsl)", "All files (*)"]
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            paneImage.visible = false;
            document.load(file);
            docType = "Shader";
            debuggMessage = docType+":"+file;
        }
    }

    FileDialog {
        id: saveDialog
        fileMode: FileDialog.SaveFile
        //        defaultSuffix: document.fileType
        nameFilters: openDialog.nameFilters
        //        selectedNameFilter.index: document.fileType === "txt" ? 0 : 1
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            document.saveAs(file)
            debuggMessage = docType+":"+file;
        }
    }

    FontDialog {
        id: fontDialog
        onAccepted: {
            document.fontFamily = font.family;
            document.fontSize = font.pointSize;
        }
    }

    ColorDialog {
        id: colorDialog
        currentColor: "black"
    }

    MessageDialog {
        id: errorDialog
    }

}
