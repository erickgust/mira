import QtQuick
import QtTest
import ".."

TestCase {
    name: "Dismissal"

    Component {
        id: dismissalComponent

        Dismissal {
            property int expired: 0
            interval: 200
            onTriggered: expired++
        }
    }

    function test_waits_until_ready() {
        const dismissal = createTemporaryObject(dismissalComponent, this);
        wait(300);
        compare(dismissal.expired, 0);
        dismissal.ready = true;
        tryCompare(dismissal, "expired", 1, 400);
    }

    function test_pauses_while_held() {
        const dismissal = createTemporaryObject(dismissalComponent, this, { ready: true });
        wait(120);
        dismissal.held = true;
        wait(300);
        compare(dismissal.expired, 0);
    }

    function test_restarts_at_the_full_interval_when_released() {
        const dismissal = createTemporaryObject(dismissalComponent, this, { ready: true });
        wait(150);
        dismissal.held = true;
        wait(50);
        dismissal.held = false;
        wait(120);
        compare(dismissal.expired, 0);
        tryCompare(dismissal, "expired", 1, 300);
    }
}
