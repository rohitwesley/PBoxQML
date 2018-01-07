import QtQuick 2.9
import QtQuick.Controls 2.3

ToolBar {
    id: background

    Label {
        id: label
        text: section
        anchors.fill: parent
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
    }
}
