import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hostCtrl.text = prefs.getString('host') ?? Config.defaultHost;
      _portCtrl.text =
          (prefs.getInt('port') ?? Config.defaultPort).toString();
    });
  }

  Future<void> _save() async {
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? Config.defaultPort;
    await Config.save(host, port);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sauvegarde'),
          backgroundColor: Color(0xFF161616),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        foregroundColor: const Color(0xFFDCDCDC),
        title: const Text('Parametres',
            style: TextStyle(
                fontSize: 13,
                letterSpacing: 1,
                color: Color(0xFF555555))),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1F1F1F)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Adresse du serveur',
                style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 12,
                    letterSpacing: 0.5)),
            const SizedBox(height: 16),
            _Field(
                label: 'IP',
                ctrl: _hostCtrl,
                hint: Config.defaultHost),
            const SizedBox(height: 12),
            _Field(
                label: 'Port',
                ctrl: _portCtrl,
                hint: '8000',
                numeric: true),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F7EF7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Sauvegarder',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final bool numeric;

  const _Field({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF555555), fontSize: 11)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1F1F1F)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType:
                numeric ? TextInputType.number : TextInputType.text,
            style: const TextStyle(
                color: Color(0xFFDCDCDC), fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Color(0xFF555555)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}