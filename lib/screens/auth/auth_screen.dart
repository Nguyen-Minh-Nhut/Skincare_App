import 'package:flutter/material.dart';
import 'package:skincare_app/widgets/app_icons.dart';
import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main_screens.dart';
import 'introduction_screen.dart';
import 'password_reset_dialog.dart';
import '../../services/facebook_sign_in_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _authTimeout = Duration(seconds: 10);
  static const _firestoreTimeout = Duration(seconds: 6);

  bool isLogin = true;
  bool isLoading = false;

  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // ==========================================
  // HÀM XỬ LÝ ĐĂNG NHẬP VÀ ĐĂNG KÝ
  // ==========================================
  Future<void> _submitAuth() async {
    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // ---------------- XỬ LÝ ĐĂNG NHẬP (ĐÃ BỌC GIÁP CHỐNG PIGEON) ----------------
        String loginId = _loginIdController.text.trim();
        String password = _passwordController.text;
        if (!loginId.contains('@') || password.isEmpty) {
          throw FirebaseAuthException(
            code: 'empty-credentials',
            message: 'Vui lòng nhập email và mật khẩu hợp lệ.',
          );
        }

        debugPrint("⏳ ĐANG ĐĂNG NHẬP...");
        User? currentUser;
        try {
          // Tiến hành đăng nhập vào Firebase Auth bằng Email
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: loginId, password: password)
              .timeout(_authTimeout);
          currentUser = FirebaseAuth.instance.currentUser;
        } catch (e) {
          // NẾU BẮT ĐƯỢC LỖI PIGEON LÚC ĐĂNG NHẬP
          if (e.toString().contains('PigeonUserDetails')) {
            debugPrint(
              "⚠️ Đã chặn lỗi Pigeon lúc Đăng Nhập! Đang lấy thông tin user ngầm...",
            );
            currentUser = FirebaseAuth.instance.currentUser;
          } else {
            rethrow; // Lỗi sai mật khẩu, sai email thì quăng ra ngoài bình thường
          }
        }

        if (currentUser == null) {
          throw Exception(
            "Đăng nhập thất bại, vui lòng kiểm tra lại thông tin.",
          );
        }

        debugPrint("✅ ĐĂNG NHẬP THÀNH CÔNG (UID: ${currentUser.uid})");

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        // ---------------- XỬ LÝ ĐĂNG KÝ (ĐÃ BỌC GIÁP CHỐNG PIGEON) ----------------
        String email = _loginIdController.text.trim();
        String password = _passwordController.text.trim();
        String username = _usernameController.text.trim().toLowerCase();
        String fullName = _nameController.text.trim();

        if (!email.contains('@')) {
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'Vui lòng nhập Email hợp lệ.',
          );
        }
        if (username.isEmpty || username.contains(' ')) {
          throw FirebaseAuthException(
            code: 'invalid-username',
            message: 'Username không được chứa khoảng trắng.',
          );
        }

        // 1. Tạo tài khoản trên hệ thống Firebase Auth
        debugPrint("⏳ BƯỚC 1: ĐANG TẠO AUTH...");
        User? currentUser;
        try {
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password)
              .timeout(_authTimeout);
          currentUser = FirebaseAuth.instance.currentUser;
        } catch (e) {
          // NẾU BẮT ĐƯỢC LỖI PIGEON LÚC ĐĂNG KÝ
          if (e.toString().contains('PigeonUserDetails')) {
            debugPrint(
              "⚠️ Đã chặn lỗi Pigeon lúc Đăng Ký! Đang lấy thông tin user ngầm...",
            );
            currentUser = FirebaseAuth.instance.currentUser;
          } else {
            rethrow;
          }
        }

        // Chốt chặn an toàn: Nếu User vẫn null tức là tạo thất bại thật sự
        if (currentUser == null) {
          throw Exception(
            "Không thể tạo tài khoản lúc này, vui lòng thử lại sau!",
          );
        }

        debugPrint("✅ BƯỚC 1: TẠO AUTH THÀNH CÔNG (UID: ${currentUser.uid})");

        // 2. Ghi dữ liệu tài khoản mới vào Firestore
        debugPrint("⏳ BƯỚC 2: ĐANG LƯU LÊN FIRESTORE...");
        final firestore = FirebaseFirestore.instance;
        final userRef = firestore.collection('users').doc(currentUser.uid);
        final usernameRef = firestore.collection('usernames').doc(username);
        try {
          await firestore.runTransaction((transaction) async {
            final usernameSnapshot = await transaction.get(usernameRef);
            if (usernameSnapshot.exists) {
              throw FirebaseAuthException(
                code: 'username-already-in-use',
                message: 'Tên người dùng này đã được sử dụng.',
              );
            }
            transaction.set(usernameRef, {
              'uid': currentUser!.uid,
              'createdAt': FieldValue.serverTimestamp(),
            });
            transaction.set(userRef, {
              'uid': currentUser.uid,
              'email': email,
              'username': username,
              'name': fullName,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          });
        } catch (_) {
          // Không để lại tài khoản Auth mồ côi nếu phần hồ sơ/username thất bại.
          await currentUser.delete();
          rethrow;
        }
        debugPrint("✅ BƯỚC 2: LƯU FIRESTORE THÀNH CÔNG");

        // 3. Chuyển ngay sang màn hình giới thiệu
        if (mounted) {
          debugPrint("🚀 BƯỚC 3: CHUYỂN MÀN HÌNH GIỚI THIỆU");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const IntroductionScreen()),
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kết nối Firebase quá chậm. Vui lòng thử lại.'),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ LỖI RỒI: $e");
      String message = 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại!';
      if (e is FirebaseAuthException) {
        message = e.message ?? message;
        if (e.code == 'wrong-password') message = 'Sai mật khẩu rồi bạn ơi.';
        if (e.code == 'invalid-credential') {
          message = 'Thông tin đăng nhập không chính xác.';
        }
        if (e.code == 'user-not-found') {
          message = 'Không tìm thấy tài khoản này.';
        }
        if (e.code == 'user-disabled') {
          message = 'Tài khoản này đã bị vô hiệu hóa.';
        }
        if (e.code == 'network-request-failed') {
          message = 'Không có kết nối mạng. Vui lòng kiểm tra Internet.';
        }
        if (e.code == 'too-many-requests') {
          message = 'Bạn đã thử quá nhiều lần. Vui lòng đợi rồi thử lại.';
        }
        if (e.code == 'empty-credentials') {
          message = 'Vui lòng nhập đầy đủ tài khoản và mật khẩu.';
        }
        if (e.code == 'email-already-in-use') {
          message = 'Email này đã được đăng ký bởi tài khoản khác.';
        }
        if (e.code == 'username-not-found') {
          message = 'Tên người dùng này không tồn tại trên hệ thống.';
        }
        if (e.code == 'username-already-in-use') {
          message = 'Tên người dùng này đã được sử dụng.';
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final googleUser = await GoogleSignIn().signIn().timeout(_authTimeout);
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication.timeout(_authTimeout);
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(_authTimeout);
      await _completeSocialSignIn(result.user, provider: 'google.com');
    } on TimeoutException {
      _showAuthError('Đăng nhập Google quá thời gian. Vui lòng thử lại.');
    } catch (error) {
      _showAuthError(_socialErrorMessage(error, 'Google'));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final result = await FacebookSignInService().signIn();
      if (result == null || !mounted) return;
      await _completeSocialSignIn(result.user, provider: 'facebook.com');
    } on TimeoutException {
      _showAuthError('Kết nối quá chậm. Vui lòng kiểm tra mạng và thử lại.');
    } catch (error) {
      _showAuthError(_socialErrorMessage(error, 'Facebook'));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _completeSocialSignIn(
    User? user, {
    required String provider,
  }) async {
    if (user == null) {
      throw FirebaseAuthException(
        code: 'social-user-missing',
        message: 'Không lấy được thông tin tài khoản.',
      );
    }

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    await userRef
        .set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? '',
          'photoUrl': user.photoURL,
          'provider': provider,
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(_firestoreTimeout);

    final profile = await userRef.get().timeout(_firestoreTimeout);
    final skinType = profile.data()?['skinType']?.toString().trim() ?? '';
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => skinType.isNotEmpty && skinType != 'Chưa xác định'
            ? const MainScreen()
            : const IntroductionScreen(),
      ),
    );
  }

  String _socialErrorMessage(Object error, String provider) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'Email này đã có tài khoản. Hãy đăng nhập bằng Google hoặc email/mật khẩu đã dùng trước đó.';
        case 'network-request-failed':
          return 'Không có kết nối mạng. Vui lòng kiểm tra Internet.';
        case 'operation-not-allowed':
          return 'Đăng nhập $provider chưa được bật trong Firebase Console.';
        case 'invalid-credential':
          return 'Thông tin đăng nhập $provider không hợp lệ.';
      }
      return error.message ?? 'Không thể đăng nhập bằng $provider.';
    }
    final text = error.toString();
    if (text.contains('ApiException: 10') || text.contains('DEVELOPER_ERROR')) {
      return 'Google Sign-In chưa được cấu hình SHA-1/SHA-256 trong Firebase.';
    }
    return 'Không thể đăng nhập bằng $provider. Vui lòng thử lại.';
  }

  void _showAuthError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showForgotPasswordDialog() {
    showPasswordResetDialog(context, initialEmail: _loginIdController.text);
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/image/Meow.png',
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      semanticLabel: 'Skincare App logo',
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Text(
                  isLogin ? 'Chào mừng trở lại!' : 'Tạo tài khoản mới',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isLogin
                      ? 'Đăng nhập để tiếp tục chăm sóc da'
                      : 'Bắt đầu hành trình làm đẹp ngay hôm nay',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 28),

                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.52),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF5356A8,
                            ).withValues(alpha: 0.10),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isLogin) ...[
                            _buildTextField(
                              controller: _nameController,
                              hint: 'Họ và tên hiển thị',
                              icon: AppIcons.personOutline,
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _usernameController,
                              hint: 'Tên user (Viết liền, không dấu)',
                              icon: AppIcons.alternateEmail,
                            ),
                            const SizedBox(height: 15),
                          ],

                          _buildTextField(
                            controller: _loginIdController,
                            hint: isLogin ? 'Email' : 'Email đăng ký',
                            icon: AppIcons.emailOutlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 15),

                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Mật khẩu',
                            icon: AppIcons.lockOutline,
                            isPassword: true,
                          ),

                          if (isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: const Text(
                                  'Quên mật khẩu?',
                                  style: TextStyle(color: Colors.blueAccent),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 30),

                          ElevatedButton(
                            onPressed: isLoading ? null : _submitAuth,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 5,
                              shadowColor: Colors.blueAccent.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isLogin ? 'Đăng nhập' : 'Đăng ký',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 22),

                          if (isLogin) ...[
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'hoặc tiếp tục với',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildSocialButton(
                              label: 'Tiếp tục với Google',
                              brand: 'G',
                              color: const Color(0xFF4285F4),
                              onPressed: _signInWithGoogle,
                            ),
                            const SizedBox(height: 10),
                            _buildSocialButton(
                              label: 'Tiếp tục với Facebook',
                              brand: 'f',
                              color: const Color(0xFF1877F2),
                              badge: 'Sắp ra mắt',
                              onPressed: _signInWithFacebook,
                            ),
                            const SizedBox(height: 8),
                          ],

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLogin
                                    ? 'Chưa có tài khoản?'
                                    : 'Đã có tài khoản?',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    isLogin = !isLogin;
                                    _loginIdController.clear();
                                    _passwordController.clear();
                                    _nameController.clear();
                                    _usernameController.clear();
                                  });
                                },
                                child: Text(
                                  isLogin ? 'Đăng ký ngay' : 'Đăng nhập',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required String brand,
    required Color color,
    required VoidCallback onPressed,
    String? badge,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  brand,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: brand == 'f' ? 24 : 17,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    fontFamily: brand == 'f' ? 'Arial' : null,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF24262F),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(
                  AppIcons.chevronRight,
                  size: 15,
                  color: Colors.grey.shade500,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
