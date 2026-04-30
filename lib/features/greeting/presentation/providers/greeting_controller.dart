import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/webview/webview_runtime.dart';

part 'greeting_controller.g.dart';

@riverpod
class GreetingController extends _$GreetingController {
  @override
  String build() => 'Hello from Flutter';

  String getGreeting({String? name}) {
    if (name == null || name.isEmpty) return state;
    return '$state, $name!';
  }

  Future<void> push({String? name}) async {
    final message = getGreeting(name: name);
    await ref.read(webViewRuntimeProvider.notifier).emit('flutter:greeting', {
      'message': message,
    });
  }
}
