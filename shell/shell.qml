pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "logic.js" as Logic

ShellRoot {
    id: root

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR")
    property int capturedScreens: 0
    readonly property bool captured: capturedScreens === Quickshell.screens.length
    property bool moving: false
    property bool recordMode: false
    property var box: null
    property string pointerScreen: Quickshell.screens[0].name
    property bool closing: false
    property bool hidden: false
    property var shot: null
    property var savedFrames: ({})
    property var frameSizes: ({})

    function framePath(screenName) {
        return `${runtimeDir}/mira-${Quickshell.processId}-${screenName}-frame.png`;
    }

    function exit(keptFrame) {
        closing = true;
        Quickshell.execDetached(["sh", "-c", 'for frame in "$1"/mira-"$2"-*-frame.png; do [ "$frame" = "$3" ] || rm -f "$frame"; done',
            "sh", runtimeDir, String(Quickshell.processId), keptFrame ?? ""]);
        Quickshell.execDetached(["qs", "kill", "--pid", String(Quickshell.processId)]);
    }

    function fail(message) {
        console.error("mira:", message);
        exit();
    }

    function frameSaved(screenName) {
        savedFrames[screenName] = true;
        tryHandOff();
    }

    function take(screenName, region, rect) {
        if (shot || closing)
            return;
        shot = { screenName: screenName, region: region, rect: rect, record: recordMode, stamp: Logic.stamp(new Date()) };
        tryHandOff();
    }

    function confirm() {
        if (box)
            take(box.screenName, box.region, box.rect);
        else
            takeWholeScreen();
    }

    function takeWholeScreen() {
        const size = frameSizes[pointerScreen];
        if (size)
            take(pointerScreen, { x: 0, y: 0, width: size.width, height: size.height }, null);
    }

    function tryHandOff() {
        if (!shot || hidden || !savedFrames[shot.screenName])
            return;
        hidden = true;
        const frame = framePath(shot.screenName);
        if (shot.record) {
            Quickshell.execDetached(["env",
                `MIRA_FRAME=${frame}`,
                `MIRA_REGION=${Logic.regionText(shot.region)}`,
                `MIRA_RECT=${shot.rect ? Logic.regionText(shot.rect) : ""}`,
                `MIRA_SCREEN=${shot.screenName}`,
                `MIRA_STAMP=${shot.stamp}`,
                "qs", "-p", Quickshell.shellPath("record.qml")]);
            exit(frame);
            return;
        }
        Quickshell.execDetached(["env",
            `MIRA_FRAME=${frame}`,
            `MIRA_REGION=${Logic.regionText(shot.region)}`,
            `MIRA_SCREEN=${shot.screenName}`,
            `MIRA_STAMP=${shot.stamp}`,
            "sh", "-c", 'qs kill -p "$1" >/dev/null 2>&1; exec qs -p "$1"', "sh", Quickshell.shellPath("thumbnail.qml")]);
        exit(frame);
    }

    Variants {
        model: Quickshell.screens

        Overlay {
            session: root
        }
    }
}
