import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'webview_runtime.g.dart';

@Riverpod(keepAlive: true)
class WebViewRuntime extends _$WebViewRuntime {
  InAppWebViewController? _controller;

  @override
  void build() {}

  void attach(InAppWebViewController controller) {
    _controller = controller;
  }

  void detach() {
    _controller = null;
  }

  // emit: ส่ง CustomEvent เข้าไปใน webview เป็นทาง Dart → JS
  // ใช้ async เพราะ evaluateJavascript() return Future
  Future<void> emit(String event, Object? payload) async {
    // อ่าน controller มาเก็บใน local variable เพื่อ Dart promote type จาก nullable → non-null
    final controller = _controller;
    // ถ้า controller ยังไม่ถูก attach (webview ยังไม่พร้อม) → ออกเงียบๆ ไม่ throw
    if (controller == null) return;
    // แปลง payload เป็น JSON string เพื่อ inline ลงใน source code ของ JS ที่จะ inject
    final json = jsonEncode(payload);
    // evaluateJavascript() = รัน JS code ใน webview ปัจจุบัน
    //   source: เป็น string ของ JS — เรา inject window.dispatchEvent() ยิง CustomEvent
    //   ฝั่ง JS (bridge.ts → onFlutterEvent) ใช้ window.addEventListener() ฟัง event ตัวนี้
    //   detail: $json คือ payload ที่ฝั่ง JS จะอ่านได้ผ่าน e.detail
    await controller.evaluateJavascript(
      source:
          "window.dispatchEvent(new CustomEvent('$event', { detail: $json }));",
    );
  }
}
