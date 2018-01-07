import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.3
import Qt.labs.platform 1.0

import XmlUnderQML 1.0

Page {
    id: xmlwindow

    title: qsTr("Xml Querry")

    FileDialog {
        id: openDialog
        nameFilters: ["Xml files (*.xml)", "All files (*)"]
        folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: xmlModel.load(file)
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
            }

        }
    }

    XmlHandler {
        id: xmlModel
        Component.onCompleted: xmlModel.load("qrc:/xml/cookbook.xml")
        onLoaded: {
            xmlQuery.text = text
            xmlFileName.text = xmlModel.fileName
        }
        onEvaluated: {
            xmlQueryOutput.text = text
        }
    }

    Flickable {
        id: flickable
        flickableDirection: Flickable.VerticalFlick
        anchors.fill: parent

        GridLayout {
            id: xmlQueryArea
            visible: true
            property alias xmlFileName: xmlFileName
            property int minimumInputSize: 120
            property string placeholderText: qsTr("<enter>")
            rows: 4
            columns: 2
            Label {
                text: qsTr("XML File Name")
                Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
            }

            TextField {
                id: xmlFileName
                focus: true
                Layout.fillWidth: true
                Layout.minimumWidth: xmlQueryArea.minimumInputSize
                Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
                placeholderText: xmlQueryArea.placeholderText
            }
            Label {
                text: qsTr("XML Query")
                Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
            }

            TextField {
                id: xmlQuery
                focus: true
                Layout.fillWidth: true
                Layout.minimumWidth: xmlQueryArea.minimumInputSize
                Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
                placeholderText: xmlQueryArea.placeholderText
            }
            Label {
                text: qsTr("XML Query Output")
                Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
            }

            TextField {
                id: xmlQueryOutput
                focus: true
                Layout.fillWidth: true
                Layout.minimumWidth: xmlQueryArea.minimumInputSize
                Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
                placeholderText: xmlQueryArea.placeholderText
            }

        }

        ScrollBar.vertical: ScrollBar {}
    }

    RoundButton {
        text: "\uf04b" // fa-play
        font.family: "fontawesome"
        highlighted: true
        anchors.margins: 10
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        onClicked: {
            xmlModel.evaluateQuery(xmlQuery.text);
        }
    }

}


