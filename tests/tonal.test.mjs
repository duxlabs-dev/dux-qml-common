import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const rgba = (r, g, b, a = 1) => ({ r, g, b, a });
const hex = value => rgba(...[1, 3, 5].map(i => parseInt(value.slice(i, i + 2), 16) / 255));
const context = vm.createContext({ Qt: { rgba, color: hex } });
const load = name => vm.runInContext(readFileSync(new URL(`../DCommon/Common/${name}`, import.meta.url), "utf8").replace(/^\.(pragma|import).*$/gm, ""), context);
load("Contrast.js");
context.Contrast = context;
load("Hct.js");
context.Hct = context;
load("Tonal.js");

const CASES = [
    { name: "catppuccin mocha mauve", primary: "#cba6f7", card: "#1e1e2e", text: "#cdd6f4" },
    { name: "tokyonight", primary: "#7aa2f7", card: "#2f3549", text: "#c0caf5" },
    { name: "nord", primary: "#81a1c1", card: "#434c5e", text: "#eceff4" },
    { name: "amoled", primary: "#ffffff", card: "#000000", text: "#ffffff" },
    { name: "catppuccin latte mauve", primary: "#8839ef", card: "#e6e9ef", text: "#4c4f69" }
];

test("soft container stays apart from the card with readable text at every tint", () => {
    for (const { name, primary, card, text } of CASES) {
        for (const tint of [0, context.defaultTint(hex(card)), 1]) {
            const container = context.softContainer(hex(primary), hex(card), tint);
            assert.ok(Math.abs(context.toHct(container).tone - context.toHct(hex(card)).tone) >= 3, `${name} ${tint} tone`);
            const on = context.readableOn(container, [hex(text), hex(card), hex("#ffffff"), hex("#000000")]);
            assert.ok(context.ratio(on, container) >= 4.5, `${name} ${tint} text`);
        }
    }
});

test("a purple accent keeps its blue lead over red on a blue-tinted card", () => {
    const card = hex("#24273a");
    const container = context.softContainer(hex("#c6a0f6"), card, context.defaultTint(card));
    assert.ok(container.b - card.b > container.r - card.r);
});

const LIGHT_SURFACES = [
    { name: "m3 purple", surface: "#fef7ff", low: "#f7f2fa", container: "#f3edf7", high: "#ece6f0", highest: "#e6e0e9", text: "#1d1b20" },
    { name: "catppuccin latte", surface: "#e6e9ef", low: "#eff1f5", container: "#e6e9ef", high: "#ccd0da", highest: "#bcc0cc", text: "#4c4f69" },
    { name: "nord", surface: "#c2d0e7", low: "#bcc9e0", container: "#b8c5db", high: "#aebacf", highest: "#aebacf", text: "#2e3440" }
];
const ladderOf = s => context.surfaceLadder(hex(s.surface), hex(s.low), hex(s.container), hex(s.high), hex(s.highest));
const toneOf = color => context.toHct(color).tone;

test("a hovered light card stays above the host, and chips and wells step down inside it", () => {
    for (const theme of LIGHT_SURFACES) {
        const ladder = ladderOf(theme);
        const hovered = context.mix(ladder.card, hex(theme.text), 0.08);
        assert.ok(toneOf(hovered) - toneOf(ladder.host) >= 3, `${theme.name} hovered card`);
        assert.ok(toneOf(ladder.card) - toneOf(ladder.chip) >= 4, `${theme.name} chip`);
        assert.ok(toneOf(ladder.chip) - toneOf(ladder.nested) >= 3, `${theme.name} nested`);
    }
});

test("dark surfaces keep the theme's own ladder", () => {
    const dark = { surface: "#141218", low: "#1d1b20", container: "#211f24", high: "#2b292f", highest: "#36343a" };
    const ladder = ladderOf(dark);
    assert.deepEqual([ladder.host, ladder.card, ladder.chip, ladder.nested], [dark.surface, dark.container, dark.high, dark.highest].map(hex));
});

test("an accent container leaves the roles it would blend into and is otherwise untouched", () => {
    const ladder = ladderOf(LIGHT_SURFACES[0]);
    const roles = [ladder.host, ladder.card, ladder.chip];
    const pale = hex("#e8def8");
    assert.ok(context.worstRatio(pale, roles) < 1.15);
    assert.ok(context.worstRatio(context.standApart(pale, roles, 1.15), roles) >= 1.15);
    const apart = hex("#bcb5c2");
    assert.equal(context.standApart(apart, roles, 1.15), apart);
});
