.pragma library

// Widens one slot into its direct row neighbors, gaps kept; returns per-slot {x, w} deltas.
function shifts(slots, index, ratio, unit, minimumWidth) {
    const result = slots.map(() => null);
    const pressed = slots[index];
    if (!pressed)
        return result;
    const row = slots.reduce((indices, slot, i) => slot && slot.y < pressed.y + pressed.h && slot.y + slot.h > pressed.y ? indices.concat([i]) : indices, []);
    row.sort((a, b) => slots[a].x - slots[b].x);
    // Slots stacked beside a tall one are not one row.
    if (row.some((i, k) => k > 0 && slots[i].x < slots[row[k - 1]].x + slots[row[k - 1]].w))
        return result;
    const at = row.indexOf(index);
    const neighbors = [row[at - 1], row[at + 1]].filter(i => i !== undefined);
    if (neighbors.length === 0)
        return result;
    const room = i => Math.max(0, slots[i].w - (minimumWidth ? minimumWidth(i) : 0));
    // As in Compose, a middle slot takes half from each side, both held to the tighter neighbor.
    const take = Math.min(ratio * Math.min(pressed.w, unit) / neighbors.length, ...neighbors.map(room));
    if (take <= 0)
        return result;
    let x = slots[row[0]].x;
    row.forEach((i, k) => {
        const slot = slots[i];
        const w = i === index ? slot.w + take * neighbors.length : neighbors.includes(i) ? slot.w - take : slot.w;
        result[i] = {
            "x": x - slot.x,
            "w": w - slot.w
        };
        const next = slots[row[k + 1]];
        if (next)
            x += w + next.x - (slot.x + slot.w);
    });
    return result;
}
