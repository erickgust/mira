pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "logic.js" as Logic

PanelWindow {
    id: overlay

    required property ShellScreen modelData
    required property var session

    property Region passThrough: Region {}
    property var pointer: null
    property var drag: null
    property var gesture: null
    readonly property bool crosshair: pointer !== null && (gesture !== null || selection === null)
    readonly property var monitor: ({ width: width, height: height })
    readonly property var owned: session.box && session.box.screenName === modelData.name ? session.box : null
    readonly property var selection: owned ? owned.rect : null
    readonly property var realSelection: owned ? owned.region : null
    readonly property string hover: gesture ? gesture.handle : Logic.hitTest(selection, pointer)

    function toReal(rect) {
        const size = view.sourceSize;
        return Logic.toReal(rect, size.width / width, size.width, size.height);
    }

    function setBox(rect) {
        session.box = { screenName: modelData.name, rect: rect, region: toReal(rect) };
    }

    function track(mouse) {
        const at = Logic.snap({ x: mouse.x, y: mouse.y }, monitor);
        session.pointerScreen = modelData.name;
        if (gesture && mouse.buttons & Qt.LeftButton)
            follow(at);
        pointer = at;
    }

    function follow(at) {
        const by = { x: at.x - gesture.at.x, y: at.y - gesture.at.y };
        if (gesture.handle === "inside")
            return setBox(Logic.moveRect(gesture.from, by, monitor));
        if (gesture.handle !== "outside")
            return setBox(Logic.resizeRect(gesture.from, gesture.handle, by, monitor));
        drag = session.moving
            ? Logic.shiftDrag(drag, { x: at.x - pointer.x, y: at.y - pointer.y }, monitor)
            : Logic.resizeDrag(drag, at);
        const drawn = Logic.dragRect(drag);
        if (Logic.bigEnough(toReal(drawn)))
            setBox(drawn);
    }

    function press(mouse) {
        track(mouse);
        gesture = { handle: hover, from: selection, at: pointer };
        drag = Logic.startDrag(pointer);
    }

    screen: modelData
    mask: session.hidden ? passThrough : null
    color: "transparent"
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "mira"
    WlrLayershell.keyboardFocus: session.hidden ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    Item {
        anchors.fill: parent
        opacity: overlay.session.captured && !overlay.session.hidden ? 1 : 0
        focus: true

        Keys.onPressed: event => {
            if (event.isAutoRepeat)
                return;
            if (event.key === Qt.Key_Escape)
                overlay.session.exit();
            else if (event.key === Qt.Key_Space)
                overlay.session.moving = true;
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                overlay.session.confirm();
        }
        Keys.onReleased: event => {
            if (!event.isAutoRepeat && event.key === Qt.Key_Space)
                overlay.session.moving = false;
        }

        ScreencopyView {
            id: view
            anchors.fill: parent
            captureSource: overlay.modelData
            live: false
            paintCursor: false
            onHasContentChanged: {
                if (!hasContent)
                    return;
                const name = overlay.modelData.name;
                overlay.session.frameSizes[name] = sourceSize;
                overlay.session.capturedScreens++;
                view.grabToImage(result => {
                    if (overlay.session.closing)
                        return;
                    if (!result.saveToFile(overlay.session.framePath(name)))
                        return overlay.session.fail(`could not write ${overlay.session.framePath(name)}`);
                    overlay.session.frameSaved(name);
                }, sourceSize);
            }
        }

        Repeater {
            model: {
                const r = overlay.selection;
                const w = overlay.width;
                const h = overlay.height;
                if (!r)
                    return [{ x: 0, y: 0, width: w, height: h }];
                return [
                    { x: 0, y: 0, width: w, height: r.y },
                    { x: 0, y: r.y + r.height, width: w, height: h - r.y - r.height },
                    { x: 0, y: r.y, width: r.x, height: r.height },
                    { x: r.x + r.width, y: r.y, width: w - r.x - r.width, height: r.height }
                ];
            }

            Rectangle {
                required property var modelData
                x: modelData.x
                y: modelData.y
                width: modelData.width
                height: modelData.height
                color: "#80101010"
            }
        }

        Rectangle {
            visible: overlay.crosshair
            x: overlay.pointer ? overlay.pointer.x : 0
            width: 1
            height: overlay.height
            color: "#59ffffff"
        }

        Rectangle {
            visible: overlay.crosshair
            y: overlay.pointer ? overlay.pointer.y : 0
            width: overlay.width
            height: 1
            color: "#59ffffff"
        }

        Rectangle {
            visible: overlay.selection !== null
            x: overlay.selection ? overlay.selection.x - 2 : 0
            y: overlay.selection ? overlay.selection.y - 2 : 0
            width: overlay.selection ? overlay.selection.width + 4 : 0
            height: overlay.selection ? overlay.selection.height + 4 : 0
            color: "transparent"
            border.width: 1
            border.color: "#40000000"
        }

        Rectangle {
            visible: overlay.selection !== null
            x: overlay.selection ? overlay.selection.x - 1 : 0
            y: overlay.selection ? overlay.selection.y - 1 : 0
            width: overlay.selection ? overlay.selection.width + 2 : 0
            height: overlay.selection ? overlay.selection.height + 2 : 0
            color: "transparent"
            border.width: 1
            border.color: "#ffffff"
        }

        Repeater {
            model: overlay.selection ? Logic.handles(overlay.selection) : []

            Item {
                required property string modelData
                readonly property var centre: Logic.handleCentre(overlay.selection, modelData)

                x: centre.x - width / 2
                y: centre.y - height / 2
                width: 8
                height: 8

                RectangularShadow {
                    anchors.fill: parent
                    radius: 4
                    offset.y: 1
                    blur: 2
                    color: "#40000000"
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    radius: 5
                    color: "#40000000"
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: "#ffffff"
                }
            }
        }

        Item {
            id: readout

            readonly property var sel: overlay.selection
            readonly property var origin: sel
                ? Logic.readoutOrigin(overlay.gesture ? overlay.pointer : { x: sel.x + sel.width, y: sel.y + sel.height },
                    { width: width, height: height }, overlay.monitor)
                : { x: 0, y: 0 }

            visible: sel !== null
            x: origin.x
            y: origin.y
            width: label.implicitWidth + 2 * 10 + 2
            height: 25

            RectangularShadow {
                anchors.fill: parent
                radius: 13
                offset.y: 2
                blur: 8
                color: "#33000000"
            }

            RectangularShadow {
                anchors.fill: parent
                radius: 13
                offset.y: 1
                blur: 1
                color: "#40000000"
            }

            Rectangle {
                anchors.fill: parent
                radius: 13
                color: "#1d1d1d"
                border.width: 1
                border.color: "#cc3d3d3d"
            }

            Row {
                id: label
                anchors.centerIn: parent

                ReadoutText {
                    text: overlay.realSelection ? overlay.realSelection.width : ""
                }
                ReadoutText {
                    text: " × "
                    color: "#99f8f9f9"
                }
                ReadoutText {
                    text: overlay.realSelection ? overlay.realSelection.height : ""
                }
            }
        }

        Item {
            readonly property var origin: overlay.pointer
                ? Logic.loupeOrigin(overlay.pointer, overlay.monitor,
                    readout.visible ? { x: readout.x, y: readout.y, width: readout.width, height: readout.height } : null)
                : { x: 0, y: 0 }

            visible: overlay.pointer !== null && overlay.session.pointerScreen === overlay.modelData.name
            x: origin.x
            y: origin.y
            width: 120
            height: 120

            RectangularShadow {
                anchors.fill: parent
                radius: 12
                offset.y: 2
                blur: 8
                color: "#33000000"
            }

            RectangularShadow {
                anchors.fill: parent
                radius: 12
                offset.y: 1
                blur: 1
                color: "#40000000"
            }

            Item {
                id: zoom
                anchors.fill: parent
                visible: false
                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                }

                ShaderEffectSource {
                    readonly property real pixelRatio: view.sourceSize.width / overlay.width || 1
                    readonly property var region: overlay.pointer
                        ? Logic.loupeSource(overlay.pointer, pixelRatio, view.sourceSize.width, view.sourceSize.height)
                        : { x: 0, y: 0, width: 1, height: 1 }

                    anchors.fill: parent
                    sourceItem: view
                    sourceRect: Qt.rect(region.x, region.y, region.width, region.height)
                    textureSize: Qt.size(15, 15)
                    smooth: false
                }

                Repeater {
                    model: 15

                    Rectangle {
                        required property int index
                        x: index * 8
                        width: 1
                        height: 120
                        color: "#1f000000"
                    }
                }

                Repeater {
                    model: 15

                    Rectangle {
                        required property int index
                        y: index * 8
                        width: 120
                        height: 1
                        color: "#1f000000"
                    }
                }

                Rectangle {
                    x: 54
                    y: 54
                    width: 12
                    height: 12
                    color: "transparent"
                    border.width: 1
                    border.color: "#66000000"
                }

                Rectangle {
                    x: 55
                    y: 55
                    width: 10
                    height: 10
                    color: "transparent"
                    border.width: 1
                    border.color: "#ffffff"
                }
            }

            Rectangle {
                id: loupeMask
                anchors.fill: parent
                radius: 12
                visible: false
                layer.enabled: true
            }

            MultiEffect {
                anchors.fill: parent
                source: zoom
                maskEnabled: true
                maskSource: loupeMask
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "transparent"
                border.width: 1
                border.color: "#cc3d3d3d"
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: ({
                    outside: Qt.CrossCursor,
                    inside: Qt.SizeAllCursor,
                    tl: Qt.SizeFDiagCursor,
                    br: Qt.SizeFDiagCursor,
                    tr: Qt.SizeBDiagCursor,
                    bl: Qt.SizeBDiagCursor,
                    l: Qt.SizeHorCursor,
                    r: Qt.SizeHorCursor,
                    t: Qt.SizeVerCursor,
                    b: Qt.SizeVerCursor
                })[overlay.hover]
            onPositionChanged: mouse => overlay.track(mouse)
            onPressed: mouse => overlay.press(mouse)
            onReleased: {
                overlay.gesture = null;
                overlay.drag = null;
            }
            onDoubleClicked: {
                if (overlay.hover === "inside")
                    overlay.session.confirm();
            }
        }
    }
}
