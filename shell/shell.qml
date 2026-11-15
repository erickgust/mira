pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import "logic.js" as Logic

ShellRoot {
    id: root

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR")
    readonly property string screenshotsDir: `${Logic.localPath(StandardPaths.writableLocation(StandardPaths.PicturesLocation))}/Screenshots`
    property int capturedScreens: 0
    readonly property bool captured: capturedScreens === Quickshell.screens.length
    property bool moving: false
    property string pointerScreen: Quickshell.screens[0].name
    property bool closing: false
    property bool hidden: false
    property var shot: null
    property var savedFrames: ({})
    property var frameSizes: ({})

    function framePath(screenName) {
        return `${runtimeDir}/mira-${Quickshell.processId}-${screenName}-frame.png`;
    }

    function exit() {
        closing = true;
        Quickshell.execDetached(["sh", "-c", 'rm -f "$1"/mira-"$2"-*-frame.png', "sh", runtimeDir, String(Quickshell.processId)]);
        Quickshell.execDetached(["qs", "kill", "--pid", String(Quickshell.processId)]);
    }

    function fail(message) {
        console.error("mira:", message);
        exit();
    }

    function frameSaved(screenName) {
        savedFrames[screenName] = true;
        trySave();
    }

    function take(screenName, region) {
        if (shot || closing)
            return;
        shot = { screenName: screenName, region: region, stamp: Logic.stamp(new Date()) };
        trySave();
    }

    function takeWholeScreen() {
        const size = frameSizes[pointerScreen];
        if (size)
            take(pointerScreen, { x: 0, y: 0, width: size.width, height: size.height });
    }

    function trySave() {
        if (!shot || hidden || !savedFrames[shot.screenName])
            return;
        hidden = true;
        saving.exec(["sh", Quickshell.shellPath("save.sh"), framePath(shot.screenName), screenshotsDir,
            Logic.geometry(shot.region), ...Logic.candidates(shot.stamp)]);
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

        Overlay {
            session: root
        }
    }
}
