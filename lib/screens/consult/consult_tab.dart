import 'package:flutter/material.dart';
import '../../widgets/ambient_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';
import 'chat_ai_screen.dart';

class ConsultTab extends StatefulWidget {
  const ConsultTab({super.key});

  @override
  State<ConsultTab> createState() => _ConsultTabState();
}

class _ConsultTabState extends State<ConsultTab> {
  // Giữ gốc tiếng Việt để truy vấn Database cho chuẩn
  String _selectedFilter = "Mới nhất";
  final List<String> _filters = [
    "Mới nhất",
    "Hỏi đáp mụn",
    "Review SP",
    "Khoe da",
    "Routine",
  ];

  // Dịch filter sang giao diện tiếng Anh
  String _getFilterName(String filter, bool isEn) {
    if (!isEn) return filter;
    switch (filter) {
      case "Mới nhất":
        return "Latest";
      case "Hỏi đáp mụn":
        return "Acne Q&A";
      case "Review SP":
        return "Reviews";
      case "Khoe da":
        return "Skin Flex";
      case "Routine":
        return "Routine";
      default:
        return filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.isEnglish;
    final isDark = appProvider.isDarkMode;

    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0, right: 8.0),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreatePostSheet(context, isEn, isDark),
          icon: const Icon(Icons.edit_square, color: Colors.white),
          label: Text(
            isEn ? "Post" : "Đăng bài",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blueAccent,
        ),
      ),

      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isEn ? "Skincare Community" : "Cộng đồng Skincare",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _buildAIChatBanner(context, isEn),
              const SizedBox(height: 25),
              _buildFilters(isEn, isDark),
              const SizedBox(height: 15),
              _buildCommunityFeed(isEn, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIChatBanner(BuildContext context, bool isEn) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatAIScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF334155)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.blueAccent,
                size: 30,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? "AI Dermatologist" : "Trợ lý da liễu AI",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEn
                        ? "Instant Q&A without waiting"
                        : "Hỏi đáp nhanh không cần chờ đợi",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(bool isEn, bool isDark) {
    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedFilter == _filters[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = _filters[index]),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blueAccent
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.blueAccent
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                ),
              ),
              child: Text(
                _getFilterName(_filters[index], isEn),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommunityFeed(bool isEn, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                isEn
                    ? "No posts yet. Be the first to post!"
                    : "Chưa có bài viết nào. Hãy là người đầu tiên đăng bài!",
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        var docs = snapshot.data!.docs;

        if (_selectedFilter != "Mới nhất") {
          docs = docs.where((doc) => doc['tag'] == _selectedFilter).toList();
        }

        return Column(
          children: docs
              .map((doc) => PostCard(postDoc: doc, isEn: isEn, isDark: isDark))
              .toList(), // Truyền biến vào đây
        );
      },
    );
  }

  void _showCreatePostSheet(BuildContext context, bool isEn, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CreatePostSheet(isEn: isEn, isDark: isDark),
    );
  }
}

// ==========================================================
// WIDGET TẠO BÀI VIẾT
// ==========================================================
class CreatePostSheet extends StatefulWidget {
  final bool isEn;
  final bool isDark;
  const CreatePostSheet({super.key, required this.isEn, required this.isDark});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final TextEditingController _contentCtrl = TextEditingController();
  final TextEditingController _imageCtrl = TextEditingController();
  String _selectedTag = "Hỏi đáp mụn";
  bool _isLoading = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  String _getFilterName(String filter) {
    if (!widget.isEn) return filter;
    switch (filter) {
      case "Hỏi đáp mụn":
        return "Acne Q&A";
      case "Review SP":
        return "Reviews";
      case "Khoe da":
        return "Skin Flex";
      case "Routine":
        return "Routine";
      default:
        return filter;
    }
  }

