# dank-qml-common

Shared QML for DMS, Dux Calendar, Dux Files and the rest of the Dux Labs suite. Widgets, theming, a file browser and lock screen pieces, all following Material 3 Expressive.

```qml
import qs.DCommon.Widgets
import qs.DCommon.Common
import qs.DCommon.FileBrowser
import qs.DCommon.Session
```

## What's in here

- **Widgets** (`DCommon/Widgets`): buttons, FABs, split buttons, button groups, toggles, sliders, chips, badges, tabs, dropdowns, text fields, steppers, tooltips, dialogs, bottom sheets, window headers, navigation bars and rails, cards, list rows, reorderable lists, carousels, color pickers, sparklines, ring gauges, clocks, a month grid, a time picker, Material shapes and the loading indicator. `DFlickable`, `DListView` and `DGridView` wrap the Qt views with our scrollbars and wheel handling.
- **Common** (`DCommon/Common`): `Style` (every theme token, with fallbacks), `Fonts` (bundled faces), `I18n`, `Paths`, `Log` and `Host` bridges, plus JS helpers for contrast, tonal colors, accents, HCT, shapes and wheel input.
- **FileBrowser** (`DCommon/FileBrowser`): the browser behind Dux Files and the DMS file picker. `FilePicker` is the dialog, `FileBrowserView` is the browser without dialog behavior, and the parts (list, grid and column views, path bar, preview pane, selection, history) work on their own too.
- **Session** (`DCommon/Session`): the power menu and on-screen keyboard shared by the DMS lock screen and [dms-greeter](https://github.com/duxlabs-dev/dux-greeter).

[SHAPES.md](SHAPES.md) covers corner radius strength and the shape scale.

## Using it in an app

Add it as a submodule and symlink it into the quickshell config:

```sh
git submodule add https://github.com/duxlabs-dev/dux-qml-common.git dank-qml-common
ln -s ../dank-qml-common/DCommon quickshell/DCommon
```

Packaging that copies the quickshell tree has to follow the symlink (`cp -rL`). `go:embed` rejects symlinks.

## The contract

Shared code never imports app singletons. The app hands them over once at startup:

```qml
import qs.DCommon.Common as DC

DC.Style.theme = Theme
DC.Style.settings = SettingsData
DC.I18n.backend = I18n
DC.Paths.backend = Paths
DC.Log.backend = Log
DC.Host.session = SessionService
DC.Host.cache = CacheData
DC.Host.files = filesBackend
```

The stubs in `Common/` and `Services/` are the full list of what the library reads. `Services/FilesBackend.qml` implements the whole file browser backend over an in-memory tree. If a widget needs a new property, add it to the stub in the same change, or the gallery won't run.

The theme's `shapeMorph` and `pillControls` bools are false in the shell's Classic interface style; a theme without them reads as true. `Style.buttonRadius` follows both: no press morph, and one `cornerRadiusL` for every control instead of pills. `DButtonGroup` without pills spaces its segments by `spacingXS` and rounds every corner, so they read as separate buttons.

## Development

The repo root is a runnable quickshell config with the stubs and a widget gallery:

```sh
qs -p /path/to/dank-qml-common
```

For qmlls, `touch .qmlls.ini` once at the repo root. Quickshell fills it in on the next launch.

Run `node tests/run.mjs` for the tests. CI runs them through prek.

The submodule is a real worktree, so edit it in place from whichever app you're working on and the running app picks it up. Land the library change first, then bump the pointer in the app.

## Translations

Widget strings live here. `translations/extract_translations.py` pulls `I18n.tr()` calls from `DCommon/` into `translations/en.json`, and the DMS POEditor project syncs translations into `DCommon/translations/poexports/`. Apps keep their own catalogs app-only and merge both at runtime, app terms win.

## Credits

Google Sans Flex is bundled under the [SIL Open Font License](DCommon/assets/fonts/google-sans-flex/OFL.txt). `DMaterialShape` paths come from [AndroidX MaterialShapes](https://github.com/androidx/androidx/blob/androidx-main/compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/MaterialShapes.kt), see `MaterialShapes.NOTICE` next to the path data.
