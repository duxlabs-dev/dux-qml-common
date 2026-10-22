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

const ring = radius => new Array(8).fill(radius);

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
