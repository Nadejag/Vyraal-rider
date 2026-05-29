import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../firebase_database_refs.dart';

class RiderOrderChatSheet extends StatefulWidget {
  const RiderOrderChatSheet({
    required this.orderId,
    required this.title,
    super.key,
  });

  final String orderId;
  final String title;

  static void show(
    BuildContext context, {
    required String orderId,
    required String title,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RiderOrderChatSheet(orderId: orderId, title: title),
    );
  }

  @override
  State<RiderOrderChatSheet> createState() => _RiderOrderChatSheetState();
}

class _RiderOrderChatSheetState extends State<RiderOrderChatSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final key = _firebaseKey(widget.orderId);
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 12),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFD84E),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFF1F1600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          widget.orderId,
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE4E7EC)),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: vyraalDatabase.ref('orderChats/$key/messages').onValue,
                builder: (context, snapshot) {
                  final messages = _messagesFromSnapshot(
                    snapshot.data?.snapshot,
                  );
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet. Send a live update to customer.',
                        style: TextStyle(color: Color(0xFF667085)),
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(14),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isMine = message.senderId == _currentUid();
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.68,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? const Color(0xFFFFD84E)
                                : const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            message.text,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Message customer...',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD84E),
                      foregroundColor: const Color(0xFF1F1600),
                    ),
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final key = _firebaseKey(widget.orderId);
    final ref = vyraalDatabase.ref('orderChats/$key/messages').push();
    final message = {
      'id': ref.key,
      'orderId': widget.orderId,
      'senderId': _currentUid(),
      'senderRole': 'rider',
      'senderName': _currentName(),
      'text': text,
      'createdAt': ServerValue.timestamp,
    };
    await vyraalDatabase.ref().update({
      'orderChats/$key/orderId': widget.orderId,
      'orderChats/$key/updatedAt': ServerValue.timestamp,
      'orderChats/$key/lastMessage': text,
      'orderChats/$key/lastSenderRole': 'rider',
      'orderChats/$key/messages/${ref.key}': message,
      'orders/$key/chatLastMessage': text,
      'orders/$key/chatUpdatedAt': ServerValue.timestamp,
      'deliveryRequests/$key/chatLastMessage': text,
      'deliveryRequests/$key/chatUpdatedAt': ServerValue.timestamp,
    });
  }

  List<_RiderChatMessage> _messagesFromSnapshot(DataSnapshot? snapshot) {
    final value = snapshot?.value;
    if (value is! Map) return const [];
    final messages = <_RiderChatMessage>[];
    for (final raw in value.values) {
      if (raw is! Map) continue;
      final data = Map<String, dynamic>.from(raw);
      messages.add(
        _RiderChatMessage(
          senderId: data['senderId'] as String? ?? '',
          text: data['text'] as String? ?? '',
          createdAt: (data['createdAt'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  String _firebaseKey(String value) {
    return value.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
  }

  String _currentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'rider';
    } catch (_) {
      return 'rider';
    }
  }

  String _currentName() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      return user?.displayName ?? user?.phoneNumber ?? 'Vyraal rider';
    } catch (_) {
      return 'Vyraal rider';
    }
  }
}

class _RiderChatMessage {
  const _RiderChatMessage({
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String senderId;
  final String text;
  final int createdAt;
}
