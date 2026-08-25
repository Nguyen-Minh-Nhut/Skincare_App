import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main_screens.dart';
import 'introduction_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
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
        String loginEmail = loginId;

        if (loginId.isEmpty || password.isEmpty) {
          throw FirebaseAuthException(
            code: 'empty-credentials',
            message: 'Vui lòng nhập đầy đủ tài khoản và mật khẩu.',
          );
        }

        // Nếu nhập Username (không có kí tự @) -> Đi tìm Email tương ứng trên Firestore
        if (!loginId.contains('@')) {
          var userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: loginId.toLowerCase())
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 15));

          // Tương thích tài khoản cũ từng lưu username có chữ hoa.
          if (userQuery.docs.isEmpty && loginId != loginId.toLowerCase()) {
            userQuery = await FirebaseFirestore.instance
                .collection('users')
                .where('username', isEqualTo: loginId)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 15));
          }

          if (userQuery.docs.isEmpty) {
            throw FirebaseAuthException(
              code: 'username-not-found',
              message: 'Tên đăng nhập không tồn tại.',
            );
          }
          loginEmail = userQuery.docs.first['email'];
        }

        debugPrint("⏳ ĐANG ĐĂNG NHẬP...");
        User? currentUser;
        try {
          // Tiến hành đăng nhập vào Firebase Auth bằng Email
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: loginEmail, password: password)
              .timeout(const Duration(seconds: 15));
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

        final duplicateUsername = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 15));
        if (duplicateUsername.docs.isNotEmpty) {
          throw FirebaseAuthException(
            code: 'username-already-in-use',
            message: 'Tên người dùng này đã được sử dụng.',
          );
        }

        // 1. Tạo tài khoản trên hệ thống Firebase Auth
        debugPrint("⏳ BƯỚC 1: ĐANG TẠO AUTH...");
        User? currentUser;
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
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
            backgroundColor: Colors.redAccent,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ==========================================
  // HÀM HIỆN POPUP QUÊN MẬT KHẨU
  // ==========================================
  void _showForgotPasswordDialog() {
    final TextEditingController resetController = TextEditingController();
    bool isSending = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Quên mật khẩu?",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Nhập Username hoặc Email để nhận liên kết đặt lại mật khẩu từ hệ thống.",
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: resetController,
                  decoration: InputDecoration(
                    hintText: "Email hoặc Tên user",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isSending
                    ? null
                    : () async {
                        String input = resetController.text.trim();
                        if (input.isEmpty) return;

                        setDialogState(() => isSending = true);
                        try {
                          String emailToReset = input;
                          if (!input.contains('@')) {
                            var userQuery = await FirebaseFirestore.instance
                                .collection('users')
                                .where('username', isEqualTo: input)
                                .limit(1)
                                .get();
                            if (userQuery.docs.isEmpty) {
                              throw Exception("Không tìm thấy Tên user này.");
                            }
                            emailToReset = userQuery.docs.first['email'];
                          }

                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: emailToReset,
                          );
                          if (dialogContext.mounted) {
                            final messenger = ScaffoldMessenger.of(
                              dialogContext,
                            );
                            Navigator.pop(dialogContext);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Đã gửi liên kết đổi mật khẩu vào hộp thư Email thành công!",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!dialogContext.mounted) return;
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text("Lỗi: $e"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        } finally {
                          if (dialogContext.mounted) {
                            setDialogState(() => isSending = false);
                          }
                        }
                      },
                child: isSending
                    ? const SizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Gửi link",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    ).whenComplete(resetController.dispose);
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
                const SizedBox(height: 40),

                if (!isLogin) ...[
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Họ và tên hiển thị',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _usernameController,
                    hint: 'Tên user (Viết liền, không dấu)',
                    icon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 15),
                ],

                _buildTextField(
                  controller: _loginIdController,
                  hint: isLogin ? 'Email hoặc Tên user' : 'Email đăng ký',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                _buildTextField(
                  controller: _passwordController,
                  hint: 'Mật khẩu',
                  icon: Icons.lock_outline,
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
                    shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
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
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLogin ? 'Chưa có tài khoản?' : 'Đã có tài khoản?',
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
}
