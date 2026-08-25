import 'package:flutter/material.dart';
import '../../widgets/ambient_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:provider/provider.dart';
import '../app_provider.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  bool _isScanning = false;

  // ========================================================
  // BỘ NÃO: GỌI API QUỐC TẾ
  // ========================================================
  Future<void> _fetchAndAddProduct(String barcode, bool isEn) async {
    setState(() => _isScanning = true);
    try {
      final url = Uri.parse(
        'https://world.openbeautyfacts.org/api/v0/product/$barcode.json',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          // TÌM THẤY TRÊN MẠNG
          String productName =
              data['product']['product_name'] ??
              (isEn ? 'Unknown product' : 'Sản phẩm không rõ tên');
          String brand = data['product']['brands'] ?? '';
          String imageUrl = data['product']['image_url'] ?? '';
          String finalName = brand.isNotEmpty
              ? '$brand $productName'
              : productName;

          _saveToWardrobe(barcode, finalName, imageUrl, isEn);
        } else {
          // KHÔNG TÌM THẤY -> MỞ POPUP CHO KHÁCH TỰ NHẬP
          if (mounted) _showAddManualProductDialog(barcode, isEn);
        }
      } else {
        if (mounted) _showAddManualProductDialog(barcode, isEn);
      }
    } catch (e) {
      // LỖI MẠNG -> CŨNG CHO KHÁCH TỰ NHẬP LUÔN
      if (mounted) _showAddManualProductDialog(barcode, isEn);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  // ========================================================
  // HÀM LƯU VÀO TỦ ĐỒ (TÁCH RIÊNG CHO GỌN)
  // ========================================================
  Future<void> _saveToWardrobe(
    String barcode,
    String name,
    String imageUrl,
    bool isEn,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wardrobe')
          .add({
            'name': name,
            'barcode': barcode,
            'imageUrl': imageUrl,
            'addedAt': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn ? "✅ Added: $name" : "✅ Đã thêm: $name"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // ========================================================
  // POPUP CHỮA CHÁY: CHO KHÁCH TỰ NHẬP TÊN SẢN PHẨM MỚI
  // ========================================================
  void _showAddManualProductDialog(String barcode, bool isEn) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController brandCtrl = TextEditingController();
    final isDark = Provider.of<AppProvider>(context, listen: false).isDarkMode;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(
              Icons.add_shopping_cart,
              size: 40,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 10),
            Text(
              isEn ? "Not Found in Database" : "Chưa có trong dữ liệu",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              isEn ? "Code: $barcode" : "Mã: $barcode",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEn
                  ? "This product is rare! Please enter its name to save."
                  : "Sản phẩm này khá hiếm! Bạn vui lòng nhập tên để lưu vào tủ đồ nhé.",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: brandCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: isEn
                    ? "Brand (e.g. Cocoon)"
                    : "Thương hiệu (VD: Cocoon)",
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: isEn
                    ? "Product Name"
                    : "Tên sản phẩm (VD: Tẩy trang hoa hồng)",
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
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
            child: Text(
              isEn ? "Cancel" : "Hủy",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                String finalName = brandCtrl.text.isNotEmpty
                    ? '${brandCtrl.text.trim()} ${nameCtrl.text.trim()}'
                    : nameCtrl.text.trim();
                Navigator.pop(context);
                _saveToWardrobe(
                  barcode,
                  finalName,
                  "",
                  isEn,
                ); // Truyền chuỗi rỗng cho ảnh
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEn
                          ? "Please enter product name!"
                          : "Vui lòng nhập tên sản phẩm!",
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: Text(
              isEn ? "Save to Wardrobe" : "Lưu vào Tủ",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      brandCtrl.dispose();
    });
  }

  // ========================================================
  // MẮT THẦN 1: BẬT CAMERA QUÉT MÃ BẰNG THƯ VIỆN MỚI
  // ========================================================
  Future<void> _startBarcodeScan(bool isEn) async {
    try {
      final barcode = await SimpleBarcodeScanner.scanBarcode(
        context,
        cancelButtonText: isEn ? 'Cancel' : 'Hủy',
      );
      if (!mounted) return;
      if (barcode != null && barcode != '-1' && barcode.isNotEmpty) {
        _fetchAndAddProduct(barcode, isEn);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn ? "Camera error!" : "Lỗi mở Camera!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ========================================================
  // MẮT THẦN 2: POPUP NHẬP MÃ BẰNG TAY (DÙNG CHO MÁY ẢO)
  // ========================================================
  void _showManualBarcodeDialog(bool isEn, bool isDark) {
    final TextEditingController barcodeCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          isEn ? "Test Barcode (Emulator)" : "Test Mã Vạch (Dành cho máy ảo)",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        content: TextField(
          controller: barcodeCtrl,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: isEn
                ? "Enter barcode number..."
                : "Nhập chuỗi số mã vạch...",
            hintStyle: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey,
              ),
            ),
          ),
          keyboardType: TextInputType.number,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              Navigator.pop(context);
              if (barcodeCtrl.text.isNotEmpty) {
                _fetchAndAddProduct(barcodeCtrl.text.trim(), isEn);
              }
            },
            child: Text(
              isEn ? "Search" : "Tìm kiếm",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ).whenComplete(barcodeCtrl.dispose);
  }

  void _deleteProduct(String docId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wardrobe')
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // LẮNG NGHE TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.isEnglish;
    final isDark = appProvider.isDarkMode;

    // MÀU SẮC ĐỘNG
    final cardColor = glassSurfaceColor(context);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          isEn ? "Skincare Wardrobe" : "Tủ đồ Skincare",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
      ),

      floatingActionButton: GestureDetector(
        onLongPress: () => _showManualBarcodeDialog(isEn, isDark),
        child: FloatingActionButton.extended(
          onPressed: () => _startBarcodeScan(isEn),
          backgroundColor: Colors.blueAccent,
          icon: _isScanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.qr_code_scanner, color: Colors.white),
          label: Text(
            _isScanning
                ? (isEn ? "Searching..." : "Đang tìm kiếm...")
                : (isEn ? "Scan Barcode" : "Quét mã vạch"),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      body: user == null
          ? Center(
              child: Text(
                isEn ? "Please login!" : "Vui lòng đăng nhập!",
                style: TextStyle(color: textColor),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('wardrobe')
                  .orderBy('addedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(isEn, isDark);
                }

                var products = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 15,
                    bottom: 80,
                    left: 15,
                    right: 15,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    var doc = products[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String name =
                        data['name'] ??
                        (isEn ? 'Unnamed Product' : 'Sản phẩm chưa tên');
                    String imageUrl = data['imageUrl'] ?? '';
                    String barcode = data['barcode'] ?? '';

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      onDismissed: (direction) => _deleteProduct(doc.id),
                      child: Card(
                        color: cardColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        _buildPlaceholderIcon(),
                                  )
                                : _buildPlaceholderIcon(),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            isEn ? "Code: $barcode" : "Mã: $barcode",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(bool isEn, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 15),
          Text(
            isEn ? "Your wardrobe is empty" : "Tủ đồ của bạn đang trống",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? "Tap 'Scan Barcode' to add\nyour skincare products here!"
                : "Bấm 'Quét mã vạch' để thêm mỹ phẩm\nđang sử dụng vào đây nhé!",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.blue.withValues(alpha: 0.15),
      child: const Icon(Icons.local_florist, color: Colors.blueAccent),
    );
  }
}
