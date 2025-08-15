import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
      orderController.getAllOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildOrdersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          orderController.getAllOrders();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // PDF Generation Methods
  Future<void> _generateOrderPDF(OrderModel order) async {
    try {
      // Show loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      final pdf = pw.Document();
      
      // Try to load fonts, but make them optional
      pw.Font? regularFont;
      pw.Font? boldFont;
      
      try {
        regularFont = await PdfGoogleFonts.notoSansRegular();
        boldFont = await PdfGoogleFonts.notoSansBold();
      } catch (e) {
        print('Font loading failed: $e');
        // Continue without custom fonts - PDF will use default fonts
      }
      
      // Load company logo (optional)
      final Uint8List? logoData = await _loadCompanyLogo();

      // Create theme with fonts only if they loaded successfully
      pw.ThemeData theme;
      if (regularFont != null && boldFont != null) {
        theme = pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        );
      } else {
        theme = pw.ThemeData();
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: theme,
          header: (context) => _buildPDFHeader(logoData),
          footer: (context) => _buildPDFFooter(),
          build: (context) => [
            _buildOrderInfo(order),
            pw.SizedBox(height: 20),
            _buildCustomerInfo(order),
            pw.SizedBox(height: 20),
            _buildProductDetails(order),
            pw.SizedBox(height: 20),
            _buildOrderSummary(order),
            pw.SizedBox(height: 30),
            _buildThankYouMessage(),
          ],
        ),
      );

      // Close loading dialog
      Get.back();

      // Show PDF preview
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Order_${order.id.substring(0, 8)}.pdf',
      );

      Get.snackbar(
        'Success',
        'PDF generated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Make sure to close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('PDF Generation Error: $e');
      Get.snackbar(
        'Error',
        'Failed to generate PDF: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  // Updated logo loading method with better error handling
  Future<Uint8List?> _loadCompanyLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/logo.png');
      return data.buffer.asUint8List();
    } catch (e) {
      print('Logo loading failed: $e');
      return null; // Return null if logo doesn't exist
    }
  }

  // PDF Header
  pw.Widget _buildPDFHeader(Uint8List? logoData) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 2, color: PdfColors.blue)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoData != null)
                pw.Image(
                  pw.MemoryImage(logoData),
                  width: 80,
                  height: 40,
                )
              else
                pw.Text(
                  'YOUR COMPANY',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
              pw.SizedBox(height: 5),
              pw.Text('Your Business Address'),
              pw.Text('City, State, ZIP Code'),
              pw.Text('Phone: (123) 456-7890'),
              pw.Text('Email: contact@yourcompany.com'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'ORDER RECEIPT',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Generated: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}'),
            ],
          ),
        ],
      ),
    );
  }

  // PDF Footer
  pw.Widget _buildPDFFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.grey)),
      ),
      child: pw.Center(
        child: pw.Column(
          children: [
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'For any questions regarding this order, please contact our customer service.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // PDF Order Info
  pw.Widget _buildOrderInfo(OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ORDER DETAILS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Order Number: #${order.id.substring(0, 8).toUpperCase()}'),
              pw.Text('Order Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(order.orderDate)}'),
              pw.Text('Status: ${order.status.toUpperCase()}'),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _getPDFStatusColor(order.status),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              order.status.toUpperCase(),
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated customer info method to handle null values safely
  pw.Widget _buildCustomerInfo(OrderModel order) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CUSTOMER INFORMATION',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Name: ${order.customerName ?? "N/A"}'),
                    pw.SizedBox(height: 4),
                    pw.Text('Phone: ${order.customerPhone ?? "N/A"}'),
                    pw.SizedBox(height: 4),
                    // Handle potential null values
                    pw.Text('Email: ${_getCustomerEmail(order)}'),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Shipping Address:'),
                    pw.SizedBox(height: 4),
                    pw.Text('${_getCustomerAddress(order)}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods to safely get customer data
  String _getCustomerEmail(OrderModel order) {
    // Add null check and provide fallback
    try {
      return order.customerEmail?.isNotEmpty == true 
          ? order.customerEmail! 
          : 'Not provided';
    } catch (e) {
      return 'Not provided';
    }
  }

  String _getCustomerAddress(OrderModel order) {
    // Add null check and provide fallback
    try {
      return order.customerAddress?.isNotEmpty == true 
          ? order.customerAddress! 
          : 'Address not provided';
    } catch (e) {
      return 'Address not provided';
    }
  }

  // Updated product details with better null handling
  pw.Widget _buildProductDetails(OrderModel order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PRODUCT DETAILS',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue),
              children: [
                _buildTableHeader('Product Name'),
                _buildTableHeader('Qty', align: pw.TextAlign.center),
                _buildTableHeader('Unit Price', align: pw.TextAlign.right),
                _buildTableHeader('Total', align: pw.TextAlign.right),
              ],
            ),
            // Product row with safe access
            pw.TableRow(
              children: [
                _buildTableCell(order.productName ?? 'Unknown Product'),
                _buildTableCell(
                  (order.quantity ?? 0).toString(), 
                  align: pw.TextAlign.center
                ),
                _buildTableCell(
                  '\$${(order.finalPrice ?? 0.0).toStringAsFixed(2)}',
                  align: pw.TextAlign.right
                ),
                _buildTableCell(
                  '\$${((order.finalPrice ?? 0.0) * (order.quantity ?? 0)).toStringAsFixed(2)}',
                  align: pw.TextAlign.right,
                  isBold: true
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods for table building
  pw.Widget _buildTableHeader(String text, {pw.TextAlign? align}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: align ?? pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {pw.TextAlign? align, bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align ?? pw.TextAlign.left,
        style: isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
      ),
    );
  }

  // Updated order summary with null safety
  pw.Widget _buildOrderSummary(OrderModel order) {
    final double finalPrice = order.finalPrice ?? 0.0;
    final int quantity = order.quantity ?? 0;
    final double totalAmount = order.totalAmount ?? 0.0;
    
    final subtotal = finalPrice * quantity;
    final tax = subtotal * 0.1; // 10% tax (adjust as needed)
    final shipping = 10.0; // Flat shipping rate (adjust as needed)
    
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 200,
                child: pw.Column(
                  children: [
                    _buildSummaryRow('Subtotal:', '\$${subtotal.toStringAsFixed(2)}'),
                    _buildSummaryRow('Tax (10%):', '\$${tax.toStringAsFixed(2)}'),
                    _buildSummaryRow('Shipping:', '\$${shipping.toStringAsFixed(2)}'),
                    pw.Divider(),
                    _buildSummaryRow(
                      'TOTAL:',
                      '\$${totalAmount.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
              color: isTotal ? PdfColors.blue : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildThankYouMessage() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your order!',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'We appreciate your business and hope you enjoy your purchase.',
            style: const pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Order tracking and updates will be sent to your registered email address.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  PdfColor _getPDFStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PdfColors.orange;
      case 'processing':
        return PdfColors.blue;
      case 'shipped':
        return PdfColors.purple;
      case 'delivered':
        return PdfColors.green;
      case 'cancelled':
        return PdfColors.red;
      default:
        return PdfColors.grey;
    }
  }

  // UI Methods
  Widget _buildOrdersList() {
    return Obx(() {
      if (orderController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (orderController.orders.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No orders found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await orderController.getAllOrders();
        },
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
      elevation: 2,
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
                    'Order #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            
            // Order Date
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(order.orderDate),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            
            const Divider(),
            const SizedBox(height: 12),
            
            // Product Information
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
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.image,
                          color: Colors.grey,
                        ),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantity: ${order.quantity}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Unit Price: \$${order.finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Customer Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Customer: ${order.customerName}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Phone: ${order.customerPhone}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Order Total and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.orange),
                      onPressed: () => _generateOrderPDF(order),
                      tooltip: 'Generate PDF',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showStatusUpdateDialog(order.id, order.status),
                      tooltip: 'Update Status',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(order.id),
                      tooltip: 'Delete Order',
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
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${orderId.substring(0, 8)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: newStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: ['pending', 'processing', 'shipped', 'delivered', 'cancelled']
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await orderController.updateOrderStatus(orderId, newStatus);
              
              // Show success message
              Get.snackbar(
                'Success',
                'Order status updated successfully',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${orderId.substring(0, 8)}'),
            const SizedBox(height: 8),
            const Text('Are you sure you want to delete this order? This action cannot be undone.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              await orderController.deleteOrder(orderId);
              
              // Show success message
              Get.snackbar(
                'Success',
                'Order deleted successfully',
                backgroundColor: Colors.red,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
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