  Future<void> _submitPost() async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    String userName =
        user?.displayName ?? user?.email?.split('@')[0] ?? "Người dùng ẩn danh";

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user?.uid ?? 'unknown',
        'userName': userName,
        'content': _contentCtrl.text.trim(),
        'tag': _selectedTag,
        'imageUrl': _imageCtrl.text.trim(),
        'likes': 0,
        'dislikes': 0,
        'comments': 0,
        'likedBy': [],
        'dislikedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String userName =
        user?.displayName ??
        user?.email?.split('@')[0] ??
        (widget.isEn ? "You" : "Bạn");

    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final hintColor = widget.isDark
        ? Colors.grey.shade500
        : Colors.grey.shade400;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isEn ? "Create Post" : "Tạo bài viết",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(
            color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.2),
                child: Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 25,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTag,
                        dropdownColor: widget.isDark
                            ? Colors.grey.shade900
                            : Colors.white,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: widget.isDark
                              ? Colors.white70
                              : Colors.grey.shade800,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark
                              ? Colors.white70
                              : Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                        items:
                            ["Hỏi đáp mụn", "Review SP", "Khoe da", "Routine"]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(_getFilterName(e)),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => _selectedTag = val!),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _contentCtrl,
            maxLines: 5,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: widget.isEn
                  ? "What's on your mind, $userName?"
                  : "$userName ơi, bạn đang nghĩ gì thế?",
              border: InputBorder.none,
              hintStyle: TextStyle(color: hintColor, fontSize: 18),
            ),
          ),
          TextField(
            controller: _imageCtrl,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: widget.isEn
                  ? "Add an image URL"
                  : "Chọn ảnh (Dán link URL)",
              prefixIcon: const Icon(Icons.image, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: widget.isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.isEn ? "Post" : "Đăng",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ==========================================================
// WIDGET CARD BÀI VIẾT
// ==========================================================
class PostCard extends StatefulWidget {
  final DocumentSnapshot postDoc;
  final bool isEn;
  final bool isDark;

  const PostCard({
    super.key,
    required this.postDoc,
    required this.isEn,
    required this.isDark,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return widget.isEn ? "Just now" : "Vừa xong";
    Duration diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inDays > 0) {
      return widget.isEn ? "${diff.inDays}d ago" : "${diff.inDays} ngày trước";
    }
    if (diff.inHours > 0) {
      return widget.isEn ? "${diff.inHours}h ago" : "${diff.inHours} giờ trước";
    }
    if (diff.inMinutes > 0) {
      return widget.isEn
          ? "${diff.inMinutes}m ago"
          : "${diff.inMinutes} phút trước";
    }
    return widget.isEn ? "Just now" : "Vừa xong";
  }

  String _getFilterName(String filter) {
    if (!widget.isEn) return filter;
    switch (filter) {
      case "Mới nhất":
        return "Latest";
      case "Hỏi đáp mụn":
        return "Acne Q&A";
      case "Review SP":
        return "Reviews";
      case "Khoe da":
        return "Skin Flex";
      case "Routine":
        return "Routine";
      default:
        return filter;
    }
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final userName =
        user?.displayName ?? user?.email?.split('@')[0] ?? "Một người dùng";
    if (uid == null) return;

    var data = widget.postDoc.data() as Map<String, dynamic>;
    List<dynamic> likedBy = data['likedBy'] ?? [];
    List<dynamic> dislikedBy = data['dislikedBy'] ?? [];

    bool currentlyLiked = likedBy.contains(uid);
    bool currentlyDisliked = dislikedBy.contains(uid);

    final docRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postDoc.id);
    String postOwnerId = data['userId'] ?? 'unknown';

    if (currentlyLiked) {
      await docRef.update({
        'likedBy': FieldValue.arrayRemove([uid]),
        'likes': FieldValue.increment(-1),
      });
    } else {
      var updates = <String, dynamic>{
        'likedBy': FieldValue.arrayUnion([uid]),
        'likes': FieldValue.increment(1),
      };
      if (currentlyDisliked) {
        updates['dislikedBy'] = FieldValue.arrayRemove([uid]);
        updates['dislikes'] = FieldValue.increment(-1);
      }
      await docRef.update(updates);

      if (postOwnerId != uid && postOwnerId != 'unknown') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(postOwnerId)
            .collection('notifications')
            .add({
              'title': widget.isEn ? 'New Like ❤️' : 'Lượt thích mới ❤️',
              'body': widget.isEn
                  ? '$userName liked your post.'
                  : '$userName vừa thích bài viết của bạn.',
              'type': 'like',
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
    }
  }

  Future<void> _toggleDislike() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    var data = widget.postDoc.data() as Map<String, dynamic>;
    List<dynamic> likedBy = data['likedBy'] ?? [];
    List<dynamic> dislikedBy = data['dislikedBy'] ?? [];

    bool currentlyLiked = likedBy.contains(uid);
    bool currentlyDisliked = dislikedBy.contains(uid);

    final docRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postDoc.id);

    if (currentlyDisliked) {
      await docRef.update({
        'dislikedBy': FieldValue.arrayRemove([uid]),
        'dislikes': FieldValue.increment(-1),
      });
    } else {
      var updates = <String, dynamic>{
        'dislikedBy': FieldValue.arrayUnion([uid]),
        'dislikes': FieldValue.increment(1),
      };
      if (currentlyLiked) {
        updates['likedBy'] = FieldValue.arrayRemove([uid]);
        updates['likes'] = FieldValue.increment(-1);
      }
      await docRef.update(updates);
    }
  }

  void _showComments() {
    final TextEditingController commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                widget.isEn ? "Comments" : "Bình luận",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              Divider(
                color: widget.isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade300,
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postDoc.id)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.blueAccent,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          widget.isEn
                              ? "No comments yet.\nBe the first to comment!"
                              : "Chưa có bình luận nào.\nHãy là người đầu tiên bình luận!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var comment =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        String timeAgo = _getTimeAgo(
                          comment['createdAt'] as Timestamp?,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue.withValues(
                                  alpha: 0.2,
                                ),
                                child: Text(
                                  (comment['userName'] ?? "U")[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: widget.isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            comment['userName'] ?? "Người dùng",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: widget.isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            timeAgo,
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment['content'] ?? "",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: widget.isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              TextField(
                controller: commentCtrl,
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: widget.isEn
                      ? "Write a comment..."
                      : "Viết bình luận...",
                  hintStyle: TextStyle(
                    color: widget.isDark
                        ? Colors.grey.shade500
                        : Colors.grey.shade400,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: () async {
                      if (commentCtrl.text.trim().isEmpty) return;

                      final user = FirebaseAuth.instance.currentUser;
                      String userName =
                          user?.displayName ??
                          user?.email?.split('@')[0] ??
                          "Người dùng ẩn danh";
                      String text = commentCtrl.text.trim();
                      commentCtrl.clear();

                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.postDoc.id)
                          .collection('comments')
                          .add({
                            'userName': userName,
                            'content': text,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.postDoc.id)
                          .update({'comments': FieldValue.increment(1)});

                      var postData =
                          widget.postDoc.data() as Map<String, dynamic>;
                      String postOwnerId = postData['userId'] ?? 'unknown';

                      if (postOwnerId != user?.uid &&
                          postOwnerId != 'unknown') {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(postOwnerId)
                            .collection('notifications')
                            .add({
                              'title': widget.isEn
                                  ? 'New Comment 💬'
                                  : 'Bình luận mới 💬',
                              'body': widget.isEn
                                  ? '$userName commented: "$text"'
                                  : '$userName đã bình luận: "$text"',
                              'type': 'comment',
                              'isRead': false,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: widget.isDark
                      ? Colors.grey.shade900
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var data = widget.postDoc.data() as Map<String, dynamic>;
    String timeAgo = _getTimeAgo(data['createdAt'] as Timestamp?);
    String imageUrl = data['imageUrl'] ?? '';

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    List<dynamic> likedBy = data['likedBy'] ?? [];
    List<dynamic> dislikedBy = data['dislikedBy'] ?? [];

    bool isLiked = likedBy.contains(uid);
    bool isDisliked = dislikedBy.contains(uid);

    int likes = data['likes'] ?? 0;
    int dislikes = data['dislikes'] ?? 0;

    final cardColor = glassSurfaceColor(context);
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.withValues(alpha: 0.2),
                child: Text(
                  data['userName'][0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['userName'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.public, size: 12, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getFilterName(data['tag']),
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            data['content'],
            style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
          ),

          if (imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ],

          const SizedBox(height: 15),
          Divider(
            height: 1,
            color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                      color: isLiked ? Colors.blueAccent : Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text(
                    "$likes",
                    style: TextStyle(
                      color: isLiked ? Colors.blueAccent : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 5),

                  IconButton(
                    icon: Icon(
                      isDisliked
                          ? Icons.thumb_down
                          : Icons.thumb_down_alt_outlined,
                      color: isDisliked
                          ? Colors.redAccent
                          : Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: _toggleDislike,
                  ),
                  Text(
                    dislikes > 0 ? "$dislikes" : "",
                    style: TextStyle(
                      color: isDisliked
                          ? Colors.redAccent
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                icon: Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
                label: Text(
                  "${data['comments']} ${widget.isEn ? "Comments" : "Bình luận"}",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _showComments,
              ),
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.isEn
                            ? 'Sharing post...'
                            : 'Đang chia sẻ bài viết...',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
