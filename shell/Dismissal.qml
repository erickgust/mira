import QtQuick

Timer {
    property bool ready: false
    property bool held: false

    interval: 5000
    running: ready && !held
}
