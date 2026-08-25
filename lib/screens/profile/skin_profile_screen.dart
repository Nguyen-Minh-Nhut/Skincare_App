import 'package:flutter/material.dart';
import '../../widgets/ambient_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // THÊM PROVIDER

import '../app_provider.dart'; // IMPORT TỔNG ĐÀI

class SkinProfileScreen extends StatefulWidget {
  const SkinProfileScreen({super.key});

  @override
  State<SkinProfileScreen> createState() => _SkinProfileScreenState();
}

class _SkinProfileScreenState extends State<SkinProfileScreen> {
  String selectedType = "Chưa xác định";
  final TextEditingController _productsCtrl = TextEditingController();
  bool _isLoading = true;

  bool hasAcne = false;
  bool hasPores = false;
  bool hasDarkSpots = false;
  bool isSensitive = false;

  @override
  void dispose() {
    _productsCtrl.dispose();
    super.dispose();
  }

  // Giữ gốc Tiếng Việt để lưu Data
  final List<Map<String, dynamic>> _skinTypes = [
    {"name": "Da dầu", "icon": Icons.water_drop, "color": Colors.blue},
    {"name": "Da khô", "icon": Icons.grain, "color": Colors.orange},
    {
      "name": "Da hỗn hợp",
      "icon": Icons.compare_arrows,
      "color": Colors.purple,
    },
    {"name": "Da nhạy cảm", "icon": Icons.warning_amber, "color": Colors.red},
    {
      "name": "Da thường",
      "icon": Icons.check_circle_outline,
      "color": Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  // Hàm dịch Tên Loại Da sang Giao Diện Tiếng Anh
  String _getSkinTypeName(String type, bool isEn) {
    if (!isEn) return type;
    switch (type) {
      case "Da dầu":
        return "Oily";
      case "Da khô":
        return "Dry";
      case "Da hỗn hợp":
        return "Combination";
      case "Da nhạy cảm":
        return "Sensitive";
      case "Da thường":
        return "Normal";
      case "Chưa xác định":
        return "Unknown";
      default:
        return type;
    }
  }

  void _loadCurrentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          selectedType = doc.data()?['skinType'] ?? "Chưa xác định";
          _productsCtrl.text = doc.data()?['currentProducts'] ?? "";
          hasAcne = doc.data()?['hasAcne'] ?? false;
          hasPores = doc.data()?['hasPores'] ?? false;
          hasDarkSpots = doc.data()?['hasDarkSpots'] ?? false;
          isSensitive = doc.data()?['isSensitive'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải hồ sơ da: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile(bool isEn) async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
        "skinType": selectedType,
        "currentProducts": _productsCtrl.text.trim(),
        "hasAcne": hasAcne,
        "hasPores": hasPores,
        "hasDarkSpots": hasDarkSpots,
        "isSensitive": isSensitive,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEn
                  ? "Skin profile updated successfully!"
                  : "Đã cập nhật hồ sơ da thành công!",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. LẮNG NGHE TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.isEnglish;
    final isDark = appProvider.isDarkMode;

    // 2. CÀI ĐẶT MÀU ĐỘNG THEO THEME
    final cardColor = glassSurfaceColor(context);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          isEn ? "Skin Profile" : "Hồ sơ làn da",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER MINH HỌA ---
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.blue.withValues(alpha: 0.2)
                                : Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.face_retouching_natural,
                            size: 60,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          isEn ? "Analyze & Track" : "Phân tích & Theo dõi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isEn
                              ? "Update info for better AI advice"
                              : "Cập nhật thông tin để AI tư vấn chính xác hơn",
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- MỤC 1: CHỌN LOẠI DA ---
                  Text(
                    isEn ? "What is your skin type?" : "Loại da của bạn là gì?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: _skinTypes.length,
                    itemBuilder: (context, index) {
                      bool isSelected =
                          selectedType == _skinTypes[index]['name'];
                      return GestureDetector(
                        onTap: () => setState(
                          () => selectedType = _skinTypes[index]['name'],
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _skinTypes[index]['color']
                                : cardColor,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected
                                  ? _skinTypes[index]['color']
                                  : borderColor,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _skinTypes[index]['color']
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _skinTypes[index]['icon'],
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600),
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getSkinTypeName(
                                  _skinTypes[index]['name'],
                                  isEn,
                                ),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : textColor,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // --- MỤC 2: VẤN ĐỀ VỀ DA ---
                  Text(
                    isEn ? "Skin Concerns" : "Vấn đề đang gặp phải",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildCheckboxTile(
                          isEn ? "Acne / Breakouts" : "Mụn viêm / Mụn ẩn",
                          hasAcne,
                          (val) => setState(() => hasAcne = val!),
                          textColor,
                        ),
                        _buildDivider(isDark),
                        _buildCheckboxTile(
                          isEn ? "Large Pores" : "Lỗ chân lông to",
                          hasPores,
                          (val) => setState(() => hasPores = val!),
                          textColor,
                        ),
                        _buildDivider(isDark),
                        _buildCheckboxTile(
                          isEn
                              ? "Dullness / Dark Spots"
                              : "Da xỉn màu, thâm nám",
                          hasDarkSpots,
                          (val) => setState(() => hasDarkSpots = val!),
                          textColor,
                        ),
                        _buildDivider(isDark),
                        _buildCheckboxTile(
                          isEn ? "Easily Irritated" : "Dễ kích ứng",
                          isSensitive,
                          (val) => setState(() => isSensitive = val!),
                          textColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- MỤC 3: SẢN PHẨM ĐANG DÙNG ---
                  Text(
                    isEn ? "Current Products" : "Các sản phẩm đang dùng",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _productsCtrl,
                    maxLines: 4,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: isEn
                          ? "E.g., Cetaphil Cleanser, La Roche-Posay Sunscreen..."
                          : "Ví dụ: Sữa rửa mặt Cetaphil, Kem chống nắng La Roche-Posay...",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey.shade500 : Colors.grey,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- NÚT LƯU HỒ SƠ ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => _saveProfile(isEn),
                      icon: const Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                      ),
                      label: Text(
                        isEn ? "SAVE PROFILE" : "LƯU HỒ SƠ DA",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool isChecked,
    Function(bool?) onChanged,
    Color textColor,
  ) {
    return CheckboxListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      value: isChecked,
      activeColor: Colors.blueAccent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      controlAffinity: ListTileControlAffinity.leading,
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      indent: 50,
    );
  }
}
