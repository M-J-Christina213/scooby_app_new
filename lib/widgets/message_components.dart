import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Widget to show last message preview for a booking
class LastMessagePreview extends StatelessWidget {
  const LastMessagePreview({super.key, required this.bookingId});
  
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;
    return FutureBuilder(
      future: sb
          .from('messages')
          .select('body, sender, created_at')
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) {
          return Text(
            'No messages yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          );
        }
        
        final m = Map<String, dynamic>.from(snap.data as Map);
        final isProv = (m['sender'] as String?) == 'provider';
        final body = (m['body'] as String?) ?? '';
        final prefix = isProv ? 'You: ' : 'Customer: ';
        
        return Text(
          '$prefix${_truncate(body, 60)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        );
      },
    );
  }

  static String _truncate(String s, int n) =>
      s.length <= n ? s : '${s.substring(0, n - 1)}…';
}

/// Bottom sheet widget for messaging functionality
class MessageSheet extends StatefulWidget {
  const MessageSheet({
    super.key,
    required this.bookingId,
    required this.providerEmail,
  });

  final String bookingId;
  final String providerEmail;

  @override
  State<MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<MessageSheet>
    with WidgetsBindingObserver {
  static const Color kPrimary = Color(0xFF6A0DAD);

  final supabase = Supabase.instance.client;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _replyTo;

  // Prevent duplicate messages from realtime
  final Set<String> _seenMessages = <String>{};
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribeFromMessages();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Auto-scroll when keyboard opens/closes
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _loadMessages() async {
    try {
      final response = await supabase
          .from('messages')
          .select()
          .eq('booking_id', widget.bookingId)
          .order('created_at', ascending: true);

      final messageList = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Mark all loaded messages as seen
      for (final message in messageList) {
        _seenMessages.add(_generateMessageKey(message));
      }

      if (mounted) {
        setState(() => _messages = messageList);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  void _subscribeToMessages() {
    _channel = supabase.channel('messages_${widget.bookingId}');

    _channel!.on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: 'booking_id=eq.${widget.bookingId}',
      ),
      (payload, [ref]) {
        final newRecord = payload.newRecord;
        if (newRecord == null || !mounted) return;
        
        final message = Map<String, dynamic>.from(newRecord);
        final messageKey = _generateMessageKey(message);
        
        // Avoid duplicate messages
        if (_seenMessages.contains(messageKey)) return;
        
        _seenMessages.add(messageKey);
        setState(() => _messages.add(message));
        _scrollToBottom();
      },
    );

    _channel!.subscribe();
  }

  void _unsubscribeFromMessages() {
    try {
      _channel?.unsubscribe();
    } catch (e) {
      debugPrint('Error unsubscribing: $e');
    }
  }

  String _generateMessageKey(Map<String, dynamic> message) =>
      '${message['created_at']}_${message['sender']}_${(message['body'] ?? '').hashCode}';

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _createQuote(String text) {
    final lines = text.trim().split('\n');
    final preview = lines.take(2).join(' ');
    final truncated = preview.length > 80 ? '${preview.substring(0, 79)}…' : preview;
    return '> $truncated\n\n';
  }

  String _formatMessageTime(dynamic createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt as String).toLocal();
      return DateFormat('MMM d • h:mm a').format(dateTime);
    } catch (_) {
      return '';
    }
  }

  String _truncateText(String text, int maxLength) {
    final trimmed = text.trim();
    return trimmed.length <= maxLength 
        ? trimmed 
        : '${trimmed.substring(0, maxLength)}…';
  }

  Widget _buildQuoteBlock(String messageBody) {
    if (!messageBody.trimLeft().startsWith('> ')) {
      return const SizedBox.shrink();
    }

    // Extract quoted lines
    final lines = messageBody.split('\n');
    final quotedLines = <String>[];
    
    for (final line in lines) {
      if (line.startsWith('> ')) {
        quotedLines.add(line.substring(2));
      } else {
        break;
      }
    }

    if (quotedLines.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.reply, size: 14, color: Colors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              quotedLines.join(' '),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _removeQuoteFromMessage(String messageBody) {
    if (!messageBody.trimLeft().startsWith('> ')) return messageBody;
    
    final lines = messageBody.split('\n');
    final nonQuotedLines = <String>[];
    bool foundNonQuote = false;
    
    for (final line in lines) {
      if (!line.startsWith('> ') || foundNonQuote) {
        foundNonQuote = true;
        nonQuotedLines.add(line);
      }
    }
    
    return nonQuotedLines.join('\n').trim();
  }

  Future<void> _sendMessage() async {
    final messageBody = _textController.text.trim();
    if (messageBody.isEmpty) return;

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final fullMessageBody = _replyTo != null
        ? '${_createQuote(_replyTo!['body'] as String? ?? '')}$messageBody'
        : messageBody;

    // Optimistic update
    final optimisticMessage = {
      'booking_id': widget.bookingId,
      'sender': 'provider',
      'body': fullMessageBody,
      'created_at': timestamp,
    };
    
    final messageKey = _generateMessageKey(optimisticMessage);
    _seenMessages.add(messageKey);
    
    setState(() {
      _messages.add(optimisticMessage);
      _textController.clear();
      _replyTo = null;
    });
    _scrollToBottom();

    try {
      await supabase.from('messages').insert(optimisticMessage);
    } catch (e) {
      // Remove optimistic message on failure
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => _generateMessageKey(m) == messageKey);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const topRadius = Radius.circular(20);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: topRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 24,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Handle bar
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),

                // Messages list
                Expanded(
                  child: _buildMessagesList(),
                ),

                // Reply banner
                if (_replyTo != null) _buildReplyBanner(),

                // Message composer
                _buildMessageComposer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isProvider = (message['sender'] as String?) == 'provider';
        final timestamp = _formatMessageTime(message['created_at']);
        final messageBody = (message['body'] as String?) ?? '';

        return GestureDetector(
          onLongPress: () => setState(() => _replyTo = message),
          child: Align(
            alignment: isProvider 
                ? Alignment.centerRight 
                : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: isProvider
                    ? kPrimary.withOpacity(0.10)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: isProvider
                      ? const Radius.circular(14)
                      : const Radius.circular(4),
                  bottomRight: isProvider
                      ? const Radius.circular(4)
                      : const Radius.circular(14),
                ),
                border: Border.all(
                  color: isProvider
                      ? kPrimary.withOpacity(0.25)
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuoteBlock(messageBody),
                  Text(
                    _removeQuoteFromMessage(messageBody),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      timestamp,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplyBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimary.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 16, color: kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _truncateText(_replyTo!['body'] as String? ?? '', 100),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyTo = null),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 5,
                onTap: _scrollToBottom,
                decoration: InputDecoration(
                  hintText: _replyTo == null ? 'Type a message…' : 'Replying…',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kPrimary, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 44,
              width: 48,
              child: ElevatedButton(
                onPressed: _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.send, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}