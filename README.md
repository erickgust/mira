# mira

A screenshot and screen-recording tool for Wayland, in the spirit of CleanShot X. It is a [Quickshell](https://github.com/outfoxxed/quickshell) config built for niri on Pond.

Press the screenshot key, draw a box and press Enter. The shot is saved, copied to the clipboard and shown as a thumbnail in Pond's sidebar. In record mode, Enter records the box instead.

## Using it

| Input | Action |
|---|---|
| Drag outside the box | Draw a new box |
| Drag a handle | Resize the box |
| Drag inside the box | Move the box |
| Hold Space while drawing | Move the box instead of resizing it |
| Enter, or double-click inside the box | Capture the box, or the whole monitor when there is no box |
| Ctrl+C | The same as Enter, outside record mode |
| R | Toggle record mode |
| Esc | Close without saving |
| Click Stop, or press the screenshot key again | End a recording |
| Click the thumbnail | Open the file |
| Drag the thumbnail out | Drop the file into another app |
| Click the trash button on the thumbnail | Move the file to the trash |

Shots are saved to `~/Pictures/Screenshots` and recordings to `~/Videos/Screencasts`, following your XDG folders.

The thumbnail card lives in pond-shell under `~/.config/quickshell/pond-shell/mira/`. Without pond-shell, mira shows its own card in the bottom-left corner.

## Layout

- `shell.qml` freezes each monitor and opens `Overlay.qml` for the selection
- `thumbnail.qml` saves and copies a shot with `save.sh`, then hands it to the card
- `record.qml` records with `wf-recorder` and checks the file with `finish.sh`
- `logic.js` holds the pure logic, and `Dismissal.qml` the card's timer

## Requirements

- A Wayland compositor with wlr layer shell and screencopy, such as niri
- Quickshell
- ImageMagick
- `wf-recorder` and `ffmpeg`, for recording
- `wl-clipboard`, `xdg-utils`
- pond-shell with the mira card, and `gio` for its trash button
- The Onest font

## Install

```sh
sh install.sh
```

Then bind it in niri:

```kdl
Print repeat=false { spawn "mira"; }
```

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

`design/mock.html` holds the visual mock.
