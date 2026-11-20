import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const iconUrl = vm.createContext({});
vm.runInContext(readFileSync(new URL("../DCommon/Common/IconUrl.js", import.meta.url), "utf8").replace(/^\.pragma.*$/gm, ""), iconUrl);

test("a plain icon URL gets the revision as its query", () => {
    assert.equal(iconUrl.withRevision("image://icon/folder", 0), "image://icon/folder?rev=0");
    assert.equal(iconUrl.withRevision("image://icon/folder", 3), "image://icon/folder?rev=3");
});

test("the revision joins a query that is already there", () => {
    assert.equal(iconUrl.withRevision("image://icon/no-such?fallback=folder", 3), "image://icon/no-such?fallback=folder&rev=3");
    assert.equal(iconUrl.withRevision("image://icon/tray?path=run/icons", 1), "image://icon/tray?path=run/icons&rev=1");
});

test("a new revision gives a new URL", () => {
    assert.notEqual(iconUrl.withRevision("image://icon/folder", 1), iconUrl.withRevision("image://icon/folder", 2));
});

test("a question mark that belongs to the icon name is left alone", () => {
    assert.equal(iconUrl.withRevision("image://icon//tmp/what?.png", 3), "image://icon//tmp/what?.png");
});

test("only image://icon/ URLs are marked, and never with a fragment", () => {
    assert.equal(iconUrl.withRevision("", 3), "");
    assert.equal(iconUrl.withRevision("file:///usr/share/icons/folder.svg", 3), "file:///usr/share/icons/folder.svg");
    assert.equal(iconUrl.withRevision("qrc:/icons/folder.svg", 3), "qrc:/icons/folder.svg");
    assert.equal(iconUrl.withRevision("image://icon/folder", 3).includes("#"), false);
});
