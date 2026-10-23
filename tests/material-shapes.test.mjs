import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const source = name => readFileSync(new URL(`../DCommon/Widgets/${name}`, import.meta.url), "utf8").replace(/^\.(pragma|import).*$/gm, "");
const load = (name, globals) => {
    const context = vm.createContext(globals ?? {});
    vm.runInContext(source(name), context);
    return context;
};
const shapes = load("MaterialShapes.js", {
    Data: load("MaterialShapeData.js"),
    Logo: load("DLogoShape.js")
});

const assertNear = (actual, expected) => {
    for (const key of Object.keys(expected))
        assert.ok(Math.abs(actual[key] - expected[key]) < 1e-12, `${key}: ${actual[key]} is not ${expected[key]}`);
};
const ring = radius => new Array(8).fill(radius);

// Eight samples from -pi fall on the axes and the diagonals, so the expected boxes are worked out by hand.
test("polar bounds box the outline, off-centre ones included", () => {
    assertNear(shapes.polarBounds(ring(0.25)), { x: -0.25, y: -0.25, width: 0.5, height: 0.5 });
    assertNear(shapes.polarBounds([0, 0, 0, 0.5, 0.5, 0.5, 0, 0]), { x: 0, y: -Math.SQRT1_2 / 2, width: 0.5, height: Math.SQRT1_2 });
});

test("morph scale shrinks the set until its widest shape fits the unit box", () => {
    assert.equal(shapes.morphScale([ring(0.25)]), 1);
    assert.equal(shapes.morphScale([ring(0.25), ring(1)]), 0.5);
});

test("profiles keep valid radii and draw a circle for anything else", () => {
    const circle = shapes.polarProfile("circle", 8);
    const only = list => {
        const profiles = shapes.profilesOf(list, 8);
        assert.equal(profiles.length, 1);
        return profiles[0];
    };
    for (const list of [null, undefined, []])
        assert.equal(only(list), circle);
    const short = ring(0.25).slice(1);
    for (const invalid of [short, [...short, 2], [...short, -0.1], [...short, NaN], [...short, undefined], 7, {}, null])
        assert.equal(only([invalid]), circle);
    const radii = ring(0.25);
    assert.equal(only([radii]), radii);
    assert.equal(only(["circle"]), circle);
});
