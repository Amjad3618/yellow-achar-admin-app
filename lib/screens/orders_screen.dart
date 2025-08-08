import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../controllers/order_controller.dart';
import '../models/order_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderController orderController = Get.put<OrderController>(OrderController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      orderController.getAllOrders();
      orderController.getAllBulkOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Single Orders'), Tab(text: 'Bulk Orders')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSingleOrdersTab(), _buildBulkOrdersTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          orderController.getAllOrders();
          orderController.getAllBulkOrders();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSingleOrdersTab() {
    return Obx(() {
      if (orderController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (orderController.orders.isEmpty) {
        return const Center(child: Text('No single orders found'));
      }

      return RefreshIndicator(
        onRefresh: () async {
          await orderController.getAllOrders();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orderController.orders.length,
          itemBuilder: (context, index) {
            return _buildSingleOrderCard(orderController.orders[index]);
          },
        ),
      );
    });
  }

  Widget _buildBulkOrdersTab() {
    return Obx(() {
      if (orderController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (orderController.bulkOrders.isEmpty) {
        return const Center(child: Text('No bulk orders found'));
      }

      return RefreshIndicator(
        onRefresh: () async {
          await orderController.getAllBulkOrders();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orderController.bulkOrders.length,
          itemBuilder: (context, index) {
            return _buildBulkOrderCard(orderController.bulkOrders[index]);
          },
        ),
      );
    });
  }

  Widget _buildSingleOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(order.orderDate),
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    order.productImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('Qty: ${order.quantity}'),
                      Text('\$${order.finalPrice.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Customer: ${order.customerName}'),
            Text('Phone: ${order.customerPhone}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed:
                          () => _showStatusUpdateDialog(order.id, order.status),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(order.id, true),
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

  Widget _buildBulkOrderCard(dynamic bulkOrder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bulk Order #${bulkOrder['id'].toString().substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(bulkOrder['status'] ?? 'pending'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bulkOrder['orderDate'] != null
                  ? DateFormat(
                    'MMM dd, yyyy • hh:mm a',
                  ).format((bulkOrder['orderDate'] as Timestamp).toDate())
                  : 'Date not available',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(),
            Text('Items: ${bulkOrder['itemCount']} items'),
            Text('Products: ${bulkOrder['items']?.length ?? 0} products'),
            const SizedBox(height: 12),
            Text('Customer: ${bulkOrder['customerName'] ?? 'N/A'}'),
            Text('Phone: ${bulkOrder['customerPhone'] ?? 'N/A'}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$${(bulkOrder['totalAmount'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed:
                          () => _showBulkStatusUpdateDialog(
                            bulkOrder['id'],
                            bulkOrder['status'] ?? 'pending',
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed:
                          () => _showDeleteDialog(bulkOrder['id'], false),
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
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'processing':
        color = Colors.blue;
        break;
      case 'shipped':
        color = Colors.purple;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(String orderId, String currentStatus) {
    String newStatus = currentStatus;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Update Order Status'),
            content: DropdownButtonFormField<String>(
              value: newStatus,
              items:
                  ['pending', 'processing', 'shipped', 'delivered', 'cancelled']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  newStatus = value;
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await orderController.updateOrderStatus(orderId, newStatus);
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _showBulkStatusUpdateDialog(String orderId, String currentStatus) {
    String newStatus = currentStatus;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Update Bulk Order Status'),
            content: DropdownButtonFormField<String>(
              value: newStatus,
              items:
                  ['pending', 'processing', 'shipped', 'delivered', 'cancelled']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  newStatus = value;
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await orderController.updateBulkOrderStatus(
                    orderId,
                    newStatus,
                  );
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(String orderId, bool isSingleOrder) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Order'),
            content: const Text('Are you sure you want to delete this order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (isSingleOrder) {
                    await orderController.deleteOrder(orderId);
                  } else {
                    await orderController.deleteBulkOrder(orderId);
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
