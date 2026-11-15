# mira

A personal screenshot tool for Wayland, in the spirit of CleanShot X. Built as a Quickshell config for niri on Pond.

Pressing the screenshot key freezes the screen and opens a selection overlay. Drag a box and release: the shot is saved and copied to the clipboard at once, and a thumbnail shows in the bottom-left corner for about five seconds.

## Using it

| Input | Action |
|---|---|
| Drag and release | Capture the box |
| Hold Space while dragging | Move the box instead of resizing it |
| Enter | Capture the whole monitor under the cursor |
| Esc | Close without saving |
| Click the thumbnail | Open the shot with `xdg-open` |
| Drag the thumbnail out | Drop the shot into a chat, Discord or a file manager |

A plain click, or a box under 4 pixels on either side, is ignored.

Shots are saved as PNG to `Screenshots/Screenshot from YYYY-MM-DD HH-MM-SS.png` inside your XDG pictures folder (`~/Pictures` when unset), never overwriting an existing file.

## Requirements

- A Wayland compositor with wlr layer shell and screencopy, such as niri
- Quickshell
- ImageMagick (`magick`)
- `wl-clipboard`, `xdg-utils`
- The Onest font (`ttf-onest`)

## Install

mira is being rewritten from Rust to Quickshell, and the install step arrives with the switch-over. Until then the Rust version, at commit `49c3f07`, is the installed one.

## Development

```sh
qs -n -p shell
/usr/lib/qt6/bin/qmltestrunner -platform offscreen -input shell/tests
sh shell/tests/save_test.sh
/usr/lib/qt6/bin/qmllint shell/*.qml shell/*.js shell/tests/*.qml
```

The Qt 6 tools are called by full path because the ones on `PATH` may be Qt 5's.

`design/mock.html` holds the visual mock.
