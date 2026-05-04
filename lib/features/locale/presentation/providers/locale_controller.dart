import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/webview/webview_runtime.dart';

part 'locale_controller.g.dart';

// LocaleController: Notifier ที่เก็บ locale ปัจจุบันของแอป (state เป็น String 'en' หรือ 'th')
// JS ฝั่ง webview เรียก getLocale() ตอน mount เพื่ออ่านค่าเริ่มต้น
// AppBar switcher เรียก setLocale() เมื่อ user กด → state update + push event ไป webview อัตโนมัติ
@riverpod
class LocaleController extends _$LocaleController {
  @override
  String build() => 'en';

  // อ่าน locale ปัจจุบัน — เรียกใน addJavaScriptHandler('getLocale')
  String getLocale() => state;

  // เปลี่ยน locale + push ไปบอก webview ผ่าน CustomEvent
  // payload จะถูกอ่านฝั่ง JS ผ่าน e.detail (ดู bridge.ts → onFlutterEvent)
  Future<void> setLocale(String locale) async {
    state = locale;
    await ref.read(webViewRuntimeProvider.notifier).emit('flutter:locale', {
      'locale': locale,
    });
  }
}
