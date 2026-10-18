import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skincare_app/widgets/app_icons.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _resolve(
    BuildContext context,
    DocumentSnapshot report, {
    required bool deleteContent,
  }) async {
    final data = report.data() as Map<String, dynamic>;
    final batch = FirebaseFirestore.instance.batch();
    final targetId = data['targetId'] as String?;
    if (deleteContent && data['targetType'] == 'post' && targetId != null) {
      batch.delete(
        FirebaseFirestore.instance.collection('posts').doc(targetId),
      );
    }
    final postId = data['postId'] as String?;
    if (deleteContent &&
        data['targetType'] == 'comment' &&
        targetId != null &&
        postId != null) {
      batch.delete(
        FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(targetId),
      );
      batch.update(FirebaseFirestore.instance.collection('posts').doc(postId), {
        'comments': FieldValue.increment(-1),
        'lastCommentId': targetId,
      });
    }
    batch.update(report.reference, {
      'status': deleteContent ? 'content_deleted' : 'dismissed',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
    final log = FirebaseFirestore.instance.collection('adminLogs').doc();
    batch.set(log, {
      'action': deleteContent ? 'delete_reported_content' : 'dismiss_report',
      'targetId': data['targetId'],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xử lý báo cáo.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quản trị nội dung')),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'open')
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Không thể tải danh sách báo cáo.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Không có báo cáo đang chờ xử lý.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final report = snapshot.data!.docs[index];
            final data = report.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(
                  AppIcons.flagOutlined,
                  color: Colors.orange,
                ),
                title: Text(
                  '${data['targetType'] ?? 'Nội dung'} • ${data['reason'] ?? 'Không rõ lý do'}',
                ),
                subtitle: Text('ID: ${data['targetId'] ?? '-'}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _resolve(
                    context,
                    report,
                    deleteContent: value == 'delete',
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'dismiss',
                      child: Text('Bỏ qua báo cáo'),
                    ),
                    PopupMenuItem(value: 'delete', child: Text('Xóa nội dung')),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
