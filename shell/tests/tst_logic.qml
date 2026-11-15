import QtQuick
import QtTest
import "../logic.js" as Logic

TestCase {
    name: "Logic"

    function rect(x, y, width, height) {
        return { x: x, y: y, width: width, height: height };
    }

    function test_real_pixels_at_scale_one_match_logical() {
        compare(Logic.toReal(rect(100, 50, 640, 360), 1, 1920, 1080), rect(100, 50, 640, 360));
    }

    function test_real_pixels_scale_up() {
        compare(Logic.toReal(rect(100, 50, 640, 360), 2, 3840, 2160), rect(200, 100, 1280, 720));
    }

    function test_fractional_scale_rounds_edges() {
        compare(Logic.toReal(rect(10, 10, 101, 33), 1.5, 2880, 1620), rect(15, 15, 152, 50));
    }

    function test_region_is_clamped_to_image() {
        compare(Logic.toReal(rect(-20, 1000, 2000, 200), 1, 1920, 1080), rect(0, 1000, 1920, 80));
    }

    function test_dragging_up_and_left_normalises_the_rect() {
        const drag = Logic.resizeDrag(Logic.startDrag({ x: 300, y: 200 }), { x: 100, y: 50 });
        compare(Logic.dragRect(drag), rect(100, 50, 200, 150));
    }

    function test_moving_keeps_size_and_stops_at_monitor_edges() {
        const monitor = { width: 1920, height: 1080 };
        const drag = Logic.resizeDrag(Logic.startDrag({ x: 100, y: 100 }), { x: 300, y: 200 });
        compare(Logic.dragRect(Logic.shiftDrag(drag, { x: 50, y: -30 }, monitor)), rect(150, 70, 200, 100));
        compare(Logic.dragRect(Logic.shiftDrag(drag, { x: -500, y: 5000 }, monitor)), rect(0, 980, 200, 100));
    }

    function test_moving_keeps_the_corner_under_the_pointer_side() {
        const drag = Logic.resizeDrag(Logic.startDrag({ x: 100, y: 100 }), { x: 300, y: 200 });
        compare(Logic.shiftDrag(drag, { x: 10, y: 10 }, { width: 1920, height: 1080 }).corner, { x: 310, y: 210 });
    }

    function test_pointer_snaps_to_whole_pixels_inside_the_monitor() {
        const monitor = { width: 1920, height: 1080 };
        compare(Logic.snap({ x: 10.4, y: 20.6 }, monitor), { x: 10, y: 21 });
        compare(Logic.snap({ x: -5, y: 2000 }, monitor), { x: 0, y: 1080 });
    }

    function test_boxes_under_four_pixels_are_too_small() {
        verify(!Logic.bigEnough(rect(0, 0, 3, 100)));
        verify(!Logic.bigEnough(rect(0, 0, 100, 3)));
        verify(!Logic.bigEnough(rect(0, 0, 0, 0)));
        verify(Logic.bigEnough(rect(0, 0, 4, 4)));
    }

    function test_readout_sits_below_right_of_the_corner() {
        compare(Logic.readoutOrigin({ x: 1280, y: 720 }, { width: 90, height: 25 }, { width: 1920, height: 1080 }), { x: 1296, y: 736 });
    }

    function test_readout_flips_near_edges_independently() {
        const monitor = { width: 1920, height: 1080 };
        compare(Logic.readoutOrigin({ x: 1900, y: 1066 }, { width: 90, height: 25 }, monitor), { x: 1794, y: 1025 });
        compare(Logic.readoutOrigin({ x: 1900, y: 500 }, { width: 90, height: 25 }, monitor), { x: 1794, y: 516 });
    }

    function test_geometry_is_magick_crop_syntax() {
        compare(Logic.geometry(rect(15, 20, 640, 360)), "640x360+15+20");
    }

    function test_stamp_pads_every_field() {
        compare(Logic.stamp(new Date(2026, 0, 5, 7, 8, 9)), "2026-01-05 07-08-09");
    }

    function test_file_names_follow_the_pattern() {
        compare(Logic.fileName("2026-11-15 10-50-00", 0), "Screenshot from 2026-11-15 10-50-00.png");
        compare(Logic.fileName("2026-11-15 10-50-00", 2), "Screenshot from 2026-11-15 10-50-00 (2).png");
    }

    function test_candidates_start_plain_then_count_up() {
        const names = Logic.candidates("2026-11-15 10-50-00");
        compare(names.length, Logic.maxNameAttempts);
        compare(names[0], "Screenshot from 2026-11-15 10-50-00.png");
        compare(names[1], "Screenshot from 2026-11-15 10-50-00 (1).png");
    }

    function test_local_path_strips_scheme_and_decodes() {
        compare(Logic.localPath("file:///home/erick/Imagens"), "/home/erick/Imagens");
        compare(Logic.localPath("file:///home/erick/Minhas%20Imagens"), "/home/erick/Minhas Imagens");
    }
}
