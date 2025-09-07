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

// Group model for grouped orders
class GroupedOrder {
  final String groupId;
  final String userId;
  final List<OrderModel> orders;
  final DateTime orderDate;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String customerAddress;
  final double totalAmount;
  final String status;

  GroupedOrder({
    required this.groupId,
    required this.userId,
    required this.orders,
    required this.orderDate,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.customerAddress,
    required this.totalAmount,
    required this.status,
  });
}

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
    'completed',
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

      print('DEBUG: Loading orders for user: $userId');
      await orderController.getUserOrders(userId);
      print('DEBUG: Orders loaded. Count: ${orderController.orders.length}');

      if (orderController.orders.isEmpty) {
        print('DEBUG: No user orders found, trying to load all orders');
        await orderController.getAllOrders();
        print('DEBUG: All orders loaded. Count: ${orderController.orders.length}');
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

  // Group orders by user ID and order time (within 5 minutes)
  List<GroupedOrder> _groupOrders(List<OrderModel> orders) {
    Map<String, List<OrderModel>> groupedMap = {};
    
    for (var order in orders) {
      // Create a group key based on userId and order time (rounded to 5-minute intervals)
      final orderTime = order.orderDate;
      final roundedTime = DateTime(
        orderTime.year,
        orderTime.month,
        orderTime.day,
        orderTime.hour,
        (orderTime.minute ~/ 5) * 5, // Round to 5-minute intervals
      );
      
      final groupKey = '${order.userId}_${roundedTime.millisecondsSinceEpoch}';
      
      if (!groupedMap.containsKey(groupKey)) {
        groupedMap[groupKey] = [];
      }
      groupedMap[groupKey]!.add(order);
    }

    // Convert to GroupedOrder objects
    List<GroupedOrder> groupedOrders = [];
    
    groupedMap.forEach((groupKey, orderList) {
      if (orderList.isNotEmpty) {
        final firstOrder = orderList.first;
        final totalAmount = orderList.fold(0.0, (sum, order) => sum + order.totalAmount);
        
        // Determine group status (prioritize pending/processing over completed)
        String groupStatus = 'delivered';
        if (orderList.any((o) => o.status.toLowerCase() == 'pending')) {
          groupStatus = 'pending';
        } else if (orderList.any((o) => o.status.toLowerCase() == 'processing')) {
          groupStatus = 'processing';
        } else if (orderList.any((o) => o.status.toLowerCase() == 'confirmed')) {
          groupStatus = 'confirmed';
        } else if (orderList.any((o) => o.status.toLowerCase() == 'shipped')) {
          groupStatus = 'shipped';
        } else if (orderList.any((o) => o.status.toLowerCase() == 'cancelled')) {
          groupStatus = 'cancelled';
        }

        groupedOrders.add(GroupedOrder(
          groupId: groupKey,
          userId: firstOrder.userId,
          orders: orderList,
          orderDate: firstOrder.orderDate,
          customerName: firstOrder.customerName,
          customerPhone: firstOrder.customerPhone,
          customerEmail: firstOrder.customerEmail,
          customerAddress: firstOrder.customerAddress,
          totalAmount: totalAmount,
          status: groupStatus,
        ));
      }
    });

    // Sort by order date (newest first)
    groupedOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return groupedOrders;
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
              itemBuilder: (context) => filterOptions.map((filter) {
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
                      if (selectedFilter == filter) const SizedBox(width: 8),
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
              final groupedOrders = _groupOrders(orderController.orders);
              final totalOrders = groupedOrders.length;
              final pendingOrders = groupedOrders
                  .where((o) => o.status.toLowerCase() == 'pending')
                  .length;
              final completedOrders = groupedOrders
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
    final groupedCount = _groupOrders(orderController.orders).length;
    final isLoading = orderController.isLoading.value;

    Get.dialog(
      AlertDialog(
        title: const Text('Debug Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: ${userId ?? "Not logged in"}'),
            Text('Raw Orders Count: $ordersCount'),
            Text('Grouped Orders Count: $groupedCount'),
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
              orderController.getAllOrders();
            },
            child: const Text('Load All Orders'),
          ),
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

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

      // Group orders first
      List<GroupedOrder> groupedOrders = _groupOrders(orderController.orders);

      // Filter grouped orders based on selected filter
      if (selectedFilter != 'all') {
        groupedOrders = groupedOrders.where((groupedOrder) {
          final status = groupedOrder.status.toLowerCase();
          
          if (selectedFilter == 'completed') {
            return status == 'delivered' || status == 'completed';
          }
          
          return status == selectedFilter;
        }).toList();
      }

      if (groupedOrders.isEmpty) {
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
          itemCount: groupedOrders.length,
          itemBuilder: (context, index) {
            return _buildGroupedOrderCard(groupedOrders[index]);
          },
        ),
      );
    });
  }

  Widget _buildGroupedOrderCard(GroupedOrder groupedOrder) {
    final totalItems = groupedOrder.orders.fold(0, (sum, order) => sum + order.quantity);
    
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
                        'Order #${groupedOrder.groupId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy • hh:mm a').format(groupedOrder.orderDate),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${groupedOrder.orders.length} items • ${totalItems} qty',
                              style: const TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontSize: 6,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(groupedOrder.status),
              ],
            ),

            const SizedBox(height: 20),

            // Products Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Products',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...groupedOrder.orders.map((order) => _buildProductRow(order)).toList(),
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
                      const Icon(Icons.person_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          groupedOrder.customerName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          groupedOrder.customerPhone,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (groupedOrder.customerAddress.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            groupedOrder.customerAddress,
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
                      'Rs ${groupedOrder.totalAmount.round()}',
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
                        onPressed: () => _generateGroupedOrderPDF(groupedOrder),
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
                        onPressed: () => _showStatusUpdateDialog(groupedOrder),
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

  Widget _buildProductRow(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: order.productImage.isNotEmpty
                  ? Image.network(
                      order.productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${order.quantity} × Rs ${order.finalPrice.round()} = Rs ${(order.quantity * order.finalPrice).round()}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          Icon(icon, size: 8, color: textColor),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Generate PDF for grouped orders
  Future<void> _generateGroupedOrderPDF(GroupedOrder groupedOrder) async {
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
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            _buildGroupedPDFHeader(),
            pw.SizedBox(height: 30),
            _buildGroupedOrderInfo(groupedOrder),
            pw.SizedBox(height: 20),
            _buildGroupedCustomerInfo(groupedOrder),
            pw.SizedBox(height: 20),
            _buildGroupedProductTable(groupedOrder),
            pw.SizedBox(height: 20),
            _buildGroupedTotal(groupedOrder),
            pw.SizedBox(height: 30),
            _buildGroupedFooter(),
          ],
        ),
      );

      Get.back(); // Close loading dialog

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice_${groupedOrder.groupId.substring(0, 8)}.pdf',
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

  // PDF Components for Grouped Orders
  pw.Widget _buildGroupedPDFHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'FRESH VALLEY',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.Text('Delicious Pickles & Spices'),
            pw.Text('WhatsApp: +9203091336378'),
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

  pw.Widget _buildGroupedOrderInfo(GroupedOrder groupedOrder) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Order ID: #${groupedOrder.groupId.substring(0, 8).toUpperCase()}'),
          pw.Text(
            'Date: ${DateFormat('MMM dd, yyyy').format(groupedOrder.orderDate)}',
          ),
          pw.Text('Status: ${groupedOrder.status.toUpperCase()}'),
        ],
      ),
    );
  }

  pw.Widget _buildGroupedCustomerInfo(GroupedOrder groupedOrder) {
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
          pw.Text('Name: ${groupedOrder.customerName}'),
          pw.Text('Phone: ${groupedOrder.customerPhone}'),
          pw.Text('Email: ${groupedOrder.customerEmail}'),
          pw.Text('Address: ${groupedOrder.customerAddress}'),
        ],
      ),
    );
  }

  pw.Widget _buildGroupedProductTable(GroupedOrder groupedOrder) {
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
            _buildGroupedTableCell('Product', isHeader: true),
            _buildGroupedTableCell('Qty', isHeader: true),
            _buildGroupedTableCell('Price', isHeader: true),
            _buildGroupedTableCell('Total', isHeader: true),
          ],
        ),
        ...groupedOrder.orders.map((order) => pw.TableRow(
          children: [
            _buildGroupedTableCell(order.productName),
            _buildGroupedTableCell(order.quantity.toString()),
            _buildGroupedTableCell('Rs ${order.finalPrice.round()}'),
            _buildGroupedTableCell(
              'Rs ${(order.finalPrice * order.quantity).round()}',
            ),
          ],
        )).toList(),
      ],
    );
  }

  pw.Widget _buildGroupedTableCell(String text, {bool isHeader = false}) {
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

  pw.Widget _buildGroupedTotal(GroupedOrder groupedOrder) {
    final subtotal = groupedOrder.orders.fold(0.0, (sum, order) => sum + (order.finalPrice * order.quantity));
    final delivery = groupedOrder.totalAmount > 1000 ? 0 : 150;
    
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
                pw.Text('Rs ${subtotal.round()}'),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Delivery:'),
                pw.Text('Rs $delivery'),
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
                  'Rs ${groupedOrder.totalAmount.round()}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildGroupedFooter() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your order!',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Fresh Valley - Authentic Pakistani Pickles'),
          pw.Text('For support: +9203091336378'),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(GroupedOrder groupedOrder) {
    String newStatus = groupedOrder.status;
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
              'Order #${groupedOrder.groupId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${groupedOrder.orders.length} products will be updated',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: statuses.contains(groupedOrder.status) ? groupedOrder.status : 'pending',
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
              items: statuses.map((status) {
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
                'Please wait while we update all order statuses',
                backgroundColor: const Color(0xFF3B82F6),
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
                snackPosition: SnackPosition.TOP,
                margin: const EdgeInsets.all(16),
                borderRadius: 12,
              );

              // Update status for all orders in the group
              bool allSuccess = true;
              for (var order in groupedOrder.orders) {
                final success = await orderController.updateOrderStatus(
                  order.id,
                  newStatus,
                );
                if (!success) {
                  allSuccess = false;
                }
              }

              if (allSuccess) {
                Get.snackbar(
                  'Success',
                  'All order statuses updated to ${newStatus.toUpperCase()}',
                  backgroundColor: const Color(0xFF10B981),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              } else {
                Get.snackbar(
                  'Partial Success',
                  'Some orders could not be updated',
                  backgroundColor: const Color(0xFFF59E0B),
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
              }

              // Refresh orders to show updated status
              _refreshOrders();
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
              'Update All',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}