import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import 'chat_screen.dart';

/// First screen shown on every cold start: makes sure the .gguf model is on
/// disk (downloading it on first run) before the chat UI ever touches it.
class ModelSetupScreen extends StatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  State<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends State<ModelSetupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initializeModel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    if (chat.status == ModelLoadStatus.ready) {
      return const ChatScreen();
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌼', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              if (chat.status == ModelLoadStatus.error) ...[
                const Text(
                  'เตรียมมะลิไม่สำเร็จ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  chat.errorMessage ?? 'ไม่ทราบสาเหตุ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.read<ChatProvider>().initializeModel(),
                  child: const Text('ลองอีกครั้ง'),
                ),
              ] else ...[
                const Text(
                  'กำลังเตรียมมะลิให้พร้อมช่วยดูแลบ้านของคุณ',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: chat.downloadProgress),
                const SizedBox(height: 8),
                Text('${(chat.downloadProgress * 100).toStringAsFixed(0)}%'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
