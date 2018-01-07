import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

GridLayout {
    id: svgQueryArea
    property alias svgFileName: svgFileName
    property alias svgQuery: svgQuery
    property alias svgQueryOutput: svgQueryOutput
    property int minimumInputSize: 120
    property string placeholderText: qsTr("<enter>")

    rows: 4
    columns: 2

    Label {
        text: qsTr("SVG File Name")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: svgFileName
        focus: true
        Layout.fillWidth: true
        Layout.minimumWidth: svgQueryArea.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: svgQueryArea.placeholderText
    }
    Label {
        text: qsTr("SVG Query")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: svgQuery
        focus: true
        Layout.fillWidth: true
        Layout.minimumWidth: svgQueryArea.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: svgQueryArea.placeholderText
    }
    Label {
        text: qsTr("SVG Query Output")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: svgQueryOutput
        focus: true
        Layout.fillWidth: true
        Layout.minimumWidth: svgQueryArea.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: svgQueryArea.placeholderText
    }

}

