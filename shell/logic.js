.pragma library

const maxNameAttempts = 100;

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
