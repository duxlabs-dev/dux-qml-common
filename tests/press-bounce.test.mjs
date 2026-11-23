import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const bounce = vm.createContext({});
vm.runInContext(readFileSync(new URL("../DCommon/Common/PressBounce.js", import.meta.url), "utf8").replace(/^\.pragma.*$/gm, ""), bounce);
const plain = value => JSON.parse(JSON.stringify(value));
const slot = (x, y, w, h) => ({ x, y, w, h });
const close = (a, b) => Math.abs(a - b) < 1e-9;

test("a pressed slot widens into its row without moving the row's ends or gaps", () => {
    const slots = [slot(0, 0, 100, 50), slot(110, 0, 200, 50), slot(320, 0, 100, 110), slot(0, 60, 310, 50), null];
    const shifts = plain(bounce.shifts(slots, 1, 0.15, Infinity));
    const moved = slots.map((s, i) => s && shifts[i] && { x: s.x + shifts[i].x, w: s.w + shifts[i].w });
    assert.equal(shifts[3], null);
    assert.ok(close(moved[0].x, 0) && close(moved[2].x + moved[2].w, 420));
    assert.ok(close(moved[1].x - (moved[0].x + moved[0].w), 10) && close(moved[2].x - (moved[1].x + moved[1].w), 10));
    assert.ok(close(moved[1].w, 230));
});

test("only the direct neighbors give way, a middle slot taking half from each", () => {
    const row = [slot(0, 0, 100, 50), slot(110, 0, 100, 50), slot(220, 0, 100, 50), slot(330, 0, 100, 50)];
    const first = plain(bounce.shifts(row, 0, 0.15, Infinity));
    assert.ok(close(first[0].w, 15) && close(first[1].x, 15) && close(first[1].w, -15));
    assert.ok(close(first[2].w, 0) && close(first[3].x, 0));
    const middle = plain(bounce.shifts(row, 1, 0.15, Infinity));
    assert.ok(close(middle[0].w, -7.5) && close(middle[1].x, -7.5) && close(middle[1].w, 15) && close(middle[2].w, -7.5) && close(middle[3].w, 0));
});

test("growth is capped by the unit and the tighter neighbor's minimum", () => {
    assert.ok(close(plain(bounce.shifts([slot(0, 0, 300, 50), slot(310, 0, 300, 50)], 0, 0.15, 80))[0].w, 12));
    assert.deepEqual(plain(bounce.shifts([slot(0, 0, 300, 50)], 0, 0.15, Infinity)), [null]);
    const row = [slot(0, 0, 100, 50), slot(110, 0, 100, 50), slot(220, 0, 100, 50)];
    const shifts = plain(bounce.shifts(row, 1, 0.15, Infinity, i => i === 2 ? 97 : 0));
    assert.ok(close(shifts[0].w, -3) && close(shifts[2].w, -3) && close(shifts[1].w, 6));
});

test("slots stacked beside a tall one do not bounce", () => {
    const stacked = [slot(0, 0, 200, 110), slot(210, 0, 600, 50), slot(210, 60, 100, 50)];
    assert.deepEqual(plain(bounce.shifts(stacked, 0, 0.15, Infinity)), [null, null, null]);
});
