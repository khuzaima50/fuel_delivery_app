import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fueldirect_app/l10n/app_localizations.dart';
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
            content: Text(AppLocalizations.of(context)!.chatSendError(e.toString())),
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
  String _dayLabel(DateTime dt, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return l10n.chatToday;
    if (d == today.subtract(const Duration(days: 1))) return l10n.chatYesterday;
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
    final l10n = AppLocalizations.of(context)!;
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
                  Text(
                    l10n.chatCustomer,
                    style: const TextStyle(
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
                    child: Text(l10n.chatError(snapshot.error.toString()),
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
                                l10n.chatNoMessagesTitle,
                                style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.chatNoMessagesSubtitle,
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

                    final bool isMe = msg['sender_id'] == _myId;
                    final bool prevIsMe =
                        prev != null && prev['sender_id'] == _myId;

                    // Show date separator when day changes
                    final showDateSep = prev == null ||
                        !_sameDay(
                            prev['created_at'], msg['created_at']);

                    // Grouped: less margin when same sender back-to-back
                    final bool isGrouped = prev != null &&
                        !showDateSep &&
                        prevIsMe == isMe;

                    return Column(
                      children: [
                        if (showDateSep) _buildDateSeparator(msg['created_at'], context),
                        _ChatBubble(
                          message: msg['message'] ?? '',
                          time: _formatTime(msg['created_at']),
                          isMe: isMe,
                          isGrouped: isGrouped,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ───────────────────────────────────────────────────
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String? iso, BuildContext context) {
    String label = '';
    if (iso != null) {
      try {
        label = _dayLabel(DateTime.parse(iso).toLocal(), context);
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

  Widget _buildInputBar(BuildContext context) {
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
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.chatMessageHint,
                    hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                    contentPadding: const EdgeInsets.symmetric(
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

  const _ChatBubble({
    required this.message,
    required this.time,
    required this.isMe,
    required this.isGrouped,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: isGrouped ? 2.0 : 8.0,
            bottom: 2.0,
          ),
          padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 6),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFE7FFDB) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isMe ? 12 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all,
                        size: 14,
                        color: Colors.blue,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
