import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import QtWebEngine 1.4

Page {
    id: pane

    RowLayout {
        id: container
        anchors.fill: parent
        spacing: 0

        HtmlList {
            id: recipeList
            Layout.minimumWidth: 124
            Layout.preferredWidth: parent.width / 3
            Layout.maximumWidth: 300
            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: true
            KeyNavigation.tab: webView
            onRecipeSelected: webView.showRecipe(url)
        }

        WebEngineView {
            id: webView
            Layout.preferredWidth: 2 * parent.width / 3
            Layout.fillWidth: true
            Layout.fillHeight: true
            KeyNavigation.tab: recipeList
            KeyNavigation.priority: KeyNavigation.BeforeItem
            // Make sure focus is not taken by the web view, so user can continue navigating
            // recipes with the keyboard.
            settings.focusOnNavigationEnabled: false

            onContextMenuRequested: function(request) {
                request.accepted = true
            }

            property bool firstLoadComplete: false
            onLoadingChanged: {
                if (loadRequest.status === WebEngineView.LoadSucceededStatus
                    && !firstLoadComplete) {
                    // Debounce the showing of the web content, so images are more likely
                    // to have loaded completely.
                    showTimer.start()
                }
            }

            Timer {
                id: showTimer
                interval: 500
                repeat: false
                onTriggered: {
                    webView.show(true)
                    webView.firstLoadComplete = true
                    recipeList.showHelp()
                }
            }

            Rectangle {
                id: webViewPlaceholder
                anchors.fill: parent
                z: 1
                color: "white"

                BusyIndicator {
                    id: busy
                    anchors.centerIn: parent
                }
            }

            function showRecipe(url) {
                webView.url = url
            }

            function show(show) {
                if (show === true) {
                    busy.running = false
                    webViewPlaceholder.visible = false
                } else {
                    webViewPlaceholder.visible = true
                    busy.running = true
                }
            }
        }
    }

}
