import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_view.dart';
import '../../cart/cart_controller.dart';
import '../../orders/views/checkout_view.dart';
import '../../orders/views/order_history_view.dart';


// หมวดหมู่จะดึงจาก Firestore จริง (distinct category/categoryTh)

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool isLoading = false;

  // ฟังก์ชันเปรียบเทียบ list ของ map (ต้องอยู่บนสุดของคลาส)


  // ฟังก์ชันเปรียบเทียบ list ของ map (ต้องอยู่บนสุดของคลาส)
  bool _listEquals(List<Map<String, String>> a, List<Map<String, String>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if ((a[i]['en'] ?? '') != (b[i]['en'] ?? '') || (a[i]['th'] ?? '') != (b[i]['th'] ?? '')) return false;
    }
    return true;
  }

  int selectedCategory = 0;
  List<Map<String, String>> categories = [];
  int selectedNav = 0; // 0: Home, 1: Categories, 2: Orders, 3: Profile
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  
  // Carousel state
  int _currentBannerIndex = 0;
  final PageController _bannerPageController = PageController();
  
  final List<Map<String, String>> _bannerImages = [
    {
      'image': 'assets/images/cupcake.png',
      'title': 'Cupcake สุดพิเศษ',
      'subtitle': 'หวานละมุน ทุกคำ',
    },
    {
      'image': 'assets/images/choco_cookie.png',
      'title': 'Chocolate Cookie',
      'subtitle': 'กรอบนอก นุ่มใน',
    },
    {
      'image': 'assets/images/strawberry_tart.png',
      'title': 'Strawberry Tart',
      'subtitle': 'สดใหม่ทุกวัน',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Auto-slide banner every 4 seconds
    Future.delayed(Duration.zero, () {
      _startAutoSlide();
    });
  }
  
  void _startAutoSlide() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return false;
      if (_bannerPageController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % _bannerImages.length;
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      return mounted;
    });
  }
  
  @override
  void dispose() {
    _bannerPageController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color darkBrown = const Color(0xFF4E342E);
    final Color mediumBrown = const Color(0xFF8D6E63);
    final Color lightBrown = const Color(0xFFD7CCC8);
    final Color cream = const Color(0xFFFAF3EF);

    final cart = context.watch<CartController>();


  // ฟังก์ชันเปรียบเทียบ list ของ map (เป็น method ของคลาส)
  bool _listEquals(List<Map<String, String>> a, List<Map<String, String>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['en'] != b[i]['en'] || a[i]['th'] != b[i]['th']) return false;
    }
    return true;
  }

    Widget buildHomeTab() {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          // รวมหมวดหมู่ที่ชื่ออังกฤษซ้ำกันให้เหลือหมวดเดียว (ใช้ en เป็น key หลัก)
          final Map<String, Map<String, String>> uniqueCats = {};
          for (final doc in docs) {
            final data = doc.data();
            final en = (data['category'] ?? '').toString().trim();
            final th = (data['categoryTh'] ?? '').toString().trim();
            if (en.isEmpty) continue;
            final key = en.toLowerCase();
            if (!uniqueCats.containsKey(key)) {
              uniqueCats[key] = {'en': en, 'th': th};
            }
          }
          // เพิ่มหมวดหมู่ All ไว้หน้าสุด
          final catList = [
            {'en': 'All', 'th': 'ทั้งหมด'}
          ] + uniqueCats.values.toList();
          if (categories.length != catList.length || !_listEquals(categories, catList)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => categories = catList);
            });
          }
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            children: [
          // Auto-sliding Banner Carousel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 180,
                    child: PageView.builder(
                      controller: _bannerPageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentBannerIndex = index;
                        });
                      },
                      itemCount: _bannerImages.length,
                      itemBuilder: (context, index) {
                        final banner = _bannerImages[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              banner['image']!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                child: const Center(child: Icon(Icons.broken_image, size: 60)),
                              ),
                            ),
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.black.withOpacity(0.6),
                                  ],
                                ),
                              ),
                            ),
                            // Text content
                            Positioned(
                              left: 20,
                              bottom: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    banner['title']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    banner['subtitle']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          offset: Offset(0, 1),
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _bannerImages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentBannerIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentBannerIndex == index
                            ? mediumBrown
                            : mediumBrown.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F4F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: lightBrown, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.brown.shade100.withOpacity(0.13),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: mediumBrown, size: 18),
                          hintText: 'Search Product',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF8D6E63)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.trim();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Categories
          if (categories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Categories',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: darkBrown,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(categories.length, (i) {
                  final selected = selectedCategory == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: selected ? mediumBrown : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? mediumBrown : Colors.brown.shade100, width: 1.2),
                        boxShadow: selected
                            ? [BoxShadow(color: mediumBrown.withOpacity(0.13), blurRadius: 6, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => selectedCategory = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(Icons.check, color: Colors.white, size: 16),
                                ),
                              Text(
                                '${categories[i]['th']} (${categories[i]['en']})',
                                style: TextStyle(
                                  color: selected ? Colors.white : darkBrown,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: 18),
          // Products Grid (from Firestore)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Builder(
              builder: (context) {
                // ฟิลเตอร์ตาม searchQuery และหมวดหมู่
                final selectedCat = categories.isNotEmpty && selectedCategory < categories.length
                    ? categories[selectedCategory]
                    : null;
                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final name = (data['name'] ?? '') as String;
                  final category = (data['category'] ?? '') as String;
                  final matchesSearch = searchQuery.isEmpty || name.toLowerCase().contains(searchQuery.toLowerCase());
                  final matchesCategory = selectedCat == null
                      || (selectedCat['en']?.toLowerCase() == 'all')
                      || category.toLowerCase() == (selectedCat['en'] ?? '').toLowerCase();
                  return matchesSearch && matchesCategory;
                }).toList();
                if (filteredDocs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No products found')),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredDocs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, i) {
                    final data = filteredDocs[i].data();
                    final name = (data['name'] ?? '') as String;
                    final price = (data['price'] ?? 0).toDouble();
                    final imageUrl = (data['imageUrl'] ?? '') as String;
                    final stock = (data['stock'] ?? 0) as int;
                    final variantsRaw = (data['variants'] ?? []) as List;
                    final variants = variantsRaw.map((v) => {
                      'name': v['name'],
                      'price': (v['price'] ?? 0).toDouble(),
                      'stock': v['stock'] ?? 0,
                    }).toList();

                    Widget productImage() {
                      if (imageUrl.startsWith('http')) {
                        return Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(Icons.image, size: 48, color: mediumBrown),
                        );
                      }
                      if (imageUrl.isNotEmpty) {
                        return Image.asset(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(Icons.image, size: 48, color: mediumBrown),
                        );
                      }
                      return Icon(Icons.image, size: 48, color: mediumBrown);
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                        border: Border.all(color: lightBrown, width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 110,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: productImage(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              name,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: darkBrown),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿${price.toStringAsFixed(2)}',
                            style: TextStyle(color: mediumBrown, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          if (stock <= 0)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text('Out of stock', style: TextStyle(color: Colors.red, fontSize: 12)),
                            )
                          else ...[
                            if (variants.isNotEmpty)
                              Center(
                                child: SizedBox(
                                  width: 110,
                                  height: 30,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: mediumBrown,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                    ),
                                    onPressed: () async {
                                      String? selectedVariantName;
                                      int selectedQty = 1;
                                      final selectedVariant = ValueNotifier<Map<String, dynamic>?>(null);
                                      await showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                        ),
                                        builder: (context) {
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: MediaQuery.of(context).viewInsets.bottom,
                                              left: 16, right: 16, top: 24),
                                            child: StatefulBuilder(
                                              builder: (context, setState) {
                                                return Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Drag indicator
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                                                      child: Center(
                                                        child: Container(
                                                          width: 40,
                                                          height: 4,
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey.shade300,
                                                            borderRadius: BorderRadius.circular(2),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    // Header with icon
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 22,
                                                            backgroundColor: Colors.brown.shade100,
                                                            backgroundImage: imageUrl.isNotEmpty
                                                                ? (imageUrl.startsWith('http')
                                                                    ? NetworkImage(imageUrl)
                                                                    : AssetImage(imageUrl)) as ImageProvider
                                                                : null,
                                                            child: imageUrl.isEmpty ? const Icon(Icons.image, color: Colors.brown, size: 28) : null,
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: Text(
                                                              'เลือกตัวเลือกสินค้า',
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 20,
                                                                color: Color(0xFF5D4037),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Variant cards
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      child: Column(
                                                        children: variants.map((v) {
                                                          final isAvailable = v['stock'] > 0;
                                                          final isSelected = selectedVariantName == v['name'];
                                                          return AnimatedContainer(
                                                            duration: const Duration(milliseconds: 200),
                                                            curve: Curves.easeInOut,
                                                            margin: const EdgeInsets.symmetric(vertical: 6),
                                                            decoration: BoxDecoration(
                                                              color: isSelected ? Colors.brown.shade50 : Colors.white,
                                                              borderRadius: BorderRadius.circular(16),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors.brown.shade100.withOpacity(0.15),
                                                                  blurRadius: 8,
                                                                  offset: const Offset(0, 2),
                                                                ),
                                                              ],
                                                              border: isSelected
                                                                  ? Border.all(color: Colors.brown.shade300, width: 2)
                                                                  : Border.all(color: Colors.transparent, width: 2),
                                                            ),
                                                            child: ListTile(
                                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                              title: Text(
                                                                '${v['name']} ฿${v['price']}',
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.w600,
                                                                  fontSize: 16,
                                                                  color: isAvailable ? Colors.black : Colors.grey,
                                                                ),
                                                              ),
                                                              subtitle: Row(
                                                                children: [
                                                                  Icon(Icons.inventory_2, size: 16, color: isAvailable ? Colors.brown : Colors.grey),
                                                                  const SizedBox(width: 4),
                                                                  Text(
                                                                    'คงเหลือ ${v['stock']}',
                                                                    style: TextStyle(
                                                                      fontSize: 13,
                                                                      color: isAvailable ? Colors.brown : Colors.grey,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              enabled: isAvailable,
                                                              leading: AnimatedContainer(
                                                                duration: const Duration(milliseconds: 200),
                                                                curve: Curves.easeInOut,
                                                                width: 28,
                                                                height: 28,
                                                                decoration: BoxDecoration(
                                                                  color: isSelected ? Colors.brown.shade300 : Colors.brown.shade100,
                                                                  shape: BoxShape.circle,
                                                                  border: Border.all(color: isSelected ? Colors.brown : Colors.brown.shade100, width: 2),
                                                                ),
                                                                child: Center(
                                                                  child: isSelected
                                                                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                                                                      : const Icon(Icons.circle_outlined, color: Colors.brown, size: 18),
                                                                ),
                                                              ),
                                                              onTap: isAvailable
                                                                  ? () {
                                                                      setState(() {
                                                                        selectedVariantName = v['name'];
                                                                        selectedVariant.value = v;
                                                                        selectedQty = 1;
                                                                      });
                                                                    }
                                                                  : null,
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                    // Quantity selector
                                                    if (selectedVariant.value != null) ...[
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            GestureDetector(
                                                              onTap: selectedQty > 1 ? () => setState(() => selectedQty--) : null,
                                                              child: Container(
                                                                width: 44,
                                                                height: 44,
                                                                decoration: BoxDecoration(
                                                                  color: selectedQty > 1 ? Colors.brown.shade50 : Colors.grey.shade200,
                                                                  borderRadius: BorderRadius.circular(22),
                                                                ),
                                                                child: const Icon(Icons.remove, color: Color(0xFF8D6E63)),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding: const EdgeInsets.symmetric(horizontal: 18),
                                                              child: Container(
                                                                width: 44,
                                                                height: 44,
                                                                alignment: Alignment.center,
                                                                decoration: BoxDecoration(
                                                                  color: Colors.brown.shade50,
                                                                  borderRadius: BorderRadius.circular(22),
                                                                ),
                                                                child: Text('$selectedQty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              onTap: selectedQty < (selectedVariant.value!['stock'] < 10 ? selectedVariant.value!['stock'] : 10)
                                                                  ? () => setState(() => selectedQty++)
                                                                  : null,
                                                              child: Container(
                                                                width: 44,
                                                                height: 44,
                                                                decoration: BoxDecoration(
                                                                  color: selectedQty < (selectedVariant.value!['stock'] < 10 ? selectedVariant.value!['stock'] : 10)
                                                                      ? Colors.brown.shade50
                                                                      : Colors.grey.shade200,
                                                                  borderRadius: BorderRadius.circular(22),
                                                                ),
                                                                child: const Icon(Icons.add, color: Color(0xFF8D6E63)),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                    // Feedback
                                                    if (selectedVariant.value == null)
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                                        child: Text(
                                                          'กรุณาเลือกตัวเลือกสินค้าก่อน',
                                                          style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                                                        ),
                                                      ),
                                                    if (selectedVariant.value != null && selectedVariant.value!['stock'] == 0)
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                                        child: Text(
                                                          'สินค้าหมดสต็อก',
                                                          style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                                                        ),
                                                      ),
                                                    // Action button
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      child: SizedBox(
                                                        width: double.infinity,
                                                        height: 48,
                                                        child: ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: mediumBrown,
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                                            elevation: 0,
                                                          ),
                                                          icon: isLoading
                                                              ? const SizedBox(
                                                                  width: 22,
                                                                  height: 22,
                                                                  child: CircularProgressIndicator(
                                                                    color: Colors.white,
                                                                    strokeWidth: 2.5,
                                                                  ),
                                                                )
                                                              : const Icon(Icons.shopping_cart_outlined, size: 22),
                                                          label: const Text(
                                                            'เพิ่มลงตะกร้า',
                                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                          ),
                                                          onPressed: selectedVariant.value != null && selectedVariant.value!['stock'] > 0 && !isLoading
                                                              ? () async {
                                                                  setState(() => isLoading = true);
                                                                  await Future.delayed(const Duration(milliseconds: 600));
                                                                  cart.addItem(
                                                                    id: filteredDocs[i].id + '_' + selectedVariant.value!['name'],
                                                                    name: name + ' ' + selectedVariant.value!['name'],
                                                                    price: selectedVariant.value!['price'],
                                                                    imageAsset: imageUrl.startsWith('http') ? null : imageUrl,
                                                                    imageUrl: imageUrl.startsWith('http') ? imageUrl : null,
                                                                    qty: selectedQty,
                                                                  );
                                                                  Navigator.pop(context);
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(content: Text('เพิ่มลงตะกร้าแล้ว')),
                                                                  );
                                                                  setState(() {
                                                                    selectedNav = 1;
                                                                    isLoading = false;
                                                                  });
                                                                }
                                                              : null,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: const Text(
                                      'เพิ่มในตะกร้า',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            if (variants.isEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: mediumBrown,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      cart.addItem(
                                        id: filteredDocs[i].id,
                                        name: name,
                                        price: price,
                                        imageAsset: imageUrl.startsWith('http') ? null : imageUrl,
                                        imageUrl: imageUrl.startsWith('http') ? imageUrl : null,
                                      );
                                      setState(() => selectedNav = 1);
                                    },
                                    child: const Text(
                                      'เพิ่มในตะกร้า',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
      );
    },
  );

  // ฟังก์ชันเปรียบเทียบ list ของ map
    }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }


    Widget buildOrdersTab() {
      if (cart.items.isEmpty) {
        return Center(
          child: Text('Your cart is empty', style: TextStyle(color: darkBrown, fontSize: 16)),
        );
      }
      return ListView.builder(
        itemCount: cart.items.length + 1,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        itemBuilder: (context, index) {
          if (index == cart.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Total: ฿${cart.totalPrice.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8D6E63), fontSize: 18)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8D6E63),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        shadowColor: Colors.brown.shade100,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CheckoutView(
                              totalPrice: cart.totalPrice,
                              items: cart.items.map((e) => {
                                'id': e.id,
                                'name': e.name,
                                'price': e.price,
                                'quantity': e.quantity,
                                'imageAsset': e.imageAsset,
                                'imageUrl': e.imageUrl,
                              }).toList(),
                            ),
                          ),
                        );
                      },
                      child: const Text('ยืนยันการสั่งซื้อ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
          final item = cart.items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.brown.shade100.withOpacity(0.10), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: ListTile(
                leading: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.brown.shade50,
                  ),
                  child: ClipOval(
                    child: () {
                      if (item.imageAsset != null && item.imageAsset!.isNotEmpty) {
                        return Image.asset(
                          item.imageAsset!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.image, size: 48),
                        );
                      }
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
                        return Image.network(
                          item.imageUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Image.asset(
                            'assets/images/logo.png',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return const Icon(Icons.image, size: 48);
                    }(),
                  ),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.bold, fontSize: 13),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                subtitle: Text('฿${item.price} x ${item.quantity}', style: TextStyle(color: Colors.brown.shade300, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => cart.removeOne(item.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.brown.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.remove_circle_outline, color: Color(0xFF8D6E63), size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => cart.addItem(
                          id: item.id,
                          name: item.name,
                          price: item.price,
                          imageAsset: item.imageAsset,
                          imageUrl: item.imageUrl,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.brown.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.add_circle_outline, color: Color(0xFF8D6E63), size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => cart.removeAll(item.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.brown.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Color(0xFF8D6E63), size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    Widget buildProfileTab() {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Your Profile'),
            subtitle: const Text('View and edit your information'),
            trailing: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async => FirebaseAuth.instance.signOut(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('ประวัติคำสั่งซื้อ'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderHistoryView()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('แก้ไขโปรไฟล์'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileView()),
              );
            },
          ),
        ],
      );
    }

    final pages = [
      buildHomeTab(),
      buildOrdersTab(),
      buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        title: const Text(
          'Homemade Bliss',
          style: TextStyle(
            color: Color(0xFF4E342E),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF4E342E)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // หลังจาก sign out จะกลับไปหน้า Login อัตโนมัติ
            },
          ),
        ],
      ),
      body: pages[selectedNav],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedNav,
        onTap: (i) => setState(() => selectedNav = i),
        selectedItemColor: mediumBrown,
        unselectedItemColor: darkBrown,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (cart.totalItems > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: mediumBrown, borderRadius: BorderRadius.circular(8)),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text('${cart.totalItems}', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
