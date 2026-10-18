import 'package:flutter/material.dart';
import 'package:skincare_app/widgets/app_icons.dart';
import '../../widgets/ambient_background.dart';
import '../../widgets/health_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../app_provider.dart';
import '../../services/community_store.dart';

class ConsultTab extends StatefulWidget {
  const ConsultTab({super.key});

  @override
  State<ConsultTab> createState() => _ConsultTabState();
}

class _ConsultTabState extends State<ConsultTab> {
  int _postLimit = 15;
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

    return Scaffold(
      backgroundColor: Colors.transparent,

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0, right: 8.0),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreatePostSheet(context, isEn, isDark),
          icon: const Icon(AppIcons.editSquare, color: Colors.white),
          label: Text(
            isEn ? "Post" : "Đăng bài",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF6264D9),
        ),
      ),

      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HealthPageHeader(
                title: isEn ? 'Community' : 'Cộng đồng',
                subtitle: isEn
                    ? 'Share a little. Care together.'
                    : 'Cùng chia sẻ, cùng chăm da.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HealthCard(
                  onTap: () => _showCreatePostSheet(context, isEn, isDark),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: .10),
                        child: Icon(
                          Icons.person_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEn
                              ? 'How is your skin today?'
                              : 'Hôm nay da bạn thế nào?',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.add_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildAIChatBanner(context, isEn),
              const SizedBox(height: 24),
              _buildFilters(isEn, isDark),
              const SizedBox(height: 15),
              _buildCommunityFeed(isEn, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIChatBanner(BuildContext context, bool isEn) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: HealthCard(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'AI chat is temporarily unavailable.'
                : 'Chat AI đang tạm thời ngừng hoạt động.',
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn ? 'Meow AI assistant' : 'Trợ lý Meow AI',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEn ? 'Under maintenance' : 'Đang bảo trì',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    ),
  );

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
                    ? const Color(0xFF6264D9)
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6264D9)
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
          .limit(_postLimit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6264D9)),
          );
        }
        if (snapshot.hasError) {
          return _FeedMessage(
            icon: AppIcons.cloudOffOutlined,
            message: isEn
                ? 'Could not load the community. Please try again.'
                : 'Không thể tải cộng đồng. Vui lòng thử lại.',
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

        if (docs.isEmpty) {
          return _FeedMessage(
            icon: AppIcons.filterAltOffOutlined,
            message: isEn
                ? 'No posts match this topic.'
                : 'Chưa có bài viết thuộc chủ đề này.',
          );
        }

        return Column(
          children: [
            ...docs.map(
              (doc) => PostCard(postDoc: doc, isEn: isEn, isDark: isDark),
            ),
            if (snapshot.data!.docs.length == _postLimit)
              TextButton.icon(
                onPressed: () => setState(() => _postLimit += 15),
                icon: const Icon(AppIcons.expandMore),
                label: Text(isEn ? 'Load more' : 'Xem thêm'),
              ),
          ],
        );
      },
    );
  }

  void _showCreatePostSheet(BuildContext context, bool isEn, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => CreatePostSheet(isEn: isEn, isDark: isDark),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        Icon(icon, size: 42, color: Colors.grey),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );
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
  Uint8List? _selectedImage;
  String _selectedTag = "Hỏi đáp mụn";
  bool _isLoading = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
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
    final content = _contentCtrl.text.trim();
    if (content.isEmpty || content.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEn
                ? 'Post content must contain 1–2000 characters.'
                : 'Nội dung bài viết phải từ 1–2000 ký tự.',
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    String userName =
        user?.displayName ?? user?.email?.split('@')[0] ?? "Người dùng ẩn danh";

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user?.uid ?? 'unknown',
        'userName': userName,
        'content': content,
        'tag': _selectedTag,
        'imageUrl': '',
        'imageData': _selectedImage == null
            ? ''
            : base64Encode(_selectedImage!),
        'photoUrl': user?.photoURL ?? '',
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

  Future<void> _pickPostImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 35,
      maxWidth: 1280,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (bytes.length > 600000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEn
                  ? 'Please choose a smaller image.'
                  : 'Vui lòng chọn ảnh nhẹ hơn.',
            ),
          ),
        );
      }
      return;
    }
    if (mounted) setState(() => _selectedImage = bytes);
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
                icon: const Icon(AppIcons.close, color: Colors.grey),
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
                    color: Color(0xFF6264D9),
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
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: widget.isDark
                            ? Colors.grey.shade900
                            : Colors.white,
                        icon: Icon(
                          AppIcons.arrowDropDown,
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
          Material(
            color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _pickPostImage,
              child: Container(
                width: double.infinity,
                height: _selectedImage == null ? 72 : 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: _selectedImage == null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            AppIcons.addPhotoAlternateOutlined,
                            color: Color(0xFF6264D9),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.isEn
                                ? 'Choose a photo'
                                : 'Chọn ảnh từ thiết bị',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_selectedImage!, fit: BoxFit.cover),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: IconButton.filled(
                              onPressed: () =>
                                  setState(() => _selectedImage = null),
                              icon: const Icon(AppIcons.close),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6264D9),
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
  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _reportPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('reports').add({
      'reporterId': user.uid,
      'targetType': 'post',
      'targetId': widget.postDoc.id,
      'reason': 'inappropriate',
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    _message(
      widget.isEn
          ? 'Report sent for review.'
          : 'Đã gửi báo cáo để quản trị viên xem xét.',
    );
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.isEn ? 'Delete post?' : 'Xóa bài viết?'),
        content: Text(
          widget.isEn
              ? 'This action cannot be undone.'
              : 'Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(widget.isEn ? 'Cancel' : 'Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(widget.isEn ? 'Delete' : 'Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.postDoc.reference.delete();
      _message(widget.isEn ? 'Post deleted.' : 'Đã xóa bài viết.');
    }
  }

  Future<void> _editPost() async {
    final data = widget.postDoc.data() as Map<String, dynamic>;
    final controller = TextEditingController(
      text: data['content'] as String? ?? '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.isEn ? 'Edit post' : 'Sửa bài viết'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 8,
          maxLength: 2000,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(widget.isEn ? 'Cancel' : 'Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(widget.isEn ? 'Save' : 'Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty && result.length <= 2000) {
      await widget.postDoc.reference.update({
        'content': result,
        'editedAt': FieldValue.serverTimestamp(),
      });
      _message(widget.isEn ? 'Post updated.' : 'Đã cập nhật bài viết.');
    }
  }

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

  Future<void> _toggleLike() => _toggleReaction(true);

  Future<void> _toggleDislike() => _toggleReaction(false);

  Future<void> _toggleReaction(bool like) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await CommunityStore.toggleReaction(
        widget.postDoc.reference,
        user,
        like: like,
        isEn: widget.isEn,
      );
    } catch (_) {
      if (mounted) {
        _message(
          widget.isEn
              ? 'Could not update. Please retry.'
              : 'Chưa cập nhật được. Vui lòng thử lại.',
        );
      }
    }
  }

  Future<void> _handleCommentAction(
    String action,
    DocumentSnapshot commentDoc,
    Map<String, dynamic> comment,
  ) async {
    if (action == 'report') {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': uid,
        'targetType': 'comment',
        'targetId': commentDoc.id,
        'postId': widget.postDoc.id,
        'reason': 'inappropriate',
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _message(widget.isEn ? 'Report sent for review.' : 'Đã gửi báo cáo.');
      return;
    }
    if (action == 'delete') {
      await CommunityStore.deleteComment(commentDoc.reference);
      return;
    }
    final controller = TextEditingController(
      text: comment['content'] as String? ?? '',
    );
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.isEn ? 'Edit comment' : 'Sửa bình luận'),
        content: TextField(
          controller: controller,
          maxLength: 1000,
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(widget.isEn ? 'Cancel' : 'Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(widget.isEn ? 'Save' : 'Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty && value.length <= 1000) {
      await commentDoc.reference.update({
        'content': value,
        'editedAt': FieldValue.serverTimestamp(),
      });
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
                          color: Color(0xFF6264D9),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          widget.isEn
                              ? 'Could not load comments.'
                              : 'Không thể tải bình luận.',
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
                        final commentDoc = snapshot.data!.docs[index];
                        var comment = commentDoc.data() as Map<String, dynamic>;
                        final currentUid =
                            FirebaseAuth.instance.currentUser?.uid;
                        final canManage =
                            currentUid == comment['userId'] ||
                            currentUid ==
                                (widget.postDoc.data()
                                    as Map<String, dynamic>)['userId'] ||
                            context.read<AppProvider>().isAdmin;
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
                                    color: Color(0xFF6264D9),
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
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                timeAgo,
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                padding: EdgeInsets.zero,
                                                onSelected: (value) =>
                                                    _handleCommentAction(
                                                      value,
                                                      commentDoc,
                                                      comment,
                                                    ),
                                                itemBuilder: (_) => [
                                                  if (currentUid ==
                                                      comment['userId'])
                                                    PopupMenuItem(
                                                      value: 'edit',
                                                      child: Text(
                                                        widget.isEn
                                                            ? 'Edit'
                                                            : 'Sửa',
                                                      ),
                                                    ),
                                                  if (canManage)
                                                    PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text(
                                                        widget.isEn
                                                            ? 'Delete'
                                                            : 'Xóa',
                                                      ),
                                                    ),
                                                  if (!canManage)
                                                    PopupMenuItem(
                                                      value: 'report',
                                                      child: Text(
                                                        widget.isEn
                                                            ? 'Report'
                                                            : 'Báo cáo',
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
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
                maxLength: 1000,
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
                    icon: const Icon(AppIcons.send, color: Color(0xFF6264D9)),
                    onPressed: () async {
                      if (commentCtrl.text.trim().isEmpty ||
                          commentCtrl.text.trim().length > 1000) {
                        return;
                      }

                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      final text = commentCtrl.text.trim();
                      commentCtrl.clear();
                      try {
                        await CommunityStore.addComment(
                          widget.postDoc.reference,
                          user,
                          text,
                          isEn: widget.isEn,
                        );
                      } catch (_) {
                        if (mounted) {
                          _message(
                            widget.isEn
                                ? 'Comment was not sent. Please retry.'
                                : 'Chưa gửi được bình luận. Vui lòng thử lại.',
                          );
                        }
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
    final imageData = data['imageData'] as String? ?? '';

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    List<dynamic> likedBy = data['likedBy'] ?? [];
    List<dynamic> dislikedBy = data['dislikedBy'] ?? [];

    bool isLiked = likedBy.contains(uid);
    bool isDisliked = dislikedBy.contains(uid);

    int likes = data['likes'] ?? 0;
    int dislikes = data['dislikes'] ?? 0;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUid != null && currentUid == data['userId'];
    final isAdmin = context.watch<AppProvider>().isAdmin;
    final userName = (data['userName'] as String?)?.trim().isNotEmpty == true
        ? data['userName'] as String
        : (widget.isEn ? 'User' : 'Người dùng');
    final photoUrl = data['photoUrl'] as String? ?? '';

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
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6264D9),
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                        const Icon(
                          AppIcons.public,
                          size: 12,
                          color: Colors.grey,
                        ),
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
                    color: Color(0xFF6264D9),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: widget.isEn ? 'Post options' : 'Tùy chọn bài viết',
                onSelected: (value) async {
                  try {
                    if (value == 'edit') await _editPost();
                    if (value == 'delete') await _deletePost();
                    if (value == 'report') await _reportPost();
                  } catch (_) {
                    _message(
                      widget.isEn
                          ? 'The action failed. Please try again.'
                          : 'Thao tác thất bại. Vui lòng thử lại.',
                    );
                  }
                },
                itemBuilder: (_) => [
                  if (isOwner)
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(widget.isEn ? 'Edit' : 'Sửa'),
                    ),
                  if (isOwner || isAdmin)
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(widget.isEn ? 'Delete' : 'Xóa'),
                    ),
                  if (!isOwner)
                    PopupMenuItem(
                      value: 'report',
                      child: Text(widget.isEn ? 'Report' : 'Báo cáo'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            data['content'],
            style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
          ),

          if (imageUrl.isNotEmpty || imageData.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: imageData.isNotEmpty
                  ? Image.memory(
                      base64Decode(imageData),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
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
                      isLiked ? AppIcons.thumbUp : AppIcons.thumbUpAltOutlined,
                      color: isLiked
                          ? const Color(0xFF6264D9)
                          : Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text(
                    "$likes",
                    style: TextStyle(
                      color: isLiked
                          ? const Color(0xFF6264D9)
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 5),

                  IconButton(
                    icon: Icon(
                      isDisliked
                          ? AppIcons.thumbDown
                          : AppIcons.thumbDownAltOutlined,
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
                  AppIcons.chatBubbleOutline,
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
                  AppIcons.shareOutlined,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
                onPressed: null,
                tooltip: widget.isEn
                    ? 'Sharing is coming soon'
                    : 'Chia sẻ sắp ra mắt',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
