import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock data
final List<Map<String, String>> categories = [
  {'name': 'Cupcake'},
  {'name': 'Dessert'},
  {'name': 'Bread'},
  {'name': 'Drink'},
  {'name': 'Cake'},
  {'name': 'Cookie'},
];

final List<Map<String, String>> products = [
  {
    'name': 'Cheese Cupcake',
    'image': 'images/cupcake1.png',
    'price': '20.0',
  },
  {
    'name': 'Strawberry Tart',
    'image': 'images/strawberry_tart.png',
    'price': '35.0',
  },
  {
    'name': 'Chocolate Cookie',
    'image': 'images/choco_cookie.png',
    'price': '15.0',
  },
  // ...add more real product images as needed
];

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int selectedCategory = 0;
  int selectedNav = 0;

  @override
  Widget build(BuildContext context) {
    final Color darkBrown = const Color(0xFF4E342E);
    final Color mediumBrown = const Color(0xFF8D6E63);
    final Color lightBrown = const Color(0xFFD7CCC8);
    final Color cream = const Color(0xFFFAF3EF);

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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        children: [
          // Banner (Promotion)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.asset(
                    'images/landing1.png',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image, size: 60)),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ลด 20% วันนี้!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'เมนูใหม่ Strawberry Tart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mediumBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {},
                          child: const Text('Shop Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Search Bar (ลดขนาด ไม่เต็ม width)
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
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: mediumBrown),
                        hintText: 'Search Product',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                      ),
                    ),
                  ),
                ),
                Spacer(flex: 3), // เพิ่มช่องว่างด้านขวา
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Categories (horizontal scroll)
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
                    label: Text(categories[i]['name']!),
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
          const SizedBox(height: 18),
          // Products Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, i) {
                final product = products[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
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
                          child: product['image'] != null
                              ? Image.asset(
                                  product['image']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(Icons.image, size: 48, color: mediumBrown),
                                )
                              : Icon(Icons.image, size: 48, color: mediumBrown),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product['name'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: darkBrown,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '฿${product['price'] ?? ''}',
                        style: TextStyle(
                          color: mediumBrown,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 80,
                        height: 28,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mediumBrown,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            // TODO: Add to cart logic
                          },
                          child: const Text('Add to Cart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedNav,
        onTap: (i) => setState(() => selectedNav = i),
        selectedItemColor: mediumBrown,
        unselectedItemColor: darkBrown,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
