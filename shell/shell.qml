import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root

    property int capturedScreens: 0
    readonly property bool captured: capturedScreens === Quickshell.screens.length

    function exit() {
        Quickshell.execDetached(["qs", "kill", "--pid", String(Quickshell.processId)]);
    }

    onCapturedChanged: if (captured)
        console.log("frozen", Date.now() - Quickshell.launchTime.getTime(), "ms after launch")

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData
            color: "transparent"
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "mira"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            Item {
                anchors.fill: parent
                opacity: root.captured ? 1 : 0
                focus: true
                Keys.onEscapePressed: root.exit()

                ScreencopyView {
                    anchors.fill: parent
                    captureSource: modelData
                    live: false
                    paintCursor: false
                    onHasContentChanged: if (hasContent)
                        root.capturedScreens++
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#80101010"
                }
            }
        }
    }
}
