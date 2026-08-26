import 'package:flutter/material.dart';
import '../../widgets/ambient_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../data/default_products.dart';
import '../app_provider.dart'; // IMPORT TỔNG ĐÀI VÀO

Widget _productImage(
  String? source, {
  double? height,
  double? width,
  BoxFit fit = BoxFit.cover,
}) {
  const placeholder = 'https://via.placeholder.com/150';
  final imageSource = source?.trim() ?? '';

  if (imageSource.startsWith('assets/')) {
    return Image.asset(
      imageSource,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, _, _) =>
          Image.network(placeholder, height: height, width: width, fit: fit),
    );
  }

  return Image.network(
    imageSource.isEmpty ? placeholder : imageSource,
    height: height,
    width: width,
    fit: fit,
    errorBuilder: (_, _, _) => Container(
      height: height,
      width: width,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    ),
  );
}

// =========================================================================
// 1. TRANG GỢI Ý MỸ PHẨM CHÍNH
// =========================================================================
class SuggestionsTab extends StatefulWidget {
  const SuggestionsTab({super.key});

  @override
  State<SuggestionsTab> createState() => _SuggestionsTabState();
}

class _SuggestionsTabState extends State<SuggestionsTab> {
  String selectedCategory = "Tất cả";

  // Lưu giá trị tiếng Việt làm gốc để truy vấn Database
  final List<String> categories = [
    "Tất cả",
    "Làm sạch",
    "Toner",
    "Đặc trị",
    "Dưỡng ẩm",
    "Bảo vệ",
  ];

  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm dịch danh mục sang tiếng Anh (Chỉ dùng để hiển thị giao diện)
  String _getCategoryName(String cat, bool isEn) {
    if (!isEn) return cat;
    switch (cat) {
      case "Tất cả":
        return "All";
      case "Làm sạch":
        return "Cleanser";
      case "Toner":
        return "Toner";
      case "Đặc trị":
        return "Treatment";
      case "Dưỡng ẩm":
        return "Moisturizer";
      case "Bảo vệ":
        return "Sunscreen";
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool isAdmin =
        user != null &&
        user.email != null &&
        user.email!.startsWith('admin000');

    // LẮNG NGHE TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.isEnglish;
    final isDark = appProvider.isDarkMode;

    // MÀU SẮC ĐỘNG
    final cardColor = glassSurfaceColor(context);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isAdmin
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0, right: 8.0),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddProductScreen(),
                    ),
                  );
                },
                label: Text(
                  isEn ? "Add Item" : "Thêm SP",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                backgroundColor: Colors.blueAccent,
              ),
            )
          : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100, top: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(isEn, isDark),
            _buildSkinProfileCard(isEn),
            const SizedBox(height: 20),
            _buildCategoryFilter(isEn, isDark, cardColor),
            const SizedBox(height: 15),
            _buildProductGrid(isEn, isDark, cardColor, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isEn, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: isEn
              ? "Search products, brands..."
              : "Tìm kiếm sản phẩm, thương hiệu...",
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = "");
                  },
                )
              : const Icon(Icons.tune, color: Colors.grey),
          filled: true,
          fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSkinProfileCard(bool isEn) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String skinType = isEn ? "Loading..." : "Đang tải...";
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          skinType = data['skinType'] ?? (isEn ? "Unknown" : "Chưa xác định");
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B8DF2), Color(0xFF4A68F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.face_retouching_natural,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? "Your Skin Profile" : "Hồ sơ da của bạn",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skinType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isEn ? "Status: Matched" : "Tình trạng: Phù hợp",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter(bool isEn, bool isDark, Color cardColor) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedCategory == categories[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = categories[index];
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.blueAccent
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                ),
              ),
              child: Text(
                _getCategoryName(categories[index], isEn),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(
    bool isEn,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        final productsById = <String, Map<String, dynamic>>{
          for (final product in defaultProducts)
            product['id'] as String: Map<String, dynamic>.from(product),
        };

        for (final doc in snapshot.data?.docs ?? const []) {
          final product = doc.data() as Map<String, dynamic>;
          final id = doc.id;
          productsById[id] = {...?productsById[id], ...product, 'id': id};
        }

        final allProducts = productsById.values.toList();

        List<Map<String, dynamic>> filteredProducts =
            selectedCategory == "Tất cả"
            ? allProducts
            : allProducts
                  .where((p) => p["category"] == selectedCategory)
                  .toList();

        if (searchQuery.isNotEmpty) {
          filteredProducts = filteredProducts
              .where(
                (p) => p["name"].toString().toLowerCase().contains(searchQuery),
              )
              .toList();
        }

        if (filteredProducts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 50,
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isEn
                        ? "No products found!"
                        : "Không tìm thấy sản phẩm nào!",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.52,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              var product = filteredProducts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(product: product),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.05,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: _productImage(
                              product["image"] as String?,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isEn
                                    ? "Match ${product["match"]}%"
                                    : "Hợp ${product["match"]}%",
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
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product["name"] ?? 'Product',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              product["price"] ?? '0đ',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${product["rating"] ?? 5.0}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  " (${product["reviews"] ?? 0})",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}

// =========================================================================
// 2. TRANG CHI TIẾT SẢN PHẨM
// =========================================================================
class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  // Tương tự, hàm dịch tên danh mục
  String _getCategoryName(String cat, bool isEn) {
    if (!isEn) return cat;
    switch (cat) {
      case "Tất cả":
        return "All";
      case "Làm sạch":
        return "Cleanser";
      case "Toner":
        return "Toner";
      case "Đặc trị":
        return "Treatment";
      case "Dưỡng ẩm":
        return "Moisturizer";
      case "Bảo vệ":
        return "Sunscreen";
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool isAdmin =
        user != null &&
        user.email != null &&
        user.email!.startsWith('admin000');

    // LẮNG NGHE TỔNG ĐÀI
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.isEnglish;
    final isDark = appProvider.isDarkMode;

    final bgColor = glassSurfaceColor(context, opacity: isDark ? 0.72 : 0.68);
    final textColor = isDark ? Colors.white : Colors.black87;
    final navColor = glassSurfaceColor(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            backgroundColor: bgColor,
            foregroundColor: textColor,
            flexibleSpace: FlexibleSpaceBar(
              background: _productImage(
                product['image'] as String?,
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_square, color: Colors.blueAccent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddProductScreen(productToEdit: product),
                      ),
                    );
                  },
                ),
              if (isAdmin && product['isBundled'] != true)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmDelete(context, isEn, isDark),
                ),
              if (!isAdmin)
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {},
                ),
              if (!isAdmin)
                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getCategoryName(product['category'] ?? '', isEn),
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product['name'] ?? '',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product['price'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        "${product['rating'] ?? 5.0} (${product['reviews'] ?? 0} ${isEn ? "reviews" : "đánh giá"})",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isEn
                              ? "Match: ${product['match'] ?? 90}%"
                              : "Độ phù hợp: ${product['match'] ?? 90}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: 40,
                    thickness: 1,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                  Text(
                    isEn ? "Product Description" : "Mô tả sản phẩm",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product['description'] ??
                        (isEn ? "No description." : "Chưa có mô tả."),
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: navColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEn ? 'Added to wardrobe!' : 'Đã thêm vào tủ đồ!',
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.blueAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEn
                            ? 'Redirecting to checkout...'
                            : 'Chuyển đến trang mua hàng...',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  isEn ? 'Buy Now' : 'Mua ngay',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, bool isEn, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          isEn ? "Confirm Delete" : "Xác nhận xóa",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          isEn
              ? "Are you sure you want to permanently delete this product?"
              : "Bạn có chắc muốn xóa vĩnh viễn sản phẩm này khỏi hệ thống?",
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(product['id'])
                  .delete();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEn ? 'Product deleted!' : 'Đã xóa sản phẩm thành công!',
                    ),
                  ),
                );
              }
            },
            child: Text(
              isEn ? "Delete" : "Xóa",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 3. TRANG THÊM/SỬA SẢN PHẨM (ADMIN)
// =========================================================================
class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? productToEdit;

  const AddProductScreen({super.key, this.productToEdit});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

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
  // Vẫn giữ value là tiếng Việt để lưu Database chuẩn
  final List<String> _categories = [
    "Làm sạch",
    "Toner",
    "Đặc trị",
    "Dưỡng ẩm",
    "Bảo vệ",
  ];
  bool _isLoading = false;
  bool _isEditing = false;

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

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      _isEditing = true;
      var p = widget.productToEdit!;
      _nameController.text = p['name'] ?? '';
      _priceController.text = p['price'] ?? '';
      _imageController.text = p['image'] ?? '';
      _ratingController.text = (p['rating'] ?? 5.0).toString();
      _reviewsController.text = (p['reviews'] ?? 0).toString();
      _matchController.text = (p['match'] ?? 90).toString();
      _descController.text = p['description'] ?? '';
      _selectedCategory = _categories.contains(p['category'])
          ? p['category']
          : "Làm sạch";
    }
  }

  // Hàm dịch danh mục trong Dropdown
  String _getCategoryName(String cat, bool isEn) {
    if (!isEn) return cat;
    switch (cat) {
      case "Làm sạch":
        return "Cleanser";
      case "Toner":
        return "Toner";
      case "Đặc trị":
        return "Treatment";
      case "Dưỡng ẩm":
        return "Moisturizer";
      case "Bảo vệ":
        return "Sunscreen";
      default:
        return cat;
    }
  }

  Future<void> _uploadProduct(bool isEn) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final products = FirebaseFirestore.instance.collection('products');
      final productRef = _isEditing
          ? products.doc(widget.productToEdit!['id'])
          : products.doc();

      await productRef.set({
        "id": productRef.id,
        "name": _nameController.text.trim(),
        "price": _priceController.text.trim(),
        "category": _selectedCategory,
        "image": _imageController.text.trim(),
        "rating": double.tryParse(_ratingController.text) ?? 5.0,
        "reviews": int.tryParse(_reviewsController.text) ?? 0,
        "match": int.tryParse(_matchController.text) ?? 90,
        "description": _descController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? (isEn ? 'Changes saved!' : 'Đã lưu chỉnh sửa!')
                  : (isEn ? 'Product added!' : 'Đã thêm sản phẩm lên kệ!'),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isEn = appProvider.isEnglish;
    final isDark = appProvider.isDarkMode;

    final bgColor = glassSurfaceColor(context, opacity: isDark ? 0.72 : 0.68);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          _isEditing
              ? (isEn ? "Edit Product" : "Sửa thông tin")
              : (isEn ? "Add New Product" : "Thêm sản phẩm mới"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      _nameController,
                      isEn ? "Product Name" : "Tên sản phẩm",
                      Icons.shopping_bag_outlined,
                      isDark,
                    ),
                    _buildTextField(
                      _priceController,
                      isEn ? "Price (e.g. \$15.00)" : "Giá bán (VD: 350.000đ)",
                      Icons.payments_outlined,
                      isDark,
                    ),
                    _buildTextField(
                      _imageController,
                      isEn ? "Image Link" : "Link ảnh",
                      Icons.image_outlined,
                      isDark,
                    ),

                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      dropdownColor: isDark
                          ? Colors.grey.shade900
                          : Colors.white,
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: isEn ? "Category" : "Danh mục",
                        labelStyle: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(_getCategoryName(c, isEn)),
                            ),
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
                            Icons.star_outline,
                            isDark,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            _matchController,
                            isEn ? "Match %" : "% Hợp da",
                            Icons.favorite_outline,
                            isDark,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),

                    _buildTextField(
                      _descController,
                      isEn ? "Description" : "Mô tả sản phẩm",
                      Icons.description_outlined,
                      isDark,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => _uploadProduct(isEn),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          _isEditing
                              ? (isEn ? "SAVE CHANGES" : "LƯU THAY ĐỔI")
                              : (isEn ? "SAVE PRODUCT" : "LƯU LÊN HỆ THỐNG"),
                          style: const TextStyle(
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
    IconData icon,
    bool isDark, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
          ),
        ),
        validator: (val) =>
            (val == null || val.isEmpty) ? "Vui lòng nhập" : null,
      ),
    );
  }
}
