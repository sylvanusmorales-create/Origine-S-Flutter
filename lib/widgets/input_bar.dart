import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class InputBar extends StatefulWidget {
  final bool isStreaming;
  final Function(String) onSend;
  final VoidCallback onStop;

  const InputBar({
    super.key,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _ctrl = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  bool _listening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _speech.initialize().then((v) {
      if (mounted) setState(() => _speechAvailable = v);
    });
  }

  void _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!_speechAvailable) return;
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            _ctrl.text = result.recognizedWords;
            _listening = false;
          });
        }
      },
      localeId: 'fr_FR',
    );
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.isStreaming) return;
    widget.onSend(text);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0B0B),
        border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Btn(
            icon: _listening ? Icons.mic : Icons.mic_none,
            color: _listening
                ? const Color(0xFFC04040)
                : const Color(0xFF555555),
            onTap: _toggleVoice,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1F1F1F)),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                    color: Color(0xFFDCDCDC), fontSize: 14, height: 1.5),
                decoration: const InputDecoration(
                  hintText: 'Envoie un message...',
                  hintStyle:
                      TextStyle(color: Color(0xFF555555), fontSize: 14),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          widget.isStreaming
              ? _Btn(
                  icon: Icons.stop_rounded,
                  color: const Color(0xFFDCDCDC),
                  filled: true,
                  onTap: widget.onStop,
                )
              : _Btn(
                  icon: Icons.arrow_forward_rounded,
                  color: Colors.white,
                  filled: true,
                  primary: true,
                  onTap: _send,
                ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool filled;
  final bool primary;
  final VoidCallback onTap;

  const _Btn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: primary
              ? const Color(0xFF4F7EF7)
              : (filled ? const Color(0xFF1F1F1F) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: filled
              ? null
              : Border.all(color: const Color(0xFF1F1F1F)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}