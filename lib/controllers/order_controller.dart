import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/order_model.dart';

class OrderController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var isLoading = false.obs;
  var orders = <OrderModel>[].obs;
  var bulkOrders = <dynamic>[].obs;
  var currentOrder = Rxn<OrderModel>();

  var customerName = ''.obs;
  var customerEmail = ''.obs;
  var customerPhone = ''.obs;
  var customerAddress = ''.obs;
  var isFormValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(customerName, (_) => validateForm());
    ever(customerEmail, (_) => validateForm());
    ever(customerPhone, (_) => validateForm());
    ever(customerAddress, (_) => validateForm());
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

      String orderId = _firestore.collection('singleorders').doc().id;

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
          .collection('singleorders')
          .doc(orderId)
          .set(order.toMap());

      orders.add(order);
      currentOrder.value = order;
      return true;
    } catch (e) {
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

      clearForm();
      Get.snackbar('Success', 'Bulk order placed successfully!');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to place bulk order: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getAllOrders() async {
    try {
      isLoading.value = true;

      QuerySnapshot querySnapshot = await _firestore
          .collection('singleorders')
          .orderBy('orderDate', descending: true)
          .get();

      orders.value = querySnapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch orders: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getAllBulkOrders() async {
    try {
      isLoading.value = true;

      QuerySnapshot querySnapshot = await _firestore
          .collection('bulkorders')
          .orderBy('orderDate', descending: true)
          .get();

      bulkOrders.value = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch bulk orders: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getUserOrders(String userId) async {
    try {
      isLoading.value = true;

      QuerySnapshot querySnapshot = await _firestore
          .collection('singleorders')
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .get();

      orders.value = querySnapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch orders: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

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
}