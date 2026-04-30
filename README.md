# js_bridge_flutter

Flutter app ที่ host **WebView** สำหรับโหลดเว็บ Preact แล้วเปิด **JS bridge** ให้สื่อสารกับ Dart
ทำงานคู่กับโปรเจกต์ `js_bridge_vite_preact` (เว็บที่ถูกโหลดใน WebView)

## ทำอะไร

1. **JS → Dart พร้อม return value** — เว็บใน webview เรียก Dart function (`getGreeting(name?)`) แล้วรับ `Promise<string>` กลับ
2. **Dart → JS push event** — Dart ยิง `CustomEvent` เข้าไปใน webview ผ่าน `evaluateJavascript()`

ทุก logic อยู่ใน Riverpod controller (Pure UI principle) — widget เป็นแค่ presentation

---

## Tech Stack

| Package | Version | ใช้ทำอะไร |
|---|---|---|
| `flutter_inappwebview` | ^6.1.5 | WebView ที่มี `addJavaScriptHandler` + `evaluateJavascript` ครบ |
| `flutter_riverpod` | ^2.5.1 | State management (Notifier 2.x) |
| `riverpod_annotation` | ^2.3.5 | `@riverpod` annotation สำหรับ codegen |
| `build_runner` + `riverpod_generator` | (dev) | สร้าง `*.g.dart` files |

---

## โครงสร้างไฟล์

```
lib/
├── main.dart                                       # entry point — ProviderScope + runApp
├── app.dart                                        # MaterialApp wrapper
├── core/
│   └── webview/
│       ├── webview_url.dart                        # devServerUrl() เลือก URL ตาม platform
│       ├── webview_runtime.dart                    # Notifier เก็บ InAppWebViewController + emit()
│       └── webview_runtime.g.dart                  # generated
└── features/
    └── greeting/
        └── presentation/
            ├── providers/
            │   ├── greeting_controller.dart        # Notifier: getGreeting(name?), push(name?)
            │   └── greeting_controller.g.dart      # generated
            └── screens/
                └── webview_screen.dart             # ConsumerWidget host webview + register handler
```

ใช้ **feature-first architecture** ตามแนวทาง Riverpod (skip domain layer สำหรับ POC)

---

## วิธีรัน

ต้องเปิด Vite dev server จาก `js_bridge_vite_preact/` ให้ฟัง `:5173` ก่อน

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # ครั้งแรก หรือเมื่อแก้ provider
flutter run                                                # เลือก iOS sim หรือ Android emulator
```

ระหว่างพัฒนา provider ใหม่ๆ ใช้:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## URL ที่ webview จะโหลด

`lib/core/webview/webview_url.dart` resolve ตาม platform:

| Platform | URL | เหตุผล |
|---|---|---|
| Android emulator | `http://10.0.2.2:5173` | `10.0.2.2` = magic IP ที่ map ไปยัง host's IPv4 loopback |
| iOS simulator / macOS | `http://localhost:5173` | simulator share network กับ host โดยตรง |
| Real device | ต้องแก้เป็น LAN IP เอง | ไม่มี magic IP ให้ใช้ |

---

## Native config ที่จำเป็น

เพราะ dev server เป็น HTTP (cleartext) ต้องเปิดสิทธิ์ทั้งสอง OS:

### Android — `android/app/src/main/AndroidManifest.xml`
```xml
<application ... android:usesCleartextTraffic="true">
```

### iOS — `ios/Runner/Info.plist`
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

---

## Bridge code map

### JS → Dart handler registration (`webview_screen.dart`)

```dart
controller.addJavaScriptHandler(
  handlerName: 'getGreeting',
  callback: (args) {
    final name = args.isNotEmpty ? args.first as String? : null;
    return ref
        .read(greetingControllerProvider.notifier)
        .getGreeting(name: name);
  },
);
```

หลัก: handler delegate ไปที่ Notifier ทันที — ไม่ใส่ logic ใน callback (Pure UI)

### Dart → JS push (`webview_runtime.dart`)

```dart
await controller.evaluateJavascript(
  source: "window.dispatchEvent(new CustomEvent('$event', { detail: $json }));",
);
```

ใช้ `evaluateJavascript()` ยิง `CustomEvent` ที่ฝั่ง JS subscribe ผ่าน `addEventListener`

---

## Riverpod patterns ที่ใช้

- **`@Riverpod(keepAlive: true)`** สำหรับ `WebViewRuntime` — ต้องคงอยู่ตลอดอายุ webview
- **`@riverpod`** (autoDispose default) สำหรับ `GreetingController` — state เป็นแค่ string
- **`ref.read(...notifier).method()`** ใน callback (ไม่ใช่ใน `build()`)
- **`ConsumerWidget`** แทน `ConsumerStatefulWidget` — ไม่มี local widget state

---

## Verify

```bash
flutter analyze       # No issues found
flutter test          # widget smoke test
```
