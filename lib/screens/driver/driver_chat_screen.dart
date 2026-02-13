import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';
import '../../services/socket_service.dart';

class DriverChatScreen extends StatefulWidget {
  final String rideId;
  final String otherName;

  const DriverChatScreen({super.key, required this.rideId, required this.otherName});

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _socket = SocketService();
  final List<Map<String, dynamic>> _messages = [];
  String _myId = '';

  // Demo messages like in the design
  final List<Map<String, dynamic>> _demoMessages = [
    {'senderId': 'other', 'text': 'omg, this is amazing', 'time': '3:40'},
    {'senderId': 'other', 'text': 'perfect! ✅', 'time': '3:41'},
    {'senderId': 'other', 'text': 'Wow, this is really epic', 'time': '3:41'},
    {'senderId': 'me', 'text': 'How are you?', 'time': '3:42'},
    {'senderId': 'other', 'text': 'just ideas for next time', 'time': '3:43'},
    {'senderId': 'other', 'text': "I'll be there in 2 mins ⏱", 'time': '3:43'},
    {'senderId': 'me', 'text': 'woohooo', 'time': '3:44'},
    {'senderId': 'me', 'text': 'Haha oh man', 'time': '3:44'},
    {'senderId': 'me', 'text': 'Haha that\'s terrifying 🔥', 'time': '3:44'},
    {'senderId': 'other', 'text': 'just ideas for next time', 'time': '3:45'},
    {'senderId': 'other', 'text': "I'll be there in 2 mins ⏱", 'time': '3:45'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _messages.addAll(_demoMessages);
    _listenForMessages();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _myId = prefs.getString(AppConfig.keyUserId) ?? '');
  }

  void _listenForMessages() {
    _socket.onChatMessage(widget.rideId, (data) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'senderId': data['senderId'],
          'text': data['message'],
          'time': _formatTime(DateTime.now()),
        });
      });
      _scrollToBottom();
    });
  }

  void _send() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _socket.sendChatMessage(widget.rideId, _myId, text);

    setState(() {
      _messages.add({
        'senderId': 'me',
        'text': text,
        'time': _formatTime(DateTime.now()),
      });
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _socket.off('chat_${widget.rideId}');
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${widget.rideId}'),
              backgroundColor: AppColors.primarySurface,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherName, style: AppText.h4),
                const Text('En ligne', style: TextStyle(fontSize: 11, color: AppColors.success, fontFamily: 'Poppins')),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Type a message',
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMe = msg['senderId'] == 'me';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${widget.rideId}'),
              backgroundColor: AppColors.primarySurface,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: !isMe ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)] : [],
              ),
              child: Text(
                msg['text'],
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySurface,
              child: const Icon(Icons.person, color: AppColors.primary, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
