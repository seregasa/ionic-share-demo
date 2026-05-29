# Ionic Custom Share Sheet Demo

Ionic 8 + Angular 20 + Capacitor 8 app demonstrating a custom native share sheet with an
app icon and title in the preview, on both iOS and Android.

## Features

- Custom icon shown in the share sheet preview (iOS squircle-masked; Android with a
  solid background fill)
- Custom title in the share sheet
- Example 1 — share a URL (on iOS the subtitle line is the URL's domain)
- Example 2 — share plain text (on iOS plain text has no subtitle — only the title; the
  text is still delivered to the receiving app)
- Web fallback using `navigator.share()`

## Project structure

```
src/plugin/
  share-preview.plugin.ts      TypeScript bridge (registerPlugin)
  share-preview.web.ts          Web fallback
src/app/home/
  home.page.ts / .html          Two-card demo UI

ios/App/App/
  SharePreviewPlugin.swift       iOS plugin (UIActivityViewController + LPLinkMetadata)
  MainViewController.swift        Registers the plugin via capacitorDidLoad()
  Assets.xcassets/ShareIcon.imageset   Icon used in the share preview

android/app/src/main/java/
  com/demo/shareplugin/SharePreviewPlugin.kt   Android plugin (ACTION_SEND + FileProvider)
  io/ionic/starter/MainActivity.java            Registers the plugin
android/app/src/main/res/drawable/share_icon.png   Icon used in the share preview
```

## Quick start

```bash
npm install
ionic build
npx cap sync

npx cap open ios       # Xcode: Clean Build Folder (Shift+Cmd+K), then Run
npx cap open android   # Android Studio: Sync Gradle, then Run
```

Runs on the iOS Simulator and on device. For iOS device builds set your own signing team
in Xcode (Signing & Capabilities); `DEVELOPMENT_TEAM` is intentionally left blank.

## Integrating into your own app

See **[INTEGRATION.md](INTEGRATION.md)** for a step-by-step guide, a risk assessment, and
every non-obvious gotcha — including the most important one:

> **Never name your `CAPBridgeViewController` subclass `ViewController`.** The generic name
> resolves to the wrong class at runtime and produces a black screen with no web content.
> Use a unique name (e.g. `MainViewController`) with `customModule="App"` in the storyboard.

## Notes

- `LPLinkMetadata` requires iOS 13+. It has a single text field (`title`); the gray
  subtitle is only ever the URL's host, so plain-text shares show no subtitle.
- Capacitor 8 uses Swift Package Manager — the plugin registers via the
  `CAPBridgedPlugin` protocol and `bridge.registerPluginInstance(...)`, not a `.m` macro.
- Android loads the icon from a plain PNG (`drawable/share_icon.png`), not the adaptive
  mipmap, and shares it as an image via Capacitor's `FileProvider`.
- The plugin is **inline** — no npm package to publish.
