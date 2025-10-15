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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: lightBrown, width: 1),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: mediumBrown),
                        hintText: 'Search Product',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.trim();
                        });
                      },
                    ),
                  ),
                ),
                const Spacer(flex: 3),
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
                    child: ChoiceChip(
                      label: Text('${categories[i]['th']} (${categories[i]['en']})'),
                      selected: selected,
                      onSelected: (_) => setState(() => selectedCategory = i),
                      selectedColor: mediumBrown,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : darkBrown,
                        fontWeight: FontWeight.bold,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Expanded(
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
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkBrown),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿${price.toStringAsFixed(2)}',
                            style: TextStyle(color: mediumBrown, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          if (stock <= 0)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text('Out of stock', style: TextStyle(color: Colors.red, fontSize: 12)),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: mediumBrown,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    cart.addItem(
                                      id: filteredDocs[i].id,
                                      name: name,
                                      price: price,
                                      imageAsset: imageUrl.startsWith('http') ? null : imageUrl,
                                    );
                                    setState(() => selectedNav = 1);
                                  },
                                  child: const Text('Add to Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
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
          child: Text('Your cart is empty', style: TextStyle(color: darkBrown)),
        );
      }
      return ListView.builder(
        itemCount: cart.items.length + 1,
        itemBuilder: (context, index) {
          if (index == cart.items.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Total: ฿${cart.totalPrice.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold, color: darkBrown, fontSize: 16)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8D6E63), foregroundColor: Colors.white),
                    onPressed: () {
                      // ไปหน้า checkout
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
                            }).toList(),
                          ),
                        ),
                      );
                    },
                    child: const Text('Place Order'),
                  ),
                ],
              ),
            );
          }
          final item = cart.items[index];
          return ListTile(
            leading: item.imageAsset != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(item.imageAsset!, width: 48, height: 48, fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.image)),
                  )
                : const Icon(Icons.image),
            title: Text(item.name, style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
            subtitle: Text('฿${item.price} x ${item.quantity}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(onPressed: () => cart.removeOne(item.id), icon: const Icon(Icons.remove_circle_outline)),
                IconButton(onPressed: () => cart.addItem(id: item.id, name: item.name, price: item.price, imageAsset: item.imageAsset), icon: const Icon(Icons.add_circle_outline)),
                IconButton(onPressed: () => cart.removeAll(item.id), icon: const Icon(Icons.delete_outline)),
              ],
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
