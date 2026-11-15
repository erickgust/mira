.pragma library

const maxNameAttempts = 100;
const minSide = 4;
const readoutOffset = 16;
const readoutEdgeMargin = 8;
const handleReach = 8;
const edgeHandleMinSide = 48;
const loupeSize = 120;
const loupePixels = 15;
const loupeOffset = 16;

function clamp(value, low, high) {
    return Math.min(Math.max(value, low), high);
}

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
    const moved = moveRect(rect, by, bounds);
    const move = point => ({ x: point.x + moved.x - rect.x, y: point.y + moved.y - rect.y });
    return { anchor: move(drag.anchor), corner: move(drag.corner) };
}

function moveRect(rect, by, bounds) {
    return {
        x: clamp(rect.x + by.x, 0, bounds.width - rect.width),
        y: clamp(rect.y + by.y, 0, bounds.height - rect.height),
        width: rect.width,
        height: rect.height
    };
}

function resizeRect(rect, handle, by, bounds) {
    const right = rect.x + rect.width;
    const bottom = rect.y + rect.height;
    const left = handle.includes("l") ? clamp(rect.x + by.x, 0, right - minSide) : rect.x;
    const top = handle.includes("t") ? clamp(rect.y + by.y, 0, bottom - minSide) : rect.y;
    const newRight = handle.includes("r") ? clamp(right + by.x, left + minSide, bounds.width) : right;
    const newBottom = handle.includes("b") ? clamp(bottom + by.y, top + minSide, bounds.height) : bottom;
    return { x: left, y: top, width: newRight - left, height: newBottom - top };
}

function handles(rect) {
    return ["tl", "tr", "br", "bl"].concat(
        rect.width >= edgeHandleMinSide ? ["t", "b"] : [],
        rect.height >= edgeHandleMinSide ? ["l", "r"] : []);
}

function handleCentre(rect, handle) {
    const along = (start, size, before, after) => handle.includes(before) ? start - 0.5
        : handle.includes(after) ? start + size + 0.5
        : start + size / 2;
    return { x: along(rect.x, rect.width, "l", "r"), y: along(rect.y, rect.height, "t", "b") };
}

function hitTest(rect, point) {
    if (!rect || !point)
        return "outside";
    const near = handle => {
        const centre = handleCentre(rect, handle);
        return Math.abs(point.x - centre.x) <= handleReach && Math.abs(point.y - centre.y) <= handleReach;
    };
    const inside = point.x >= rect.x && point.x < rect.x + rect.width && point.y >= rect.y && point.y < rect.y + rect.height;
    return handles(rect).find(near) ?? (inside ? "inside" : "outside");
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

function overlaps(a, b) {
    return a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height;
}

function loupeOrigin(cursor, monitor, readout) {
    const right = cursor.x + loupeOffset;
    const left = cursor.x - loupeOffset - loupeSize;
    const above = cursor.y - loupeOffset - loupeSize;
    const below = cursor.y + loupeOffset;
    const xs = right + loupeSize > monitor.width - readoutEdgeMargin ? [left, right] : [right, left];
    const ys = above < readoutEdgeMargin ? [below, above] : [above, below];
    const spots = [{ x: xs[0], y: ys[0] }, { x: xs[1], y: ys[0] }, { x: xs[0], y: ys[1] }, { x: xs[1], y: ys[1] }];
    const fits = spot => spot.x >= 0 && spot.y >= 0 && spot.x + loupeSize <= monitor.width && spot.y + loupeSize <= monitor.height
        && !(readout && overlaps({ x: spot.x, y: spot.y, width: loupeSize, height: loupeSize }, readout));
    return spots.find(fits) ?? spots[0];
}

function loupeSource(point, scale, imageWidth, imageHeight) {
    const start = (value, limit) => (Math.min(Math.floor(value * scale), limit - 1) - (loupePixels - 1) / 2) / scale;
    return { x: start(point.x, imageWidth), y: start(point.y, imageHeight), width: loupePixels / scale, height: loupePixels / scale };
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

function regionText(region) {
    return [region.x, region.y, region.width, region.height].join(",");
}

function parseRegion(text) {
    const [x, y, width, height] = text.split(",").map(Number);
    return { x: x, y: y, width: width, height: height };
}

function fileUrl(path) {
    return "file://" + path.split("/").map(encodeURIComponent).join("/");
}

function localPath(url) {
    return decodeURIComponent(String(url).replace(/^file:\/\//, ""));
}
