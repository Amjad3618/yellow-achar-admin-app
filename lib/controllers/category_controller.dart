import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../models/category_model.dart';
// Import your CategoryModel here
// import 'package:your_app/models/category_model.dart';

class CategoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Observable lists
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<CategoryModel> mainCategories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploadingImage = false.obs;
  
  // Form controllers for the dialog
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final RxString selectedParentId = ''.obs;
  final RxBool isFeatured = false.obs;
  final RxString selectedImagePath = ''.obs;
  final RxString uploadedImageUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  // Pick image from gallery
  Future<void> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        selectedImagePath.value = image.path;
        // Upload image immediately after selection
        await uploadImage(File(image.path));
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Upload image to Firebase Storage
  Future<void> uploadImage(File imageFile) async {
    try {
      isUploadingImage.value = true;
      
      // Create unique filename
      String fileName = 'categories/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to Firebase Storage
      TaskSnapshot snapshot = await _storage.ref().child(fileName).putFile(imageFile);
      
      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      uploadedImageUrl.value = downloadUrl;
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploadingImage.value = false;
    }
  }
  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      
      final QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .orderBy('sortOrder')
          .orderBy('name')
          .get();

      categories.clear();
      mainCategories.clear();
      
      for (var doc in snapshot.docs) {
        final category = CategoryModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
        
        categories.add(category);
        
        // Separate main categories for parent selection
        if (category.isMainCategory) {
          mainCategories.add(category);
        }
      }
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch categories: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Add new category
  Future<void> addCategory() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Category name is required',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Create new category
      final category = CategoryModel.create(
        name: nameController.text.trim(),
        adminId: 'current_admin_id', // Replace with actual admin ID
        description: descriptionController.text.trim(),
        parentId: selectedParentId.value.isEmpty ? null : selectedParentId.value,
        imageUrl: uploadedImageUrl.value,
        sortOrder: categories.length,
      );

      // Add to Firestore
      final docRef = await _firestore.collection('categories').add(category.toJson());
      
      // Update the category with the generated ID
      final updatedCategory = category.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});

      // Add to local list
      categories.add(updatedCategory);
      if (updatedCategory.isMainCategory) {
        mainCategories.add(updatedCategory);
      }

      // Clear form
      clearForm();
      
      Get.back(); // Close dialog
      Get.snackbar(
        'Success',
        'Category added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add category: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update category
  Future<void> updateCategory(CategoryModel category) async {
    try {
      isLoading.value = true;

      final updatedCategory = category.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(updatedCategory.toJson());

      // Update local list
      final index = categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        categories[index] = updatedCategory;
      }

      Get.snackbar(
        'Success',
        'Category updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update category: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Delete category
  Future<void> deleteCategory(CategoryModel category) async {
    try {
      // Check if category has products
      if (category.hasProducts) {
        Get.snackbar(
          'Error',
          'Cannot delete category with products',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Check if category has subcategories
      final hasSubcategories = categories.any((c) => c.parentId == category.id);
      if (hasSubcategories) {
        Get.snackbar(
          'Error',
          'Cannot delete category with subcategories',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;

      await _firestore.collection('categories').doc(category.id).delete();

      // Remove from local lists
      categories.removeWhere((c) => c.id == category.id);
      mainCategories.removeWhere((c) => c.id == category.id);

      Get.snackbar(
        'Success',
        'Category deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete category: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle category status
  Future<void> toggleCategoryStatus(CategoryModel category) async {
    final updatedCategory = category.toggleActive();
    await updateCategory(updatedCategory);
  }

  // Toggle featured status
  Future<void> toggleFeaturedStatus(CategoryModel category) async {
    final updatedCategory = category.toggleFeatured();
    await updateCategory(updatedCategory);
  }

  // Clear form fields
  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    selectedParentId.value = '';
    isFeatured.value = false;
    selectedImagePath.value = '';
    uploadedImageUrl.value = '';
  }

  // Get subcategories for a parent category
  List<CategoryModel> getSubCategories(String parentId) {
    return categories.where((c) => c.parentId == parentId).toList();
  }

  // Get category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Show add category dialog
  void showAddCategoryDialog() {
    clearForm();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Category Name
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Category Name *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Parent Category Dropdown
                  Obx(() => DropdownButtonFormField<String>(
                    value: selectedParentId.value.isEmpty ? null : selectedParentId.value,
                    decoration: InputDecoration(
                      labelText: 'Parent Category (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('None (Main Category)'),
                      ),
                      ...mainCategories.map((category) => DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      )),
                    ],
                    onChanged: (value) {
                      selectedParentId.value = value ?? '';
                    },
                  )),
                  const SizedBox(height: 16),
                  
                  // Image Selection
                  Text(
                    'Category Image',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: uploadedImageUrl.value.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              uploadedImageUrl.value,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          )
                        : selectedImagePath.value.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(selectedImagePath.value),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : InkWell(
                                onTap: pickImage,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to select image',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  )),
                  
                  // Change image button if image is selected
                  Obx(() => selectedImagePath.value.isNotEmpty || uploadedImageUrl.value.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: pickImage,
                            icon: Icon(Icons.edit),
                            label: Text('Change Image'),
                          ),
                        )
                      : SizedBox.shrink()),
                  
                  const SizedBox(height: 16),
                  
                  // Upload Progress
                  Obx(() => isUploadingImage.value
                      ? Column(
                          children: [
                            LinearProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(
                              'Uploading image...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        )
                      : SizedBox.shrink()),
                  
                  // Featured Checkbox
                  Obx(() => CheckboxListTile(
                    title: Text('Featured Category'),
                    value: isFeatured.value,
                    onChanged: (value) {
                      isFeatured.value = value ?? false;
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  )),
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      Obx(() => ElevatedButton(
                        onPressed: (isLoading.value || isUploadingImage.value) ? null : addCategory,
                        child: (isLoading.value || isUploadingImage.value)
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text('Add Category'),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}