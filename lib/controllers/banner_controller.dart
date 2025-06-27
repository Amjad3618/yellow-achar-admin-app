import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../models/banner_model.dart';

class BannerController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Observable lists
  final RxList<BannerModel> banners = <BannerModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploadingImage = false.obs;
  
  // Form controllers for the dialog
  final TextEditingController nameController = TextEditingController();
  final RxString selectedImagePath = ''.obs;
  final RxString uploadedImageUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBanners();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  // Pick image from gallery
  Future<void> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
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
      String fileName = 'banners/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
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

  // Fetch all banners
  Future<void> fetchBanners() async {
    try {
      isLoading.value = true;
      
      final QuerySnapshot snapshot = await _firestore
          .collection('banners')
          .orderBy('createdAt', descending: true)
          .get();

      banners.clear();
      
      for (var doc in snapshot.docs) {
        final banner = BannerModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
        
        banners.add(banner);
      }
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch banners: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Add new banner
  Future<void> addBanner() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Banner name is required',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (uploadedImageUrl.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Banner image is required',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // Create new banner
      final banner = BannerModel.create(
        name: nameController.text.trim(),
        imageUrl: uploadedImageUrl.value,
      );

      // Add to Firestore
      final docRef = await _firestore.collection('banners').add(banner.toJson());
      
      // Update the banner with the generated ID
      final updatedBanner = banner.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});

      // Add to local list
      banners.insert(0, updatedBanner);

      // Clear form
      clearForm();
      
      Get.back(); // Close dialog
      Get.snackbar(
        'Success',
        'Banner added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add banner: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Update banner
  Future<void> updateBanner(BannerModel banner) async {
    try {
      isLoading.value = true;

      final updatedBanner = banner.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection('banners')
          .doc(banner.id)
          .update(updatedBanner.toJson());

      // Update local list
      final index = banners.indexWhere((b) => b.id == banner.id);
      if (index != -1) {
        banners[index] = updatedBanner;
      }

      Get.snackbar(
        'Success',
        'Banner updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update banner: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Delete banner
  Future<void> deleteBanner(BannerModel banner) async {
    try {
      isLoading.value = true;

      await _firestore.collection('banners').doc(banner.id).delete();

      // Remove from local list
      banners.removeWhere((b) => b.id == banner.id);

      Get.snackbar(
        'Success',
        'Banner deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete banner: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle banner status
  Future<void> toggleBannerStatus(BannerModel banner) async {
    final updatedBanner = banner.toggleActive();
    await updateBanner(updatedBanner);
  }

  // Clear form fields
  void clearForm() {
    nameController.clear();
    selectedImagePath.value = '';
    uploadedImageUrl.value = '';
  }

  // Get banner by ID
  BannerModel? getBannerById(String id) {
    try {
      return banners.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get active banners only
  List<BannerModel> getActiveBanners() {
    return banners.where((b) => b.isActive).toList();
  }

  // Show add banner dialog
  void showAddBannerDialog() {
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
                    'Add New Banner',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Banner Name
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Banner Name *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Image Selection
                  Text(
                    'Banner Image *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Container(
                    width: double.infinity,
                    height: 180,
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
                                      size: 50,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to select banner image',
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
                        onPressed: (isLoading.value || isUploadingImage.value) ? null : addBanner,
                        child: (isLoading.value || isUploadingImage.value)
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text('Add Banner'),
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

  // Show edit banner dialog
  void showEditBannerDialog(BannerModel banner) {
    nameController.text = banner.name;
    uploadedImageUrl.value = banner.imageUrl;
    selectedImagePath.value = '';
    
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
                    'Edit Banner',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Banner Name
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Banner Name *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Image Selection
                  Text(
                    'Banner Image *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Container(
                    width: double.infinity,
                    height: 180,
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
                                      size: 50,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to select banner image',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  )),
                  
                  // Change image button
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: pickImage,
                      icon: Icon(Icons.edit),
                      label: Text('Change Image'),
                    ),
                  ),
                  
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
                        onPressed: (isLoading.value || isUploadingImage.value) ? null : () async {
                          if (nameController.text.trim().isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Banner name is required',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }
                          
                          final updatedBanner = banner.copyWith(
                            name: nameController.text.trim(),
                            imageUrl: uploadedImageUrl.value,
                          );
                          
                          await updateBanner(updatedBanner);
                          Get.back();
                        },
                        child: (isLoading.value || isUploadingImage.value)
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text('Update Banner'),
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