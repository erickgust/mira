#!/bin/sh
card="$(dirname "$0")/thumbnail.qml"
for pid in $(qs list -p "$card" 2>/dev/null | sed -n 's/^ *Process ID: //p'); do
    qs ipc --pid "$pid" call card replace >/dev/null 2>&1
done
exec qs -p "$card"
