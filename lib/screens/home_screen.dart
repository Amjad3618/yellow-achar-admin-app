import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yellow_admin/screens/add_products_screen.dart';
import 'package:yellow_admin/screens/categories_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: CustomText(
          "Admin Dashboard",
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                _showLogoutDialog();
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              tooltip: 'Sign Out',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.dashboard_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    CustomText(
                      "Welcome Back!",
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      "Manage your store efficiently",
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Quick Actions Title
              CustomText(
                "Quick Actions",
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              
              const SizedBox(height: 16),
              
              // Action Cards Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildActionCard(
                    icon: Icons.shopping_cart_checkout_rounded,
                    title: "Check Orders",
                    subtitle: "View recent orders",
                    color: Colors.blue,
                    onTap: () {
                      // Handle order button press
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.add_box_rounded,
                    title: "Add Products",
                    subtitle: "Manage inventory",
                    color: Colors.green,
                    onTap: () {
                      Get.to(() => ProductsScreen());
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.image_rounded,
                    title: "Add Banners",
                    subtitle: "Promotional content",
                    color: Colors.orange,
                    onTap: () {
                      Get.to(() => BannerScreen());
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.category_rounded,
                    title: "Add Categories",
                    subtitle: "Organize products",
                    color: Colors.purple,
                    onTap: () {
                      Get.to(() => CategoriesScreen());
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Statistics Section (Optional)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_rounded,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        CustomText(
                          "Quick Stats",
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem("Total Products", "0", Icons.inventory_2_rounded),
                        _buildStatItem("Categories", "0", Icons.category_rounded),
                        _buildStatItem("Orders", "0", Icons.shopping_bag_rounded),
                      ],
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                const SizedBox(height: 4),
                CustomText(
                  subtitle,
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(height: 8),
        CustomText(
          value,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 4),
        CustomText(
          label,
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red),
              const SizedBox(width: 8),
              CustomText("Sign Out", fontWeight: FontWeight.w600),
            ],
          ),
          content: CustomText("Are you sure you want to sign out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: CustomText("Cancel", color: Colors.grey[600]),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                authController.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: CustomText("Sign Out", color: Colors.white),
            ),
          ],
        );
      },
    );
  }
}