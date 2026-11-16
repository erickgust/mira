pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "logic.js" as Logic

ShellRoot {
    id: root

    readonly property bool video: Quickshell.env("MIRA_KIND") === "video"
    readonly property string framePath: Quickshell.env("MIRA_FRAME")
    readonly property var region: Logic.parseRegion(Quickshell.env("MIRA_REGION"))
    readonly property string stamp: Quickshell.env("MIRA_STAMP")
    readonly property var targetScreen: Quickshell.screens.find(screen => screen.name === Quickshell.env("MIRA_SCREEN")) ?? Quickshell.screens[0]
    readonly property var cardSize: ({ width: 240, height: 135 })
    readonly property string screenshotsDir: `${Logic.localPath(StandardPaths.writableLocation(StandardPaths.PicturesLocation))}/Screenshots`
    property string savedPath: video ? Quickshell.env("MIRA_FILE") : ""
    property bool hovered: false
    property bool lifting: false
    property bool dragging: false
    property var dragImage
    property bool closing: false
    property bool replaced: false

    function exit() {
        Quickshell.execDetached(["qs", "kill", "--pid", String(Quickshell.processId)]);
    }

    function fail(message) {
        console.error("mira:", message);
        Quickshell.execDetached(["rm", "-f", framePath]);
        exit();
    }

    function save() {
        saving.exec(["sh", Quickshell.shellPath("save.sh"), framePath, screenshotsDir, Logic.geometry(region), ...Logic.candidates(stamp)]);
    }

    function close() {
        if (closing)
            return;
        closing = true;
        enter.stop();
        leave.start();
    }

    function open() {
        if (!savedPath)
            return;
        Quickshell.execDetached(["xdg-open", savedPath]);
        close();
    }

    Process {
        id: saving
        stdout: StdioCollector {
            id: savedOutput
        }
        stderr: StdioCollector {
            id: savingErrors
        }
        onExited: code => {
            if (code !== 0)
                return root.fail(savingErrors.text.trim() || `save.sh exited with ${code}`);
            root.savedPath = savedOutput.text.trim();
            console.log(root.savedPath);
            if (root.replaced)
                return root.exit();
            copying.exec(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", root.savedPath]);
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
        }
    }

    IpcHandler {
        target: "card"

        function replace(): void {
            root.replaced = true;
            if (root.savedPath)
                root.exit();
        }
    }

    Dismissal {
        ready: root.savedPath !== "" && !root.closing
        held: root.hovered || root.dragging
        onTriggered: root.close()
    }

    PanelWindow {
        visible: !root.replaced
        screen: root.targetScreen
        color: "transparent"
        implicitWidth: 10 + root.cardSize.width + 40
        implicitHeight: 40 + root.cardSize.height + 10
        anchors {
            left: true
            bottom: true
        }
        mask: Region {
            item: card
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "mira-thumbnail"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Normal
        WlrLayershell.exclusiveZone: 0

        Item {
            id: card

            x: 10
            y: 40
            width: root.cardSize.width
            height: root.cardSize.height
            opacity: 0
            transform: Translate {
                id: rise
                y: 16
            }

            ParallelAnimation {
                id: enter
                running: true

                NumberAnimation {
                    target: card
                    property: "opacity"
                    to: 1
                    duration: 220
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
                }
                NumberAnimation {
                    target: rise
                    property: "y"
                    to: 0
                    duration: 220
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.2, 0, 0, 1, 1, 1]
                }
            }

            NumberAnimation {
                id: leave
                target: card
                property: "opacity"
                to: 0
                duration: 120
                easing.type: Easing.OutCubic
                onFinished: root.exit()
            }

            Item {
                anchors.fill: parent
                opacity: root.dragging ? 0 : 1

                Repeater {
                    model: [
                        { offset: 4, blur: 40, color: "#1a000000" },
                        { offset: 3, blur: 20, color: "#1f000000" },
                        { offset: 3, blur: 12, color: "#26000000" },
                        { offset: 2, blur: 8, color: "#33000000" },
                        { offset: 1, blur: 1, color: "#40000000" }
                    ]

                    RectangularShadow {
                        required property var modelData
                        anchors.fill: parent
                        radius: 12
                        offset.y: modelData.offset
                        blur: modelData.blur
                        color: modelData.color
                    }
                }

                Item {
                    id: face
                    anchors.fill: parent

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: 12
                        color: "#707070"

                        Image {
                            anchors.fill: parent
                            source: Logic.fileUrl(root.framePath)
                            sourceClipRect: Qt.rect(root.region.x, root.region.y, root.region.width, root.region.height)
                            asynchronous: false
                            cache: false
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            mipmap: true
                            Component.onCompleted: root.video ? Quickshell.execDetached(["rm", "-f", root.framePath]) : root.save()
                        }

                        Rectangle {
                            visible: root.video
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 6
                            width: durationText.implicitWidth + 12
                            height: 18
                            radius: 9
                            color: "#99000000"

                            Text {
                                id: durationText
                                anchors.centerIn: parent
                                text: Logic.duration(Number(Quickshell.env("MIRA_DURATION")))
                                color: "white"
                                font.family: "IBM Plex Mono"
                                font.weight: Font.Medium
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "black"
                            opacity: root.hovered && !root.lifting ? 0.5 : 0.1

                            Behavior on opacity {
                                enabled: !root.lifting

                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !root.lifting
                        opacity: root.hovered ? 1 : 0
                        text: "Open"
                        color: "white"
                        font.family: "Onest"
                        font.weight: Font.Medium
                        font.pixelSize: 13
                        lineHeightMode: Text.FixedHeight
                        lineHeight: 17

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: "transparent"
                        border.width: 1
                        border.color: "#24ffffff"
                    }
                }
            }

            Item {
                id: dragSource

                anchors.fill: parent
                Drag.dragType: Drag.Automatic
                Drag.supportedActions: Qt.CopyAction
                Drag.mimeData: ({ "text/uri-list": Logic.fileUrl(root.savedPath) + "\r\n" })
                Drag.onDragFinished: dropAction => {
                    if (dropAction !== Qt.IgnoreAction)
                        return root.close();
                    root.dragging = false;
                    root.lifting = false;
                }
            }

            MouseArea {
                property point pressedAt
                property bool dragStarted: false

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: root.hovered = containsMouse
                onPressed: mouse => {
                    pressedAt = Qt.point(mouse.x, mouse.y);
                    dragStarted = false;
                }
                onPositionChanged: mouse => {
                    if (!pressed || dragStarted || !root.savedPath || root.closing)
                        return;
                    if (Math.hypot(mouse.x - pressedAt.x, mouse.y - pressedAt.y) < Qt.styleHints.startDragDistance)
                        return;
                    dragStarted = true;
                    root.lifting = true;
                    const hotSpot = pressedAt;
                    face.grabToImage(result => {
                        root.dragImage = result;
                        dragSource.Drag.imageSource = result.url;
                        dragSource.Drag.hotSpot = hotSpot;
                        root.dragging = true;
                        dragSource.Drag.active = true;
                    });
                }
                onClicked: {
                    if (!dragStarted)
                        root.open();
                }
            }
        }
    }
}
