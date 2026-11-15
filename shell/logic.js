.pragma library

const maxNameAttempts = 100;
const minSide = 4;
const readoutOffset = 16;
const readoutEdgeMargin = 8;

function snap(position, bounds) {
    return {
        x: Math.min(Math.max(Math.round(position.x), 0), bounds.width),
        y: Math.min(Math.max(Math.round(position.y), 0), bounds.height)
    };
}

function startDrag(at) {
    return { anchor: at, corner: at };
}

function resizeDrag(drag, to) {
    return { anchor: drag.anchor, corner: to };
}

function shiftDrag(drag, by, bounds) {
    const rect = dragRect(drag);
    const dx = Math.min(Math.max(by.x, -rect.x), bounds.width - rect.x - rect.width);
    const dy = Math.min(Math.max(by.y, -rect.y), bounds.height - rect.y - rect.height);
    const move = point => ({ x: point.x + dx, y: point.y + dy });
    return { anchor: move(drag.anchor), corner: move(drag.corner) };
}

function dragRect(drag) {
    return {
        x: Math.min(drag.anchor.x, drag.corner.x),
        y: Math.min(drag.anchor.y, drag.corner.y),
        width: Math.abs(drag.anchor.x - drag.corner.x),
        height: Math.abs(drag.anchor.y - drag.corner.y)
    };
}

function bigEnough(region) {
    return region.width >= minSide && region.height >= minSide;
}

function readoutOrigin(corner, size, monitor) {
    const place = (corner, size, monitor) => Math.round(
        corner + readoutOffset + size > monitor - readoutEdgeMargin
            ? corner - readoutOffset - size
            : corner + readoutOffset);
    return { x: place(corner.x, size.width, monitor.width), y: place(corner.y, size.height, monitor.height) };
}

function toReal(logical, scale, imageWidth, imageHeight) {
    const real = (value, limit) => Math.min(Math.max(Math.round(value * scale), 0), limit);
    const left = real(logical.x, imageWidth);
    const top = real(logical.y, imageHeight);
    const right = real(logical.x + logical.width, imageWidth);
    const bottom = real(logical.y + logical.height, imageHeight);
    return { x: left, y: top, width: right - left, height: bottom - top };
}

function geometry(region) {
    return `${region.width}x${region.height}+${region.x}+${region.y}`;
}

function stamp(date) {
    const pad = value => String(value).padStart(2, "0");
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} `
        + `${pad(date.getHours())}-${pad(date.getMinutes())}-${pad(date.getSeconds())}`;
}

function fileName(stamp, attempt) {
    return attempt === 0 ? `Screenshot from ${stamp}.png` : `Screenshot from ${stamp} (${attempt}).png`;
}

function candidates(stamp) {
    return Array.from({ length: maxNameAttempts }, (_, attempt) => fileName(stamp, attempt));
}

function localPath(url) {
    return decodeURIComponent(String(url).replace(/^file:\/\//, ""));
}
