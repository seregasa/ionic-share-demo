# Integrating the Custom Share Sheet Plugin into an Existing Ionic App

This guide explains how to add the inline **SharePreview** plugin (custom native share
sheet with app icon + title) into an existing Ionic + Capacitor project, and documents
every non-obvious pitfall discovered while building it.

## Target stack

- Ionic 8, Angular (module-based or standalone), **Capacitor 7** (this branch — iOS on
  **CocoaPods**). The `main` branch is the Capacitor 8 / Swift Package Manager version.
- iOS deployment target 13+ (LPLinkMetadata requires iOS 13)
- Android minSdk 23+, Android 10+ for the title preview

The plugin **code is identical** across Capacitor 6/7/8 — `CAPBridgedPlugin` +
`bridge.registerPluginInstance(...)` work on all of them. Only the iOS packaging differs:
**Cap 7 = CocoaPods**, Cap 8 = SPM. The Cap 7 / CocoaPods specifics and their extra risks
are called out below (Pitfall #2b).

---

## Risk assessment (read first)

The plugin is **additive** — it adds new files and a few registration hooks. It does not
change your app's routing, business logic, or dependency versions. Overall risk is
**low-to-medium**, concentrated in three integration points:

| Area | Risk | Why |
|---|---|---|
| iOS view controller + storyboard | Medium | You must register the plugin from a `CAPBridgeViewController` subclass and point the storyboard at it. Touching the storyboard is the highest-risk step. |
| iOS CocoaPods (Cap 7 only) | Medium | CocoaPods must be installed and `pod install` must run. You must open `App.xcworkspace`, never `App.xcodeproj`, or you get `No such module 'Capacitor'`. See Pitfall #2b. |
| Android Kotlin enablement | Medium | If your Android project is Java-only, you must enable the Kotlin Gradle plugin. Trivial if you already use Kotlin. |
| Android FileProvider | Low | Reuse Capacitor's existing provider; do not declare a second one with the same authority. |
| Everything else (TS bridge, Swift/Kotlin plugin files, icon assets) | Low | Pure additions. |

**Do NOT copy these demo-only changes into your app** (they were fixes for this demo's
scaffold, not part of the plugin):
- `color-scheme` meta / disabling `dark.system.css` in `global.scss`
- `ios.backgroundColor` in `capacitor.config`
- the white background in the view controller's `viewDidLoad`

Your app owns its own theming; leave it alone.

---

## Files that make up the plugin

```
src/plugin/share-preview.plugin.ts      TypeScript bridge (registerPlugin)
src/plugin/share-preview.web.ts          Web fallback (navigator.share)
ios/App/App/SharePreviewPlugin.swift      iOS native plugin
ios/App/App/MainViewController.swift       iOS plugin registration (see pitfall #1)
android/.../com/demo/shareplugin/SharePreviewPlugin.kt   Android native plugin
```
Plus icon assets and a few registration edits described below.

---

## 1. TypeScript bridge (safe, framework-agnostic)

Copy `src/plugin/share-preview.plugin.ts` and `src/plugin/share-preview.web.ts`.
Call it from anywhere:

```ts
import { SharePreview } from '../../plugin/share-preview.plugin';
await SharePreview.share({ title: 'Custom title', url: 'https://example.com' });
await SharePreview.share({ title: 'Custom title', text: 'Custom message text' });
```

No module/standalone constraints — works in both.

---

## 2. iOS integration

### Pitfall #1 — never name the view controller `ViewController`

Capacitor registers inline plugins from a `CAPBridgeViewController` subclass via
`capacitorDidLoad()`. The subclass **must not be named `ViewController`**.

A class literally named `ViewController` (and/or `@objc(ViewController)`) collides at
runtime class resolution: the storyboard resolves the *wrong* class, no `WKWebView` is
created, and you get a **pure black screen** (app runs, status bar shows, no web content,
no crash). An empty subclass named `ViewController` reproduces it; renaming fixes it.

Use a unique name, e.g. `MainViewController`:

```swift
import UIKit
import Capacitor

class MainViewController: CAPBridgeViewController {
    override func capacitorDidLoad() {
        bridge?.registerPluginInstance(SharePreviewPlugin())
    }
}
```

In `Main.storyboard`, point the initial view controller at it **with the module**:

```xml
<viewController id="BYZ-38-t0r" customClass="MainViewController" customModule="App" sceneMemberID="viewController"/>
```

`customModule` is your app target's module name (`App` in a stock Capacitor project).
If your app already subclasses `CAPBridgeViewController`, just add the
`registerPluginInstance` line to your existing `capacitorDidLoad()` and skip the new file.

### Pitfall #2 — registration uses `CAPBridgedPlugin` (not the `.m` macro)

Register via the Swift `CAPBridgedPlugin` protocol (see `SharePreviewPlugin.swift`). This
works on Capacitor 6/7/8 regardless of CocoaPods vs SPM. (On Cap 8 SPM the old Objective-C
`CAP_PLUGIN(...)` `.m` macro does **not** register the plugin at all; on Cap 7 CocoaPods
the `.m` macro would also work, but using `CAPBridgedPlugin` keeps the code identical
across versions.)

```swift
@objc(SharePreviewPlugin)
public class SharePreviewPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "SharePreviewPlugin"
    public let jsName = "SharePreview"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "share", returnType: CAPPluginReturnPromise)
    ]
    @objc func share(_ call: CAPPluginCall) { ... }
}
```

### Pitfall #2b — Capacitor 7 iOS uses CocoaPods (extra risks)

On Capacitor 7, `npx cap add ios` produces a **CocoaPods** project, not SPM. This adds
several failure modes we hit in practice:

- **CocoaPods must be installed** before `npx cap sync`. If it isn't, `cap sync` silently
  skips `pod install`, and Xcode then fails with
  `unable to open base configuration reference file ... Pods-App.debug.xcconfig`.
  Fix: `brew install cocoapods`, then `npx cap sync` (or `cd ios/App && pod install`).
- **Open `App.xcworkspace`, NEVER `App.xcodeproj`.** The pods (including `Capacitor`) are
  only linked in the workspace. Opening the bare project gives
  `No such module 'Capacitor'` / `Unable to resolve module dependency: 'Capacitor'`.
  Confirm a **Pods** project appears in the navigator. `npx cap open ios` opens the
  correct file.
- **Don't switch a single clone between the Cap 8 (`main`, SPM) and Cap 7
  (`capacitor-7`, CocoaPods) branches in place.** Git leaves behind the other manager's
  build artifacts (SPM `Package.resolved`, or `Pods/`), and Xcode picks up the stale
  state → `No such module 'Capacitor'` even with Pods present. Use a **fresh clone per
  branch**, or after switching: `rm -rf ios/App/Pods ios/App/App/public && npx cap sync`.
- If the module error persists after a clean workspace + `pod install`, delete DerivedData
  (`rm -rf ~/Library/Developer/Xcode/DerivedData/App-*`) and Clean Build Folder. On
  Xcode 16, also try Build Settings → set **Explicitly Built Modules** to No.

The yellow `Auto property synthesis will not synthesize property … 'CAPBridgedPlugin'`
warnings come from Capacitor's own pods (e.g. CapacitorKeyboard) — they are harmless and
not from this plugin.

### Pitfall #3 — add Swift files to the Xcode target properly

Do not hand-edit `project.pbxproj` UUIDs. Either drag the files into the App target in
Xcode, or use the `xcodeproj` Ruby gem:

```ruby
require 'xcodeproj'
project = Xcodeproj::Project.open('App/App.xcodeproj')
target  = project.targets.find { |t| t.name == 'App' }
group   = project.main_group.find_subpath('App', false)
['MainViewController.swift', 'SharePreviewPlugin.swift'].each do |f|
  ref = group.new_reference(f)
  target.source_build_phase.add_file_reference(ref)
end
project.save
```

### Icon for the iOS share sheet

The plugin loads a **regular image set** named `ShareIcon`, NOT the app icon set.
`UIImage(named: "AppIcon")` returns nil / the Xcode placeholder grid — app icon sets are
not loadable that way. Add `Assets.xcassets/ShareIcon.imageset` with a ~180×180 PNG.

The plugin applies the iOS squircle (continuous-corner) mask itself so the icon matches
the home-screen shape rather than being clipped to a circle. The mask render runs on the
main thread (CALayer requirement) and is pre-built once at `load()`.

### Icon item provider

Provide the icon with `NSItemProvider(object: uiImage)` (rich image, renders full size).
Do **not** use `registerDataRepresentation(public.png)` — iOS then treats it as a generic
file and renders a small icon.

### URL subtitle

The gray subtitle line under the title is **only** the URL's host. `LPLinkMetadata` has
exactly one text field (`title`) — there is no `subtitle`/`summary` property. So:
- URL share: set `metadata.URL` → subtitle shows the domain.
- Plain-text share: no URL → no subtitle is possible. The text is still delivered to the
  receiving app, but the preview header shows only the title.

Pass the URL to the activity item as a **String**, not a `URL` object — a `URL` object
triggers Launch Services sandbox lookups ("Cannot issue sandbox extension for URL",
`canmaplsdatabase` errors) that delay presentation.

---

## 3. Android integration

### Enable Kotlin (skip if your project already uses Kotlin)

`android/build.gradle` (buildscript block — define the version where it is evaluated):
```gradle
buildscript {
    ext.kotlinVersion = '2.0.21'
    dependencies {
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion"
    }
}
```
`android/app/build.gradle`:
```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib:$kotlinVersion"
}
```

### Register the plugin in `MainActivity`

```java
// MainActivity.java
import android.os.Bundle;
import com.demo.shareplugin.SharePreviewPlugin;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(SharePreviewPlugin.class);
        super.onCreate(savedInstanceState);
    }
}
```

### Pitfall #4 — load the icon from a real PNG, not the adaptive mipmap

On API 26+, `R.mipmap.ic_launcher` resolves to **adaptive-icon XML**, which
`BitmapFactory.decodeResource` cannot decode (returns null → no icon). Also,
`getApplicationIcon()` returns an `AdaptiveIconDrawable` that **self-clips to a circle**
when drawn to a Canvas.

Fix: ship a plain square PNG at `res/drawable/share_icon.png` and decode that directly.

### Pitfall #5 — title preview needs an image ClipData, not a raw URL

A thumbnail only appears when `ClipData` carries an **image content URI** (MIME
`image/png`). Putting the URL into `ClipData.newRawUri` does nothing. The plugin writes
the icon PNG to `cacheDir` and shares it via `FileProvider`, with the real URL/text in
`EXTRA_TEXT` and the label in `EXTRA_TITLE`.

### Pitfall #6 — reuse Capacitor's FileProvider

Capacitor already declares a `FileProvider` with authority
`${applicationId}.fileprovider` and `res/xml/file_paths.xml`. Reuse it. Ensure
`file_paths.xml` contains a cache path:
```xml
<cache-path name="my_cache_images" path="." />
```
Do not declare a second provider with the same authority — it will crash at install.

### Icon background color (the gray "border")

The thin gray you may see around the Android thumbnail is the system Sharesheet frame
plus the sheet background showing through any transparent pixels of the icon. The app
cannot remove the system frame, but it can fill the icon background. The plugin composites
the icon onto a solid color before sharing:
```kotlin
private val ICON_BACKGROUND_COLOR = Color.WHITE   // change to any color / Color.parseColor("#RRGGBB")
```

---

## 4. Build & run

```bash
npm install
ionic build
npx cap sync
npx cap open ios      # Xcode: Clean Build Folder (Shift+Cmd+K), then Run
npx cap open android  # Android Studio: Sync Gradle, then Run
```

For iOS device builds, each developer sets their own signing team in Xcode (Signing &
Capabilities). Simulator builds need no signing.
