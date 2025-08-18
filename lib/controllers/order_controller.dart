import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/order_model.dart';

class OrderController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var orders = <OrderModel>[].obs;
  var bulkOrders = <dynamic>[].obs;
  var currentOrder = Rxn<OrderModel>();

  var customerName = ''.obs;
  var customerEmail = ''.obs;
  var customerPhone = ''.obs;
  var customerAddress = ''.obs;
  var isFormValid = false.obs;

  // Pagination
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  final int _pageSize = 10;

  @override
  void onInit() {
    super.onInit();
    ever(customerName, (_) => validateForm());
    ever(customerEmail, (_) => validateForm());
    ever(customerPhone, (_) => validateForm());
    ever(customerAddress, (_) => validateForm());
    
    // Auto-load user orders when controller initializes
    _initializeUserOrders();
  }

  void _initializeUserOrders() async {
    final userId = getCurrentUserId();
    if (userId != null) {
      await getUserOrders(userId);
    }
  }

  void validateForm() {
    isFormValid.value =
        customerName.value.isNotEmpty &&
        customerEmail.value.contains('@') &&
        customerPhone.value.length >= 10 &&
        customerAddress.value.isNotEmpty;
  }

  String? getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  Future<bool> createOrder({
    required String productId,
    required String productName,
    required String productImage,
    required double productPrice,
    required double finalPrice,
    required int quantity,
  }) async {
    try {
      isLoading.value = true;

      String? userId = getCurrentUserId();
      if (userId == null) {
        Get.snackbar('Error', 'Please login to place an order');
        return false;
      }

      double subtotal = finalPrice * quantity;
      double deliveryCharges = subtotal > 1000 ? 0 : 150;
      double totalAmount = subtotal + deliveryCharges;

      String orderId = _firestore.collection('Orders').doc().id;

      OrderModel order = OrderModel(
        id: orderId,
        userId: userId,
        productId: productId,
        productName: productName,
        productImage: productImage,
        productPrice: productPrice,
        finalPrice: finalPrice,
        quantity: quantity,
        customerName: customerName.value,
        customerEmail: customerEmail.value,
        customerPhone: customerPhone.value,
        customerAddress: customerAddress.value,
        subtotal: subtotal,
        totalAmount: totalAmount,
        orderDate: DateTime.now(),
      );

      await _firestore
          .collection('Orders')
          .doc(orderId)
          .set(order.toMap());

      // Add to local list at the beginning (newest first)
      orders.insert(0, order);
      currentOrder.value = order;
      
      Get.snackbar('Success', 'Order placed successfully!');
      return true;
    } catch (e) {
      print('Order creation error: $e');
      Get.snackbar('Error', 'Failed to place order: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createBulkOrder({
    required List<dynamic> cartItems,
    required Map<String, dynamic> totals,
  }) async {
    try {
      isLoading.value = true;

      String? userId = getCurrentUserId();
      if (userId == null) {
        Get.snackbar('Error', 'Please login to place an order');
        return false;
      }

      String bulkOrderId = _firestore.collection('bulkorders').doc().id;

      Map<String, dynamic> bulkOrderData = {
        'id': bulkOrderId,
        'userId': userId,
        'customerName': customerName.value,
        'customerEmail': customerEmail.value,
        'customerPhone': customerPhone.value,
        'customerAddress': customerAddress.value,
        'items': cartItems,
        'subtotal': totals['subtotal'] ?? 0,
        'tax': totals['tax'] ?? 0,
        'shipping': totals['shipping'] ?? 0,
        'discount': totals['discount'] ?? 0,
        'totalAmount': totals['total'] ?? 0,
        'itemCount': cartItems.fold<int>(0, (sum, item) => sum + ((item['quantity'] ?? 0) as int)),
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      await _firestore
          .collection('bulkorders')
          .doc(bulkOrderId)
          .set(bulkOrderData);

      // Add to local list
      bulkOrders.insert(0, bulkOrderData);
      
      clearForm();
      Get.snackbar('Success', 'Bulk order placed successfully!');
      return true;
    } catch (e) {
      print('Bulk order creation error: $e');
      Get.snackbar('Error', 'Failed to place bulk order: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Improved method with pagination and better error handling
  Future<void> getUserOrders(String userId, {bool loadMore = false}) async {
    try {
      if (!loadMore) {
        isLoading.value = true;
        _lastDocument = null;
        _hasMoreData = true;
      } else {
        if (!_hasMoreData || isLoadingMore.value) return;
        isLoadingMore.value = true;
      }

      Query query = _firestore
          .collection('Orders')
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        _hasMoreData = false;
        if (!loadMore) {
          orders.clear();
        }
        return;
      }

      List<OrderModel> newOrders = querySnapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      if (loadMore) {
        orders.addAll(newOrders);
      } else {
        orders.value = newOrders;
      }

      _lastDocument = querySnapshot.docs.last;
      _hasMoreData = querySnapshot.docs.length == _pageSize;

    } catch (e) {
      print('Get user orders error: $e');
      Get.snackbar('Error', 'Failed to fetch orders: ${e.toString()}');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // Optimized method for getting all orders (admin view)
  Future<void> getAllOrders({bool loadMore = false}) async {
    try {
      if (!loadMore) {
        isLoading.value = true;
        _lastDocument = null;
        _hasMoreData = true;
      } else {
        if (!_hasMoreData || isLoadingMore.value) return;
        isLoadingMore.value = true;
      }

      Query query = _firestore
          .collection('Orders')
          .orderBy('orderDate', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        _hasMoreData = false;
        if (!loadMore) {
          orders.clear();
        }
        return;
      }

      List<OrderModel> newOrders = querySnapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      if (loadMore) {
        orders.addAll(newOrders);
      } else {
        orders.value = newOrders;
      }

      _lastDocument = querySnapshot.docs.last;
      _hasMoreData = querySnapshot.docs.length == _pageSize;

    } catch (e) {
      print('Get all orders error: $e');
      Get.snackbar('Error', 'Failed to fetch orders: ${e.toString()}');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> getAllBulkOrders({bool loadMore = false}) async {
    try {
      if (!loadMore) {
        isLoading.value = true;
        _lastDocument = null;
        _hasMoreData = true;
      } else {
        if (!_hasMoreData || isLoadingMore.value) return;
        isLoadingMore.value = true;
      }

      Query query = _firestore
          .collection('bulkorders')
          .orderBy('orderDate', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        _hasMoreData = false;
        if (!loadMore) {
          bulkOrders.clear();
        }
        return;
      }

      List<dynamic> newOrders = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      if (loadMore) {
        bulkOrders.addAll(newOrders);
      } else {
        bulkOrders.value = newOrders;
      }

      _lastDocument = querySnapshot.docs.last;
      _hasMoreData = querySnapshot.docs.length == _pageSize;

    } catch (e) {
      print('Get bulk orders error: $e');
      Get.snackbar('Error', 'Failed to fetch bulk orders: ${e.toString()}');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  // Method to refresh orders
  Future<void> refreshOrders() async {
    final userId = getCurrentUserId();
    if (userId != null) {
      await getUserOrders(userId);
    }
  }

  // Load more orders (for pagination)
  Future<void> loadMoreOrders() async {
    final userId = getCurrentUserId();
    if (userId != null) {
      await getUserOrders(userId, loadMore: true);
    }
  }

  bool get hasMoreData => _hasMoreData;

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('singleorders').doc(orderId).update({
        'status': status,
      });

      int index = orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        orders[index] = orders[index].copyWith(status: status);
        orders.refresh();
      }

      Get.snackbar('Success', 'Order status updated successfully!');
      return true;
    } catch (e) {
      print('Update order status error: $e');
      Get.snackbar('Error', 'Failed to update order status: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateBulkOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('bulkorders').doc(orderId).update({
        'status': status,
      });

      int index = bulkOrders.indexWhere((order) => order['id'] == orderId);
      if (index != -1) {
        bulkOrders[index]['status'] = status;
        bulkOrders.refresh();
      }

      Get.snackbar('Success', 'Bulk order status updated successfully!');
      return true;
    } catch (e) {
      print('Update bulk order status error: $e');
      Get.snackbar('Error', 'Failed to update bulk order status: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    try {
      await _firestore.collection('singleorders').doc(orderId).delete();
      orders.removeWhere((order) => order.id == orderId);
      Get.snackbar('Success', 'Order deleted successfully!');
      return true;
    } catch (e) {
      print('Delete order error: $e');
      Get.snackbar('Error', 'Failed to delete order: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteBulkOrder(String orderId) async {
    try {
      await _firestore.collection('bulkorders').doc(orderId).delete();
      bulkOrders.removeWhere((order) => order['id'] == orderId);
      Get.snackbar('Success', 'Bulk order deleted successfully!');
      return true;
    } catch (e) {
      print('Delete bulk order error: $e');
      Get.snackbar('Error', 'Failed to delete bulk order: ${e.toString()}');
      return false;
    }
  }

  void setCustomerName(String value) => customerName.value = value;
  void setCustomerEmail(String value) => customerEmail.value = value;
  void setCustomerPhone(String value) => customerPhone.value = value;
  void setCustomerAddress(String value) => customerAddress.value = value;

  void clearForm() {
    customerName.value = '';
    customerEmail.value = '';
    customerPhone.value = '';
    customerAddress.value = '';
  }

  // Method to check authentication status
  bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  // Method to get order by ID (useful for invoice generation)
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('singleorders')
          .doc(orderId)
          .get();
      
      if (doc.exists) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Get order by ID error: $e');
      return null;
    }
  }
}