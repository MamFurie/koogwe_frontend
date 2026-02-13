import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';
import '../../services/socket_service.dart';

class PassengerChatScreen extends StatefulWidget {
  final String rideId;
  final String driverName;

  const PassengerChatScreen({super.key, required this.rideId, required this.driverName});

  @override
  State<PassengerChatScreen> createState() => _PassengerChatScreenState();
}

class _PassengerChatScreenState extends State<PassengerChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _socket = SocketService();
  final List<Map<String, dynamic>> _messages = [];
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
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
          'isMe': data['senderId'] == _myId,
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
      _messages.add({'senderId': 'me', 'text': text, 'time': _formatTime(DateTime.now()), 'isMe': true});
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

  String _formatTime(DateTime dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

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
              backgroundColor: AppColors.primarySurface,
              child: const Icon(Icons.person, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.driverName, style: AppText.h4),
                const Text('Votre chauffeur', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Poppins')),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.phone_outlined, color: AppColors.primary), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat_bubble_outline, color: AppColors.border, size: 56),
                        SizedBox(height: 12),
                        Text('Démarrez la conversation', style: AppText.bodySecondary),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe = msg['isMe'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              const CircleAvatar(radius: 14, backgroundColor: AppColors.primarySurface, child: Icon(Icons.person, size: 14, color: AppColors.primary)),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                  ),
                                  boxShadow: !isMe ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)] : [],
                                ),
                                child: Text(msg['text'], style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14, fontFamily: 'Poppins')),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 6),
                              const CircleAvatar(radius: 14, backgroundColor: AppColors.primarySurface, child: Icon(Icons.person, size: 14, color: AppColors.primary)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44, height: 44,
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
}
