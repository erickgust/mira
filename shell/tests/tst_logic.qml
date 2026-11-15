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
