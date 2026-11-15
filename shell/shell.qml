pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "logic.js" as Logic

ShellRoot {
    id: root

    readonly property var fixedRegion: ({ x: 0, y: 0, width: 960, height: 540 })
    readonly property string framePath: `${Quickshell.env("XDG_RUNTIME_DIR")}/mira-${Quickshell.processId}-frame.png`
    readonly property string screenshotsDir: `${Logic.localPath(StandardPaths.writableLocation(StandardPaths.PicturesLocation))}/Screenshots`

    function exit() {
        Quickshell.execDetached(["qs", "kill", "--pid", String(Quickshell.processId)]);
    }

    function fail(message) {
        console.error("mira:", message);
        Quickshell.execDetached(["rm", "-f", framePath]);
        exit();
    }

    function shoot(view, screen) {
        const size = view.sourceSize;
        const region = Logic.toReal(fixedRegion, size.width / screen.width, size.width, size.height);
        const names = Logic.candidates(Logic.stamp(new Date()));
        view.grabToImage(result => {
            if (!result.saveToFile(framePath))
                return fail(`could not write ${framePath}`);
            saving.exec(["sh", Quickshell.shellPath("save.sh"), framePath, screenshotsDir, Logic.geometry(region), ...names]);
        }, size);
    }

    Process {
        id: saving
        stdout: StdioCollector {
            id: savedPath
        }
        stderr: StdioCollector {
            id: savingErrors
        }
        onExited: code => {
            if (code !== 0)
                return root.fail(savingErrors.text.trim() || `save.sh exited with ${code}`);
            copying.exec(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", savedPath.text.trim()]);
        }
    }

    Process {
        id: copying
        stderr: StdioCollector {
            id: copyingErrors
        }
        onExited: code => {
            if (code !== 0)
                console.error("mira: wl-copy:", copyingErrors.text.trim() || `exited with ${code}`);
            console.log(savedPath.text.trim());
            root.exit();
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

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
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            Item {
                anchors.fill: parent
                opacity: 0

                ScreencopyView {
                    id: view
                    anchors.fill: parent
                    captureSource: panel.modelData
                    live: false
                    paintCursor: false
                    onHasContentChanged: if (hasContent && panel.modelData === Quickshell.screens[0])
                        root.shoot(view, panel.modelData)
                }
            }
        }
    }
}
