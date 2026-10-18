import 'package:flutter/material.dart';
import 'package:skincare_app/widgets/app_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Các bộ điều khiển nhập liệu
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController(
    text: "5.0",
  );
  final TextEditingController _reviewsController = TextEditingController(
    text: "0",
  );
  final TextEditingController _matchController = TextEditingController(
    text: "90",
  );
  final TextEditingController _descController = TextEditingController();

  String _selectedCategory = "Làm sạch";
  final List<String> _categories = [
    "Làm sạch",
    "Toner",
    "Đặc trị",
    "Dưỡng ẩm",
    "Bảo vệ",
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _ratingController.dispose();
    _reviewsController.dispose();
    _matchController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Hàm lưu sản phẩm
  Future<void> _uploadProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final productRef = FirebaseFirestore.instance
          .collection('products')
          .doc();
      await productRef.set({
        "id": productRef.id,
        "name": _nameController.text.trim(),
        "price": _priceController.text.trim(),
        "category": _selectedCategory,
        "image": _imageController.text.trim(), // Dán link GitHub Raw vào đây
        "rating": double.tryParse(_ratingController.text) ?? 5.0,
        "reviews": int.tryParse(_reviewsController.text) ?? 0,
        "match": int.tryParse(_matchController.text) ?? 90,
        "description": _descController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm sản phẩm lên kệ thành công! 🎉'),
          ),
        );
        Navigator.pop(context); // Lưu xong quay về trang Suggestions
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi rồi Nhựt ơi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Thêm sản phẩm mới",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      _nameController,
                      "Tên sản phẩm",
                      AppIcons.shoppingBagOutlined,
                    ),
                    _buildTextField(
                      _priceController,
                      "Giá bán (VD: 350.000đ)",
                      AppIcons.paymentsOutlined,
                    ),
                    _buildTextField(
                      _imageController,
                      "Link ảnh (GitHub Raw)",
                      AppIcons.imageOutlined,
                    ),

                    const SizedBox(height: 15),
                    // Dropdown chọn danh mục
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: "Danh mục",
                        prefixIcon: const Icon(AppIcons.categoryOutlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val!),
                    ),

                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _ratingController,
                            "Rating",
                            AppIcons.starOutline,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            _matchController,
                            "% Hợp da",
                            AppIcons.favoriteOutline,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),

                    _buildTextField(
                      _descController,
                      "Mô tả sản phẩm",
                      AppIcons.descriptionOutlined,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _uploadProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6264D9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "LƯU LÊN HỆ THỐNG",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        validator: (val) =>
            (val == null || val.isEmpty) ? "Vui lòng không để trống" : null,
      ),
    );
  }
}
