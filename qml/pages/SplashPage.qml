import QtQuick 2.9
import QtQuick.Controls 2.3

Pane {
    id: pane

    Image {
        id: logo
        width: pane.availableWidth / 2
        height: pane.availableHeight / 2
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -50
        fillMode: Image.PreserveAspectFit
        source: "qrc:/media/images/qt-logo.png"
    }

    Label {
        text: "Qt Quick Controls 2 provides a set of controls that can be used to build complete interfaces in Qt Quick."
        anchors.margins: 20
        anchors.top: logo.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        horizontalAlignment: Label.AlignHCenter
        verticalAlignment: Label.AlignVCenter
        wrapMode: Label.Wrap
    }

}
