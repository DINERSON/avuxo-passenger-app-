import 'package:flutter/material.dart';

class RideChatSheet extends StatefulWidget {
  const RideChatSheet({
    super.key,
    required this.messages,
    required this.onSend,
  });

  final List<Map<String, dynamic>> messages;
  final void Function(String text) onSend;

  @override
  State<RideChatSheet> createState() => _RideChatSheetState();
}

class _RideChatSheetState extends State<RideChatSheet> {
  static const Color avuxoGreen = Color(0xFF24F877);

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<Map<String, dynamic>> localMessages = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(covariant RideChatSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    localMessages.removeWhere((local) {
      final localText = _text(local).toLowerCase();

      return widget.messages.any(
        (msg) =>
            _isPassenger(msg) &&
            _text(msg).toLowerCase() == localText,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  bool _isPassenger(Map<String, dynamic> msg) {
    final sender = '${msg['sender'] ?? msg['from'] ?? msg['role'] ?? ''}'
        .trim()
        .toLowerCase();

    return sender == 'passenger' ||
        sender == 'cliente' ||
        sender == 'user';
  }

  String _text(Map<String, dynamic> msg) {
    return '${msg['message'] ?? msg['text'] ?? msg['body'] ?? ''}'.trim();
  }

  String _createdAt(Map<String, dynamic> msg) {
    return '${msg['createdAt'] ?? msg['created_at'] ?? msg['time'] ?? ''}';
  }

  String _keyOf(Map<String, dynamic> msg) {
    final id = '${msg['id'] ?? msg['_id'] ?? ''}'.trim();

    if (id.isNotEmpty && id != 'null') {
      return id;
    }

    return '${_isPassenger(msg)}-${_text(msg)}-${_createdAt(msg)}';
  }

  List<Map<String, dynamic>> get _allMessages {
    final merged = <Map<String, dynamic>>[];
    final keys = <String>{};

    for (final msg in widget.messages) {
      final text = _text(msg);

      if (text.isEmpty) continue;

      final key = _keyOf(msg);

      if (keys.add(key)) {
        merged.add(msg);
      }
    }

    for (final local in localMessages) {
      final text = _text(local);

      if (text.isEmpty) continue;

      final existsInServer = widget.messages.any((msg) {
        return _isPassenger(msg) &&
            _text(msg).toLowerCase() == text.toLowerCase();
      });

      if (existsInServer) continue;

      final key = _keyOf(local);

      if (keys.add(key)) {
        merged.add(local);
      }
    }

    merged.sort((a, b) {
      final aTime = DateTime.tryParse(_createdAt(a)) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final bTime = DateTime.tryParse(_createdAt(b)) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return aTime.compareTo(bTime);
    });

    return merged;
  }

  void _send() {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    controller.clear();

    final localMessage = {
      'id': 'local-${DateTime.now().microsecondsSinceEpoch}',
      'sender': 'passenger',
      'from': 'passenger',
      'role': 'passenger',
      'message': text,
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
      'local': true,
    };

    setState(() {
      localMessages.add(localMessage);
    });

    widget.onSend(text);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (!mounted || !scrollController.hasClients) return;

    Future.delayed(
      const Duration(milliseconds: 50),
      () {
        if (!mounted || !scrollController.hasClients) return;

        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _allMessages;

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, sheetScrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0B1117),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Chat da corrida',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma mensagem ainda.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final mine = _isPassenger(msg);
                          final text = _text(msg);

                          if (text.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.72,
                              ),
                              decoration: BoxDecoration(
                                color: mine ? avuxoGreen : Colors.white10,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(mine ? 18 : 4),
                                  bottomRight: Radius.circular(mine ? 4 : 18),
                                ),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: mine ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: 'Digite sua mensagem...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _send,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: avuxoGreen,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}