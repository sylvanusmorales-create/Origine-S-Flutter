import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_bar.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final WsService _ws = WsService();
  final ScrollController _scroll = ScrollController();
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  List<Conversation> _conversations = [];
  Conversation? _current;
  List<Message> _messages = [];
  bool _streaming = false;
  bool _online = false;
  String? _toolLabel;
  int? _streamIdx;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final online = await ApiService.checkHealth();
    if (mounted) setState(() => _online = online);
    await _loadConvs();
  }

  Future<void> _loadConvs() async {
    try {
      final convs = await ApiService.getConversations();
      if (!mounted) return;
      setState(() => _conversations = convs);
      if (convs.isNotEmpty && _current == null) {
        await _openConv(convs.first);
      }
    } catch (_) {}
  }

  Future<void> _openConv(Conversation conv) async {
    if (_streaming) return;
    _ws.disconnect();
    try {
      final msgs = await ApiService.getMessages(conv.id);
      if (!mounted) return;
      setState(() {
        _current = conv;
        _messages = msgs;
        _streaming = false;
        _toolLabel = null;
        _streamIdx = null;
      });
      _scrollBottom();
      _connectWs(conv.id);
    } catch (_) {}
  }

  void _connectWs(int convId) {
    _ws.onEvent = _onWsEvent;
    _ws.connect(convId);
    setState(() => _online = true);
  }

  void _onWsEvent(Map<String, dynamic> e) {
    if (!mounted) return;
    switch (e['type'] as String) {
      case 'tool_start':
        setState(() => _toolLabel = _tLabel(e['name'] ?? ''));
        break;

      case 'tool_end':
        setState(() => _toolLabel = null);
        break;

      case 'token':
        final chunk = e['content'] as String? ?? '';
        if (_streamIdx == null) {
          setState(() {
            _messages.add(
                Message(role: 'assistant', content: chunk, isStreaming: true));
            _streamIdx = _messages.length - 1;
          });
        } else {
          setState(() {
            _messages[_streamIdx!] = Message(
              role: 'assistant',
              content: _messages[_streamIdx!].content + chunk,
              isStreaming: true,
            );
          });
        }
        _scrollBottom();
        break;

      case 'done':
        if (_streamIdx != null) {
          setState(() {
            _messages[_streamIdx!] = Message(
              id: e['msg_id'],
              role: 'assistant',
              content: _messages[_streamIdx!].content,
              isStreaming: false,
            );
            _streamIdx = null;
          });
        }
        setState(() {
          _streaming = false;
          _toolLabel = null;
        });
        break;

      case 'stopped':
        if (_streamIdx != null) {
          setState(() {
            _messages[_streamIdx!] = Message(
              role: 'assistant',
              content: _messages[_streamIdx!].content,
              isStreaming: false,
            );
            _streamIdx = null;
          });
        }
        setState(() {
          _streaming = false;
          _toolLabel = null;
        });
        break;

      case 'title':
        final title = e['title'] as String? ?? '';
        setState(() {
          final idx = _conversations.indexWhere((c) => c.id == _current?.id);
          if (idx >= 0) _conversations[idx].title = title;
          if (_current != null) {
            _current = Conversation(
              id: _current!.id,
              title: title,
              createdAt: _current!.createdAt,
              updatedAt: _current!.updatedAt,
            );
          }
        });
        break;

      case 'error':
        setState(() {
          _streaming = false;
          _toolLabel = null;
          _streamIdx = null;
        });
        break;

      case 'disconnected':
        setState(() => _online = false);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _current != null) _connectWs(_current!.id);
        });
        break;
    }
  }

  String _tLabel(String name) {
    switch (name) {
      case 'web_search':
        return 'Recherche web...';
      case 'run_python':
        return 'Execution Python...';
      default:
        return '$name...';
    }
  }

  void _send(String content) async {
    if (_streaming) return;
    if (_current == null) {
      await _newConv();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!_ws.isConnected) return;
    setState(() {
      _streaming = true;
      _messages.add(Message(role: 'user', content: content));
    });
    _scrollBottom();
    _ws.sendMessage(content);
  }

  void _stop() => _ws.stop();

  Future<void> _newConv() async {
    if (_streaming) return;
    try {
      final conv = await ApiService.createConversation();
      if (!mounted) return;
      setState(() {
        _conversations.insert(0, conv);
        _current = conv;
        _messages = [];
      });
      _connectWs(conv.id);
    } catch (_) {}
  }

  Future<void> _deleteConv(Conversation conv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Supprimer',
            style: TextStyle(color: Color(0xFFDCDCDC), fontSize: 15)),
        content: const Text('Supprimer cette conversation ?',
            style: TextStyle(color: Color(0xFF555555))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF555555))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFC04040))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ApiService.deleteConversation(conv.id);
    setState(() {
      _conversations.removeWhere((c) => c.id == conv.id);
      if (_current?.id == conv.id) {
        _current = null;
        _messages = [];
        _ws.disconnect();
      }
    });
    if (_conversations.isNotEmpty) _openConv(_conversations.first);
  }

  Future<void> _renameConv(Conversation conv) async {
    final ctrl = TextEditingController(text: conv.title);
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Renommer',
            style: TextStyle(color: Color(0xFFDCDCDC), fontSize: 15)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Color(0xFFDCDCDC)),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF1F1F1F))),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF4F7EF7))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF555555))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('OK',
                style: TextStyle(color: Color(0xFF4F7EF7))),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    await ApiService.renameConversation(conv.id, title);
    setState(() {
      final idx = _conversations.indexWhere((c) => c.id == conv.id);
      if (idx >= 0) _conversations[idx].title = title;
      if (_current?.id == conv.id) {
        _current = Conversation(
          id: conv.id,
          title: title,
          createdAt: conv.createdAt,
          updatedAt: conv.updatedAt,
        );
      }
    });
  }

  void _showMemory() async {
    try {
      final data = await ApiService.getMemory();
      final interactions = data['interactions'] as List? ?? [];
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF111111),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          side: BorderSide(color: Color(0xFF1F1F1F)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('MEMOIRE',
                  style: TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 11,
                      letterSpacing: 1.5)),
              const SizedBox(height: 12),
              if (interactions.isEmpty)
                const Text('Aucune interaction memorisee.',
                    style: TextStyle(color: Color(0xFF555555)))
              else
                ...interactions.reversed.take(10).map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${(i['timestamp'] as String).substring(0, 10)}  —  ${_truncate(i['message'] as String, 80)}',
                        style: const TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 12,
                            height: 1.6),
                      ),
                    )),
            ],
          ),
        ),
      );
    } catch (_) {}
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}...' : s;

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showOptions(Conversation conv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: Color(0xFF1F1F1F)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined,
                color: Color(0xFFDCDCDC), size: 18),
            title: const Text('Renommer',
                style: TextStyle(color: Color(0xFFDCDCDC), fontSize: 14)),
            onTap: () {
              Navigator.pop(ctx);
              _renameConv(conv);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline,
                color: Color(0xFFC04040), size: 18),
            title: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFC04040), fontSize: 14)),
            onTap: () {
              Navigator.pop(ctx);
              _deleteConv(conv);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ws.disconnect();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      backgroundColor: const Color(0xFF0B0B0B),
      drawer: _drawer(),
      appBar: _appBar(),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _welcome()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount:
                        _messages.length + (_toolLabel != null ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (_toolLabel != null && i == _messages.length) {
                        return _toolIndicator();
                      }
                      return MessageBubble(
                        key: ValueKey('m$i'),
                        message: _messages[i],
                        isStreaming: _messages[i].isStreaming,
                      );
                    },
                  ),
          ),
          InputBar(
            isStreaming: _streaming,
            onSend: _send,
            onStop: _stop,
          ),
        ],
      ),
    );
  }

  Widget _welcome() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('ORIGINE S',
              style: TextStyle(
                  color: Color(0xFFDCDCDC),
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 6)),
          SizedBox(height: 8),
          Text('Agent IA Personnel',
              style: TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 13,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _toolIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: Color(0xFF4F7EF7)),
          ),
          const SizedBox(width: 8),
          Text(_toolLabel ?? '',
              style: const TextStyle(
                  color: Color(0xFF4F7EF7), fontSize: 12)),
        ],
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0B0B0B),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Color(0xFF555555), size: 20),
        onPressed: () => _key.currentState?.openDrawer(),
      ),
      title: Text(
        _current?.title ?? 'Origine S',
        style: const TextStyle(
            color: Color(0xFF555555),
            fontSize: 13,
            fontWeight: FontWeight.w400),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Center(
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _online
                    ? const Color(0xFF3A7D44)
                    : const Color(0xFF3C3C3C),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: _showMemory,
          child: const Text('MEM',
              style: TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 11,
                  letterSpacing: 0.5)),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: Color(0xFF555555), size: 18),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SettingsScreen())),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFF1F1F1F)),
      ),
    );
  }

  Widget _drawer() {
    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFF1F1F1F))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ORIGINE S',
                    style: TextStyle(
                        color: Color(0xFFDCDCDC),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2)),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _newConv();
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFF1F1F1F)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.add,
                        color: Color(0xFFDCDCDC), size: 16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _conversations.isEmpty
                ? const Center(
                    child: Text('Aucune conversation',
                        style: TextStyle(
                            color: Color(0xFF555555), fontSize: 12)))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _conversations.length,
                    itemBuilder: (ctx, i) {
                      final conv = _conversations[i];
                      final active = conv.id == _current?.id;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _openConv(conv);
                        },
                        onLongPress: () => _showOptions(conv),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF161616)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            conv.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active
                                  ? const Color(0xFFDCDCDC)
                                  : const Color(0xFF555555),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}