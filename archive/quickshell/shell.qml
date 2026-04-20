import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import "bar" as Bar
import "hub" as Hub
import "Colors.qml" as ThemeColors

ShellRoot {
    Variants {
        model: Quickshell.screens

        Scope {
            id: v
            property var modelData

            Hub.HubWindow {
                id: hub
                screen: v.modelData
                visible: false
            }

            Bar.Bar {
                id: bar
                screen: v.modelData
            }

            function toggleHub() {
                hub.visible = !hub.visible
            }

            Connections {
                target: bar
                function onRequestHubToggle() {
                    toggleHub()
                }
            }

            GlobalShortcut {
                name: "hubToggle"
                description: "Toggle hub"
                onPressed: toggleHub()
            }


        }
    }
}
