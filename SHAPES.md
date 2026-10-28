# Shapes

`Style.radiusStrength` ranges from 0 to 100. The default, 50, uses the Material shape scale. Zero removes configurable corner rounding. 100 doubles every baseline. Full corners stop at half the shorter side.

`Style.fixedRadius` caps the scale when it is 0 or more: `m` and every larger token return that pixel value, smaller tokens keep their proportion to `m` so joined rows and segmented buttons still read as one surface, and full corners cap at it. `scaledRadius(base, limit)` still replaces its base with the fixed value, capped by `limit`. Minus one, the default, keeps the strength scale. Fixed values clamp to 0 through 32.

Set `theme.radiusStrength` and `theme.fixedRadius` when injecting a theme. Older hosts can still supply `theme.cornerRadius`; `Style` converts it to strength. `cornerRadius` remains an alias for `cornerRadiusM`. The 2-unit `cornerRadiusXXS` is a DMS extension for small details.

Use named tokens for fixed corners. Use `Style.fullRadius(width, height)` for pills and round controls, `Style.buttonRadius(width, height, sizeHeight, pressed, round)` for button states, and `Style.scaledRadius(baseRadius, limit)` for component metrics such as slider track corners. `cornerRadiusFull` remains a compatibility sentinel; use the dimension-aware helper for new code. `buttonRadius` follows the theme's `pillControls` and `shapeMorph` bools (both false in the shell's Classic interface style): no pills and no press morph, one `l` corner for every control.

Strength is a DMS preference, not a Material token. Radii scale by `strength / 50` on both sides of the default, so each slider step moves the same amount. Legacy medium radii map to the nearest integer strength: 0 → 0, 6 → 25, 12 → 50, 16 → 67, 24 and above → 100. Component token corrections can change individual shapes after migration.

## Component baselines

The values below come from Google's published Material component tokens. DMS maps these logical dimensions to QML coordinates.

| Component | Baseline | Source |
| --- | --- | --- |
| Shape scale | XS 4, S 8, M 12, L 16, L increased 20, XL 28, XL increased 32, XXL 48; full uses half the shorter side | [ShapeTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ShapeTokens.kt) |
| Buttons, XS and S | Round: full; square: 12; pressed: 8 | [ButtonSmallTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ButtonSmallTokens.kt) |
| Buttons, M | Round: full; square: 16; pressed: 12 | [ButtonMediumTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ButtonMediumTokens.kt) |
| Buttons, L and XL | Round: full; square: 28; pressed: 16 | [ButtonLargeTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ButtonLargeTokens.kt) |
| Icon buttons, S and M | Same rest and pressed radii as buttons; selection swaps round and square | [SmallIconButtonTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/SmallIconButtonTokens.kt) |
| Connected button groups, S | Full outer corners; inner 8; pressed inner 4; selected inner full | [ConnectedButtonGroupSmallTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ConnectedButtonGroupSmallTokens.kt) |
| Split buttons, XS/S/M/L/XL | Full outer corners; inner 4/4/4/8/12; pressed inner 8/12/12/20/20; expanded menu inner full | [SplitButton defaults and states](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/SplitButton.kt) |
| FABs and small extended FABs | L (16), capped at half the height | [ExtendedFabSmallTokens](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ExtendedFabSmallTokens.kt) |
| Grouped lists | Outer 16; inner 4 in every state. Compose's interactive list item morphs the inner corners to 12 on hover and 16 on press, focus and selection; DMS keeps them fixed | [ListTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/ListTokens.kt), [list specifications](https://m3.material.io/components/lists/specs) |
| Filter chips | 8 in selected and unselected states | [Chip specifications](https://m3.material.io/components/chips/specs) |
| Slider tracks, XS through XL | Outer 8, 8, 12, 16, 28; handle-facing corners 2 | [Slider specifications](https://m3.material.io/components/sliders/specs), [Slider implementation](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/Slider.kt) |
| Cards | 12 | [FilledCardTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/FilledCardTokens.kt) |
| Outlined text fields | 4 | [OutlinedTextFieldTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/OutlinedTextFieldTokens.kt) |
| Switches | Full track and handle | [SwitchTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/SwitchTokens.kt) |
| Tooltips | 4 | [PlainTooltipTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/PlainTooltipTokens.kt) |
| Date cells | Full for the 40dp selection indicator; DMS draws filled day tiles with a number and event dots, so `DMonthGrid` uses S at rest and XS pressed | [DatePickerModalTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/DatePickerModalTokens.kt) |
| Time picker | Container 28; time fields and period selector 8; circular clock dial | [TimePickerTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/TimePickerTokens.kt) |
| Dialogs | 28 | [DialogTokens](https://github.com/androidx/androidx/blob/4e102078781149f17980c915a12984efb7aed817/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/tokens/DialogTokens.kt) |

DMS surfaces without a direct Material component equivalent keep their existing named shape roles. Explicit frame, island and compositor radius overrides remain pixel values. Clock dials, circular image masks, chart markers and artwork geometry retain their geometric shapes.

Split buttons keep their resting shape on hover, matching the [Compose interaction implementation](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/SplitButton.kt). Each half changes its inner corners on press. Opening the menu rounds the trailing half and rotates its arrow. `menuOnly` changes which action the leading half invokes; it does not change these shapes.

Slider inner corners scale independently from outer corners and never use the full-radius helper. The Material slider page currently disagrees with its embedded medium-handle token: the measurements table says 52, the token says 44. DMS retains 44. `centerMinimum` is a DMS mapping that places the minimum at the midpoint; it retains a leading filled track.
