# mira

A personal screenshot and screen-recording tool for Wayland, in the spirit of CleanShot X. It is a [Quickshell](https://github.com/outfoxxed/quickshell) config, written in QML with a few small shell scripts, built for niri on Pond. There is nothing to compile.

Pressing the screenshot key freezes the screen and opens a selection overlay. Draw a box, adjust it, and press Enter: the shot is saved and copied to the clipboard at once, and a thumbnail shows at the bottom of Pond's sidebar for about five seconds. In record mode, Enter starts a screen recording of the box instead.

## Using it

| Input | Action |
|---|---|
| Drag outside the box | Draw a new box |
| Drag a handle | Resize the box |
| Drag inside the box | Move the box |
| Hold Space while drawing | Move the box instead of resizing it |
| Enter, or double-click inside the box | Capture the box, or the whole monitor under the cursor when there is no box |
| Ctrl+C | The same as Enter, outside record mode |
| R | Toggle record mode |
| Esc | Close without saving |
| Click Stop, or press the screenshot key again | End a recording |
| Click the thumbnail | Open the shot with `xdg-open` |
| Drag the thumbnail out | Drop the shot into a chat, Discord or a file manager |
| Click the trash button on the thumbnail | Move the shot to the trash with `gio trash` |

A plain click, or a box under 4 pixels on either side, is ignored.

Shots are saved as PNG to `Screenshots/Screenshot from YYYY-MM-DD HH-MM-SS.png` inside your XDG pictures folder (`~/Pictures` when unset), never overwriting an existing file. Recordings are saved as MP4 to `Screencasts/Screencast from YYYY-MM-DD HH-MM-SS.mp4` inside your XDG videos folder (`~/Videos` when unset), and are not copied to the clipboard. While recording, a Stop button with the elapsed time sits below the box, above it when there is no room below, or in the top-right corner for a whole-monitor recording or when neither fits.

The thumbnail stays while the pointer is over it or a drag is in progress, then closes five seconds later. A drag offers the saved file to the other app as a copy, and sandboxed Flatpak apps receive it through the file-transfer portal without extra permissions. On niri, Qt cannot tell a drop from a cancelled drag, so the thumbnail does not close the moment a drop succeeds; it closes five seconds later. A new shot replaces any thumbnail still showing, and pressing the key while the overlay is open does nothing.

The sidebar card lives in pond-shell, not in this repo: `~/.config/quickshell/pond-shell/mira/` holds it, and `Sidebar.qml` places it above pond's own screenshot preview. When pond-shell is not running or has no `mira` IPC target, mira shows its own card in the bottom-left corner instead, without the trash button.

## How it works

Each press runs the `~/.local/bin/mira` launcher. It first asks a running recording to stop; when none is running, it starts `qs -n -p ~/.local/share/mira`, where `-n` makes a second press exit while an overlay is open.

1. `shell.qml` opens one see-through overlay per monitor, captures each monitor with Quickshell's `ScreencopyView`, and only then draws the frozen image, so the overlay never appears in the shot. `Overlay.qml` handles the selection.
2. Each frozen frame is written to `$XDG_RUNTIME_DIR` while you select. On confirm the overlay vanishes and hands the shot to `thumbnail.qml`, a separate Quickshell instance, then exits. Starting the thumbnail hides any older one, which exits once its shot is saved, without copying it over the new one.
3. `thumbnail.qml` runs `save.sh`, which crops with ImageMagick and claims a free file name with `ln` so nothing is ever overwritten, and copies the result with `wl-copy`. It then hands the saved file to pond-shell with `qs -c pond-shell ipc call mira screenshot` and exits, or shows its own card when that call fails.

In record mode the overlay hands the box to `record.qml` instead, which runs `wf-recorder` until it is stopped, checks the file with `finish.sh`, and then shows the card. For a recording, pond-shell gets the frame and the box too, to show the first frame, and deletes the frame when the card goes away.

`logic.js` holds the pure logic (pixel conversion, the selection, file names), and `Dismissal.qml` the five-second timer.

## Requirements

- A Wayland compositor with wlr layer shell and screencopy, such as niri
- Quickshell
- ImageMagick (`magick`)
- `wf-recorder` and `ffmpeg`, for recording
- `wl-clipboard`, `xdg-utils`
- pond-shell with the mira card, and `gio` (glib2) for its trash button; without them the card shows in the corner
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
sh shell/tests/card_test.sh
/usr/lib/qt6/bin/qmllint shell/*.qml shell/*.js shell/tests/*.qml
```

The Qt 6 tools are called by full path because the ones on `PATH` may be Qt 5's. `qmllint` reports two known false alarms: `PanelWindow` "is not creatable" and `startDragDistance` "not found".

Only one monitor at scale 1 has been tested.

`design/mock.html` holds the visual mock.
