import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_screens.dart'; // Đổi đường dẫn cho đúng file MainScreen của sếp nhe

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  String _selectedSkinType = "Da thường";
  bool _isLoading = false;

  final List<String> _skinTypes = [
    "Da thường",
    "Da dầu",
    "Da khô",
    "Da hỗn hợp",
    "Da nhạy cảm",
  ];

  Future<void> _finishIntroduction() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Lưu thẳng loại da lên Firebase
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'skinType': _selectedSkinType,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          // Vào thẳng màn hình chính Home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi lưu loại da: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // ICON VÀ LỜI GIỚI THIỆU APP
              const Icon(
                Icons.auto_awesome,
                size: 70,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),
              const Text(
                "Chào mừng bạn đến với\nSkincare App! 🎉",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Ứng dụng sẽ đồng hành cùng bạn trong hành trình theo dõi làn da, nhật ký mụn và tư vấn routine chuẩn y khoa cùng bác sĩ ảo Meow AI.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),

              // KHU VỰC CHỌN LOẠI DA TỐI GIẢN
              const Text(
                "Vui lòng chọn loại da của bạn:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _skinTypes.map((type) {
                  bool isSelected = _selectedSkinType == type;
                  return ChoiceChip(
                    label: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.blueAccent,
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(
                      color: isSelected
                          ? Colors.blueAccent
                          : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() => _selectedSkinType = type);
                      }
                    },
                  );
                }).toList(),
              ),

              const Spacer(),

              // NÚT VÀO HOME
              ElevatedButton(
                onPressed: _isLoading ? null : _finishIntroduction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
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
                    : const Text(
                        'Bắt đầu ngay ->',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
