# mira

A personal screenshot tool for Wayland, in the spirit of CleanShot X. It is a [Quickshell](https://github.com/outfoxxed/quickshell) config, written in QML with a small shell script, built for niri on Pond. There is nothing to compile.

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

The thumbnail stays while the pointer is over it or a drag is in progress, then closes five seconds later. A drag offers the saved file to the other app as a copy, and sandboxed Flatpak apps receive it through the file-transfer portal without extra permissions. On niri, Qt cannot tell a drop from a cancelled drag, so the thumbnail does not close the moment a drop succeeds; it closes five seconds later. A new shot replaces any thumbnail still showing, and pressing the key while the overlay is open does nothing.

## How it works

Each press runs `qs -n -p ~/.local/share/mira`; `-n` makes a second press exit while an overlay is open.

1. `shell.qml` opens one see-through overlay per monitor, captures each monitor with Quickshell's `ScreencopyView`, and only then draws the frozen image, so the overlay never appears in the shot. `Overlay.qml` handles the selection.
2. Each frozen frame is written to `$XDG_RUNTIME_DIR` while you select. On release the overlay vanishes and hands the shot to `thumbnail.qml`, a separate Quickshell instance, then exits. Starting the thumbnail removes any older one.
3. `thumbnail.qml` shows the card straight from the frame, then runs `save.sh`, which crops with ImageMagick and claims a free file name with `ln` so nothing is ever overwritten, and copies the result with `wl-copy`.

`logic.js` holds the pure logic (pixel conversion, the selection, file names), and `Dismissal.qml` the five-second timer.

## Requirements

- A Wayland compositor with wlr layer shell and screencopy, such as niri
- Quickshell
- ImageMagick (`magick`)
- `wf-recorder` and `ffmpeg`, for recording
- `wl-clipboard`, `xdg-utils`
- The Onest font (`ttf-onest`)

## Install

From a clone:

```sh
sh install.sh
```

This copies `shell/` to `~/.local/share/mira` and writes the `~/.local/bin/mira` launcher, replacing any earlier install. Then bind it in niri:

```kdl
Print repeat=false { spawn "mira"; }
```

`repeat=false` keeps a held key from launching several overlays at once.

## Development

```sh
qs -n -p shell
/usr/lib/qt6/bin/qmltestrunner -platform offscreen -input shell/tests
sh shell/tests/save_test.sh
sh shell/tests/install_test.sh
sh shell/tests/finish_test.sh
/usr/lib/qt6/bin/qmllint shell/*.qml shell/*.js shell/tests/*.qml
```

The Qt 6 tools are called by full path because the ones on `PATH` may be Qt 5's. `qmllint` reports two known false alarms: `PanelWindow` "is not creatable" and `startDragDistance` "not found".

Only one monitor at scale 1 has been tested.

`design/mock.html` holds the visual mock.
