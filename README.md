# FillLight

Turn your screen into a fill light when the room is too dark for the camera.

- **Mac**: a menu bar app that lights a soft ring around the edge of your display. Works any time, not only during calls, and on top of full-screen apps.
- **iPhone / iPad**: a full-screen light you can point at your face. *(In progress.)*

macOS 26.2 and later ships a similar feature called [Edge Light](https://support.apple.com/en-la/125934), but it only shows up during video calls. FillLight is for everything else too: recording, photos, reading your face in a dark room, or Macs that don't have Edge Light.

## Mac

### Features

- Click the lightbulb in the menu bar, or press **⌃⌥L** anywhere, to turn the light on or off.
- **Brightness** makes the ring wider. **Warmth** goes from daylight (6500K) to warm (2700K).
- **Fade Near Pointer** clears a soft hole around the mouse pointer so menus and buttons under the ring stay usable. The ring never blocks clicks.
- Lights the display with the built-in camera by default. Turn on **Light All Displays** to light every screen.
- Control it from Shortcuts or scripts with `filllight://on`, `filllight://off` and `filllight://toggle`, for example `open filllight://toggle`.
- Settings are remembered. No Accessibility or camera permission needed.

For the most light, turn your display brightness all the way up.

### Install

Download `FillLight-macOS-*.zip` from [Releases](../../releases), unzip it, and move `FillLight.app` to Applications.

The app is not notarized, so macOS will block it the first time. Right-click `FillLight.app` and choose **Open**, then confirm. If macOS still refuses, run:

```bash
xattr -dr com.apple.quarantine /Applications/FillLight.app
```

### Build from source

Requires macOS 13 or later and Swift 5.9 or later. Xcode Command Line Tools are enough.

```bash
./scripts/build-mac-app.sh
```

This produces `build/FillLight.app` and a zip for releases. `swift run core-check` runs the checks for the shared color math.

## iPhone / iPad

iOS does not let apps draw on top of other apps, so the iPhone and iPad version can't light the edges of FaceTime the way the Mac version does. Instead it turns the whole screen into an adjustable light you can aim at yourself, for example while on a call from your Mac.

Coming soon.

## Project layout

```
Shared/   color temperature and ring math, used by both apps
Mac/      macOS menu bar app (AppKit)
iOS/      iPhone and iPad app (SwiftUI)
Tools/    core-check, sanity checks for Shared/
scripts/  build-mac-app.sh
```

## License

[MIT](LICENSE)
