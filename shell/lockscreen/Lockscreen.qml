/*
 * Quantum Shell - The desktop shell for Quantum OS following Material Design
 * Copyright (C) 2014 Michael Spencer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.4
import Material 0.1
import Material.Extras 0.1
import Papyros.Desktop 0.1
import "../components"
import "../indicators"

Item {
    id: lockscreen

    anchors.fill: parent

    opacity: shell.state == "locked" ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: 400
        }
    }

    Timer {
        id: timer
        interval: 15000
        onTriggered: lockscreen.state = "locked"
    }

    Image {
        id: wallpaper

        anchors.fill: parent

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

    MouseArea {
        anchors.fill: parent

        hoverEnabled: enabled
        enabled: shell.state == "locked"

        onPositionChanged: {
            lockscreen.state = "unlock"
            timer.restart()
        }
    }

    View {
        id: indicators

        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: Units.dp(20)
        }

        width: row.width + Units.dp(24)
        height: Units.dp(48)

        radius: Units.dp(2)
        elevation: 2

        Row {
            id: row

            anchors.centerIn: parent
            height: parent.height

            IndicatorView {
                indicator: DateTimeIndicator {}
                defaultColor: Theme.light.iconColor
                defaultTextColor: Theme.light.textColor
                visible: !indicator.userSensitive
            }

            Repeater {
                model: shell.indicators
                delegate: IndicatorView {
                    indicator: modelData
                    defaultColor: Theme.light.iconColor
                    defaultTextColor: Theme.light.textColor
                    visible: !indicator.userSensitive
                }
            }
        }
    }

    View {
        id: dialog

        anchors.centerIn: parent

        width: Units.dp(240)
        height: Units.dp(260)

        radius: Units.dp(2)
        elevation: 2

        CircleImage {
            id: image

            source: currentUser.faceIconUrl
            width: Units.dp(80)
            height: width
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: Units.dp(45)
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Qt.rgba(0,0,0,0.3)
                radius: width/2
            }
        }

        Label {
            id: label

            text: currentUser.fullName !== "" ? currentUser.fullName : currentUser.loginName
            style: "title"

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: image.bottom
                topMargin: Units.dp(20)
            }
        }

        TextField {
            id: textField
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: Units.dp(20)
            }

            floatingLabel: true
            placeholderText: "Password"

            echoMode: TextInput.Password

            onTextChanged: {
                textField.helperText = ""
                textField.hasError = false
            }

            onAccepted: SessionManager.authenticate(text)
        }
    }

    Connections {
        target: SessionManager

        onAuthenticationSucceeded: {
            textField.text = ""
            shell.state = "default"
        }
        onAuthenticationFailed: {
            textField.helperText = "Invalid password"
            textField.hasError = true
            print("FAILURE!")
        }
        onAuthenticationError: {
            textField.helperText = "Error"
            textField.hasError = true
            print("ERROR!")
        }
    }
}
