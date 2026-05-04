import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/webview/webview_runtime.dart';
import '../../../../core/webview/webview_url.dart';
import '../../../locale/presentation/providers/locale_controller.dart';
import '../providers/greeting_controller.dart';

// ใช้ ConsumerStatefulWidget เพราะต้อง override dispose() เพื่อ detach controller
// ออกจาก WebViewRuntime ตอนหน้าโดน pop — ถ้าไม่ทำ runtime จะถือ reference ของ
// InAppWebViewController ที่ถูก dispose แล้ว แล้วครั้งถัดไปที่ emit() จะ throw
// "InAppWebViewController was used after being disposed"
class WebViewScreen extends ConsumerStatefulWidget {
  const WebViewScreen({super.key});

  @override
  ConsumerState<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends ConsumerState<WebViewScreen> {
  // cache notifier ไว้ตั้งแต่ initState — ใน dispose() ใช้ ref ไม่ได้แล้ว
  // (Riverpod throw "Cannot use ref after the widget was disposed")
  // WebViewRuntime ใช้ keepAlive:true → instance เดียวตลอดอายุแอป → cache ปลอดภัย
  late final WebViewRuntime _runtime;

  @override
  void initState() {
    super.initState();
    _runtime = ref.read(webViewRuntimeProvider.notifier);
  }

  @override
  void dispose() {
    // ปลด reference ของ controller ก่อนที่ Flutter framework จะ dispose มัน
    // หลังจากนี้ emit() ใน WebViewRuntime จะเห็น _controller == null และ return เงียบๆ
    _runtime.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JS Bridge POC')),
      body: SafeArea(
        child: InAppWebView(
          // devServerUrl() คืน 10.0.2.2:5173 (Android) หรือ localhost:5173 (iOS/macOS)
          initialUrlRequest: URLRequest(url: WebUri(devServerUrl())),
          initialSettings: InAppWebViewSettings(
            // เปิด JavaScript
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            // ทำให้พื้นหลัง webview โปร่งใส
            transparentBackground: true,
          ),
          onWebViewCreated: (controller) {
            // เก็บ controller ลงใน WebViewRuntime provider เพื่อให้ method push() ใน greeting_controller
            // เรียก emit() บนตัวนี้ได้ภายหลัง
            ref.read(webViewRuntimeProvider.notifier).attach(controller);

            // ลงทะเบียน handler ฝั่ง Dart ให้ฝั่ง JS เรียก
            // JS จะเรียกผ่าน window.flutter_inappwebview.callHandler('getGreeting', ...args)
            controller.addJavaScriptHandler(
              // ชื่อ handler — ต้องตรงกับฝั่ง JS
              handlerName: 'getGreeting',
              // callback รับ List<dynamic> args จาก JS — return อะไรก็ได้ จะถูก serialize กลับเป็น JS Promise
              callback: (args) {
                final name = args.isNotEmpty ? args.first as String? : null;
                return ref
                    .read(greetingControllerProvider.notifier)
                    .getGreeting(name: name);
              },
            );

            // handler 'getLocale' — JS เรียกตอน mount เพื่ออ่าน locale เริ่มต้นจาก Flutter
            // delegate ไปที่ LocaleController โดยไม่มี logic ใน callback (Pure UI)
            controller.addJavaScriptHandler(
              handlerName: 'getLocale',
              callback: (args) {
                return ref
                    .read(localeControllerProvider.notifier)
                    .getLocale();
              },
            );
          },
          // onConsoleMessage รับ console.log / warn / error จาก JS มา print ใน Flutter terminal
          // มีประโยชน์มากตอน debug bridge — เห็น log ของ JS ได้เลย
          onConsoleMessage: (_, msg) {
            debugPrint('[webview] ${msg.messageLevel}: ${msg.message}');
          },
        ),
      ),
      // FAB ที่กดแล้วยิง event ไปฝั่ง JS เพื่อทดสอบทาง Dart → JS
      floatingActionButton: FloatingActionButton.extended(
        // onPressed callback — ใช้ ref.read (ไม่ใช่ .watch) เพราะอยู่ใน callback ไม่ใช่ใน build()
        onPressed: () {
          // เรียก push() บน controller — controller จะเรียก WebViewRuntime.emit() ต่อ
          // ส่ง name 'Webview' เข้าไป → JS จะได้รับข้อความ 'Hello from Flutter, Webview!'
          ref.read(greetingControllerProvider.notifier).push(name: 'Webview');
        },
        icon: const Icon(Icons.send),
        label: const Text('Push to JS'),
      ),
    );
  }
}
