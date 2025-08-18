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
  final OrderController orderController = Get.put<OrderController>(OrderController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() async {
    // Check if user is logged in
    final userId = orderController.getCurrentUserId();
    if (userId == null) {
      Get.snackbar(
        'Authentication Required',
        'Please login to view orders',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Load user-specific orders instead of all orders
    await orderController.getUserOrders(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: _buildOrdersList(),
    );
  }

  Future<void> _refreshOrders() async {
    final userId = orderController.getCurrentUserId();
    if (userId != null) {
      await orderController.getUserOrders(userId);
    }
  }

  // Optimized PDF Generation - Much Faster!
  Future<void> _generateOrderPDF(OrderModel order) async {
    try {
      // Show loading with timeout
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating PDF...\nThis may take a few seconds'),
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // Create PDF with minimal complexity for speed
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Simple Header
              _buildSimplePDFHeader(),
              pw.SizedBox(height: 30),
              
              // Order Info
              _buildSimpleOrderInfo(order),
              pw.SizedBox(height: 20),
              
              // Customer Info
              _buildSimpleCustomerInfo(order),
              pw.SizedBox(height: 20),
              
              // Product Table
              _buildSimpleProductTable(order),
              pw.SizedBox(height: 20),
              
              // Total
              _buildSimpleTotal(order),
              pw.SizedBox(height: 30),
              
              // Footer
              _buildSimpleFooter(),
            ],
          ),
        ),
      );

      // Close loading dialog
      Get.back();

      // Show PDF immediately
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Order_${order.id.substring(0, 8)}.pdf',
      );

    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('PDF Generation Error: $e');
      Get.snackbar(
        'Error',
        'Failed to generate invoice. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Simplified PDF Components for Speed
  pw.Widget _buildSimplePDFHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'YELLOW ACHAR',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.Text('Delicious Pickles & Spices'),
            pw.Text('WhatsApp: +923231324627'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text('Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
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
          pw.Text('Date: ${DateFormat('MMM dd, yyyy').format(order.orderDate)}'),
          pw.Text('Status: ${(order.status ?? 'Pending').toUpperCase()}'),
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
          pw.Text('Name: ${order.customerName ?? "N/A"}'),
          pw.Text('Phone: ${order.customerPhone ?? "N/A"}'),
          pw.Text('Email: ${order.customerEmail ?? "N/A"}'),
          pw.Text('Address: ${order.customerAddress ?? "N/A"}'),
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
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildSimpleTableCell('Product', isHeader: true),
            _buildSimpleTableCell('Qty', isHeader: true),
            _buildSimpleTableCell('Price', isHeader: true),
            _buildSimpleTableCell('Total', isHeader: true),
          ],
        ),
        // Product Row
        pw.TableRow(
          children: [
            _buildSimpleTableCell(order.productName ?? 'Unknown'),
            _buildSimpleTableCell(order.quantity.toString()),
            _buildSimpleTableCell('Rs ${order.finalPrice.round()}'),
            _buildSimpleTableCell('Rs ${(order.finalPrice * order.quantity).round()}'),
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
                pw.Text('Rs ${order.subtotal?.round() ?? (order.finalPrice * order.quantity).round()}'),
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
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Yellow Achar - Authentic Pakistani Pickles'),
          pw.Text('For support: +923231324627'),
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
              ),
              SizedBox(height: 16),
              Text('Loading orders...'),
            ],
          ),
        );
      }

      if (orderController.orders.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No orders found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your orders will appear here once you make a purchase',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Shopping'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orderController.orders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(orderController.orders[index]);
          },
        ),
      );
    });
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildStatusChip(order.status ?? 'pending'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Order Date
            Text(
              'Placed: ${DateFormat('MMM dd, yyyy • hh:mm a').format(order.orderDate)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            
            const Divider(),
            const SizedBox(height: 12),
            
            // Product Information
            Row(
              children: [
                // Product Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: order.productImage.isNotEmpty
                        ? Image.network(
                            order.productImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
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
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Qty: ${order.quantity}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Rs ${order.finalPrice.round()} each',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Customer Info Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        order.customerName ?? 'Customer Name Not Available',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        order.customerPhone ?? 'Phone Not Available',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Total and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Rs ${order.totalAmount.round()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.print, color: Colors.orange[700]),
                        onPressed: () => _generateOrderPDF(order),
                        tooltip: 'Print Invoice',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue[700]),
                        onPressed: () => _showStatusUpdateDialog(order.id, order.status ?? 'pending'),
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
    
    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'confirmed':
      case 'processing':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'shipped':
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        break;
      case 'delivered':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'cancelled':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
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
      'cancelled'
    ];

    Get.dialog(
      AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Order #${orderId.substring(0, 8).toUpperCase()}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: statuses.contains(currentStatus) ? currentStatus : 'pending',
              decoration: const InputDecoration(
                labelText: 'New Status',
                border: OutlineInputBorder(),
              ),
              items: statuses
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              
              // Show updating status
              Get.snackbar(
                'Updating...',
                'Please wait while we update the order status',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
                snackPosition: SnackPosition.BOTTOM,
              );
              
              final success = await orderController.updateOrderStatus(orderId, newStatus);
              
              if (success) {
                Get.snackbar(
                  'Success',
                  'Order status updated to ${newStatus.toUpperCase()}',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}