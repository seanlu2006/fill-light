# FillLight

Turn your screen into a fill light when the room is too dark for the camera.

- **Mac**: a menu bar app that lights a soft ring around the edge of your display. Works any time, not only during calls, and on top of full-screen apps.
- **iPhone / iPad**: a full-screen light you can point at your face, or a ring light with your front camera in the middle.

macOS 26.2 and later ships a similar feature called [Edge Light](https://support.apple.com/en-la/125934), but it only shows up during video calls. FillLight is for everything else too: recording, photos, reading your face in a dark room, or Macs that don't have Edge Light.

## Mac

### Features

- Click the lightbulb in the menu bar, or press **⌃⌥L** anywhere, to turn the light on or off.
- **Brightness** makes the ring wider. **Warmth** goes from daylight (6500K) to warm (2700K).
- **Custom Color…** lights the ring in any color you pick. Move the Warmth slider or choose **White Light** to go back to white.
- **Fade Near Pointer** clears a soft hole around the mouse pointer so menus and buttons under the ring stay usable. The ring never blocks clicks.
- Lights the display with the built-in camera by default. Turn on **Light All Displays** to light every screen.
- Control it from Shortcuts or scripts with `filllight://on`, `filllight://off` and `filllight://toggle`, for example `open filllight://toggle`.
- Settings are remembered. No Accessibility or camera permission needed.

### More light

Ring width is only one way to get more light. Two options in the menu go further:

- **HDR Boost** draws the ring brighter than normal white on HDR displays, such as the XDR display on MacBook Pro. It uses more power, and macOS may dim the rest of the screen a little to make room for it.
- **Max Screen Brightness While On** turns the built-in display all the way up while the light is on and puts it back when the light goes off. macOS has no public API for this, so FillLight uses a private one that many open-source utilities rely on. If a future macOS removes it, the option disappears from the menu.

Saturated colors give much less light than white, because only some of the display's red, green and blue subpixels are lit. Pale colors are a good middle ground.

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

### Features

- **Full** mode lights the whole screen. **Ring** mode lights the edges and shows your front camera in the middle, so you can see how you're lit. The camera image never leaves the device and is never recorded.
- **Brightness** sets the display brightness. Your own brightness comes back when you leave the app.
- **HDR Boost** makes the light brighter than normal white on HDR screens. It uses more battery.
- **Warmth** goes from daylight (6500K) to warm (2700K). **Ring width** controls how much of the screen glows in Ring mode.
- Switch from **White** to **Color** to light the screen in any color. The picker covers only half the screen, so you can watch the light change as you pick.
- Controls fade away after a few seconds. Tap anywhere to bring them back.
- The screen stays awake while the app is open.

### Install

Requires iOS or iPadOS 17 or later. There is no App Store version, so you build it onto your own device with Xcode. A free Apple ID is enough.

1. Install [Xcode](https://apps.apple.com/app/id497799835) and open `iOS/FillLight.xcodeproj`.
2. Select the **FillLight** target → **Signing & Capabilities**, set **Team** to your Apple ID, and change the **Bundle Identifier** to something unique, like `com.yourname.FillLight`.
3. Connect your iPhone or iPad, choose it as the run destination, and press **Run**.
4. The first time, your device asks you to trust the developer: **Settings → General → VPN & Device Management**. You also need to turn on **Developer Mode** in **Settings → Privacy & Security**.

With a free Apple ID the app stops opening after 7 days. Press **Run** in Xcode again to renew it. A paid Apple Developer account extends this to a year.

`iOS/project.yml` describes the project for [XcodeGen](https://github.com/yonaskolb/XcodeGen). You only need XcodeGen if you change it: run `xcodegen` inside `iOS/`.

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
