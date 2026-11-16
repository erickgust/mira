pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "logic.js" as Logic

ShellRoot {
    id: root

    readonly property string framePath: Quickshell.env("MIRA_FRAME")
    readonly property string regionText: Quickshell.env("MIRA_REGION")
    readonly property var region: Logic.parseRegion(regionText)
    readonly property var rect: Quickshell.env("MIRA_RECT") ? Logic.parseRegion(Quickshell.env("MIRA_RECT")) : null
    readonly property string stamp: Quickshell.env("MIRA_STAMP")
    readonly property var targetScreen: Quickshell.screens.find(screen => screen.name === Quickshell.env("MIRA_SCREEN")) ?? Quickshell.screens[0]
    readonly property string screencastsDir: `${Logic.localPath(StandardPaths.writableLocation(StandardPaths.MoviesLocation))}/Screencasts`
    readonly property string recordingPath: `${screencastsDir}/.mira-${Quickshell.processId}-recording.mp4`
    property real startedAt: 0
    property int elapsed: 0
    property bool stopping: false

    function exit() {
        Quickshell.execDetached(["qs", "kill", "--pid", String(Quickshell.processId)]);
    }

    function fail(message) {
        console.error("mira:", message);
        Quickshell.execDetached(["rm", "-f", framePath]);
        exit();
    }

    function stop() {
        if (stopping || !recorder.running)
            return;
        stopping = true;
        recorder.signal(2);
    }

    Component.onCompleted: preparing.exec(["mkdir", "-p", screencastsDir])

    Process {
        id: preparing
        onExited: code => {
            if (code !== 0)
                return root.fail(`could not create ${root.screencastsDir}`);
            root.startedAt = Date.now();
            recorder.exec(["wf-recorder", ...Logic.recorderArgs(root.targetScreen.name, root.rect, root.region, root.recordingPath)]);
        }
    }

    Process {
        id: recorder
        stderr: StdioCollector {
            id: recorderLog
        }
        onExited: code => {
            root.elapsed = Math.round((Date.now() - root.startedAt) / 1000);
            if (!root.stopping)
                console.error("mira: wf-recorder stopped by itself:", recorderLog.text.trim().split("\n").slice(-3).join(" "));
            finishing.exec(["sh", Quickshell.shellPath("finish.sh"), root.recordingPath, root.screencastsDir,
                ...Logic.candidates(root.stamp, "Screencast", "mp4")]);
        }
    }

    Process {
        id: finishing
        stdout: StdioCollector {
            id: savedOutput
        }
        stderr: StdioCollector {
            id: finishingErrors
        }
        onExited: code => {
            if (code !== 0)
                return root.fail(finishingErrors.text.trim() || `finish.sh exited with ${code}`);
            const saved = savedOutput.text.trim();
            console.log(saved);
            Quickshell.execDetached(["env",
                "MIRA_KIND=video",
                `MIRA_FILE=${saved}`,
                `MIRA_FRAME=${root.framePath}`,
                `MIRA_REGION=${root.regionText}`,
                `MIRA_SCREEN=${root.targetScreen.name}`,
                `MIRA_DURATION=${root.elapsed}`,
                "sh", Quickshell.shellPath("card.sh")]);
            root.exit();
        }
    }

    IpcHandler {
        target: "recording"

        function stop(): void {
            root.stop();
        }
    }

    Timer {
        running: recorder.running
        interval: 250
        repeat: true
        onTriggered: root.elapsed = Math.floor((Date.now() - root.startedAt) / 1000)
    }

    PanelWindow {
        id: stopWindow

        readonly property var origin: Logic.stopOrigin(root.rect, { width: button.width, height: button.height },
            { width: root.targetScreen.width, height: root.targetScreen.height })

        screen: root.targetScreen
        color: "transparent"
        implicitWidth: button.width + 20
        implicitHeight: button.height + 20
        anchors {
            left: true
            top: true
        }
        margins {
            left: origin.x - 10
            top: origin.y - 10
        }
        mask: Region {
            item: button
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "mira-stop"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        Item {
            id: button

            x: 10
            y: 10
            width: content.implicitWidth + 2 * 12 + 2
            height: 30

            RectangularShadow {
                anchors.fill: parent
                radius: 15
                offset.y: 2
                blur: 8
                color: "#33000000"
            }

            RectangularShadow {
                anchors.fill: parent
                radius: 15
                offset.y: 1
                blur: 1
                color: "#40000000"
            }

            Rectangle {
                anchors.fill: parent
                radius: 15
                color: pointer.containsMouse ? "#262626" : "#1d1d1d"
                border.width: 1
                border.color: "#cc3d3d3d"
            }

            Row {
                id: content
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    radius: 2
                    color: "#fd6164"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Logic.duration(root.elapsed)
                    color: "#f8f9f9"
                    font.family: "IBM Plex Mono"
                    font.weight: Font.Medium
                    font.pixelSize: 13
                }
            }

            MouseArea {
                id: pointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.stop()
            }
        }
    }
}
