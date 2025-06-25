// lib/controllers/product_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart'; // For TextEditingController, etc.
import 'package:firebase_auth/firebase_auth.dart'; // To get current user ID

import '../models/product_model.dart'; // Make sure this path is correct
import '../models/category_model.dart'; // Assuming you might need categories for dropdowns

class ProductController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance; // To get current admin ID

  // --- Observable Lists and States ---
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isSavingProduct = false.obs; // For add/edit operations

  // --- Form Controllers for Add/Edit Product ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController discountPriceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController tagsController = TextEditingController(); // For comma-separated tags

  // Observable values for dropdowns and checkboxes
  final RxString selectedCategory = ''.obs;
  final RxString selectedSubCategory = ''.obs; // If you implement subcategories
  final RxString selectedBrand = ''.obs; // If you implement brands
  final RxList<String> selectedImagesPaths = <String>[].obs; // Local paths of selected images
  final RxList<String> uploadedImagesUrls = <String>[].obs; // URLs of uploaded images
  final RxBool isFeatured = false.obs;
  final RxBool isOnSale = false.obs;
  final RxBool isActive = true.obs;
  final RxString currentProductStatus = 'draft'.obs; // draft, published, archived

  // --- For Categories dropdowns (optional, but good for UX) ---
  final RxList<CategoryModel> categories = <CategoryModel>[].obs; // To populate category dropdown
  final RxList<CategoryModel> subCategoriesForSelectedCategory = <CategoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchCategoriesForDropdown(); // Fetch categories for the product form
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    discountPriceController.dispose();
    stockController.dispose();
    skuController.dispose();
    weightController.dispose();
    heightController.dispose();
    widthController.dispose();
    lengthController.dispose();
    tagsController.dispose();
    super.onClose();
  }

  // --- Data Fetching ---

  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final QuerySnapshot snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true) // Order by creation date
          .get();

      products.clear();
      for (var doc in snapshot.docs) {
        products.add(ProductModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }));
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch products: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategoriesForDropdown() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('categories')
          .orderBy('name')
          .get();

      categories.clear();
      for (var doc in snapshot.docs) {
        categories.add(CategoryModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }));
      }
    } catch (e) {
      print('Error fetching categories for dropdown: $e');
      // No snackbar here as it's a background fetch for UI, not a critical operation failure
    }
  }

  // Call this when selectedCategory changes
  void updateSubCategories(String categoryId) {
    subCategoriesForSelectedCategory.clear();
    // Assuming you have a way to get subcategories from your fetched categories
    // This might involve iterating through `categories` and filtering by parentId
    // For simplicity, let's assume a direct query or filtering from all categories
    final selectedCat = categories.firstWhereOrNull((cat) => cat.id == categoryId);
    if (selectedCat != null) {
      subCategoriesForSelectedCategory.addAll(
        categories.where((cat) => cat.parentId == selectedCat.id).toList()
      );
    }
    selectedSubCategory.value = ''; // Reset sub-category when parent changes
  }


  // --- Image Handling ---

  Future<void> pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        selectedImagesPaths.clear();
        for (XFile image in images) {
          selectedImagesPaths.add(image.path);
        }
        await uploadImages(selectedImagesPaths);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick images: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> uploadImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return;

    isUploadingImage.value = true;
    uploadedImagesUrls.clear(); // Clear previous URLs before new upload
    try {
      for (String path in imagePaths) {
        File imageFile = File(path);
        String fileName = 'products/${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
        UploadTask uploadTask = _storage.ref().child(fileName).putFile(imageFile);

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedImagesUrls.add(downloadUrl);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload images: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      uploadedImagesUrls.clear(); // Clear URLs if any upload fails
    } finally {
      isUploadingImage.value = false;
    }
  }

  void removeImage(String imageUrl) {
    // Optionally, delete from Firebase Storage here if the product is not yet added/updated
    // For simplicity, this just removes it from the list
    uploadedImagesUrls.remove(imageUrl);
    selectedImagesPaths.removeWhere((path) => uploadedImagesUrls.contains(path)); // This logic might need refinement if paths don't match URLs directly
    Get.snackbar('Image Removed', 'Image removed from selection.', backgroundColor: Colors.orange);
  }

  // --- Product CRUD Operations ---

  Future<void> addProduct() async {
    if (!validateProductForm()) return;

    // Get current admin ID
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('Error', 'No admin user logged in. Cannot add product.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      isSavingProduct.value = true;

      final product = ProductModel.create(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        price: double.parse(priceController.text),
        discountPrice: discountPriceController.text.isEmpty
            ? null
            : double.parse(discountPriceController.text),
        stock: int.parse(stockController.text),
        category: selectedCategory.value,
        subCategory: selectedSubCategory.value.isEmpty ? null : selectedSubCategory.value,
        brand: selectedBrand.value.isEmpty ? null : selectedBrand.value,
        images: uploadedImagesUrls.toList(),
        tags: tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        adminId: currentUser.uid,
        weight: weightController.text.isEmpty ? 0.0 : double.parse(weightController.text),
        dimensions: {
          'height': heightController.text.trim(),
          'width': widthController.text.trim(),
          'length': lengthController.text.trim(),
        },
      ).copyWith(
        isFeatured: isFeatured.value,
        isOnSale: isOnSale.value,
        isActive: isActive.value,
        status: currentProductStatus.value,
      );

      final docRef = await _firestore.collection('products').add(product.toJson());
      final newProductWithId = product.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id}); // Update Firestore document with its own ID

      products.add(newProductWithId); // Add to local observable list
      clearForm(); // Clear form fields
      Get.back(); // Close dialog/screen
      Get.snackbar(
        'Success',
        'Product added successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add product: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSavingProduct.value = false;
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    if (!validateProductForm()) return; // Re-validate before updating

    try {
      isSavingProduct.value = true;

      final updatedProduct = product.copyWith(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        price: double.parse(priceController.text),
        discountPrice: discountPriceController.text.isEmpty
            ? null
            : double.parse(discountPriceController.text),
        stock: int.parse(stockController.text),
        category: selectedCategory.value,
        subCategory: selectedSubCategory.value.isEmpty ? null : selectedSubCategory.value,
        brand: selectedBrand.value.isEmpty ? null : selectedBrand.value,
        images: uploadedImagesUrls.toList(), // Use the new/updated image URLs
        tags: tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        isFeatured: isFeatured.value,
        isOnSale: isOnSale.value,
        isActive: isActive.value,
        weight: weightController.text.isEmpty ? 0.0 : double.parse(weightController.text),
        dimensions: {
          'height': heightController.text.trim(),
          'width': widthController.text.trim(),
          'length': lengthController.text.trim(),
        },
        status: currentProductStatus.value,
        updatedAt: DateTime.now(), // Ensure updated timestamp
      );

      await _firestore.collection('products').doc(updatedProduct.id).update(updatedProduct.toJson());

      // Update local list
      final index = products.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        products[index] = updatedProduct;
      }
      
      Get.back(); // Close dialog/screen
      Get.snackbar(
        'Success',
        'Product updated successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update product: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSavingProduct.value = false;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      isLoading.value = true;
      // You might want to add a confirmation dialog here
      await _firestore.collection('products').doc(productId).delete();

      products.removeWhere((p) => p.id == productId); // Remove from local list

      // Optional: Delete images from Firebase Storage as well
      // You would need to fetch the product first to get its image URLs
      // For simplicity, this is omitted, but recommended for cleanup.

      Get.snackbar(
        'Success',
        'Product deleted successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete product: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- Helper Methods ---

  bool validateProductForm() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Product name is required.', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Product description is required.', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (priceController.text.trim().isEmpty || double.tryParse(priceController.text) == null) {
      Get.snackbar('Error', 'Valid price is required.', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (stockController.text.trim().isEmpty || int.tryParse(stockController.text) == null) {
      Get.snackbar('Error', 'Valid stock quantity is required.', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (selectedCategory.value.isEmpty) {
      Get.snackbar('Error', 'Category is required.', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (uploadedImagesUrls.isEmpty) {
      Get.snackbar('Error', 'At least one image is required.', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    // Add more validation as needed for other fields
    return true;
  }

  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    priceController.clear();
    discountPriceController.clear();
    stockController.clear();
    skuController.clear();
    weightController.clear();
    heightController.clear();
    widthController.clear();
    lengthController.clear();
    tagsController.clear();
    selectedCategory.value = '';
    selectedSubCategory.value = '';
    selectedBrand.value = '';
    selectedImagesPaths.clear();
    uploadedImagesUrls.clear();
    isFeatured.value = false;
    isOnSale.value = false;
    isActive.value = true;
    currentProductStatus.value = 'draft';
  }

  // Method to load product data into form for editing
  void loadProductForEdit(ProductModel product) {
    nameController.text = product.name;
    descriptionController.text = product.description;
    priceController.text = product.price.toString();
    discountPriceController.text = product.discountPrice?.toString() ?? '';
    stockController.text = product.stock.toString();
    skuController.text = product.sku;
    weightController.text = product.weight.toString();
    heightController.text = product.dimensions['height'] ?? '';
    widthController.text = product.dimensions['width'] ?? '';
    lengthController.text = product.dimensions['length'] ?? '';
    tagsController.text = product.tags.join(', '); // Join tags for display
    
    selectedCategory.value = product.category;
    updateSubCategories(product.category); // Populate subcategories for the selected category
    selectedSubCategory.value = product.subCategory;
    selectedBrand.value = product.brand;

    uploadedImagesUrls.assignAll(product.images); // Assign existing image URLs
    selectedImagesPaths.clear(); // Clear local paths as they don't persist
    
    isFeatured.value = product.isFeatured;
    isOnSale.value = product.isOnSale;
    isActive.value = product.isActive;
    currentProductStatus.value = product.status;
  }

  // --- UI Related Dialogs/Screens (Example implementations) ---

  void showAddEditProductDialog({ProductModel? productToEdit}) {
    clearForm(); // Always clear form before showing
    if (productToEdit != null) {
      loadProductForEdit(productToEdit); // Load if editing
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: Get.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.9,
          ),
          child: Obx(() => Stack( // Use Stack for loading overlay
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productToEdit == null ? 'Add New Product' : 'Edit Product',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Product Name
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Product Name *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price & Discount Price
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Price *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: discountPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Discount Price',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stock & SKU
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Stock *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: skuController,
                              decoration: InputDecoration(
                                labelText: 'SKU (Optional)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Category Dropdown
                      Obx(() => DropdownButtonFormField<String>(
                        value: selectedCategory.value.isEmpty ? null : selectedCategory.value,
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Select Category'),
                          ),
                          ...categories.map((category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          )),
                        ],
                        onChanged: (value) {
                          selectedCategory.value = value ?? '';
                          updateSubCategories(value ?? ''); // Update subcategories when category changes
                        },
                      )),
                      const SizedBox(height: 16),

                      // Sub-Category Dropdown (only if a category is selected and has subcategories)
                      Obx(() {
                        if (selectedCategory.value.isNotEmpty && subCategoriesForSelectedCategory.isNotEmpty) {
                          return Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: selectedSubCategory.value.isEmpty ? null : selectedSubCategory.value,
                                decoration: InputDecoration(
                                  labelText: 'Sub-Category (Optional)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Select Sub-Category'),
                                  ),
                                  ...subCategoriesForSelectedCategory.map((subCat) => DropdownMenuItem<String>(
                                    value: subCat.id,
                                    child: Text(subCat.name),
                                  )),
                                ],
                                onChanged: (value) {
                                  selectedSubCategory.value = value ?? '';
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // Brand (Optional)
                      TextFormField(
                        controller: TextEditingController(text: selectedBrand.value), // Use a controller or update the observable
                        decoration: InputDecoration(
                          labelText: 'Brand (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (value) => selectedBrand.value = value.trim(),
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      TextFormField(
                        controller: tagsController,
                        decoration: InputDecoration(
                          labelText: 'Tags (comma-separated)',
                          hintText: 'e.g., electronics, mobile, smartphone',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Weight
                      TextFormField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Weight (kg, optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dimensions
                      Text('Dimensions (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: heightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Height (cm)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: widthController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Width (cm)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: lengthController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Length (cm)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),


                      // Image Selection
                      Text(
                        'Product Images *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Column(
                        children: [
                          // Display uploaded images
                          if (uploadedImagesUrls.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: uploadedImagesUrls.map((imageUrl) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 80),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => removeImage(imageUrl),
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.red,
                                          child: Icon(Icons.close, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 8),
                          // Button to pick more images
                          ElevatedButton.icon(
                            onPressed: pickImages,
                            icon: Icon(Icons.add_photo_alternate),
                            label: Text(uploadedImagesUrls.isEmpty ? 'Add Images' : 'Add More Images'),
                          ),
                        ],
                      )),
                      const SizedBox(height: 16),

                      // Upload Progress
                      Obx(() => isUploadingImage.value
                          ? Column(
                        children: [
                          LinearProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(
                            'Uploading images...',
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
                        title: Text('Featured Product'),
                        value: isFeatured.value,
                        onChanged: (value) {
                          isFeatured.value = value ?? false;
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      )),
                      // On Sale Checkbox
                      Obx(() => CheckboxListTile(
                        title: Text('On Sale'),
                        value: isOnSale.value,
                        onChanged: (value) {
                          isOnSale.value = value ?? false;
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      )),
                      // Is Active Checkbox
                      Obx(() => CheckboxListTile(
                        title: Text('Active Product'),
                        value: isActive.value,
                        onChanged: (value) {
                          isActive.value = value ?? false;
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      )),

                      // Product Status Dropdown (Draft, Published, Archived)
                      Obx(() => DropdownButtonFormField<String>(
                        value: currentProductStatus.value,
                        decoration: InputDecoration(
                          labelText: 'Product Status',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: <String>['draft', 'published', 'archived'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(StringCasingExtension(value).capitalizeFirst), // Using explicit extension override
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            currentProductStatus.value = newValue;
                          }
                        },
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
                          ElevatedButton(
                            onPressed: (isSavingProduct.value || isUploadingImage.value)
                                ? null
                                : (productToEdit == null ? addProduct : () => updateProduct(productToEdit)),
                            child: (isSavingProduct.value || isUploadingImage.value)
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(productToEdit == null ? 'Add Product' : 'Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Loading overlay
              if (isSavingProduct.value || isUploadingImage.value)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          )),
        ),
      ),
    );
  }
}

// Helper extension for String capitalization (from GetX)
extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String get capitalizeFirst => toCapitalized();
}
