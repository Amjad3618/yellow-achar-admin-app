// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../controllers/order_controller.dart';
import '../models/order_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderController orderController = Get.put<OrderController>(
    OrderController(),
  );
  String selectedFilter = 'all';

  final List<String> filterOptions = [
    'all',
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'completed', // Add this if you want a separate completed filter
    'cancelled',
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() async {
    try {
      // Debug: Check authentication
      final userId = orderController.getCurrentUserId();
      print('DEBUG: Current User ID: $userId');

      if (userId == null) {
        print('DEBUG: No user ID found - user not authenticated');
        Get.snackbar(
          'Authentication Required',
          'Please login to view orders',
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return;
      }

      // Load orders with error handling
      print('DEBUG: Loading orders for user: $userId');
      await orderController.getUserOrders(userId);
      print('DEBUG: Orders loaded. Count: ${orderController.orders.length}');

      // If still no orders, try loading all orders (for admin)
      if (orderController.orders.isEmpty) {
        print('DEBUG: No user orders found, trying to load all orders');
        await orderController.getAllOrders();
        print(
          'DEBUG: All orders loaded. Count: ${orderController.orders.length}',
        );
      }
    } catch (e) {
      print('DEBUG: Error loading orders: $e');
      Get.snackbar(
        'Error',
        'Failed to load orders: ${e.toString()}',
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Orders Management',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          // Filter Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              onSelected: (value) {
                setState(() {
                  selectedFilter = value;
                });
              },
              itemBuilder:
                  (context) =>
                      filterOptions.map((filter) {
                        return PopupMenuItem(
                          value: filter,
                          child: Row(
                            children: [
                              if (selectedFilter == filter)
                                const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Color(0xFF3B82F6),
                                ),
                              if (selectedFilter == filter)
                                const SizedBox(width: 8),
                              Text(filter.toUpperCase()),
                            ],
                          ),
                        );
                      }).toList(),
            ),
          ),
          // Refresh Button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              onPressed: _refreshOrders,
              tooltip: 'Refresh Orders',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Obx(() {
              final orders = orderController.orders;
              final totalOrders = orders.length;
              final pendingOrders =
                  orders
                      .where((o) => o.status.toLowerCase() == 'pending')
                      .length;
              final completedOrders =
                  orders
                      .where((o) => o.status.toLowerCase() == 'delivered')
                      .length;

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Orders',
                      totalOrders.toString(),
                      Icons.receipt_long_rounded,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      pendingOrders.toString(),
                      Icons.pending_actions_rounded,
                      const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Completed',
                      completedOrders.toString(),
                      Icons.check_circle_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                ],
              );
            }),
          ),

          // Orders List
          Expanded(child: _buildOrdersList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Debug button to check orders
          _showDebugInfo();
        },
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.bug_report_rounded),
        label: const Text('Debug'),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshOrders() async {
    try {
      final userId = orderController.getCurrentUserId();
      print('DEBUG: Refreshing orders for user: $userId');

      if (userId != null) {
        await orderController.getUserOrders(userId);
        // Also try loading all orders if user orders are empty
        if (orderController.orders.isEmpty) {
          await orderController.getAllOrders();
        }
      }

      Get.snackbar(
        'Refreshed',
        'Orders updated successfully',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('DEBUG: Refresh error: $e');
      Get.snackbar(
        'Error',
        'Failed to refresh orders',
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  void _showDebugInfo() {
    final userId = orderController.getCurrentUserId();
    final ordersCount = orderController.orders.length;
    final isLoading = orderController.isLoading.value;

    Get.dialog(
      AlertDialog(
        title: const Text('Debug Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: ${userId ?? "Not logged in"}'),
            Text('Orders Count: $ordersCount'),
            Text('Is Loading: $isLoading'),
            Text('Controller: ${orderController.runtimeType}'),
            const SizedBox(height: 16),
            const Text('Troubleshooting Steps:'),
            const Text('1. Check if user is authenticated'),
            const Text('2. Verify database connection'),
            const Text('3. Check getUserOrders() method'),
            const Text('4. Try getAllOrders() method'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Try to load all orders
              orderController.getAllOrders();
            },
            child: const Text('Load All Orders'),
          ),
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  // Updated filtering logic in _buildOrdersList method:
  Widget _buildOrdersList() {
    return Obx(() {
      if (orderController.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                'Loading orders...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      // Filter orders based on selected filter
      List<OrderModel> filteredOrders = orderController.orders;
      if (selectedFilter != 'all') {
        filteredOrders =
            orderController.orders.where((order) {
              final orderStatus = order.status.toLowerCase();

              // Special handling: treat 'delivered' orders as 'completed' for filtering
              if (selectedFilter == 'completed') {
                return orderStatus == 'delivered' || orderStatus == 'completed';
              }

              return orderStatus == selectedFilter;
            }).toList();
      }

      if (filteredOrders.isEmpty) {
        return Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  selectedFilter == 'all'
                      ? 'No orders found'
                      : selectedFilter == 'completed'
                      ? 'No completed orders'
                      : 'No ${selectedFilter} orders',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  selectedFilter == 'all'
                      ? 'Orders will appear here once customers place them'
                      : selectedFilter == 'completed'
                      ? 'No completed/delivered orders found'
                      : 'No orders with ${selectedFilter} status found',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _refreshOrders,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _showDebugInfo,
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('Debug'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _refreshOrders,
        color: const Color(0xFF3B82F6),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(filteredOrders[index]);
          },
        ),
      );
    });
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy • hh:mm a',
                        ).format(order.orderDate),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),

            const SizedBox(height: 20),

            // Product Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  // Product Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child:
                          order.productImage.isNotEmpty
                              ? Image.network(
                                order.productImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(
                                      Icons.image_not_supported_rounded,
                                      color: Color(0xFF94A3B8),
                                      size: 24,
                                    ),
                                  );
                                },
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(0xFF3B82F6),
                                              ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                              : Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(
                                  Icons.shopping_bag_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 24,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Qty: ${order.quantity}',
                                style: const TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Rs ${order.finalPrice.round()} each',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Customer Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customerName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customerPhone,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  // ignore: unnecessary_null_comparison
                  if (order.customerAddress != null &&
                      order.customerAddress.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.customerAddress,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Total and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${order.totalAmount.round()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.print_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        onPressed: () => _generateOrderPDF(order),
                        tooltip: 'Print Invoice',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                        onPressed:
                            () =>
                                _showStatusUpdateDialog(order.id, order.status),
                        tooltip: 'Update Status',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = const Color(0xFFF59E0B).withOpacity(0.1);
        textColor = const Color(0xFFF59E0B);
        icon = Icons.pending_actions_rounded;
        break;
      case 'confirmed':
        backgroundColor = const Color(0xFF3B82F6).withOpacity(0.1);
        textColor = const Color(0xFF3B82F6);
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'processing':
        backgroundColor = const Color(0xFF6366F1).withOpacity(0.1);
        textColor = const Color(0xFF6366F1);
        icon = Icons.autorenew_rounded;
        break;
      case 'shipped':
        backgroundColor = const Color(0xFF8B5CF6).withOpacity(0.1);
        textColor = const Color(0xFF8B5CF6);
        icon = Icons.local_shipping_rounded;
        break;
      case 'delivered':
        backgroundColor = const Color(0xFF10B981).withOpacity(0.1);
        textColor = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        backgroundColor = const Color(0xFFDC2626).withOpacity(0.1);
        textColor = const Color(0xFFDC2626);
        icon = Icons.cancel_rounded;
        break;
      default:
        backgroundColor = const Color(0xFF64748B).withOpacity(0.1);
        textColor = const Color(0xFF64748B);
        icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Optimized PDF Generation
  Future<void> _generateOrderPDF(OrderModel order) async {
    try {
      // Show loading dialog
      Get.dialog(
        PopScope(
          canPop: false,
          child: const Center(
            child: Card(
              margin: EdgeInsets.all(32),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF3B82F6),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Generating Invoice...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please wait while we create your PDF',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build:
              (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSimplePDFHeader(),
                  pw.SizedBox(height: 30),
                  _buildSimpleOrderInfo(order),
                  pw.SizedBox(height: 20),
                  _buildSimpleCustomerInfo(order),
                  pw.SizedBox(height: 20),
                  _buildSimpleProductTable(order),
                  pw.SizedBox(height: 20),
                  _buildSimpleTotal(order),
                  pw.SizedBox(height: 30),
                  _buildSimpleFooter(),
                ],
              ),
        ),
      );

      Get.back(); // Close loading dialog

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice_${order.id.substring(0, 8)}.pdf',
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      print('PDF Generation Error: $e');
      Get.snackbar(
        'Error',
        'Failed to generate invoice. Please try again.',
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  // PDF Components
  pw.Widget _buildSimplePDFHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'FRESH VALLEY', // Changed from YELLOW ACHAR
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.Text(
              'Delicious Pickles & Spices',
            ), // You can also change this tagline if needed
            pw.Text('WhatsApp: +923231324627'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSimpleOrderInfo(OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Order ID: #${order.id.substring(0, 8).toUpperCase()}'),
          pw.Text(
            'Date: ${DateFormat('MMM dd, yyyy').format(order.orderDate)}',
          ),
          pw.Text('Status: ${order.status.toUpperCase()}'),
        ],
      ),
    );
  }

  pw.Widget _buildSimpleCustomerInfo(OrderModel order) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CUSTOMER DETAILS',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Name: ${order.customerName}'),
          pw.Text('Phone: ${order.customerPhone}'),
          pw.Text('Email: ${order.customerEmail}'),
          pw.Text('Address: ${order.customerAddress}'),
        ],
      ),
    );
  }

  pw.Widget _buildSimpleProductTable(OrderModel order) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildSimpleTableCell('Product', isHeader: true),
            _buildSimpleTableCell('Qty', isHeader: true),
            _buildSimpleTableCell('Price', isHeader: true),
            _buildSimpleTableCell('Total', isHeader: true),
          ],
        ),
        pw.TableRow(
          children: [
            _buildSimpleTableCell(order.productName),
            _buildSimpleTableCell(order.quantity.toString()),
            _buildSimpleTableCell('Rs ${order.finalPrice.round()}'),
            _buildSimpleTableCell(
              'Rs ${(order.finalPrice * order.quantity).round()}',
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSimpleTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildSimpleTotal(OrderModel order) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal:'),
                pw.Text('Rs ${order.subtotal.round()}'),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Delivery:'),
                pw.Text('Rs ${order.totalAmount > 1000 ? 0 : 150}'),
              ],
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Rs ${order.totalAmount.round()}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildSimpleFooter() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your order!',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Fresh Valley - Authentic Pakistani Pickles',
          ), // Changed from Yellow Achar
          pw.Text('For support: +923231324627'),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(String orderId, String currentStatus) {
    String newStatus = currentStatus;
    final List<String> statuses = [
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'delivered',
      'cancelled',
    ];

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Update Order Status',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${orderId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value:
                  statuses.contains(currentStatus) ? currentStatus : 'pending',
              decoration: InputDecoration(
                labelText: 'New Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B82F6),
                    width: 2,
                  ),
                ),
              ),
              items:
                  statuses.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  newStatus = value;
                }
              },
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              Get.back();

              Get.snackbar(
                'Updating...',
                'Please wait while we update the order status',
                backgroundColor: const Color(0xFF3B82F6),
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
                snackPosition: SnackPosition.TOP,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );

              final success = await orderController.updateOrderStatus(
                orderId,
                newStatus,
              );

              if (success) {
                Get.snackbar(
                  'Success',
                  'Order status updated to ${newStatus.toUpperCase()}',
                  backgroundColor: const Color(0xFF10B981),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to update order status',
                  backgroundColor: const Color(0xFFDC2626),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Update',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
