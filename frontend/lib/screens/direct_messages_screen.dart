import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/chat_room_model.dart';
import '../widgets/app_widgets.dart';
import '../main.dart' show appSocket;
import 'chat_screen.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});
  @override State<DirectMessagesScreen> createState() =>
      _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  List<ChatRoomModel> _rooms    = [];
  List<ChatRoomModel> _filtered = [];
  bool    _loading = true;
  String  _search  = '';
  String? _currentUserId;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    _currentUserId = await AuthService.getUserId();
    final rooms = await ChatService.fetchChatRooms();
    if (!mounted) return;
    setState(() {
      _rooms    = rooms;
      _filtered = rooms;
      _loading  = false;
    });
  }

  void _onSearch(String q) {
    setState(() {
      _search   = q;
      _filtered = _rooms
          .where((r) => r.username.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m';
    if (diff.inHours   < 24)  return '${diff.inHours}h';
    if (diff.inDays    < 7)   return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const Text('Messages',
                      style: TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  _IconBtn(
                      icon: Icons.edit_outlined,
                      onTap: _showNewChatSheet),
                  const SizedBox(width: 8),
                  _IconBtn(
                    icon: Icons.logout,
                    onTap: () async {
                      appSocket?.dispose();
                      await AuthService.logout();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/landing');
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                    color: AppColor.surface2,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColor.border)),
                child: TextField(
                  onChanged: _onSearch,
                  style: const TextStyle(
                      color: AppColor.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle:
                        TextStyle(color: AppColor.textHint, fontSize: 14),
                    prefixIcon:
                        Icon(Icons.search, color: AppColor.textHint, size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColor.primaryColor))
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.chat_bubble_outline,
                                  color: AppColor.textHint, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _search.isNotEmpty
                                    ? 'No results for "$_search"'
                                    : 'No conversations yet.\nTap ✏ to start one.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColor.textHint,
                                    fontSize: 14,
                                    height: 1.6),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColor.primaryColor,
                          backgroundColor: AppColor.surface,
                          onRefresh: _load,
                          child: ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final room = _filtered[i];
                              return _RoomTile(
                                room:      room,
                                timeLabel: _timeAgo(room.latestMessageTime),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      receiverId: room.userId,
                                      username:   room.username,
                                      isOnline:   room.isOnline,
                                    ),
                                  ),
                                ).then((_) => _load()),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: AppColor.surface,
            border: Border(top: BorderSide(color: AppColor.border))),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation:       0,
          selectedItemColor:   AppColor.primaryColor,
          unselectedItemColor: AppColor.textHint,
          currentIndex: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_outline), label: 'People'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications_none), label: 'Alerts'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _showNewChatSheet() async {
    final users = await ChatService.fetchAllUsers();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColor.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _NewChatSheet(
        users:         users,
        currentUserId: _currentUserId ?? '',
        onSelect: (uid, username) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                  receiverId: uid,
                  username:   username,
                  isOnline:   false),
            ),
          ).then((_) => _load());
        },
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final ChatRoomModel room;
  final String        timeLabel;
  final VoidCallback  onTap;

  const _RoomTile(
      {required this.room,
      required this.timeLabel,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            AvatarWidget(
                username: room.username, isOnline: room.isOnline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.username,
                      style: const TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (room.latestMessageStatus != null) ...[
                        MessageStatusIcon(
                            status: room.latestMessageStatus!),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          room.latestMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: room.unreadCount > 0
                                  ? AppColor.textSecondary
                                  : AppColor.textHint,
                              fontSize: 13,
                              fontWeight: room.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeLabel,
                    style: TextStyle(
                        color: room.unreadCount > 0
                            ? AppColor.primaryColor
                            : AppColor.textHint,
                        fontSize: 11)),
                const SizedBox(height: 4),
                if (room.unreadCount > 0)
                  Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(
                        color: AppColor.primaryColor,
                        shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                        room.unreadCount > 9
                            ? '9+'
                            : '${room.unreadCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NewChatSheet extends StatelessWidget {
  final List<Map<String, dynamic>>           users;
  final String                               currentUserId;
  final void Function(String, String)        onSelect;

  const _NewChatSheet(
      {required this.users,
      required this.currentUserId,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final others = users
        .where((u) =>
            u['_id']?.toString() != currentUserId &&
            u['userId']?.toString() != currentUserId)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: AppColor.border,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('New Message',
              style: TextStyle(
                  color: AppColor.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        if (others.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No other users found.',
                style: TextStyle(color: AppColor.textHint)),
          )
        else
          ...others.map((u) {
            final uid      = u['_id']?.toString() ?? '';
            final username = u['username']?.toString() ?? 'Unknown';
            return ListTile(
              leading:  AvatarWidget(username: username),
              title:    Text(username,
                  style: const TextStyle(
                      color: AppColor.textPrimary, fontSize: 15)),
              onTap: () => onSelect(uid, username),
            );
          }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
            color: AppColor.surface2,
            shape: BoxShape.circle,
            border: Border.all(color: AppColor.border)),
        child: Icon(icon, color: AppColor.textSecondary, size: 18),
      ),
    );
  }
}
