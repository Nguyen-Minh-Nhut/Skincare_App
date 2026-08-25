import 'package:flutter/material.dart';
import '../../widgets/ambient_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // Truyền thêm biến isEn vào hàm tính thời gian
  String _getTimeAgo(Timestamp? timestamp, bool isEn) {
    if (timestamp == null) return isEn ? "Just now" : "Vừa xong";
    Duration diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inDays > 0) {
      return isEn ? "${diff.inDays} days ago" : "${diff.inDays} ngày trước";
    }
    if (diff.inHours > 0) {
      return isEn ? "${diff.inHours} hours ago" : "${diff.inHours} giờ trước";
    }
    if (diff.inMinutes > 0) {
      return isEn
          ? "${diff.inMinutes} mins ago"
          : "${diff.inMinutes} phút trước";
    }
    return isEn ? "Just now" : "Vừa xong";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // LẮNG NGHE TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.isEnglish;
    final isDark = appProvider.isDarkMode;

    // CÀI ĐẶT MÀU ĐỘNG
    final cardColor = glassSurfaceColor(context);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;
    // Màu nền cho thông báo chưa đọc
    final unreadColor = isDark
        ? Colors.blue.withValues(alpha: 0.15)
        : Colors.blue.shade50.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          isEn ? "Notifications" : "Thông báo",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.blueAccent),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEn ? 'Marked all as read' : 'Đã đánh dấu đọc tất cả',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Text(
                isEn ? "Please login" : "Vui lòng đăng nhập",
                style: TextStyle(color: textColor),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 80,
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          isEn
                              ? "No notifications yet"
                              : "Bạn chưa có thông báo nào",
                          style: TextStyle(color: subTextColor, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    var data =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    bool isRead = data['isRead'] ?? false;
                    String type = data['type'] ?? 'system';

                    IconData iconData = Icons.notifications;
                    Color iconColor = Colors.blueAccent;

                    if (type == 'like') {
                      iconData = Icons.favorite;
                      iconColor = Colors.pinkAccent;
                    } else if (type == 'comment') {
                      iconData = Icons.chat_bubble;
                      iconColor = Colors.green;
                    } else if (type == 'routine') {
                      iconData = Icons.alarm;
                      iconColor = Colors.orangeAccent;
                    }

                    return Container(
                      color: isRead ? cardColor : unreadColor,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withValues(alpha: 0.2),
                          child: Icon(iconData, color: iconColor, size: 20),
                        ),
                        title: Text(
                          data['title'] ??
                              (isEn ? 'New Notification' : 'Thông báo mới'),
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            data['body'] ?? '',
                            style: TextStyle(color: subTextColor, fontSize: 13),
                          ),
                        ),
                        trailing: Text(
                          _getTimeAgo(data['createdAt'] as Timestamp?, isEn),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                        onTap: () {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('notifications')
                              .doc(snapshot.data!.docs[index].id)
                              .update({'isRead': true});
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
