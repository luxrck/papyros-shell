import QtQuick 2.4
import QtQuick.Layouts 1.0
import Material 0.1
import Material.Extras 0.1
import GreenIsland 1.0
import GreenIsland.Desktop 1.0
import "../components"

/*
 * The desktop consists of multiple workspaces, one of which is shown at a time. The desktop
 * can also go into exposed-mode,
 */
Item {
    id: desktop

    objectName: "desktop" // Used by the C++ wrapper to hook up the signals

    anchors.fill: parent

    property bool expanded: shell.state == "exposed"

    property real verticalOffset: height * 0.1
    property real horizontalOffset: width * 0.1

    property alias windowManager: windowManager
    property alias windowSwitcher: windowSwitcher

    function switchNext() {
        windowManager.moveFront(windowManager.orderedWindows.get(1).item)
    }

    function switchPrevious() {
        var index = windowManager.orderedWindows.count - 1

        windowManager.moveFront(windowManager.orderedWindows.get(index).item)
    }

    WindowManager {
        id: windowManager
        anchors.fill: parent

        onSelectWorkspace: {
            print("Switching to index: ", workspace.index, listView.currentIndex)

            if (workspace == listView.currentIndex) {
                print("Switching to default!")
                shell.state = "default"
            } else {
                listView.currentIndex = workspace.index
            }
        }
    }

    ListView {
        id: listView
        anchors {
            fill: parent
            leftMargin: expanded ? horizontalOffset : 0
            rightMargin: expanded ? horizontalOffset : 0
            topMargin: expanded ? verticalOffset : 0
            bottomMargin: expanded ? verticalOffset : 0

            Behavior on leftMargin {
                NumberAnimation { duration: 300 }
            }

            Behavior on rightMargin {
                NumberAnimation { duration: 300 }
            }

            Behavior on topMargin {
                NumberAnimation { duration: 300 }
            }

            Behavior on bottomMargin {
                NumberAnimation { duration: 300 }
            }
        }

        displayMarginBeginning: horizontalOffset
        displayMarginEnd: horizontalOffset

        snapMode: ListView.SnapOneItem

        orientation: Qt.Horizontal
        interactive: desktop.expanded
        highlightFollowsCurrentItem: true
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 500
        currentIndex: 0

        spacing: expanded ? horizontalOffset * 0.70 : 0

        Behavior on spacing {
            NumberAnimation { duration: 300 }
        }

        model: 1
        delegate: View {
            elevation: 5
            width: listView.width
            height: listView.height

            CrossFadeImage {
                id: wallpaper

                anchors.fill: parent

                fadeDuration: 500
                fillMode: Image.Stretch

                source: {
                    var filename = wallpaperSetting.pictureUri

                    if (filename.indexOf("xml") != -1) {
                        // We don't support GNOME's time-based wallpapers. Default to our default wallpaper
                        return Qt.resolvedUrl("../images/papyros_wallpaper.png")
                    } else {
                        return filename
                    }
                }
            }

            Workspace {
                id: workspace
                isCurrentWorkspace: ListView.currentItem == workspace

                scale: parent.width/width
                anchors.centerIn: parent
            }
        }
    }

    HotCorners {
        anchors {
            fill: parent
        }

        onTopLeftTriggered: {
            if (desktop.expanded)
                shell.state = "default"
            else
                shell.state = "exposed"
        }
    }

    View {
        id: windowSwitcher

        anchors.centerIn: parent
        elevation: 2
        radius: Units.dp(2)

        height: column.height + Units.dp(16)
        width: column.width + Units.dp(16)

        backgroundColor: Qt.rgba(0.2, 0.2, 0.2, 0.9)

        opacity: showing ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        property bool showing: shell.state == "switcher"
        property int index
        property bool enabled: windowManager.orderedWindows.count > 1

        onEnabled: {
            if (!enabled && showing)
                dismiss()
        }

        function show() {
            index = 0
            shell.state = "switcher"
        }

        function dismiss() {
            windowManager.moveFront(windowManager.orderedWindows.get(index).item)
            shell.state = "default"
        }

        function next() {
            print("Next!")
            index = (index + 1) % windowManager.orderedWindows.count
        }

        function prev() {
            print("Previ!")
            index = (index - 1) % windowManager.orderedWindows.count
        }

        ColumnLayout {
            id: column
            anchors.centerIn: parent

            spacing: Units.dp(8)
        
            Row {
                spacing: Units.dp(8)

                Repeater {
                    model: windowManager.orderedWindows
                    delegate: Rectangle {
                        height: Units.dp(100)
                        width: preview.implicitWidth

                        color: "transparent"

                        border.color: index == windowSwitcher.index ? "white" : "transparent"
                        border.width: Units.dp(2)
                        radius: Units.dp(2)

                        WindowPreview {
                            id: preview
                            anchors {
                                fill: parent
                                margins: Units.dp(8) 
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.AllButtons
                            onClicked: preview.activate()
                        }
                    }
                }
            }

            Label {
                Layout.fillWidth: true

                horizontalAlignment: Qt.AlignHCenter

                elide: Text.ElideRight

                text: windowManager.orderedWindows.get(windowSwitcher.index).window.title
                style: "subheading"
                color: Theme.dark.textColor
            }
        }
    }

    OverlayLayer {
        id: tooltipOverlayLayer
        objectName: "desktopTooltipOverlayLayer"
        z: 100
    }
}
