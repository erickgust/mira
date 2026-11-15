import QtQuick
import QtTest
import "../logic.js" as Logic

TestCase {
    name: "Logic"

    function rect(x, y, width, height) {
        return { x: x, y: y, width: width, height: height };
    }

    function test_hit_test_without_a_pointer_is_outside() {
        compare(Logic.hitTest(rect(0, 0, 100, 100), null), "outside");
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

    function test_handles_win_over_inside_and_outside() {
        const box = rect(640, 360, 640, 360);
        compare(Logic.hitTest(box, { x: 640, y: 360 }), "tl");
        compare(Logic.hitTest(box, { x: 647, y: 367 }), "tl");
        compare(Logic.hitTest(box, { x: 632, y: 352 }), "tl");
        compare(Logic.hitTest(box, { x: 1287, y: 720 }), "br");
        compare(Logic.hitTest(box, { x: 1280, y: 540 }), "r");
        compare(Logic.hitTest(box, { x: 960, y: 355 }), "t");
        compare(Logic.hitTest(box, { x: 960, y: 540 }), "inside");
        compare(Logic.hitTest(box, { x: 648, y: 368 }), "inside");
        compare(Logic.hitTest(box, { x: 631, y: 540 }), "outside");
        compare(Logic.hitTest(null, { x: 960, y: 540 }), "outside");
    }

    function test_edge_handles_hide_on_short_sides() {
        compare(Logic.handles(rect(0, 0, 47, 100)), ["tl", "tr", "br", "bl", "l", "r"]);
        compare(Logic.handles(rect(0, 0, 100, 47)), ["tl", "tr", "br", "bl", "t", "b"]);
        compare(Logic.hitTest(rect(100, 100, 40, 40), { x: 120, y: 98 }), "outside");
    }

    function test_handles_sit_on_the_border_line() {
        const box = rect(640, 360, 640, 360);
        compare(Logic.handleCentre(box, "tl"), { x: 639.5, y: 359.5 });
        compare(Logic.handleCentre(box, "r"), { x: 1280.5, y: 540 });
        compare(Logic.handleCentre(box, "b"), { x: 960, y: 720.5 });
    }

    function test_resizing_moves_only_the_dragged_sides() {
        const monitor = { width: 1920, height: 1080 };
        const box = rect(640, 360, 640, 360);
        compare(Logic.resizeRect(box, "r", { x: 120, y: 50 }, monitor), rect(640, 360, 760, 360));
        compare(Logic.resizeRect(box, "tl", { x: -40, y: -60 }, monitor), rect(600, 300, 680, 420));
        compare(Logic.resizeRect(box, "b", { x: 99, y: -10 }, monitor), rect(640, 360, 640, 350));
    }

    function test_resizing_stops_at_the_monitor_and_four_pixels_short_of_the_far_side() {
        const monitor = { width: 1920, height: 1080 };
        const box = rect(640, 360, 640, 360);
        compare(Logic.resizeRect(box, "br", { x: 5000, y: 5000 }, monitor), rect(640, 360, 1280, 720));
        compare(Logic.resizeRect(box, "tl", { x: -5000, y: -5000 }, monitor), rect(0, 0, 1280, 720));
        compare(Logic.resizeRect(box, "l", { x: 5000, y: 0 }, monitor), rect(1276, 360, 4, 360));
        compare(Logic.resizeRect(box, "t", { x: 0, y: 5000 }, monitor), rect(640, 716, 640, 4));
        compare(Logic.resizeRect(box, "br", { x: -5000, y: -5000 }, monitor), rect(640, 360, 4, 4));
    }

    function test_moving_a_box_keeps_its_size_inside_the_monitor() {
        const monitor = { width: 1920, height: 1080 };
        const box = rect(640, 360, 640, 360);
        compare(Logic.moveRect(box, { x: 10, y: -20 }, monitor), rect(650, 340, 640, 360));
        compare(Logic.moveRect(box, { x: 5000, y: -5000 }, monitor), rect(1280, 0, 640, 360));
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

    function test_loupe_sits_above_right_of_the_cursor() {
        compare(Logic.loupeOrigin({ x: 960, y: 540 }, { width: 1920, height: 1080 }, rect(1296, 736, 90, 25)), { x: 976, y: 404 });
    }

    function test_loupe_flips_on_both_axes_in_the_top_right_corner() {
        compare(Logic.loupeOrigin({ x: 1880, y: 40 }, { width: 1920, height: 1080 }, null), { x: 1744, y: 56 });
    }

    function test_loupe_flipped_below_moves_aside_from_the_readout() {
        compare(Logic.loupeOrigin({ x: 500, y: 40 }, { width: 1920, height: 1080 }, rect(516, 56, 90, 25)), { x: 364, y: 56 });
    }

    function test_loupe_moves_aside_from_a_readout_flipped_above() {
        compare(Logic.loupeOrigin({ x: 500, y: 1070 }, { width: 1920, height: 1080 }, rect(516, 1029, 90, 25)), { x: 364, y: 934 });
    }

    function test_loupe_avoids_a_resting_readout_under_it() {
        compare(Logic.loupeOrigin({ x: 960, y: 540 }, { width: 1920, height: 1080 }, rect(1000, 450, 90, 25)), { x: 824, y: 404 });
    }

    function test_loupe_shows_fifteen_real_pixels_centred_on_the_cursor() {
        compare(Logic.loupeSource({ x: 960, y: 540 }, 1, 1920, 1080), rect(953, 533, 15, 15));
        compare(Logic.loupeSource({ x: 1920, y: 0 }, 1, 1920, 1080), rect(1912, -7, 15, 15));
        compare(Logic.loupeSource({ x: 11, y: 10 }, 1.5, 2880, 1620), rect(6, 8 / 1.5, 10, 10));
        compare(Logic.loupeSource({ x: 100, y: 50 }, 2, 3840, 2160), rect(96.5, 46.5, 7.5, 7.5));
    }

    function test_geometry_is_magick_crop_syntax() {
        compare(Logic.geometry(rect(15, 20, 640, 360)), "640x360+15+20");
    }

    function test_stamp_pads_every_field() {
        compare(Logic.stamp(new Date(2026, 0, 5, 7, 8, 9)), "2026-01-05 07-08-09");
    }

    function test_duration_is_minutes_and_seconds_under_an_hour() {
        compare(Logic.duration(0), "0:00");
        compare(Logic.duration(5), "0:05");
        compare(Logic.duration(102), "1:42");
        compare(Logic.duration(3599), "59:59");
    }

    function test_duration_adds_hours_from_an_hour() {
        compare(Logic.duration(3600), "1:00:00");
        compare(Logic.duration(3725), "1:02:05");
        compare(Logic.duration(36000), "10:00:00");
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

    function test_region_survives_the_handoff() {
        const region = rect(15, 20, 640, 360);
        compare(Logic.parseRegion(Logic.regionText(region)), region);
    }

    function test_file_url_encodes_each_path_segment() {
        compare(Logic.fileUrl("/home/erick/Imagens/Screenshots/Screenshot from 2026-11-15 10-50-00 (1).png"),
            "file:///home/erick/Imagens/Screenshots/Screenshot%20from%202026-11-15%2010-50-00%20(1).png");
        compare(Logic.fileUrl("/tmp/a#b?.png"), "file:///tmp/a%23b%3F.png");
    }

    function test_local_path_strips_scheme_and_decodes() {
        compare(Logic.localPath("file:///home/erick/Imagens"), "/home/erick/Imagens");
        compare(Logic.localPath("file:///home/erick/Minhas%20Imagens"), "/home/erick/Minhas Imagens");
    }
}
