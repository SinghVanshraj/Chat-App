import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../main.dart' show appSocket, connectGlobalSocket;
import '../utils/constants.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/message_model.dart';
import '../widgets/app_widgets.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId, username;
  final bool   isOnline;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.username,
    required this.isOnline,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<MessageModel> _messages    = [];
  bool      _loading     = true;
  bool      _loadingMore = false;
  bool      _isTyping    = false;
  String?   _myId;
  int       _page    = 1;
  bool      _hasMore = true;
  DateTime? _lastTyped;

  IO.Socket? get _socket => appSocket;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _emitTypingStop();
    _removeSocketListeners();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _myId = await AuthService.getUserId();

    if (_socket == null || _socket!.disconnected) {
      await connectGlobalSocket();
    }

    _attachSocketListeners();
    await _loadMessages();
  }

  void _attachSocketListeners() {
    _socket?.on('receive_message',       _onReceiveMessage);
    _socket?.on('message_status_update', _onStatusUpdate);
    _socket?.on('user_typing',           _onUserTyping);
    _socket?.on('all_messages_read',     _onAllRead);
  }

  void _removeSocketListeners() {
    _socket?.off('receive_message',       _onReceiveMessage);
    _socket?.off('message_status_update', _onStatusUpdate);
    _socket?.off('user_typing',           _onUserTyping);
    _socket?.off('all_messages_read',     _onAllRead);
  }

  void _onReceiveMessage(dynamic data) {
    if (!mounted) return;
    if (data['sender']?.toString() != widget.receiverId) return;

    final msg = MessageModel(
      messageId:  data['messageId']?.toString()  ?? '',
      chatRoomId: data['chatRoomId']?.toString() ?? '',
      senderId:   data['sender']?.toString()     ?? '',
      receiverId: data['receiver']?.toString()   ?? '',
      message:    data['message']?.toString()    ?? '',
      status:     data['status']?.toString()     ?? 'delivered',
      createdAt:  data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isMine: false,
    );
    setState(() => _messages.add(msg));
    _scrollToBottom();

    _socket?.emit('message_read', {
      'messageId': msg.messageId,
      'senderId':  widget.receiverId,
    });
  }

  void _onStatusUpdate(dynamic data) {
    if (!mounted) return;
    final mid       = data['messageId']?.toString();
    final status    = data['status']?.toString();
    final tempId    = data['clientTempId']?.toString();
    if (mid == null || status == null) return;

    setState(() {
      if (tempId != null) {
        final tempIdx = _messages.indexWhere((m) => m.messageId == tempId);
        if (tempIdx != -1) {
          _messages[tempIdx] = _messages[tempIdx].copyWith(
            messageId: mid,
            status:    status,
          );
          return;
        }
      }
      final idx = _messages.indexWhere((m) => m.messageId == mid);
      if (idx != -1) _messages[idx] = _messages[idx].copyWith(status: status);
    });
  }

  void _onUserTyping(dynamic data) {
    if (!mounted) return;
    if (data['userId']?.toString() != widget.receiverId) return;
    setState(() => _isTyping = data['isTyping'] == true);
  }

  void _onAllRead(dynamic _) {
    if (!mounted) return;
    setState(() {
      _messages = _messages
          .map((m) => m.isMine ? m.copyWith(status: 'read') : m)
          .toList();
    });
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _loadingMore) return;
      setState(() => _loadingMore = true);
      _page++;
    } else {
      _page = 1;
    }

    final msgs = await ChatService.fetchMessages(
      receiverId: widget.receiverId,
      page:  _page,
      limit: 20,
    );

    if (!mounted) return;
    setState(() {
      if (loadMore) {
        _messages    = [...msgs, ..._messages];
        _loadingMore = false;
      } else {
        _messages = msgs;
        _loading  = false;
      }
      _hasMore = msgs.length == 20;
    });

    if (!loadMore) _scrollToBottom();

    if (msgs.isNotEmpty && _myId != null) {
      _socket?.emit('mark_all_read', {
        'userId':    _myId,
        'partnerId': widget.receiverId,
      });
    }
  }

  void _onScroll() {
    if (_scrollCtrl.hasClients &&
        _scrollCtrl.position.pixels <= 80) {
      _loadMessages(loadMore: true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _socket == null) return;
    _msgCtrl.clear();
    _emitTypingStop();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    setState(() => _messages.add(MessageModel(
      messageId:  tempId,
      chatRoomId: '',
      senderId:   _myId ?? '',
      receiverId: widget.receiverId,
      message:    text,
      status:     'sent',
      createdAt:  DateTime.now(),
      isMine:     true,
    )));
    _scrollToBottom();

    _socket!.emit('send_message', {
      'senderId':     _myId,
      'receiverId':   widget.receiverId,
      'message':      text,
      'clientTempId': tempId,
    });
  }

  void _onTextChanged(String text) {
    _lastTyped = DateTime.now();
    if (text.isNotEmpty) {
      _socket?.emit('typing_start', {
        'senderId':   _myId,
        'receiverId': widget.receiverId,
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (_lastTyped != null &&
            DateTime.now().difference(_lastTyped!).inSeconds >= 2) {
          _emitTypingStop();
        }
      });
    } else {
      _emitTypingStop();
    }
  }

  void _emitTypingStop() {
    if (_socket?.connected ?? false) {
      _socket?.emit('typing_stop', {
        'senderId':   _myId,
        'receiverId': widget.receiverId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              username: widget.username,
              isOnline: widget.isOnline,
              onBack:   () => Navigator.pop(context),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColor.primaryColor))
                  : _buildList(),
            ),
            if (_isTyping) _TypingBubble(username: widget.username),
            _InputBar(
              controller: _msgCtrl,
              onChanged:  _onTextChanged,
              onSend:     _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarWidget(username: widget.username, size: 64),
            const SizedBox(height: 16),
            Text(widget.username,
                style: const TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Say hello! 👋',
                style: TextStyle(color: AppColor.textHint, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: _messages.length + (_loadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (_loadingMore && i == 0) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: AppColor.primaryColor, strokeWidth: 2),
              ),
            ),
          );
        }
        final idx  = _loadingMore ? i - 1 : i;
        final msg  = _messages[idx];
        final prev = idx > 0 ? _messages[idx - 1] : null;
        final showDate =
            prev == null || !_sameDay(prev.createdAt, msg.createdAt);

        return Column(children: [
          if (showDate) _DateDivider(date: msg.createdAt),
          _Bubble(msg: msg),
        ]);
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Header extends StatelessWidget {
  final String username;
  final bool   isOnline;
  final VoidCallback onBack;
  const _Header({required this.username, required this.isOnline, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppColor.surface,
          border: Border(bottom: BorderSide(color: AppColor.border))),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.surface2,
                  border: Border.all(color: AppColor.border)),
              child: const Icon(Icons.arrow_back,
                  color: AppColor.textSecondary, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          AvatarWidget(username: username, size: 40, isOnline: isOnline),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    style: const TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                Text(isOnline ? '● Online' : 'Offline',
                    style: TextStyle(
                        color: isOnline ? AppColor.online : AppColor.textHint,
                        fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.surface2,
                border: Border.all(color: AppColor.border)),
            child: const Icon(Icons.phone_outlined,
                color: AppColor.textSecondary, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.surface2,
                border: Border.all(color: AppColor.border)),
            child: const Icon(Icons.more_vert,
                color: AppColor.textSecondary, size: 18),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final String username;
  const _TypingBubble({required this.username});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          AvatarWidget(username: username, size: 24),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColor.surface2,
              borderRadius: BorderRadius.only(
                topLeft:     Radius.circular(18),
                topRight:    Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft:  Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _Dot(delay: i * 200)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: -5.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          transform: Matrix4.translationValues(0, _anim.value, 0),
          width: 6, height: 6,
          decoration: const BoxDecoration(
              color: AppColor.textHint, shape: BoxShape.circle),
        ),
      );
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>  onChanged;
  final VoidCallback          onSend;
  const _InputBar({required this.controller, required this.onChanged, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: AppColor.surface,
          border: Border(top: BorderSide(color: AppColor.border))),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.surface2,
                border: Border.all(color: AppColor.border)),
            child: const Icon(Icons.attach_file,
                color: AppColor.textSecondary, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: AppColor.surface2,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColor.border)),
              child: TextField(
                controller:      controller,
                onChanged:       onChanged,
                onSubmitted:     (_) => onSend(),
                textInputAction: TextInputAction.send,
                style: const TextStyle(color: AppColor.textPrimary, fontSize: 14),
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: AppColor.textHint, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  suffixIcon: Icon(Icons.sentiment_satisfied_alt_outlined,
                      color: AppColor.textHint, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(
                  color: AppColor.primaryColor, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final MessageModel msg;
  const _Bubble({required this.msg});

  String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            msg.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMine) ...[
            AvatarWidget(username: msg.senderId, size: 26),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment:
                msg.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: msg.isMine ? AppColor.primaryColor : AppColor.surface2,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(18),
                    topRight:    const Radius.circular(18),
                    bottomLeft:  Radius.circular(msg.isMine ? 18 : 4),
                    bottomRight: Radius.circular(msg.isMine ? 4 : 18),
                  ),
                ),
                child: Text(msg.message,
                    style: TextStyle(
                        color: msg.isMine ? Colors.white : AppColor.textPrimary,
                        fontSize: 14,
                        height: 1.4)),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_time(msg.createdAt),
                      style: const TextStyle(
                          color: AppColor.textHint, fontSize: 10)),
                  if (msg.isMine) ...[
                    const SizedBox(width: 4),
                    MessageStatusIcon(status: msg.status),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  String get _label {
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        const Expanded(child: Divider(color: AppColor.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(_label,
              style: const TextStyle(color: AppColor.textHint, fontSize: 11)),
        ),
        const Expanded(child: Divider(color: AppColor.border)),
      ]),
    );
  }
}
