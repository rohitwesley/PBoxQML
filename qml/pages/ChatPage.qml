import QtQuick 2.9
import QtQuick.Controls 2.3

Pane {
    id: pane

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: UserPage {}
    }

}
