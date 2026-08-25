import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_screens.dart';

class OnboardingQuizScreen extends StatefulWidget {
  const OnboardingQuizScreen({super.key});

  @override
  State<OnboardingQuizScreen> createState() => _OnboardingQuizScreenState();
}

class _OnboardingQuizScreenState extends State<OnboardingQuizScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Biến lưu câu trả lời của user
  String _selectedSkinType = "";
  String _selectedConcern = "";
  String _selectedGoal = "";

  // Dữ liệu các câu hỏi khảo sát
  final List<String> _skinTypes = [
    "Da thường",
    "Da dầu",
    "Da khô",
    "Da hỗn hợp",
    "Da nhạy cảm",
  ];
  final List<String> _concerns = [
    "Mụn viêm / Mụn ẩn",
    "Nám / Tàn nhang",
    "Lỗ chân lông to",
    "Da xỉn màu",
    "Kích ứng / Đỏ rát",
  ];
  final List<String> _goals = [
    "Trị mụn dứt điểm",
    "Mờ thâm sáng da",
    "Cấp ẩm mịn màng",
    "Thu nhỏ lỗ chân lông",
    "Phục hồi da khỏe mạnh",
  ];

  // Hàm chuyển bước hoặc hoàn tất lưu vào Firebase
  void _nextStep() async {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Nếu đã ở bước cuối -> Tiến hành lưu FirebaseFirestore
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'skinType': _selectedSkinType,
                'skinConcern': _selectedConcern,
                'skinGoal': _selectedGoal,
                'hasCompletedOnboarding': true,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

          if (mounted) {
            // Chuyển thẳng vào màn hình chính của App
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi lưu cấu hình: $e'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // 1. THANH TIẾN TRÌNH KHẢO SÁT
            _buildProgressBar(),

            // 2. KHU VỰC CÂU HỎI TRƯỢT (PAGEVIEW)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Khóa không cho vuốt bậy
                children: [
                  _buildQuizPage(
                    "✨ Bước 1: Tìm hiểu loại da",
                    "Da bạn thuộc loại nào dưới đây?",
                    _skinTypes,
                    _selectedSkinType,
                    (val) => setState(() => _selectedSkinType = val),
                  ),
                  _buildQuizPage(
                    "🔮 Bước 2: Tình trạng hiện tại",
                    "Vấn đề bạn đang lo lắng nhất là gì?",
                    _concerns,
                    _selectedConcern,
                    (val) => setState(() => _selectedConcern = val),
                  ),
                  _buildQuizPage(
                    "🎯 Bước 3: Mục tiêu làm đẹp",
                    "Mục tiêu lớn nhất của bạn là gì?",
                    _goals,
                    _selectedGoal,
                    (val) => setState(() => _selectedGoal = val),
                  ),
                ],
              ),
            ),

            // 3. NÚT TIẾP TỤC BÁM ĐÁY
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // Widget vẽ thanh Progress Bar
  Widget _buildProgressBar() {
    double progress = (_currentStep + 1) / 3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 18,
              color: Colors.black87,
            ),
            onPressed: _currentStep == 0
                ? () => Navigator.pop(context)
                : () {
                    setState(() => _currentStep--);
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6, // Làm thanh trượt mỏng lại
                backgroundColor: Colors.grey.shade100,
                valueColor: const AnimationValueColor<Color>(Colors.blueAccent),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            "${_currentStep + 1}/3",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Giao diện chung cho từng trang câu hỏi
  Widget _buildQuizPage(
    String stepTitle,
    String questionText,
    List<String> options,
    String selectedValue,
    Function(String) onSelect,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ĐÃ FIX: Chữ nhỏ lại, gọn gàng hơn
          Text(
            stepTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 8),
          // ĐÃ FIX: Hạ từ w800 xuống w600, giảm size
          Text(
            questionText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 30),

          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                String option = options[index];
                bool isSelected = selectedValue == option;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => onSelect(option),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.blueAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ĐÃ FIX: Khi không chọn thì chữ bình thường (w400), chọn mới đậm nhẹ (w600)
                          Text(
                            option,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.blue.shade900
                                  : Colors.black87,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Khung nút bấm ở dưới cùng màn hình
  Widget _buildBottomButton() {
    bool isOptionSelected =
        (_currentStep == 0 && _selectedSkinType.isNotEmpty) ||
        (_currentStep == 1 && _selectedConcern.isNotEmpty) ||
        (_currentStep == 2 && _selectedGoal.isNotEmpty);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: (isOptionSelected && !_isLoading) ? _nextStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            disabledBackgroundColor: Colors.grey.shade200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ), // Bo góc thanh lịch
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
              // ĐÃ FIX: Chữ w600 thay vì bold cứng
              : Text(
                  _currentStep == 2 ? "Hoàn tất" : "Tiếp tục",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isOptionSelected
                        ? Colors.white
                        : Colors.grey.shade500,
                  ),
                ),
        ),
      ),
    );
  }
}

class AnimationValueColor<T> extends AlwaysStoppedAnimation<T> {
  const AnimationValueColor(super.value);
}
