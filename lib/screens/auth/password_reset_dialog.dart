import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_icons.dart';

typedef PasswordResetSender = Future<void> Function(String email);

Future<void> showPasswordResetDialog(
  BuildContext context, {
  String initialEmail = '',
  bool isEnglish = false,
  PasswordResetSender? sendResetEmail,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => PasswordResetDialog(
      initialEmail: initialEmail,
      isEnglish: isEnglish,
      sendResetEmail: sendResetEmail,
    ),
  );
}

/// Owns its controller until the route's closing animation has finished.
class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({
    super.key,
    this.initialEmail = '',
    this.isEnglish = false,
    this.sendResetEmail,
  });
  final String initialEmail;
  final bool isEnglish;
  final PasswordResetSender? sendResetEmail;

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email;
  bool _sending = false;
  bool _sent = false;
  String? _error;
  String _sentEmail = '';
  int _seconds = 0;
  Timer? _timer;
  bool get en => widget.isEnglish;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || _seconds > 0 || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      if (widget.sendResetEmail != null) {
        await widget.sendResetEmail!(email).timeout(
          const Duration(seconds: 20),
        );
      } else {
        final auth = FirebaseAuth.instance;
        await (() async {
          await auth.setLanguageCode(en ? 'en' : 'vi');
          await auth.sendPasswordResetEmail(email: email);
        })().timeout(const Duration(seconds: 20));
      }
      if (mounted) _showSent(email);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      // The same confirmation preserves Firebase's email-enumeration protection.
      if (error.code == 'user-not-found') {
        _showSent(email);
      } else {
        setState(
          () => _error = switch (error.code) {
            'invalid-email' =>
              en
                  ? 'Enter a valid email address.'
                  : 'Vui lòng nhập email hợp lệ.',
            'too-many-requests' =>
              en
                  ? 'Too many requests. Please wait a few minutes.'
                  : 'Bạn gửi quá nhiều lần. Vui lòng đợi vài phút rồi thử lại.',
            'network-request-failed' =>
              en
                  ? 'Check your internet connection and try again.'
                  : 'Kiểm tra kết nối mạng rồi thử lại nhé.',
            _ =>
              en
                  ? 'Could not send the email. Please try again later.'
                  : 'Chưa gửi được email. Vui lòng thử lại sau.',
          },
        );
      }
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _error = en
              ? 'The request took too long. Check your inbox before trying again.'
              : 'Phản hồi hơi lâu. Kiểm tra hộp thư trước khi gửi lại nhé.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = en
              ? 'Could not send the email. Please try again.'
              : 'Chưa gửi được email. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSent(String email) {
    setState(() {
      _sent = true;
      _sentEmail = email;
      _seconds = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
      if (_seconds == 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF2F3FA) : const Color(0xFF222438);
    final muted = dark ? const Color(0xFFB6B8CC) : const Color(0xFF6E7187);
    const accent = Color(0xFF6558D9);
    return Dialog(
      backgroundColor: dark ? const Color(0xFF242638) : Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: en ? 'Close' : 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(AppIcons.close, color: muted, size: 20),
                  ),
                ),
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: _sent
                          ? const Color(0xFFE6F6ED)
                          : const Color(0xFFEFEDFF),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      _sent
                          ? AppIcons.checkCircleRounded
                          : AppIcons.lockOutline,
                      size: 32,
                      color: _sent ? const Color(0xFF278459) : accent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _sent
                      ? (en ? 'Check your inbox' : 'Kiểm tra hộp thư nhé')
                      : (en ? 'Reset your password' : 'Đặt lại mật khẩu'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _sent
                      ? (en
                            ? 'If this email is eligible, you will receive a link to choose a new password.'
                            : 'Nếu email này đủ điều kiện, bạn sẽ nhận được liên kết để tạo mật khẩu mới.')
                      : (en
                            ? 'Enter your account email. We will send you a link to choose a new password.'
                            : 'Nhập email tài khoản của bạn. Tụi mình sẽ gửi liên kết để bạn tạo mật khẩu mới.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, height: 1.5, fontSize: 14),
                ),
                const SizedBox(height: 24),
                if (_sent) ...[
                  Text(
                    _sentEmail,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    en
                        ? 'Check Spam/Junk too. Open the link in your email, save your new password, then return to the app.'
                        : 'Nhớ kiểm tra cả mục Thư rác. Mở liên kết trong email, lưu mật khẩu mới rồi quay lại ứng dụng.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, height: 1.5, fontSize: 13),
                  ),
                ] else
                  TextFormField(
                    controller: _email,
                    enabled: !_sending,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.send,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    style: TextStyle(color: ink),
                    onFieldSubmitted: (_) => _send(),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return en
                            ? 'Enter your email address.'
                            : 'Bạn chưa nhập email.';
                      }
                      if (!RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(email)) {
                        return en
                            ? 'Enter a valid email address.'
                            : 'Email chưa đúng định dạng.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'ban@example.com',
                      labelStyle: TextStyle(color: muted),
                      prefixIcon: const Icon(
                        AppIcons.emailOutlined,
                        color: accent,
                        size: 21,
                      ),
                      filled: true,
                      fillColor: dark
                          ? const Color(0xFF303247)
                          : const Color(0xFFF7F7FC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: dark
                              ? Colors.white12
                              : const Color(0xFFE6E5F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: accent, width: 1.5),
                      ),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: dark
                              ? Colors.red.shade200
                              : Colors.red.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _sending || (_sent && _seconds > 0) ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _sent
                              ? (_seconds > 0
                                    ? (en
                                          ? 'Resend in ${_seconds}s'
                                          : 'Gửi lại sau ${_seconds}s')
                                    : (en ? 'Resend email' : 'Gửi lại email'))
                              : (en
                                    ? 'Send reset link'
                                    : 'Gửi liên kết đặt lại'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    _sent
                        ? (en ? 'Done' : 'Xong')
                        : (en ? 'Go back' : 'Quay lại'),
                    style: TextStyle(color: muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
