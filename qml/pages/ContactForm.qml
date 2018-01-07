import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

GridLayout {
    id: grid
    property alias fullName: fullName
    property alias address: address
    property alias city: city
    property alias number: number
    property int minimumInputSize: 120
    property string placeholderText: qsTr("<enter>")

    rows: 4
    columns: 2

    Label {
        text: qsTr("Full Name")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: fullName
        focus: true
        Layout.fillWidth: true
        Layout.minimumWidth: grid.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: grid.placeholderText
    }

    Label {
        text: qsTr("Address")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: address
        Layout.fillWidth: true
        Layout.minimumWidth: grid.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: grid.placeholderText
    }

    Label {
        text: qsTr("City")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: city
        Layout.fillWidth: true
        Layout.minimumWidth: grid.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: grid.placeholderText
    }

    Label {
        text: qsTr("Number")
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
    }

    TextField {
        id: number
        Layout.fillWidth: true
        Layout.minimumWidth: grid.minimumInputSize
        Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        placeholderText: grid.placeholderText
    }
}

