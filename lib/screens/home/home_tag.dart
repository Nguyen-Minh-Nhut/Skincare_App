import 'package:flutter/material.dart';
import 'package:skincare_app/widgets/app_icons.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../app_provider.dart';
import 'notification_screen.dart';
import '../../widgets/feature_unavailable.dart';
import 'scan_history.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedSkinStatus = "";
  bool _isRoutineExpanded = false;

  double uvIndex = 0.0;
  bool isLoadingWeather = true;
  String? _uvError;
  Color uvColor = Colors.blueAccent;
  IconData weatherIcon = AppIcons.cloud;

  List<Map<String, dynamic>> skinDiary = [];
  bool isLoadingDiary = true;
  bool _diaryLoadFailed = false;
  bool _isSavingDiary = false;
  List<SavedScan> _savedScans = const [];

  // LỊCH SKINCARE: Đã thêm cờ 'hasTimer' để phân biệt bước nào cần đếm ngược
  List<Map<String, dynamic>> morningRoutine = [
    {
      "task_vi": "Sữa rửa mặt dịu nhẹ",
      "task_en": "Gentle Cleanser",
      "isDone": false,
      "hasTimer": false,
    },
    {
      "task_vi": "Đắp mặt nạ đất sét (10p)",
      "task_en": "Clay Mask (10m)",
      "isDone": false,
      "hasTimer": true,
      "defaultMinutes": 10,
    },
    {
      "task_vi": "Toner cấp ẩm",
      "task_en": "Hydrating Toner",
      "isDone": false,
      "hasTimer": false,
    },
    {
      "task_vi": "Đắp mặt nạ giấy (15p)",
      "task_en": "Sheet Mask (15m)",
      "isDone": false,
      "hasTimer": true,
      "defaultMinutes": 15,
    },
    {
      "task_vi": "Kem chống nắng",
      "task_en": "Sunscreen",
      "isDone": false,
      "hasTimer": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDiaryFromFirestore();
    _loadSavedScans();
    _fetchUVWithLocation();
  }

  Future<void> _loadSavedScans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final scans = await ScanHistoryStore.load(userId: user.uid);
    if (mounted) setState(() => _savedScans = scans);
  }

  // ... (Giữ nguyên các hàm _fetchUVWithLocation, _fetchUVData, _updateUVLogic, _getUVMessage, _getGreeting, _launchURL, _loadDiaryFromFirestore, _addDiaryPhoto, _showBeforeAfterDialog, _showTipDetail, _showAddTipDialog, _showEditTipDialog, _deleteTip như cũ)

  Future<void> _fetchUVWithLocation() async {
    if (mounted) {
      setState(() {
        isLoadingWeather = true;
        _uvError = null;
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setUVError(
          'Hãy bật dịch vụ vị trí',
          'Please enable location services',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setUVError(
            'Cần quyền vị trí để đo UV',
            'Location permission is required',
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _setUVError(
          'Hãy cấp quyền vị trí trong Cài đặt',
          'Enable location permission in Settings',
        );
        return;
      }

      // Luôn lấy vị trí mới để UV phản ánh đúng nơi người dùng đang đứng,
      // thay vì dùng vị trí cuối cùng có thể đã cũ.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      await _fetchUVData(position.latitude, position.longitude);
    } on TimeoutException {
      _setUVError(
        'Không lấy được vị trí hiện tại',
        'Could not get current location',
      );
    } catch (_) {
      _setUVError('Không thể cập nhật vị trí', 'Could not update location');
    }
  }

  Future<void> _fetchUVData(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=uv_index&timezone=auto',
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        _setUVError('Dịch vụ UV đang bận', 'UV service is unavailable');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      final value = current?['uv_index'];
      if (value is! num) {
        _setUVError('Dữ liệu UV không hợp lệ', 'Invalid UV data');
        return;
      }

      if (mounted) {
        setState(() {
          uvIndex = value.toDouble();
          _updateUVLogic();
          isLoadingWeather = false;
          _uvError = null;
        });
      }
    } on TimeoutException {
      _setUVError('Cập nhật UV quá thời gian', 'UV request timed out');
    } catch (_) {
      _setUVError('Không thể cập nhật UV', 'Could not update UV');
    }
  }

  void _setUVError(String vi, String en) {
    if (!mounted) return;
    final isEn = context.read<AppProvider>().isEnglish;
    setState(() {
      isLoadingWeather = false;
      _uvError = isEn ? en : vi;
    });
  }

  void _updateUVLogic() {
    if (uvIndex <= 0) {
      uvColor = Colors.indigo.shade400;
      weatherIcon = AppIcons.nightsStay;
    } else if (uvIndex < 3) {
      uvColor = Colors.green;
      weatherIcon = AppIcons.wbSunnyOutlined;
    } else if (uvIndex < 6) {
      uvColor = Colors.orange;
      weatherIcon = AppIcons.wbSunny;
    } else if (uvIndex < 8) {
      uvColor = Colors.deepOrange;
      weatherIcon = AppIcons.wbTwilight;
    } else {
      uvColor = Colors.redAccent;
      weatherIcon = AppIcons.localFireDepartment;
    }
  }

  String _getUVMessage(bool isEn) {
    if (isLoadingWeather) return isEn ? "Loading..." : "Đang cập nhật...";
    if (_uvError != null) return _uvError!;
    if (uvIndex <= 0) return isEn ? "Night (No UV)" : "Trời tối (Không có UV)";
    if (uvIndex < 3) return isEn ? "Low (Safe)" : "UV Thấp (An toàn)";
    if (uvIndex < 6) return isEn ? "Moderate (Sunscreen)" : "UV Vừa (Bôi KCN)";
    if (uvIndex < 8) return isEn ? "High (Cover up)" : "UV Cao (Che chắn)";
    return isEn ? "Extreme (Stay inside)" : "UV Gắt (Tránh nắng)";
  }

  String _getGreeting(String name, bool isEn) {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return isEn ? 'Good morning,\n$name! 🌤️' : 'Chào buổi sáng,\n$name! 🌤️';
    }
    if (hour < 15) {
      return isEn ? 'Good afternoon,\n$name! ☀️' : 'Chào buổi trưa,\n$name! ☀️';
    }
    if (hour < 18) {
      return isEn ? 'Good evening,\n$name! ☕' : 'Chào buổi chiều,\n$name! ☕';
    }
    return isEn ? 'Good night,\n$name! 🌙' : 'Chào buổi tối,\n$name! 🌙';
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể mở link!')));
      }
    }
  }

  Future<void> _loadDiaryFromFirestore() async {
    setState(() {
      isLoadingDiary = true;
      _diaryLoadFailed = false;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 12));
      final entries = List<Map<String, dynamic>>.from(
        doc.data()?['skinDiary'] ?? [],
      );
      if (mounted) setState(() => skinDiary = entries);
    } catch (_) {
      if (mounted) setState(() => _diaryLoadFailed = true);
    } finally {
      if (mounted) setState(() => isLoadingDiary = false);
    }
  }

  Future<void> _addDiaryPhoto() async {
    if (_isSavingDiary) return;
    final isEn = context.read<AppProvider>().isEnglish;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'Sign in to save your diary.'
                : 'Đăng nhập để lưu nhật ký da.',
          ),
        ),
      );
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(isEn ? 'Take a photo' : 'Chụp ảnh mới'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              title: Text(
                isEn ? 'Choose from gallery' : 'Chọn ảnh từ thư viện',
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _isSavingDiary = true);
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 30,
        maxWidth: 720,
        maxHeight: 720,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final entry = <String, dynamic>{
        'week': skinDiary.length + 1,
        'image': base64Encode(bytes),
        'date': DateTime.now().toIso8601String(),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'skinDiary': FieldValue.arrayUnion([entry]),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() => skinDiary = [...skinDiary, entry]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? 'Diary photo saved.' : 'Đã lưu ảnh nhật ký!'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is TimeoutException
                ? (isEn
                      ? 'Save not confirmed. Reload the diary before adding again.'
                      : 'Chưa xác nhận được ảnh đã lưu. Hãy tải lại nhật ký trước khi thêm lại.')
                : (isEn
                      ? 'Could not select or save the photo. Please try again.'
                      : 'Không thể chọn hoặc lưu ảnh. Vui lòng thử lại.'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingDiary = false);
    }
  }

  void _showBeforeAfterDialog(bool isEn) {
    if (skinDiary.length < 2) return;
    final before = skinDiary.first;
    final after = skinDiary.last;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEn ? "Your Journey" : "Hành trình của bạn",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isEn
                    ? "Compare your first and latest photos under similar lighting."
                    : "Quan sát ảnh đầu tiên và mới nhất trong điều kiện ánh sáng tương tự.",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: MemoryImage(base64Decode(before['image'])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "BEFORE",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Text(
                          isEn
                              ? "Week ${before['week']}"
                              : "Tuần ${before['week']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.greenAccent,
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: MemoryImage(base64Decode(after['image'])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "AFTER",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        Text(
                          isEn
                              ? "Week ${after['week']}"
                              : "Tuần ${after['week']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    isEn ? "Awesome!" : "Quá đỉnh!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTipDetail(
    Map<String, dynamic> tip,
    bool isAdmin,
    bool isEn,
    Color cardColor,
    Color textColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      tip['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  if (isAdmin)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            AppIcons.editSquare,
                            color: Colors.orangeAccent,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditTipDialog(tip, isEn, cardColor);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            AppIcons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteTip(tip['id'], isEn, cardColor);
                          },
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                tip['summary'] ?? tip['desc'] ?? '',
                style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(AppIcons.articleOutlined),
                  label: Text(
                    isEn ? 'Read full article' : 'Đọc bài viết chi tiết',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (tip['url'] != null &&
                        tip['url'].toString().isNotEmpty) {
                      _launchURL(tip['url']);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAddTipDialog(bool isEn, Color cardColor) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Thêm mẹo mới (Admin)',
            style: TextStyle(
              fontSize: 18,
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Tiêu đề mẹo'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả cực ngắn (Hiện ngoài)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: summaryCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Tóm tắt nội dung (Hiện popup)',
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Link bài báo (http...)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                isEn ? 'Cancel' : 'Hủy',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('tips').add({
                    "title": titleCtrl.text,
                    "desc": descCtrl.text,
                    "summary": summaryCtrl.text.isNotEmpty
                        ? summaryCtrl.text
                        : descCtrl.text,
                    "url": urlCtrl.text,
                    "createdAt": FieldValue.serverTimestamp(),
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                }
              },
              child: const Text('Thêm Mẹo'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      titleCtrl.dispose();
      descCtrl.dispose();
      summaryCtrl.dispose();
      urlCtrl.dispose();
    });
  }

  void _showEditTipDialog(
    Map<String, dynamic> tip,
    bool isEn,
    Color cardColor,
  ) {
    final titleCtrl = TextEditingController(text: tip['title']);
    final descCtrl = TextEditingController(text: tip['desc']);
    final summaryCtrl = TextEditingController(text: tip['summary']);
    final urlCtrl = TextEditingController(text: tip['url']);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Sửa mẹo (Admin)',
            style: TextStyle(
              fontSize: 18,
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Tiêu đề mẹo'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả cực ngắn (Hiện ngoài)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: summaryCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Tóm tắt nội dung (Hiện popup)',
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Link bài báo (http...)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                isEn ? 'Cancel' : 'Hủy',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('tips')
                      .doc(tip['id'])
                      .update({
                        "title": titleCtrl.text,
                        "desc": descCtrl.text,
                        "summary": summaryCtrl.text,
                        "url": urlCtrl.text,
                      });
                  if (!dialogContext.mounted) return;
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  Navigator.pop(dialogContext);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Đã cập nhật mẹo thành công!'),
                    ),
                  );
                }
              },
              child: const Text('Lưu Thay Đổi'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      titleCtrl.dispose();
      descCtrl.dispose();
      summaryCtrl.dispose();
      urlCtrl.dispose();
    });
  }

  void _deleteTip(String id, bool isEn, Color cardColor) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(isEn ? "Confirm Delete" : "Xác nhận xóa"),
        content: Text(
          isEn
              ? "Are you sure you want to delete this tip?"
              : "Bạn có chắc muốn xóa bài viết này không?",
        ),
        actions: [
          TextButton(
            child: Text(
              isEn ? "Cancel" : "Hủy",
              style: const TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('tips')
                  .doc(id)
                  .delete();
              if (dialogContext.mounted) {
                final messenger = ScaffoldMessenger.of(dialogContext);
                Navigator.pop(dialogContext);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      isEn ? 'Tip deleted!' : 'Đã xóa mẹo khỏi hệ thống!',
                    ),
                  ),
                );
              }
            },
            child: Text(isEn ? "Delete" : "Xóa vĩnh viễn"),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // HÀM HIỂN THỊ ĐỒNG HỒ ĐẾM NGƯỢC (Đắp mặt nạ)
  // ========================================================
  void _showTimerDialog(
    String taskName,
    int minutes,
    bool isEn,
    Color cardColor,
    Color textColor,
  ) {
    int remainingSeconds = minutes * 60;
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Hàm bắt đầu đếm
            void startTimer() {
              countdownTimer = Timer.periodic(const Duration(seconds: 1), (
                timer,
              ) {
                if (remainingSeconds > 0) {
                  setStateDialog(() => remainingSeconds--);
                } else {
                  timer.cancel();
                  // Gọi hàm Push Notification ở đây nếu đã cài thư viện flutter_local_notifications
                  // Ví dụ: NotificationService.showNotification(title: "Xong rồi!", body: "Đã hết thời gian $taskName");
                }
              });
            }

            // Gọi chạy ngay khi mở Dialog
            if (countdownTimer == null) startTimer();

            int min = remainingSeconds ~/ 60;
            int sec = remainingSeconds % 60;
            String timeString =
                '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
            double progress = remainingSeconds / (minutes * 60);

            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  const Icon(
                    AppIcons.timer,
                    color: Colors.blueAccent,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    taskName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          color: remainingSeconds == 0
                              ? Colors.green
                              : Colors.blueAccent,
                        ),
                      ),
                      Text(
                        remainingSeconds == 0
                            ? (isEn ? "Done!" : "Xong!")
                            : timeString,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: remainingSeconds == 0
                              ? Colors.green
                              : textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    remainingSeconds == 0
                        ? (isEn
                              ? "You can wash your face now!"
                              : "Đến lúc rửa mặt rồi bạn ơi!")
                        : (isEn
                              ? "Relax and wait..."
                              : "Thư giãn và chờ đợi nhé..."),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                if (remainingSeconds > 0)
                  TextButton(
                    onPressed: () {
                      countdownTimer?.cancel();
                      Navigator.pop(context);
                    },
                    child: Text(
                      isEn ? "Stop" : "Dừng lại",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: remainingSeconds == 0
                        ? Colors.green
                        : Colors.blueAccent,
                  ),
                  onPressed: () {
                    countdownTimer?.cancel();
                    Navigator.pop(context);
                  },
                  child: Text(
                    remainingSeconds == 0
                        ? (isEn ? "Close" : "Đóng")
                        : (isEn ? "Hide Timer" : "Ẩn đồng hồ"),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Đảm bảo tắt timer nếu user đóng dialog đột ngột
      countdownTimer?.cancel();
    });
  }

  // ========================================================
  // HÀM HIỂN THỊ POPUP CHỈNH SỬA LỊCH SKINCARE
  // ========================================================
  void _showEditRoutineDialog(bool isEn, Color cardColor, Color textColor) {
    // Tạo một bản sao để sửa
    List<Map<String, dynamic>> tempRoutine = List.from(
      morningRoutine.map((e) => Map<String, dynamic>.from(e)),
    );
    final TextEditingController taskCtrlVi = TextEditingController();
    final TextEditingController taskCtrlEn = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: cardColor,
              title: Text(
                isEn ? "Edit Routine" : "Chỉnh sửa Lịch trình",
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Danh sách hiện tại
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tempRoutine.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              isEn
                                  ? tempRoutine[index]['task_en']
                                  : tempRoutine[index]['task_vi'],
                              style: TextStyle(color: textColor),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                AppIcons.removeCircle,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                setStateDialog(() {
                                  tempRoutine.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Divider(color: Colors.grey.withValues(alpha: 0.3)),
                    // Khu vực thêm mới
                    TextField(
                      controller: taskCtrlVi,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: isEn
                            ? "Add step (Vietnamese)..."
                            : "Thêm bước (Tiếng Việt)...",
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextField(
                      controller: taskCtrlEn,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: isEn
                            ? "Add step (English)..."
                            : "Thêm bước (Tiếng Anh)...",
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (taskCtrlVi.text.isNotEmpty &&
                            taskCtrlEn.text.isNotEmpty) {
                          setStateDialog(() {
                            tempRoutine.add({
                              "task_vi": taskCtrlVi.text.trim(),
                              "task_en": taskCtrlEn.text.trim(),
                              "isDone": false,
                              "hasTimer":
                                  false, // Mặc định tự thêm là ko có đếm ngược
                            });
                            taskCtrlVi.clear();
                            taskCtrlEn.clear();
                          });
                        }
                      },
                      icon: const Icon(
                        AppIcons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        isEn ? "Add" : "Thêm",
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isEn ? "Cancel" : "Hủy",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      morningRoutine = List.from(tempRoutine);
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    isEn ? "Save" : "Lưu lại",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      taskCtrlVi.dispose();
      taskCtrlEn.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'Bạn';

    final appProvider = Provider.of<AppProvider>(context);
    final bool isAdmin = appProvider.isAdmin;
    final bool isEn = appProvider.isEnglish;
    final bool isDark = appProvider.isDarkMode;

    // ============================================================
    // APP COLORS
    // ============================================================

    final Color cardColor = isDark ? const Color(0xFF1B1E24) : Colors.white;

    final Color textColor = isDark ? Colors.white : const Color(0xFF202124);

    final Color subTextColor = isDark
        ? Colors.white60
        : const Color(0xFF8A9099);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF111318), Color(0xFF171A28)]
              : const [Color(0xFFF2F6FF), Color(0xFFF8F5FF), Color(0xFFF4FAFF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 120,
            right: -90,
            child: _ambientOrb(
              size: 260,
              color: isDark ? const Color(0xFF493A9D) : const Color(0xFF9A8CFF),
              opacity: isDark ? 0.24 : 0.30,
            ),
          ),
          Positioned(
            top: 540,
            left: -110,
            child: _ambientOrb(
              size: 300,
              color: isDark ? const Color(0xFF164F78) : const Color(0xFF70C6F5),
              opacity: isDark ? 0.22 : 0.28,
            ),
          ),
          Positioned(
            bottom: 90,
            right: -70,
            child: _ambientOrb(
              size: 230,
              color: isDark ? const Color(0xFF63376F) : const Color(0xFFF2A8D4),
              opacity: isDark ? 0.20 : 0.24,
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // =====================================================
                  // HEADER
                  // =====================================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _getGreeting(displayName, isEn),
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              height: 1.15,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Row(
                          children: [
                            _buildUVIndexCard(isEn, cardColor, textColor),

                            const SizedBox(width: 8),

                            _buildNotificationBell(user, cardColor, textColor),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Hành động quan trọng nhất luôn xuất hiện trong màn hình đầu.
                  _buildAIScanBanner(isEn),

                  const SizedBox(height: 18),

                  _buildLatestScanCard(
                    isEn,
                    cardColor,
                    textColor,
                    subTextColor,
                  ),

                  const SizedBox(height: 18),

                  // =====================================================
                  // TODAY
                  // =====================================================
                  _buildTodayCard(isEn, cardColor, textColor, subTextColor),

                  const SizedBox(height: 26),

                  // =====================================================
                  // DIARY
                  // =====================================================
                  _buildSkinDiary(isEn, textColor, subTextColor),

                  const SizedBox(height: 30),

                  // =====================================================
                  // TIPS
                  // =====================================================
                  _buildCosmeticUsageTips(isAdmin, isEn, cardColor, textColor),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ambientOrb({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }

  // Style dùng chung cho mọi khối card trong trang Home để đồng bộ giao diện
  BoxDecoration _cardDecoration(Color cardColor) {
    final isDarkCard = cardColor.computeLuminance() < 0.25;
    return BoxDecoration(
      color: cardColor.withValues(alpha: isDarkCard ? 0.56 : 0.52),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDarkCard
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.72),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDarkCard ? 0.18 : 0.055),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _glassCard({
    required Color cardColor,
    required EdgeInsetsGeometry padding,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: _cardDecoration(cardColor),
          child: child,
        ),
      ),
    );
  }

  Widget _buildUVIndexCard(bool isEn, Color cardColor, Color textColor) {
    return GestureDetector(
      onTap: _uvError == null ? null : _fetchUVWithLocation,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 155),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: isLoadingWeather
                ? Colors.transparent
                : uvColor.withValues(alpha: 0.20),
          ),
        ),

        child: isLoadingWeather
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isEn ? "Loading..." : "Đang đo...",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _uvError == null
                        ? weatherIcon
                        : AppIcons.locationOffOutlined,
                    color: _uvError == null ? uvColor : Colors.orange,
                    size: 19,
                  ),

                  const SizedBox(width: 6),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _uvError == null
                            ? "UV: ${uvIndex.toStringAsFixed(1)}"
                            : (isEn ? "Tap to retry" : "Chạm để thử lại"),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),

                      Text(
                        _getUVMessage(isEn),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _uvError == null ? uvColor : Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNotificationBell(User? user, Color cardColor, Color textColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .where('isRead', isEqualTo: false)
                .snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(AppIcons.notificationsNone, color: textColor),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Khối "Hôm nay của bạn": gộp chọn trạng thái da + checklist skincare vào 1 card
  Widget _buildTodayCard(
    bool isEn,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    final List<String> statusesVi = [
      'Bình thường',
      'Đổ dầu',
      'Khô rát',
      'Nổi mụn',
      'Nhạy cảm',
    ];

    final List<String> statusesEn = [
      'Normal',
      'Oily',
      'Dry',
      'Acne',
      'Sensitive',
    ];

    final statuses = isEn ? statusesEn : statusesVi;

    final Map<String, String> advicesVi = {
      'Bình thường': 'Da đẹp quá! Hãy tiếp tục duy trì routine nhé.',
      'Đổ dầu': 'Nhớ cấp nước đầy đủ và kiểm soát dầu nhé.',
      'Khô rát': 'Ưu tiên dưỡng ẩm và phục hồi da hôm nay.',
      'Nổi mụn': 'Hạn chế chạm tay lên mặt và chăm sóc nhẹ nhàng.',
      'Nhạy cảm': 'Hôm nay nên tối giản routine.',
    };

    final Map<String, String> advicesEn = {
      'Normal': 'Great skin! Keep up your routine.',
      'Oily': 'Remember to hydrate and control excess oil.',
      'Dry': 'Focus on hydration and skin recovery today.',
      'Acne': 'Avoid touching your face and keep things gentle.',
      'Sensitive': 'Keep your routine simple today.',
    };

    final advices = isEn ? advicesEn : advicesVi;

    final int doneCount = morningRoutine
        .where((e) => e['isDone'] == true)
        .length;
    final double routineProgress = morningRoutine.isEmpty
        ? 0
        : doneCount / morningRoutine.length;
    final visibleRoutine = _isRoutineExpanded
        ? morningRoutine
        : morningRoutine.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _glassCard(
        cardColor: cardColor,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================================================
            // SKIN STATUS
            // ========================================================
            Text(
              isEn ? 'How is your skin today?' : 'Hôm nay da bạn thế nào?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statuses.map((status) {
                final bool isSelected = _selectedSkinStatus == status;

                return ChoiceChip(
                  label: Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),

                  selected: isSelected,

                  onSelected: (_) {
                    setState(() {
                      _selectedSkinStatus = status;
                    });

                    ScaffoldMessenger.of(context).clearSnackBars();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('💡 ${advices[status]}'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },

                  backgroundColor: isSelected
                      ? Colors.blueAccent
                      : Colors.transparent,

                  selectedColor: Colors.blueAccent,

                  side: BorderSide(
                    color: isSelected
                        ? Colors.blueAccent
                        : const Color(0xFFD9DDE5),
                    width: 1,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // ========================================================
            // DIVIDER
            // ========================================================
            Container(
              height: 1,
              color: _selectedSkinStatus.isEmpty
                  ? Colors.grey.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.16),
            ),

            const SizedBox(height: 16),

            // ========================================================
            // ROUTINE HEADER
            // ========================================================
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEn ? "Today's Routine" : "Lịch Skincare hôm nay",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$doneCount/${morningRoutine.length}",
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                Material(
                  color: Colors.grey.withValues(alpha: 0.10),
                  shape: const CircleBorder(),

                  child: InkWell(
                    customBorder: const CircleBorder(),

                    onTap: () =>
                        _showEditRoutineDialog(isEn, cardColor, textColor),

                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        AppIcons.editOutlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: routineProgress,
                minHeight: 7,
                backgroundColor: const Color(0xFFE8EEF8),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF4F7DF3)),
              ),
            ),

            const SizedBox(height: 8),

            // ========================================================
            // ROUTINE LIST
            // ========================================================
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),

              itemCount: visibleRoutine.length,

              separatorBuilder: (_, _) {
                return Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.10),
                );
              },

              itemBuilder: (context, index) {
                final item = visibleRoutine[index];

                final String taskName = isEn
                    ? item['task_en']
                    : item['task_vi'];

                final bool isDone = item['isDone'] == true;

                return ListTile(
                  dense: true,
                  minTileHeight: 48,
                  visualDensity: const VisualDensity(vertical: -2),
                  contentPadding: EdgeInsets.zero,

                  leading: Transform.scale(
                    scale: 1.05,
                    child: Checkbox(
                      value: isDone,
                      activeColor: Colors.blueAccent,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),

                      onChanged: (value) {
                        setState(() {
                          morningRoutine[index]['isDone'] = value;
                        });
                      },
                    ),
                  ),

                  title: Text(
                    taskName,

                    style: TextStyle(
                      fontSize: 14.5,

                      fontWeight: isDone ? FontWeight.w400 : FontWeight.w600,

                      color: isDone ? subTextColor : textColor,

                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),

                  trailing: item['hasTimer'] == true
                      ? IconButton(
                          visualDensity: VisualDensity.compact,

                          icon: const Icon(
                            AppIcons.timerOutlined,
                            color: Colors.orangeAccent,
                            size: 21,
                          ),

                          onPressed: () {
                            final int mins = item['defaultMinutes'] ?? 15;

                            _showTimerDialog(
                              taskName,
                              mins,
                              isEn,
                              cardColor,
                              textColor,
                            );
                          },
                        )
                      : null,
                );
              },
            ),

            if (morningRoutine.length > 3)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _isRoutineExpanded = !_isRoutineExpanded),
                  icon: Icon(
                    _isRoutineExpanded
                        ? AppIcons.keyboardArrowUpRounded
                        : AppIcons.keyboardArrowDownRounded,
                    size: 20,
                  ),
                  label: Text(
                    _isRoutineExpanded
                        ? (isEn ? 'Show less' : 'Thu gọn')
                        : (isEn
                              ? 'View all ${morningRoutine.length} steps'
                              : 'Xem đủ ${morningRoutine.length} bước'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF356FE8),
                    minimumSize: const Size.fromHeight(40),
                    padding: const EdgeInsets.only(top: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIScanBanner(bool isEn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => showFeatureUnavailable(context, isEnglish: isEn),

        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 18, 22),

          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3157D5), Color(0xFF7067F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

            borderRadius: BorderRadius.circular(28),

            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F86F7).withValues(alpha: 0.20),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),

          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  AppIcons.faceRetouchingNaturalRounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      isEn ? "Your AI skin journal" : "Nhật ký làn da AI",

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      isEn
                          ? "Scan, track changes and improve your routine"
                          : "Soi da, theo dõi thay đổi và tối ưu routine",

                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 36,
                height: 36,

                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  AppIcons.cameraAltRounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestScanCard(
    bool isEn,
    Color cardColor,
    Color textColor,
    Color subTextColor,
  ) {
    final latest = _savedScans.isEmpty ? null : _savedScans.first;
    final previous = _savedScans.length > 1 ? _savedScans[1] : null;

    if (latest == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _glassCard(
          cardColor: cardColor,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  AppIcons.insightsRounded,
                  color: Color(0xFF4D6FE8),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Start tracking your skin' : 'Bắt đầu theo dõi da',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEn
                          ? 'Your saved scans will appear here.'
                          : 'Kết quả đã lưu sẽ xuất hiện tại đây.',
                      style: TextStyle(color: subTextColor, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final difference = previous == null
        ? null
        : latest.acneCount - previous.acneCount;
    final trendColor = difference == null || difference == 0
        ? const Color(0xFF7A8494)
        : difference < 0
        ? const Color(0xFF20A66A)
        : const Color(0xFFE66A55);
    final trendText = difference == null
        ? (isEn ? 'First saved scan' : 'Lần soi đầu tiên')
        : difference == 0
        ? (isEn ? 'No change' : 'Không thay đổi')
        : difference < 0
        ? (isEn
              ? '${difference.abs()} fewer than last scan'
              : 'Giảm ${difference.abs()} nốt so với lần trước')
        : (isEn
              ? '$difference more than last scan'
              : 'Tăng $difference nốt so với lần trước');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => showFeatureUnavailable(context, isEnglish: isEn),
        child: _glassCard(
          cardColor: cardColor,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(latest.imagePath),
                  width: 88,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEn ? 'Latest skin check' : 'Lần soi gần nhất',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          AppIcons.chevronRightRounded,
                          color: Color(0xFF9AA2AF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${latest.acneCount} ${isEn ? 'spots detected' : 'nốt được phát hiện'}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            difference != null && difference < 0
                                ? AppIcons.trendingDownRounded
                                : difference != null && difference > 0
                                ? AppIcons.trendingUpRounded
                                : AppIcons.horizontalRuleRounded,
                            color: trendColor,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              trendText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: trendColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkinDiary(bool isEn, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isEn ? 'Your Skin Diary' : 'Nhật ký da của bạn',

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              if (skinDiary.length >= 2)
                TextButton(
                  onPressed: () => _showBeforeAfterDialog(isEn),

                  child: Text(
                    isEn ? 'Compare' : 'So sánh',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            isEn
                ? "Take photos weekly to see changes!"
                : "Chụp ảnh mỗi tuần để thấy rõ sự thay đổi!",

            style: TextStyle(color: subTextColor, fontSize: 13.5),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isEn
                  ? '1. Add a clear photo today.\n2. Use the same angle and lighting each week, without filters.\n3. Add a second photo to unlock Compare.'
                  : '1. Thêm một ảnh rõ mặt hôm nay.\n2. Mỗi tuần chụp cùng góc, cùng ánh sáng, không dùng bộ lọc.\n3. Có từ 2 ảnh, bấm So sánh để xem thay đổi.',
              style: TextStyle(color: textColor, height: 1.5, fontSize: 13),
            ),
          ),
          if (_diaryLoadFailed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn
                      ? 'Could not load your diary. Check your connection and retry.'
                      : 'Chưa tải được nhật ký. Kiểm tra kết nối rồi thử lại.',
                  style: TextStyle(color: subTextColor),
                ),
                TextButton(
                  onPressed: _loadDiaryFromFirestore,
                  child: Text(isEn ? 'Retry' : 'Thử lại'),
                ),
              ],
            ),
          if (_isSavingDiary)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          if (isLoadingDiary)
            const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SizedBox(
              height: 165,

              child: ListView.builder(
                scrollDirection: Axis.horizontal,

                physics: const BouncingScrollPhysics(),

                itemCount: skinDiary.length + 1,

                itemBuilder: (context, index) {
                  // ============================================
                  // NEW WEEK
                  // ============================================

                  if (index == skinDiary.length) {
                    return GestureDetector(
                      onTap: _isSavingDiary ? null : _addDiaryPhoto,

                      child: Container(
                        width: 125,

                        margin: const EdgeInsets.only(right: 12),

                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.08),

                          borderRadius: BorderRadius.circular(20),

                          border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.22),
                          ),
                        ),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            const Icon(
                              AppIcons.addAPhotoOutlined,
                              color: Colors.blueAccent,
                              size: 34,
                            ),

                            const SizedBox(height: 12),

                            Text(
                              _isSavingDiary
                                  ? (isEn ? "Saving…" : "Đang lưu…")
                                  : (isEn ? "Add photo" : "Thêm ảnh"),

                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // ============================================
                  // EXISTING PHOTO
                  // ============================================

                  final entry = skinDiary[index];

                  return Container(
                    width: 125,

                    margin: const EdgeInsets.only(right: 12),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),

                      image: DecorationImage(
                        image: MemoryImage(base64Decode(entry['image'])),
                        fit: BoxFit.cover,
                      ),
                    ),

                    child: Align(
                      alignment: Alignment.bottomCenter,

                      child: Container(
                        width: double.infinity,

                        padding: const EdgeInsets.symmetric(vertical: 8),

                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),

                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                        ),

                        child: Text(
                          isEn
                              ? "Week ${entry['week']}"
                              : "Tuần ${entry['week']}",

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
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

  Widget _buildCosmeticUsageTips(
    bool isAdmin,
    bool isEn,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),

          child: Row(
            children: [
              Expanded(
                child: Text(
                  isEn ? 'Skincare Tips' : 'Mẹo sử dụng mỹ phẩm',

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),

              if (isAdmin)
                IconButton(
                  icon: const Icon(
                    AppIcons.addCircleRounded,
                    color: Colors.blueAccent,
                  ),
                  onPressed: () => _showAddTipDialog(isEn, cardColor),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('tips').snapshots(),

          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Text(
                  isEn ? "Updating tips..." : "Mẹo đang cập nhật",

                  style: const TextStyle(color: Colors.grey),
                ),
              );
            }

            final tips = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              data['id'] = doc.id;

              return data;
            }).toList();

            return SizedBox(
              height: 120,

              child: ListView.builder(
                scrollDirection: Axis.horizontal,

                padding: const EdgeInsets.symmetric(horizontal: 16),

                itemCount: tips.length,

                itemBuilder: (context, index) {
                  final tip = tips[index];

                  return GestureDetector(
                    onTap: () => _showTipDetail(
                      tip,
                      isAdmin,
                      isEn,
                      cardColor,
                      textColor,
                    ),

                    child: Container(
                      width: 210,

                      margin: const EdgeInsets.symmetric(horizontal: 4),

                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFEAF2FF),
                            const Color(0xFFF4F7FF),
                          ],

                          begin: Alignment.topLeft,

                          end: Alignment.bottomRight,
                        ),

                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.10),
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Text(
                            tip['title'] ?? '',

                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              color: Color(0xFF2769D9),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 7),

                          Text(
                            tip['desc'] ?? '',

                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              color: Color(0xFF6F7C90),
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
