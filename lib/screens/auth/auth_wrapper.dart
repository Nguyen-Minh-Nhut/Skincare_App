import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Vì file này nằm trong thư mục 'auth', nên gọi auth_screen và introduction_screen thì KHÔNG cần ../
import 'auth_screen.dart';
import 'introduction_screen.dart';

// Riêng main_screens.dart nằm ở ngoài, nên CẦN ../ để lùi ra một bước
import '../main_screens.dart';

enum SignedInDestination { main, introduction }

SignedInDestination resolveSignedInDestination({
  required bool firestoreFailed,
  required bool documentExists,
  Map<String, dynamic>? userData,
}) {
  // Firebase Auth mới là nguồn xác thực. Khi Firestore tạm mất mạng, không
  // được đẩy một người đã đăng nhập quay lại onboarding.
  if (firestoreFailed) return SignedInDestination.main;
  if (!documentExists || userData == null) {
    return SignedInDestination.introduction;
  }
  final skinType = userData['skinType']?.toString().trim() ?? '';
  return skinType.isNotEmpty && skinType != 'Chưa xác định'
      ? SignedInDestination.main
      : SignedInDestination.introduction;
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Đang tải kiểm tra trạng thái
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          );
        }

        // 2. Chưa đăng nhập -> Về thẳng màn hình Đăng Nhập / Đăng Ký
        if (!snapshot.hasData || snapshot.data == null) {
          return const AuthScreen();
        }

        // 3. ĐÃ ĐĂNG NHẬP -> Kiểm tra trên Firestore xem có loại da chưa
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
              );
            }

            if (userSnapshot.hasError) {
              return const MainScreen();
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>?;
              if (resolveSignedInDestination(
                    firestoreFailed: false,
                    documentExists: true,
                    userData: userData,
                  ) ==
                  SignedInDestination.main) {
                return const MainScreen();
              }
            }

            // Mọi trường hợp còn lại (db trống, chưa chọn loại da) -> Đẩy vào trang Giới Thiệu
            return const IntroductionScreen();
          },
        );
      },
    );
  }
}
