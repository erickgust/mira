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
    readonly property var monitor: ({ width: width, height: height })
    readonly property var selection: drag ? Logic.dragRect(drag) : null
    readonly property var realSelection: selection ? toReal(selection) : null

    function toReal(rect) {
        const size = view.sourceSize;
        return Logic.toReal(rect, size.width / width, size.width, size.height);
    }

    function track(mouse) {
        const at = Logic.snap({ x: mouse.x, y: mouse.y }, monitor);
        session.pointerScreen = modelData.name;
        if (drag && mouse.buttons & Qt.LeftButton)
            drag = session.moving
                ? Logic.shiftDrag(drag, { x: at.x - pointer.x, y: at.y - pointer.y }, monitor)
                : Logic.resizeDrag(drag, at);
        pointer = at;
    }

    function release() {
        if (!drag)
            return;
        const region = realSelection;
        if (!Logic.bigEnough(region)) {
            drag = null;
            return;
        }
        session.take(modelData.name, region);
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
                overlay.session.takeWholeScreen();
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
            visible: overlay.pointer !== null
            x: overlay.pointer ? overlay.pointer.x : 0
            width: 1
            height: overlay.height
            color: "#59ffffff"
        }

        Rectangle {
            visible: overlay.pointer !== null
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

        Item {
            id: readout

            readonly property var origin: overlay.drag
                ? Logic.readoutOrigin(overlay.drag.corner, { width: width, height: height }, overlay.monitor)
                : { x: 0, y: 0 }

            visible: overlay.drag !== null
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

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.CrossCursor
            onPositionChanged: mouse => overlay.track(mouse)
            onPressed: mouse => {
                overlay.track(mouse);
                overlay.drag = Logic.startDrag(overlay.pointer);
            }
            onReleased: overlay.release()
        }
    }
}
