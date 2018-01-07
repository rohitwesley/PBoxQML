import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import QtWebSockets 1.1

Page {
    id: pane

    WebSocket {
        id: socket
        //url: "ws://qtdatabase.firebaseio.com"
        url: "ws://localhost:1234"
        onTextMessageReceived: {
            messageBox.text = messageBox.text + "\nReceived message: " + message
        }
        onStatusChanged: if (socket.status == WebSocket.Error) {
                             console.log("Error: " + socket.errorString)
                         } else if (socket.status == WebSocket.Open) {
                             socket.sendTextMessage("Hello World")
                         } else if (socket.status == WebSocket.Connecting) {
                             messageBox.text += "\nSocket Connecting......"
                         } else if (socket.status == WebSocket.Closing) {
                             messageBox.text += "\nSocket Closing......."
                         } else if (socket.status == WebSocket.Closed) {
                             messageBox.text += "\nSocket closed"
                         }
        active: false
    }

//    WebSocket {
//        id: secureWebSocket
//        url: "wss://localhost:1234"
//        onTextMessageReceived: {
//            messageBox.text = messageBox.text + "\nReceived secure message: " + message
//        }
//        onStatusChanged: if (secureWebSocket.status == WebSocket.Error) {
//                             console.log("Error: " + secureWebSocket.errorString)
//                         } else if (secureWebSocket.status == WebSocket.Open) {
//                             secureWebSocket.sendTextMessage("Hello Secure World")
//                         } else if (secureWebSocket.status == WebSocket.Connecting) {
//                             messageBox.text += "\nSecure socket Connecting......"
//                         } else if (secureWebSocket.status == WebSocket.Closing) {
//                             messageBox.text += "\nSecure socket Closing......."
//                         } else if (secureWebSocket.status == WebSocket.Closed) {
//                             messageBox.text += "\nSecure socket closed"
//                         }
//        active: false
//    }


    MouseArea {
        anchors.fill: parent
        onClicked: {
//            socket.active = !socket.active
//            secureWebSocket.active =  !secureWebSocket.active;
            //Qt.quit();
        }
    }

    ColumnLayout {
        spacing: 20
        anchors.horizontalCenter: parent.horizontalCenter

        Text {
            id: messageBox
            text: socket.status == WebSocket.Open ? qsTr("Sending...") : qsTr("Welcome!")
        }

        Switch {
            text: "Connect"
            onClicked: socket.active = !socket.active
        }
        Button {
            text: "Status"
            Layout.fillWidth: true
            onClicked: {
                if (socket.status == WebSocket.Error) {
                    console.log("Error: " + socket.errorString)
                } else if (socket.status == WebSocket.Open) {
                    socket.sendTextMessage("Hello World")
                } else if (socket.status == WebSocket.Connecting) {
                    messageBox.text = "\nSocket Connecting......"
                } else if (socket.status == WebSocket.Closing) {
                    messageBox.text = "\nSocket Closing......."
                } else if (socket.status == WebSocket.Closed) {
                    messageBox.text = "\nSocket closed"
                }
            }
        }
        Label {
            text: qsTr("Name")
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        }
        TextField {
            id: fullName
            focus: true
            Layout.fillWidth: true
        }

        Label {
            text: qsTr("Message")
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        }

        TextField {
            id: messageSend
            Layout.fillWidth: true
        }
        Button {
            text: "Send Message"
            Layout.fillWidth: true
            onClicked: {
                if (socket.status == WebSocket.Open)
                    socket.sendTextMessage(messageSend.text + fullName.text)
                else
                    messageBox.text = "Cannot Send Message : " + socket.status
            }
        }

    }

}
