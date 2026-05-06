import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String orderId;
  final String customerId;
  final String customerName;

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient _supabase = Supabase.instance.client;
  late final String _myId;
  bool _isSending = false;
  bool _hasText = false;

  // Brand colours
  static const Color _orange = Color(0xFFFF4D00);
  static const Color _orangeLight = Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _myId = _supabase.auth.currentUser?.id ?? '';
    _messageController.addListener(() {
      final has = _messageController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Send ──────────────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _myId.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'order_id': widget.orderId,
        'sender_id': _myId,
        'receiver_id': widget.customerId,
        'message': text,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      NotificationService.notifyChatMessage(
        receiverId: widget.customerId,
        receiverType: 'user',
        messageText: text,
        orderId: widget.orderId,
      );

      _scrollToBottom();
    } catch (e) {
      debugPrint('[Chat] Error sending: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return '';
    }
  }

  /// Returns a label like "Today", "Yesterday", or "Mon, 5 May"
  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(dt);
  }

  bool _sameDay(String? a, String? b) {
    if (a == null || b == null) return false;
    try {
      final da = DateTime.parse(a).toLocal();
      final db = DateTime.parse(b).toLocal();
      return da.year == db.year && da.month == db.month && da.day == db.day;
    } catch (_) {
      return false;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final initials = widget.customerName.isNotEmpty
        ? widget.customerName.trim()[0].toUpperCase()
        : 'C';

    return Scaffold(
      backgroundColor: const Color(0xFFEFE7DD), // WhatsApp-style warm beige
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: _orangeLight,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Customer',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Message list ────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('order_id', widget.orderId)
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _orange),
                  );
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Start the conversation below',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll on new data
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final prev =
                        index > 0 ? messages[index - 1] : null;
                    final next = index < messages.length - 1
                        ? messages[index + 1]
                        : null;

                    final bool isMe = msg['sender_id'] == _myId;
                    final bool prevIsMe =
                        prev != null && prev['sender_id'] == _myId;
                    final bool nextIsMe =
                        next != null && next['sender_id'] == _myId;

                    // Show date separator when day changes
                    final showDateSep = prev == null ||
                        !_sameDay(
                            prev['created_at'], msg['created_at']);

                    // Grouped: less margin when same sender back-to-back
                    final bool isGrouped = prev != null &&
                        !showDateSep &&
                        prevIsMe == isMe;
                    final bool isLastInGroup = next == null ||
                        nextIsMe != isMe ||
                        !_sameDay(
                            msg['created_at'], next['created_at']);

                    return Column(
                      children: [
                        if (showDateSep) _buildDateSeparator(msg['created_at']),
                        _ChatBubble(
                          message: msg['message'] ?? '',
                          time: _formatTime(msg['created_at']),
                          isMe: isMe,
                          isGrouped: isGrouped,
                          isLastInGroup: isLastInGroup,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ───────────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String? iso) {
    String label = '';
    if (iso != null) {
      try {
        label = _dayLabel(DateTime.parse(iso).toLocal());
      } catch (_) {}
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFCCBBAA))),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDDD6CE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B6B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: Color(0xFFCCBBAA))),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF0F0F0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(fontSize: 15, height: 1.4),
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _hasText
                    ? const Color(0xFFFF4D00)
                    : const Color(0xFFBBBBBB),
                shape: BoxShape.circle,
                boxShadow: _hasText
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF4D00)
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: (_hasText && !_isSending) ? _sendMessage : null,
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chat Bubble Widget ────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;
  final bool isGrouped;
  final bool isLastInGroup;

  const _ChatBubble({
    required this.message,
    required this.time,
    required this.isMe,
    required this.isGrouped,
    required this.isLastInGroup,
  });

  static const Color _sentBg = Color(0xFFFF4D00);
  static const Color _receivedBg = Color(0xFFFFFFFF);
  static const double _radius = 18;
  static const double _tailRadius = 4;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Avatar dimensions (received side only)
    const double avatarWidth = 28;
    const double avatarGap = 6;

    // Maximum bubble width — leave room for avatar on received side
    final double maxBubbleWidth = screenWidth * 0.70;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      margin: EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: isMe ? _sentBg : _receivedBg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(_radius),
          topRight: const Radius.circular(_radius),
          bottomLeft: isMe
              ? const Radius.circular(_radius)
              : (isLastInGroup
                  ? const Radius.circular(_tailRadius)
                  : const Radius.circular(_radius)),
          bottomRight: isMe
              ? (isLastInGroup
                  ? const Radius.circular(_tailRadius)
                  : const Radius.circular(_radius))
              : const Radius.circular(_radius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message text
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF1C1C1C),
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Timestamp + tick
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : const Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 3),
                Icon(
                  Icons.done_all_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (isMe) {
      // Sent: flush right with a small right margin, large left push
      return Padding(
        padding: EdgeInsets.only(
          top: isGrouped ? 2 : 6,
          left: 56, // min gap from left edge
          right: 8,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: bubble,
        ),
      );
    }

    // Received: avatar + bubble, flush left
    return Padding(
      padding: EdgeInsets.only(
        top: isGrouped ? 2 : 6,
        left: 8,
        right: 56, // min gap from right edge
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar slot — always takes up width to keep alignment consistent
          SizedBox(
            width: avatarWidth,
            height: avatarWidth,
            child: isLastInGroup
                ? CircleAvatar(
                    radius: avatarWidth / 2,
                    backgroundColor:
                        const Color(0xFFFF4D00).withValues(alpha: 0.15),
                    child: const Icon(Icons.person,
                        size: 16, color: Color(0xFFFF4D00)),
                  )
                : const SizedBox(),
          ),
          const SizedBox(width: avatarGap),
          // Bubble
          bubble,
        ],
      ),
    );
  }
}
