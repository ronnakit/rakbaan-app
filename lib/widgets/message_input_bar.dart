import 'package:flutter/material.dart';

class MessageInputBar extends StatefulWidget {
  const MessageInputBar({
    super.key,
    required this.onSend,
    required this.enabled,
  });

  final ValueChanged<String> onSend;
  final bool enabled;

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  void _onMicPressed() {
    // Placeholder: wire up the `speech_to_text` package here to fill
    // _controller.text with the recognized Thai speech, then optionally
    // call _submit(). Left as a stub since speech-to-text needs its own
    // microphone-permission flow and on-device testing.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ฟีเจอร์พูดสั่งงานจะเปิดให้ใช้ในเวอร์ชันถัดไปค่ะ')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'พูดถามมะลิ',
              onPressed: widget.enabled ? _onMicPressed : null,
              icon: const Icon(Icons.mic_none_rounded),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'พิมพ์คำถามเกี่ยวกับการซ่อมบ้าน...',
                  filled: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              tooltip: 'ส่งคำถาม',
              onPressed: widget.enabled ? _submit : null,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
