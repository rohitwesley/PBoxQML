import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3



GridLayout {
    id: grid
    property alias svgName: svgName
    property alias svgpath: svgpath
    property alias svginking: svginking
    property alias svgfillcolor: svgfillcolor
    property alias svgtexture: svgtexture
    property alias svglighting: svglighting
    property alias svgobjectAnimation: svgobjectAnimation
    property alias svgpathAnimation: svgpathAnimation
    property int minimumInputSize: 120
    property string placeholderText: qsTr("<enter>")

    rows: 4
    columns: 2

    Label {
        text: qsTr("SVG Node Name")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: svgName
        focus: true
        Layout.fillWidth: true
        Layout.minimumWidth: grid.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: grid.placeholderText
    }

    Label {
        text: qsTr("Path")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: svgpath
        Layout.fillWidth: true
        Layout.minimumWidth: grid.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: grid.placeholderText
    }

    Label {
        text: qsTr("Inking")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: svginking
        Layout.fillWidth: true
        Layout.minimumWidth: grid.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: grid.placeholderText
    }

    Label {
        text: qsTr("SVGFillColor")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: svgfillcolor
        Layout.fillWidth: true
        Layout.minimumWidth: grid.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: grid.placeholderText
    }

    Label {
        text: qsTr("Texture")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: svgtexture
        Layout.fillWidth: true
        Layout.minimumWidth: grid.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: grid.placeholderText
    }

    Label {
        text: qsTr("Lighting")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: svglighting
        Layout.fillWidth: true
        Layout.minimumWidth: grid.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: grid.placeholderText
    }

    Label {
        text: qsTr("ObjectAnimation")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: svgobjectAnimation
        Layout.fillWidth: true
        Layout.minimumWidth: grid.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: grid.placeholderText
    }

    Label {
        text: qsTr("PathAnimation")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: svgpathAnimation
        Layout.fillWidth: true
        Layout.minimumWidth: grid.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: grid.placeholderText
    }

}

