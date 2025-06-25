import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yellow_admin/Utils/colors.dart';
import 'package:yellow_admin/widgets/CustomeTextAndBtns/custome_text.dart';

import '../controllers/category_controller.dart';
import '../models/category_model.dart';
// Import your CategoryController here
// import 'package:yellow_admin/controllers/category_controller.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CategoryController categoryController = Get.put(CategoryController());

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: CustomText(
          "Categories",
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => categoryController.fetchCategories(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section (Optional)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                PopupMenuButton<String>(
                  icon: Icon(Icons.filter_list),
                  onSelected: (value) {
                    // Handle filter selection
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'all', child: Text('All Categories')),
                    PopupMenuItem(value: 'main', child: Text('Main Categories')),
                    PopupMenuItem(value: 'sub', child: Text('Sub Categories')),
                    PopupMenuItem(value: 'featured', child: Text('Featured')),
                    PopupMenuItem(value: 'active', child: Text('Active')),
                    PopupMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                ),
              ],
            ),
          ),
          
          // Categories List
          Expanded(
            child: Obx(() {
              if (categoryController.isLoading.value && categoryController.categories.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                );
              }

              if (categoryController.categories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      CustomText(
                        "No categories found",
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      CustomText(
                        "Tap the + button to add your first category",
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => categoryController.fetchCategories(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categoryController.categories.length,
                  itemBuilder: (context, index) {
                    final category = categoryController.categories[index];
                    final subcategories = categoryController.getSubCategories(category.id);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: category.isActive 
                              ? AppColors.primaryColor.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          child: category.imageUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    category.imageUrl,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.category, color: AppColors.primaryColor),
                                  ),
                                )
                              : Icon(
                                  Icons.category,
                                  color: category.isActive ? AppColors.primaryColor : Colors.grey,
                                ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                category.name,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: category.isActive ? Colors.black87 : Colors.grey,
                              ),
                            ),
                            if (category.isFeatured)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: CustomText(
                                  'Featured',
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (category.description.isNotEmpty)
                              CustomText(
                                category.description,
                                fontSize: 12,
                                color: Colors.grey[600],
                                maxLines: 2,
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (category.isSubCategory)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: CustomText(
                                      'Sub Category',
                                      fontSize: 10,
                                      color: Colors.blue,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                CustomText(
                                  '${category.productCount} products',
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                const Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: category.isActive 
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: CustomText(
                                    category.isActive ? 'Active' : 'Inactive',
                                    fontSize: 10,
                                    color: category.isActive ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'toggle_status':
                                categoryController.toggleCategoryStatus(category);
                                break;
                              case 'toggle_featured':
                                categoryController.toggleFeaturedStatus(category);
                                break;
                              case 'delete':
                                _showDeleteDialog(context, categoryController, category);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle_status',
                              child: Row(
                                children: [
                                  Icon(
                                    category.isActive ? Icons.visibility_off : Icons.visibility,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.isActive ? 'Deactivate' : 'Activate'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle_featured',
                              child: Row(
                                children: [
                                  Icon(
                                    category.isFeatured ? Icons.star_border : Icons.star,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.isFeatured ? 'Remove Featured' : 'Make Featured'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        children: subcategories.map((subCategory) => ListTile(
                          contentPadding: EdgeInsets.only(left: 72, right: 16),
                          leading: Icon(
                            Icons.subdirectory_arrow_right,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          title: CustomText(
                            subCategory.name,
                            fontSize: 14,
                            color: subCategory.isActive ? Colors.black87 : Colors.grey,
                          ),
                          subtitle: CustomText(
                            '${subCategory.productCount} products',
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'toggle_status':
                                  categoryController.toggleCategoryStatus(subCategory);
                                  break;
                                case 'delete':
                                  _showDeleteDialog(context, categoryController, subCategory);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'toggle_status',
                                child: Text(subCategory.isActive ? 'Deactivate' : 'Activate'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => categoryController.showAddCategoryDialog(),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, CategoryController controller, CategoryModel category) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteCategory(category);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}