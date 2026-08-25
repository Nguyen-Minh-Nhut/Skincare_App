import 'package:flutter/material.dart';
import '../../widgets/ambient_background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart'; // THÊM PROVIDER

import '../app_provider.dart'; // IMPORT TỔNG ĐÀI

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String _selectedGender = "Nam";
  String _selectedSkinType = "Chưa xác định";

  // Vẫn giữ mảng gốc tiếng Việt để lưu Database chuẩn
  final List<String> _genders = ["Nam", "Nữ", "Khác"];
  final List<String> _skinTypes = [
    "Chưa xác định",
    "Da thường",
    "Da dầu",
    "Da khô",
    "Da hỗn hợp",
    "Da nhạy cảm",
  ];

  bool isLoading = false;
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Hàm dịch Giới tính
  String _getGenderName(String gender, bool isEn) {
    if (!isEn) return gender;
    switch (gender) {
      case "Nam":
        return "Male";
      case "Nữ":
        return "Female";
      case "Khác":
        return "Other";
      default:
        return gender;
    }
  }

  // Hàm dịch Loại da
  String _getSkinTypeName(String type, bool isEn) {
    if (!isEn) return type;
    switch (type) {
      case "Chưa xác định":
        return "Unknown";
      case "Da thường":
        return "Normal Skin";
      case "Da dầu":
        return "Oily Skin";
      case "Da khô":
        return "Dry Skin";
      case "Da hỗn hợp":
        return "Combination Skin";
      case "Da nhạy cảm":
        return "Sensitive Skin";
      default:
        return type;
    }
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _dobController.text = data['dob'] ?? '';
            _selectedGender = _genders.contains(data['gender'])
                ? data['gender']
                : "Nam";
            _selectedSkinType = _skinTypes.contains(data['skinType'])
                ? data['skinType']
                : "Chưa xác định";
            _avatarBase64 = data.containsKey('avatarUrl')
                ? data['avatarUrl']
                : null;
          });
        }
      } else {
        _nameController.text =
            user!.displayName ?? user!.email?.split('@')[0] ?? '';
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
    );

    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      final String base64Image = base64Encode(bytes);
      setState(() {
        _avatarBase64 = base64Image;
      });
    }
  }

  Future<void> _saveProfile(bool isEn) async {
    if (user == null) return;
    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _selectedGender, // Lưu nguyên bản tiếng Việt
        'skinType': _selectedSkinType, // Lưu nguyên bản tiếng Việt
        'avatarUrl': _avatarBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEn
                  ? 'Profile updated successfully!'
                  : 'Đã cập nhật hồ sơ thành công!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. LẮNG NGHE TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.isEnglish;
    final isDark = appProvider.isDarkMode;

    // 2. MÀU SẮC ĐỘNG
    final bgColor = glassSurfaceColor(context, opacity: isDark ? 0.72 : 0.68);
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white54 : Colors.grey.shade800;
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          isEn ? 'Edit Profile' : 'Chỉnh sửa trang cá nhân',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: textColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // =====================================
            // AVATAR NẰM GIỮA MÀN HÌNH
            // =====================================
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: isDark
                          ? Colors.blue.withValues(alpha: 0.15)
                          : Colors.blue.shade50,
                      backgroundImage: _avatarBase64 != null
                          ? MemoryImage(base64Decode(_avatarBase64!))
                          : null,
                      child: _avatarBase64 == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.blueAccent,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: bgColor,
                        radius: 20,
                        child: CircleAvatar(
                          backgroundColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          radius: 17,
                          child: Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                isEn ? "Personal Information" : "Thông tin cá nhân",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildFBInputTile(
                    isEn ? "Full Name" : "Họ và tên",
                    Icons.person,
                    _nameController,
                    hint: isEn ? "Enter your name" : "Nhập họ và tên...",
                    textColor: textColor,
                    iconColor: iconColor,
                    hintColor: hintColor,
                  ),
                  _buildFBInputTile(
                    isEn ? "Phone Number" : "Số điện thoại",
                    Icons.phone,
                    _phoneController,
                    keyboardType: TextInputType.phone,
                    hint: isEn ? "Enter phone number" : "Nhập số điện thoại...",
                    textColor: textColor,
                    iconColor: iconColor,
                    hintColor: hintColor,
                  ),
                  _buildFBInputTile(
                    isEn ? "Date of Birth" : "Ngày sinh",
                    Icons.cake,
                    _dobController,
                    hint: "DD/MM/YYYY",
                    textColor: textColor,
                    iconColor: iconColor,
                    hintColor: hintColor,
                  ),

                  _buildFBDropdownTile(
                    isEn ? "Gender" : "Giới tính",
                    Icons.transgender,
                    _selectedGender,
                    _genders,
                    (val) => setState(() => _selectedGender = val!),
                    isEn,
                    isDark,
                    textColor,
                    iconColor,
                  ),
                  _buildFBDropdownTile(
                    isEn ? "Skin Type" : "Loại da",
                    Icons.face_retouching_natural,
                    _selectedSkinType,
                    _skinTypes,
                    (val) => setState(() => _selectedSkinType = val!),
                    isEn,
                    isDark,
                    textColor,
                    iconColor,
                    isSkinType: true,
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _saveProfile(isEn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
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
                              isEn ? 'Save Changes' : 'Lưu thay đổi',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFBInputTile(
    String title,
    IconData icon,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? hint,
    required Color textColor,
    required Color iconColor,
    required Color hintColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: TextStyle(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: hint ?? 'Nhập $title...',
                    hintStyle: TextStyle(color: hintColor, fontSize: 14),
                    isDense: true,
                    contentPadding: const EdgeInsets.only(top: 5),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.edit, color: iconColor.withValues(alpha: 0.5), size: 20),
        ],
      ),
    );
  }

  Widget _buildFBDropdownTile(
    String title,
    IconData icon,
    String value,
    List<String> items,
    Function(String?) onChanged,
    bool isEn,
    bool isDark,
    Color textColor,
    Color iconColor, {
    bool isSkinType = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                SizedBox(
                  height: 30,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: value,
                      dropdownColor: isDark
                          ? Colors.grey.shade900
                          : Colors.white,
                      icon: const SizedBox.shrink(),
                      items: items
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                isSkinType
                                    ? _getSkinTypeName(e, isEn)
                                    : _getGenderName(e, isEn),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.edit, color: iconColor.withValues(alpha: 0.5), size: 20),
        ],
      ),
    );
  }
}
