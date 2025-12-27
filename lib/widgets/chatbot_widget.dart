import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';
import '../core/constants/app_colors.dart';

class ChatbotWidget extends StatefulWidget {
  final VoidCallback onClose;

  const ChatbotWidget({super.key, required this.onClose});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _initializeChatbot();
  }

  void _initializeChatbot() async {
    await ChatbotService.initialize();
    _messages = ChatbotService.getMessages();
    _suggestions = ChatbotService.getSuggestions();

    if (_messages.isEmpty) {
      await ChatbotService.sendMessage('');
    }

    ChatbotService.onMessage((message) {
      if (mounted) {
        setState(() {
          _messages = ChatbotService.getMessages();
        });
        _scrollToBottom();
      }
    });

    setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await ChatbotService.sendMessage(text);
  }

  void _handleSuggestionTap(String text) async {
    await ChatbotService.sendMessage(text);
  }

  LinearGradient get _tirangaGradient => const LinearGradient(
    colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 70,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        elevation: 20,
        shadowColor: Colors.black.withOpacity(0.2), // Deprecated replacement not needed for cosmetic
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 600,
          decoration: BoxDecoration(
            gradient: _tirangaGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4169E1).withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(27),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
            child: Column(
              children: [
                // Premium Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // AI Avatar with Pulse
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _tirangaGradient,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_rounded, color: AppColors.navyBlue, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Smart Safety Hub',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.verified, size: 14, color: Colors.blue[600]),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF138808),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Active • Official Help',
                                style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: widget.onClose,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                        ),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textGrey, size: 20),
                      ),
                    ],
                  ),
                ),

                // Messages Area
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC), // Very subtle blue-grey
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _ChatBubble(message: message);
                      },
                    ),
                  ),
                ),

                // Suggestions Panel
                if (_suggestions.isNotEmpty)
                  Container(
                    height: 60,
                    width: double.infinity,
                    color: Colors.white,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () => _handleSuggestionTap(_suggestions[index]),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue[100]!),
                              ),
                              child: Text(
                                _suggestions[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Input Area
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _textController,
                                  style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message...',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onSubmitted: (_) => _handleSendMessage(),
                                ),
                              ),
                              // Report Button
                              Container(
                                margin: const EdgeInsets.all(4),
                                child: Material(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    onTap: () {},
                                    borderRadius: BorderRadius.circular(20),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.report_gmailerrorred_rounded, color: Color(0xFFD32F2F), size: 18),
                                          SizedBox(width: 4),
                                          Text(
                                            'Report', 
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Send Button
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.navyBlue,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navyBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _handleSendMessage,
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );

  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isAi = !message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAi)
            Container(
              margin: const EdgeInsets.only(right: 12, top: 4),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/images/ai_avatar_placeholder.png'), // Fallback to icon if needed
                child: Icon(Icons.shield, size: 18, color: AppColors.indiaGreen),
              ),
            ),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                // Gradient for user, White for AI
                gradient: message.isUser 
                    ? const LinearGradient(
                        colors: [AppColors.navyBlue, Color(0xFF2C3E50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isAi ? Colors.white : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isAi ? 4 : 20),
                  bottomRight: Radius.circular(isAi ? 20 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAi)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AI Guardian',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.indiaGreen.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 10, color: AppColors.indiaGreen),
                        ],
                      ),
                    ),
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: message.isUser ? Colors.white : const Color(0xFF1F2937),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 10, top: 12),
              width: 10, // Spacer
            ),
        ],
      ),
    );
  }
}