import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Keeps counters and notifications in the same commit as their source action.
class CommunityStore {
  static Map<String, dynamic> _notification(
    User user,
    String postId,
    String type,
    String commentId,
    bool isEn,
  ) => {
    'actorId': user.uid,
    'postId': postId,
    'commentId': commentId,
    'type': type,
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
    'title': type == 'like'
        ? (isEn ? 'New like' : 'Lượt thích mới')
        : (isEn ? 'New comment' : 'Bình luận mới'),
    'body': type == 'like'
        ? (isEn
              ? 'Someone liked your post.'
              : 'Có người vừa thích bài viết của bạn.')
        : (isEn
              ? 'Someone commented on your post.'
              : 'Có người vừa bình luận bài viết của bạn.'),
  };

  static Future<void> toggleReaction(
    DocumentReference post,
    User user, {
    required bool like,
    required bool isEn,
  }) async {
    final db = FirebaseFirestore.instance;
    await db.runTransaction((tx) async {
      final snapshot = await tx.get(post);
      final data = snapshot.data() as Map<String, dynamic>;
      final likes = List<String>.from(data['likedBy'] ?? []);
      final dislikes = List<String>.from(data['dislikedBy'] ?? []);
      final selected = like ? likes : dislikes;
      final other = like ? dislikes : likes;
      final removing = selected.contains(user.uid);
      if (removing) {
        selected.remove(user.uid);
      } else {
        selected.add(user.uid);
        other.remove(user.uid);
      }
      // One notification per user's first like avoids repeat-toggle spam.
      final notification = db
          .collection('users')
          .doc(data['userId'])
          .collection('notifications')
          .doc('like_${post.id}_${user.uid}');
      final shouldNotify = like && !removing && data['userId'] != user.uid;
      // Send through a separate immutable receipt: reading another user's
      // notification is deliberately prohibited by the security rules.
      final receipt = post.collection('likeReceipts').doc(user.uid);
      final sent = shouldNotify ? (await tx.get(receipt)).exists : true;
      tx.update(post, {
        'likedBy': likes,
        'dislikedBy': dislikes,
        'likes': likes.length,
        'dislikes': dislikes.length,
      });
      if (shouldNotify && !sent) {
        tx.set(receipt, {'createdAt': FieldValue.serverTimestamp()});
        tx.set(
          notification,
          _notification(user, post.id, 'like', 'none', isEn),
        );
      }
    });
  }

  static Future<void> addComment(
    DocumentReference post,
    User user,
    String content, {
    required bool isEn,
  }) async {
    final db = FirebaseFirestore.instance;
    final comment = post.collection('comments').doc();
    await db.runTransaction((tx) async {
      final snapshot = await tx.get(post);
      final data = snapshot.data() as Map<String, dynamic>;
      tx.set(comment, {
        'userId': user.uid,
        'userName':
            user.displayName ?? user.email?.split('@')[0] ?? 'Người dùng',
        'content': content,
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(post, {
        'comments': (data['comments'] as num? ?? 0).toInt() + 1,
        'lastCommentId': comment.id,
      });
      if (data['userId'] != user.uid) {
        tx.set(
          db
              .collection('users')
              .doc(data['userId'])
              .collection('notifications')
              .doc('comment_${comment.id}'),
          _notification(user, post.id, 'comment', comment.id, isEn),
        );
      }
    });
  }

  static Future<void> deleteComment(DocumentReference comment) async {
    final post = comment.parent.parent!;
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final existing = await tx.get(comment);
      final snapshot = await tx.get(post);
      if (!existing.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      tx.delete(comment);
      tx.update(post, {
        'comments': (data['comments'] as num).toInt() - 1,
        'lastCommentId': comment.id,
      });
    });
  }
}
