import 'package:flutter/material.dart';
import '../../widgets/ambient_background.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // THÊM PROVIDER

import '../app_provider.dart'; // IMPORT TỔNG ĐÀI VÀO

class ChatAIScreen extends StatefulWidget {
  const ChatAIScreen({super.key});

  @override
  State<ChatAIScreen> createState() => _ChatAIScreenState();
}

class _ChatAIScreenState extends State<ChatAIScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  late final GenerativeModel _model;
  late ChatSession _chat;

  List<Map<String, dynamic>> _chatSessions = [];
  String? _currentSessionId;

  final List<Content> _baseHistory = [
    Content.text(
      "Từ giờ trở đi, bạn là Meow - một chú mèo thông minh làm Bác sĩ da liễu ảo của app Skincare. "
      "Hãy trả lời ngắn gọn, chuyên nghiệp, thân thiện. Trả lời bằng ngôn ngữ mà người dùng hỏi (Việt hoặc Anh). Thỉnh thoảng xưng là 'Meow' hoặc thêm vài từ meo meo dễ thương. "
      "Chỉ tư vấn về chăm sóc da, thành phần mỹ phẩm, mụn, thâm, nám. "
      "Nếu khách hỏi chủ đề khác, hãy từ chối khéo léo và lái câu chuyện về Skincare.",
    ),
    Content.model([
      TextPart(
        "Meow! Chào bạn, tôi là Bác sĩ da liễu AI Meow. Tôi đã hiểu rõ nhiệm vụ và sẵn sàng tư vấn các vấn đề về làn da cho bạn rồi meow!",
      ),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
    _chat = _model.startChat(history: List.from(_baseHistory));
    _loadAllSessions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _storageKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
    return 'meow_sessions_$uid';
  }

  Future<void> _loadAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      setState(() {
        _chatSessions = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final dataToSave = _chatSessions
        .map(
          (session) => {
            'id': session['id'],
            'title': session['title'],
            'timestamp': session['timestamp'],
            'messages': session['messages'],
          },
        )
        .toList();
    await prefs.setString(_storageKey, jsonEncode(dataToSave));
  }

  void _startNewChat() {
    setState(() {
      _currentSessionId = null;
      _messages.clear();
      _chat = _model.startChat(history: List.from(_baseHistory));
    });
    Navigator.pop(context);
  }

  void _loadSession(String sessionId) {
    final session = _chatSessions.firstWhere((s) => s['id'] == sessionId);
    setState(() {
      _currentSessionId = sessionId;
      _messages = List<Map<String, dynamic>>.from(
        session['messages'].map((m) => Map<String, dynamic>.from(m)),
      );
    });

    List<Content> aiHistory = List.from(_baseHistory);
    for (var msg in _messages) {
      if (msg['role'] == 'user') {
        aiHistory.add(Content.text(msg['content']));
      } else {
        aiHistory.add(Content.model([TextPart(msg['content'])]));
      }
    }
    _chat = _model.startChat(history: aiHistory);
    Navigator.pop(context);
  }

  void _deleteSession(String sessionId) {
    setState(() {
      _chatSessions.removeWhere((s) => s['id'] == sessionId);
      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
        _messages.clear();
        _chat = _model.startChat(history: List.from(_baseHistory));
      }
    });
    _saveSessions();
  }

  void _updateCurrentSession() {
    final List<Map<String, dynamic>> messagesCopy = List.from(
      _messages.map((m) => Map<String, dynamic>.from(m)),
    );

    if (_currentSessionId == null) {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _chatSessions.insert(0, {
        'id': _currentSessionId,
        'title': messagesCopy.firstWhere((m) => m['role'] == 'user')['content'],
        'timestamp': DateTime.now().toIso8601String(),
        'messages': messagesCopy,
      });
    } else {
      final index = _chatSessions.indexWhere(
        (s) => s['id'] == _currentSessionId,
      );
      if (index != -1) {
        _chatSessions[index]['messages'] = messagesCopy;
      }
    }
    _saveSessions();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa cấu hình GEMINI_API_KEY. Hãy chạy app bằng --dart-define.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
    });
    _controller.clear();
    _updateCurrentSession();

    try {
      final response = await _chat.sendMessage(Content.text(text));

      String cleanText =
          response.text ?? "Meow đang bận chải lông, thử lại nha!";
      cleanText = cleanText
          .replaceAll(
            RegExp(r'\(thought[\s\S]*?\)\s*', multiLine: true, dotAll: true),
            '',
          )
          .trim();

      setState(() {
        _messages.add({
          "role": "bot",
          "content": cleanText,
          "isLiked": false,
          "isDisliked": false,
        });
      });
      _updateCurrentSession();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi kết nối AI: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. LẮNG NGHE TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.isEnglish;
    final isDark = appProvider.isDarkMode;

    // 2. MÀU SẮC ĐỘNG
    final cardColor = glassSurfaceColor(context);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        title: const Text(
          "Meow AI",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, size: 28),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _buildHistoryDrawer(isEn, isDark, cardColor, textColor),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildCatPawBackground(),
                _messages.isEmpty
                    ? _buildWelcomeScreen(isEn, isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _buildChatBubble(
                          _messages[index],
                          index,
                          isEn,
                          isDark,
                          textColor,
                        ),
                      ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: RainbowLinearProgressIndicator(),
            ),
          _buildInputArea(isEn, isDark, cardColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(
    bool isEn,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    return Drawer(
      backgroundColor: cardColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: isEn
                      ? "Search conversations"
                      : "Tìm kiếm cuộc trò chuyện",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.grey.shade900
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_square, color: Colors.blueAccent),
              title: Text(
                isEn ? "New conversation" : "Cuộc trò chuyện mới",
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _startNewChat,
            ),
            Divider(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
              child: Text(
                isEn ? "Chat history" : "Lịch sử trò chuyện",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: _chatSessions.isEmpty
                  ? Center(
                      child: Text(
                        isEn ? "No history yet" : "Chưa có lịch sử",
                        style: TextStyle(
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chatSessions.length,
                      itemBuilder: (context, index) {
                        final session = _chatSessions[index];
                        bool isActive = session['id'] == _currentSessionId;
                        return ListTile(
                          tileColor: isActive
                              ? (isDark
                                    ? Colors.blue.withValues(alpha: 0.15)
                                    : Colors.blue.shade50)
                              : null,
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            color: isDark ? Colors.white54 : Colors.black54,
                            size: 20,
                          ),
                          title: Text(
                            session['title'] ??
                                (isEn ? 'New chat' : 'Chat mới'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            onPressed: () => _deleteSession(session['id']),
                          ),
                          onTap: () => _loadSession(session['id']),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatPawBackground() {
    String imageUrl =
        'https://raw.githubusercontent.com/Nguyen-Minh-Nhut/skincare-app-assets/main/Assest/paw_print_silhouette.png';
    return Positioned(
      bottom: -20,
      right: -20,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            opacity: 0.05,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(bool isEn, bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    final name =
        user?.displayName ??
        user?.email?.split('@')[0] ??
        (isEn ? 'there' : 'bạn');
    final textColor = isDark ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            isEn ? "Hello $name!" : "Xin chào $name!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent.shade200,
            ),
          ),
          Text(
            isEn ? "What should we do today?" : "Hôm nay chúng ta sẽ làm gì?",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 40),

          _buildLargeSuggestionChip(
            "🔮",
            isEn ? "For you" : "Dành cho bạn",
            isEn
                ? "Recommend a beginner skincare routine"
                : "Gợi ý routine skincare cho người mới bắt đầu",
            isDark,
          ),
          _buildLargeSuggestionChip(
            "🧴",
            isEn ? "Ingredient analysis" : "Phân tích thành phần",
            isEn
                ? "Analyze the benefits of Niacinamide"
                : "Phân tích công dụng của Niacinamide",
            isDark,
          ),
          _buildLargeSuggestionChip(
            "💧",
            isEn ? "Acne treatment" : "Xử lý da mụn",
            isEn
                ? "How to care for red inflammatory acne"
                : "Cách chăm sóc da khi bị mụn viêm đỏ",
            isDark,
          ),
          _buildLargeSuggestionChip(
            "✨",
            isEn ? "Brightening tips" : "Bí quyết sáng da",
            isEn
                ? "Effective Vitamin C routine"
                : "Quy trình dùng Vitamin C hiệu quả",
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLargeSuggestionChip(
    String emoji,
    String title,
    String promptText,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            side: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            alignment: Alignment.centerLeft,
          ),
          onPressed: () {
            _controller.text = promptText;
            _sendMessage();
          },
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog(
    Map<String, dynamic> msg,
    int index,
    bool isEn,
    bool isDark,
  ) {
    final bgColor = glassSurfaceColor(context);
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEn ? "What went wrong?" : "Đã xảy ra lỗi gì?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  isEn
                      ? "Your feedback helps improve Meow for everyone."
                      : "Ý kiến phản hồi của bạn sẽ giúp cải thiện Meow cho tất cả mọi người.",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              _buildFeedbackOption(
                isEn ? "Offensive/Unsafe" : "Phản cảm/Không an toàn",
                msg,
                index,
                isEn,
                isDark,
              ),
              _buildFeedbackOption(
                isEn ? "Not true" : "Không đúng sự thật",
                msg,
                index,
                isEn,
                isDark,
              ),
              _buildFeedbackOption(
                isEn ? "Didn't follow instructions" : "Không tuân theo chỉ dẫn",
                msg,
                index,
                isEn,
                isDark,
              ),
              _buildFeedbackOption(
                isEn
                    ? "Personalization issue"
                    : "Vấn đề về tính năng cá nhân hóa",
                msg,
                index,
                isEn,
                isDark,
              ),
              _buildFeedbackOption(
                isEn ? "Other" : "Khác",
                msg,
                index,
                isEn,
                isDark,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackOption(
    String text,
    Map<String, dynamic> msg,
    int index,
    bool isEn,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _messages[index]['isDisliked'] = true;
          _messages[index]['isLiked'] = false;
        });
        _updateCurrentSession();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEn
                  ? 'Thanks for your feedback!'
                  : 'Cảm ơn bạn đã gửi phản hồi!',
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(
    Map<String, dynamic> msg,
    int index,
    bool isEn,
    bool isDark,
    Color textColor,
  ) {
    bool isUser = msg['role'] == "user";

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            msg['content'],
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['content'],
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          msg['isLiked'] == true
                              ? Icons.thumb_up
                              : Icons.thumb_up_alt_outlined,
                          size: 20,
                        ),
                        color: msg['isLiked'] == true
                            ? Colors.blueAccent
                            : Colors.grey.shade500,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(right: 15),
                        onPressed: () {
                          setState(() {
                            _messages[index]['isLiked'] =
                                !(_messages[index]['isLiked'] ?? false);
                            if (_messages[index]['isLiked'] == true) {
                              _messages[index]['isDisliked'] = false;
                            }
                          });
                          _updateCurrentSession();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          msg['isDisliked'] == true
                              ? Icons.thumb_down
                              : Icons.thumb_down_alt_outlined,
                          size: 20,
                        ),
                        color: msg['isDisliked'] == true
                            ? Colors.redAccent
                            : Colors.grey.shade500,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(right: 15),
                        onPressed: () {
                          if (msg['isDisliked'] == true) {
                            setState(() {
                              _messages[index]['isDisliked'] = false;
                            });
                            _updateCurrentSession();
                          } else {
                            _showFeedbackDialog(msg, index, isEn, isDark);
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.copy_outlined,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(right: 15),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: msg['content']),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEn
                                    ? 'Copied to clipboard'
                                    : 'Đã sao chép vào khay nhớ tạm',
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInputArea(
    bool isEn,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.blueAccent,
                  ),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 1,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: isEn ? "Ask Meow..." : "Hỏi Meow...",
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _isLoading ? Colors.grey : Colors.blueAccent,
                  ),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? "Meow is an AI and can make mistakes."
                : "Meow là AI và có thể mắc sai sót.",
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey.shade500,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          SafeArea(child: const SizedBox(height: 4)),
        ],
      ),
    );
  }
}

class RainbowLinearProgressIndicator extends StatefulWidget {
  const RainbowLinearProgressIndicator({super.key});

  @override
  State<RainbowLinearProgressIndicator> createState() =>
      _RainbowLinearProgressIndicatorState();
}

class _RainbowLinearProgressIndicatorState
    extends State<RainbowLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<Color> _colors = [
    Colors.red.shade300,
    Colors.orange.shade300,
    Colors.yellow.shade300,
    Colors.green.shade300,
    Colors.blue.shade300,
    Colors.indigo.shade300,
    Colors.purple.shade300,
    Colors.red.shade300,
    Colors.orange.shade300,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                return Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(-barWidth * _animation.value, 0),
                      child: Container(
                        width: barWidth * 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _colors,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
