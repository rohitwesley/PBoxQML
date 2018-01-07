import QtQuick 2.9
import QtQuick.Controls 2.3

Pane {
    id: pane

    ScrollView {
        anchors.fill: parent

        ListView {
            width: parent.width
            model: 20
            delegate: ItemDelegate {
                text: "Item " + (index + 1)
                width: parent.width
            }
        }
    }

}
