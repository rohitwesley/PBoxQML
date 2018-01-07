import QtQuick 2.9
import QtQuick.Controls 2.3
import Backend 1.0

ListView {
    id: listView

    signal pressAndHold(int index)

    width: 320
    height: 480

    focus: true
    boundsBehavior: Flickable.StopAtBounds

    section.property: "fullName"
    section.criteria: ViewSection.FirstCharacter
    section.delegate: SectionDelegate {
        width: listView.width
    }

    delegate: ContactDelegate {
        id: delegate
        width: listView.width

        Connections {
            target: delegate
            onPressAndHold: listView.pressAndHold(index)
        }
    }

    model: ContactModel {
        id: contactModel
    }

    ScrollBar.vertical: ScrollBar { }
}
