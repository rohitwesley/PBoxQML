import QtQuick.Window 2.2
import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Controls.Universal 2.3

ApplicationWindow {
    id: mainwindow
    visible: true
    width: 640
    height: Screen.desktopAvailableHeight//480
    title: qsTr("PandorasBox")

    header: ToolBar {
        contentHeight: toolButton.implicitHeight

        ToolButton {
            id: toolButton
            text: stackView.depth > 1 ? "\uf104" : "\uf039"
            font.family: "fontawesome"
            font.pixelSize: Qt.application.font.pixelSize * 1.6
            onClicked: {
                if (stackView.depth > 1) {
                    stackView.pop()
                } else {
                    drawer.open()
                }
            }
        }

        Label {
            text: stackView.currentItem.title
            anchors.centerIn: parent
        }
    }

    Drawer {
        id: drawer
        width: mainwindow.width * 0.66
        height: mainwindow.height

        Column {
            anchors.fill: parent

            ItemDelegate {
                text: qsTr("Onboarding")
                width: parent.width
                onClicked: {
                    stackView.push("qrc:/qml/pages/OnboardingPage.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                text: qsTr("ListView")
                width: parent.width
                onClicked: {
                    stackView.push("qrc:/qml/pages/ListPage.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                text: qsTr("ContactPage")
                width: parent.width
                onClicked: {
                    stackView.push("qrc:/qml/pages/ContactPage.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                text: qsTr("TextEditPage")
                width: parent.width
                onClicked: {
                    stackView.push("qrc:/qml/pages/TextEditPage.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                text: qsTr("XmlPage")
                width: parent.width
                onClicked: {
                    stackView.push("qrc:/qml/pages/XmlPage.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                text: qsTr("HtmlPage")
                width: parent.width
                onClicked: {
                    stackView.push("qrc:/qml/pages/HtmlPage.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                text: qsTr("ChatPage")
                width: parent.width
                onClicked: {
                    stackView.push("qrc:/qml/pages/ChatPage.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                text: qsTr("WebSocketPage")
                width: parent.width
                onClicked: {
                    stackView.push("qrc:/qml/pages/WebSocketPage.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                text: qsTr("Browser")
                width: parent.width
                onClicked: {
                    stackView.push("qrc:/qml/pages/BrowserWindow.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                text: qsTr("GlPage")
                width: parent.width
                onClicked: {
                    stackView.push("qrc:/qml/pages/GlPage.qml")
                    drawer.close()
                }
            }
            ItemDelegate {
                text: qsTr("SvgPage")
                width: parent.width
                onClicked: {
                    stackView.push("qrc:/qml/pages/svgmodel/SvgPage.qml")
                    drawer.close()
                }
            }
        }
    }

    StackView {
        id: stackView
        initialItem: "qrc:/qml/pages/SplashPage.qml"
        anchors.fill: parent
    }

}
