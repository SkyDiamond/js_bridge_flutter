import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../greeting/presentation/screens/webview_screen.dart';
import '../../../locale/presentation/providers/locale_controller.dart';

// HomeScreen: หน้าแรกของแอป — มี 2 ส่วน
//   1) Toggle เปลี่ยนภาษา TH/EN (อ่าน/เขียน LocaleController)
//   2) ปุ่ม "Open WebView" — push WebViewScreen ไปแสดงเว็บใน webview
// เมื่อ webview เปิด JS จะเรียก getLocale() เพื่อ sync ภาษาเริ่มต้นจาก state ปัจจุบัน
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('JS Bridge POC')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ส่วนที่ 1: เลือกภาษา
              Text(
                'Language',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // SegmentedButton: แสดง 2 ตัวเลือก EN/TH ด้วย UI แบบ toggle
              // selected: ค่าที่ active อยู่ (ต้องเป็น Set แม้จะเลือกได้ตัวเดียว)
              // onSelectionChanged: callback ที่ได้ Set<String> ของค่าที่เลือก
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'en', label: Text('EN')),
                  ButtonSegment(value: 'th', label: Text('TH')),
                ],
                selected: {locale},
                onSelectionChanged: (selection) {
                  // selection.first ปลอดภัย เพราะ multiSelectionEnabled default = false
                  // → SegmentedButton บังคับให้ Set มีสมาชิก 1 ตัวเสมอ
                  ref
                      .read(localeControllerProvider.notifier)
                      .setLocale(selection.first);
                },
              ),

              const SizedBox(height: 32),

              // ส่วนที่ 2: ปุ่มเปิด webview
              Text(
                'WebView',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  // push หน้า WebViewScreen เข้าไปใน navigation stack
                  // pop กลับมาเมื่อกดปุ่ม back ของระบบ → state ของ LocaleController ยังอยู่
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WebViewScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open WebView'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
