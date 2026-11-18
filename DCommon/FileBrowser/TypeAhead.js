.pragma library

function find(count, nameAt, start, needle) {
    for (let step = 0; step < count; step++) {
        const index = (start + step) % count;
        if (nameAt(index).toLowerCase().startsWith(needle))
            return index;
    }
    return -1;
}

function next(count, nameAt, current, prefix, text) {
    const typed = prefix + text.toLowerCase();
    const letters = Array.from(typed);
    const repeated = letters.length > 1 && letters.every(letter => letter === letters[0]);
    const skipsRow = current >= 0 && (prefix === "" || repeated);
    return {
        "index": find(count, nameAt, skipsRow ? current + 1 : Math.max(0, current), repeated ? letters[0] : typed),
        "prefix": typed
    };
}
