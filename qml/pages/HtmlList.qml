import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Controls.Universal 2.3
import QtQuick.Layouts 1.3

FocusScope {
    id: root
    signal recipeSelected(url url)

    ColumnLayout {
        spacing: 0
        anchors.fill: parent

        ToolBar {
            id: headerBackground
            Layout.fillWidth: true
            implicitHeight: headerText.height + 20

            Label {
                id: headerText
                width: parent.width
                text: qsTr("Favorite recipes")
                padding: 10
                anchors.centerIn: parent
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            keyNavigationWraps: true
            clip: true
            focus: true
            ScrollBar.vertical: ScrollBar { }

            model: recipeModel

            delegate: ItemDelegate {
                width: parent.width
                text: model.name
                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: parent.enabled ? parent.Material.primaryTextColor
                                          : parent.Material.hintTextColor
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                }

                property url url: model.url
                highlighted: ListView.isCurrentItem

                onClicked: {
                    listView.forceActiveFocus()
                    listView.currentIndex = model.index
                }
            }

            onCurrentItemChanged: {
                root.recipeSelected(currentItem.url)
            }

            ListModel {
                id: recipeModel

                ListElement {
                    name: "Pizza Diavola"
                    url: "qrc:///html/pizza.html"
                }
                ListElement {
                    name: "Steak"
                    url: "qrc:///html/steak.html"
                }
                ListElement {
                    name: "Burger"
                    url: "qrc:///html/burger.html"
                }
                ListElement {
                    name: "Soup"
                    url: "qrc:///html/soup.html"
                }
                ListElement {
                    name: "Pasta"
                    url: "qrc:///html/pasta.html"
                }
                ListElement {
                    name: "Grilled Skewers"
                    url: "qrc:///html/skewers.html"
                }
                ListElement {
                    name: "Cupcakes"
                    url: "qrc:///html/cupcakes.html"
                }
            }

            ToolTip {
                id: help
                implicitWidth: root.width - padding * 3
                y: root.y + root.height
                delay: 1000
                timeout: 5000
                text: qsTr("Use keyboard, mouse, or touch controls to navigate through the\
                            recipes.")

                contentItem: Text {
                    text: help.text
                    font: help.font
                    color: help.Material.primaryTextColor
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    function showHelp() {
        help.open()
    }
}


