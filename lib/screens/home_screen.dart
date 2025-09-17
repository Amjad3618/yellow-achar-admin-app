// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yellow_admin/screens/add_products_screen.dart';
import 'package:yellow_admin/screens/categories_screen.dart';
import 'package:yellow_admin/screens/orders_screen.dart';
import 'package:yellow_admin/widgets/CustomeTextAndBtns/custome_text.dart';

import '../Utils/colors.dart';
import '../controllers/auth_controller.dart';
import 'banner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController authController = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Variables to store collection counts
  int productsCount = 0;
  int categoriesCount = 0;
  int ordersCount = 0;
  bool isLoadingCounts = true;

  @override
  void initState() {
    super.initState();
    _fetchCollectionCounts();
  }

  // Method to fetch collection counts
  Future<void> _fetchCollectionCounts() async {
    try {
      setState(() {
        isLoadingCounts = true;
      });

      // Fetch products count
      final productsSnapshot = await _firestore.collection('products').get();
      
      // Fetch categories count
      final categoriesSnapshot = await _firestore.collection('categories').get();
      
      // Fetch orders count
      final ordersSnapshot = await _firestore.collection('Orders').get();

      setState(() {
        productsCount = productsSnapshot.docs.length;
        categoriesCount = categoriesSnapshot.docs.length;
        ordersCount = ordersSnapshot.docs.length;
        isLoadingCounts = false;
      });
    } catch (e) {
      print('Error fetching collection counts: $e');
      setState(() {
        isLoadingCounts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: CustomText(
          "Admin Dashboard",
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: const Color(0xFF1E293B),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            child: IconButton(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout_rounded),
              color: const Color(0xFFDC2626),
              tooltip: 'Sign Out',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626).withOpacity(0.1),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchCollectionCounts,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.dashboard_customize_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomText(
                        "Welcome Back, Admin!",
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 6),
                      CustomText(
                        "Manage your store efficiently with powerful tools",
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Quick Actions Section
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CustomText(
                      "Quick Actions",
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Action Cards Grid - Fixed overflow issue
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1, // Increased for more height
                  children: [
                    _buildActionCard(
                      icon: Icons.shopping_cart_checkout_rounded,
                      title: "Orders",
                      subtitle: "View & manage",
                      color: const Color(0xFF3B82F6),
                      onTap: () => Get.to(() => OrdersScreen()),
                    ),
                    _buildActionCard(
                      icon: Icons.inventory_2_rounded,
                      title: "Products",
                      subtitle: "Add & manage",
                      color: const Color(0xFF10B981),
                      onTap: () => Get.to(() => ProductsScreen()),
                    ),
                    _buildActionCard(
                      icon: Icons.campaign_rounded,
                      title: "Banners",
                      subtitle: "Promotional",
                      color: const Color(0xFFF59E0B),
                      onTap: () => Get.to(() => BannerScreen()),
                    ),
                    _buildActionCard(
                      icon: Icons.category_rounded,
                      title: "Categories",
                      subtitle: "Organize",
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Get.to(() => CategoriesScreen()),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Statistics Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.analytics_rounded,
                              color: AppColors.primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          CustomText(
                            "Store Overview",
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                          const Spacer(),
                          if (isLoadingCounts)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              "Products",
                              isLoadingCounts ? "..." : productsCount.toString(),
                              Icons.inventory_2_rounded,
                              const Color(0xFF10B981),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              "Categories",
                              isLoadingCounts ? "..." : categoriesCount.toString(),
                              Icons.category_rounded,
                              const Color(0xFF8B5CF6),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              "Orders",
                              isLoadingCounts ? "..." : ordersCount.toString(),
                              Icons.shopping_bag_rounded,
                              const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(height: 12),

              // Text content with flexible layout
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      title,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      subtitle,
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                      maxLines: 1,
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

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          CustomText(
            value,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          const SizedBox(height: 2),
          CustomText(
            label,
            fontSize: 11,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              CustomText(
                "Sign Out",
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: const Color(0xFF1E293B),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CustomText(
              "Are you sure you want to sign out of your admin account?",
              fontSize: 15,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: CustomText(
                "Cancel",
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                authController.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: CustomText(
                "Sign Out",
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}