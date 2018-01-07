import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

ItemDelegate {
    id: delegate

    checkable: true

    contentItem: ColumnLayout {
        spacing: 10

        Label {
            text: svgName
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        GridLayout {
            id: grid
            visible: false

            columns: 2
            rowSpacing: 10
            columnSpacing: 10

            Label {
                text: qsTr("Path:")
                Layout.leftMargin: 60
            }

            Label {
                text: svgpath
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Inking:")
                Layout.leftMargin: 60
            }

            Label {
                text: svginking
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("SVGFillColor:")
                Layout.leftMargin: 60
            }

            Label {
                text: svgfillcolor
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Texture:")
                Layout.leftMargin: 60
            }

            Label {
                text: svgtexture
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Lighting:")
                Layout.leftMargin: 60
            }

            Label {
                text: svglighting
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("ObjectAnimation:")
                Layout.leftMargin: 60
            }

            Label {
                text: svgobjectAnimation
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("PathAnimation:")
                Layout.leftMargin: 60
            }

            Label {
                text: svgpathAnimation
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    states: [
        State {
            name: "expanded"
            when: delegate.checked

            PropertyChanges {
                target: grid
                visible: true
            }
        }
    ]
}

