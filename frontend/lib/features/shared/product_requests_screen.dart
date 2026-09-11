import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class ProductRequest {
  final String id;
  final String customerName;
  final String customerId;
  final String customerEmail;
  final String productName;
  final String productModel;
  final String category;
  final int quantity;
  final String date;
  final String status;

  const ProductRequest({
    required this.id,
    required this.customerName,
    required this.customerId,
    required this.customerEmail,
    required this.productName,
    required this.productModel,
    required this.category,
    required this.quantity,
    required this.date,
    required this.status,
  });
}

class ProductRequestsScreen extends StatefulWidget {
  const ProductRequestsScreen({super.key});

  @override
  State<ProductRequestsScreen> createState() => _ProductRequestsScreenState();
}

class _ProductRequestsScreenState extends State<ProductRequestsScreen> {
  // Mock data based on the provided image
  final List<ProductRequest> _requests = [
    const ProductRequest(
      id: '1',
      customerName: 'ANJI.G',
      customerId: 'VEVO15',
      customerEmail: 'veeraanji4777@gmail.com',
      productName: 'TESTPRODUCT',
      productModel: 'MODEL: SCOTTY PEP',
      category: 'VEHICLES\n(2WHEELER/4WHEELER)',
      quantity: 1,
      date: '31\nAUG',
      status: 'FULFILLED',
    ),
  ];

  Future<void> _handleProcessYield() async {
    // Show confirmation dialog with specific text
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PROCESS MONTHLY YIELD',
      message: "Process this month's cashback? This credits one monthly installment (10%) to every cycle that is due, and can only run ONCE per calendar month.",
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A), // Dark blue to match theme
    );

    if (confirmed == true) {
      // Execute process...
      ToastService.show(
        title: 'Yield Processed',
        message: 'Monthly cashback installments have been successfully credited.',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light crisp background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 1. Top Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users, orders, assets...',
                    hintStyle: const TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.kTextMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Process Monthly Yield Button
              ElevatedButton.icon(
                onPressed: _handleProcessYield,
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text(
                  'PROCESS MONTHLY YIELD',
                  style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A), // Dark blue from design
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Main Data Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Header
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PRODUCT REQUESTS',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'CUSTOMER-SUBMITTED PRODUCT REQUESTS AWAITING REVIEW',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF94A3B8).withOpacity(0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          // Pending Review Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD97706),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '0 PENDING REVIEW',
                                  style: TextStyle(
                                    color: Color(0xFFD97706),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(height: 1, color: AppColors.kBorder),

                    // Scrollable Data Table (Mobile Responsive)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: DataTable(
                          columnSpacing: 48,
                          headingRowHeight: 56,
                          dataRowMinHeight: 100, // Taller rows for multi-line content
                          dataRowMaxHeight: 100,
                          dividerThickness: 0,
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                          columns: const [
                            DataColumn(label: Text('CUSTOMER')),
                            DataColumn(label: Text('REQUESTED PRODUCT')),
                            DataColumn(label: Text('SPECS')),
                            DataColumn(label: Text('STATUS')),
                            DataColumn(label: Text('ACTIONS')),
                          ],
                          rows: _requests.map((request) {
                            return DataRow(
                              cells: [
                                // CUSTOMER CELL
                                DataCell(
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E3A8A), // Dark blue bg
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          request.customerName.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(
                                            color: Color(0xFFFBBF24), // Yellow text
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            request.customerName,
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 15),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            request.customerId,
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706), fontSize: 11), // Yellow/Orange
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            request.customerEmail,
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // REQUESTED PRODUCT CELL
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request.productName,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        request.productModel,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706), fontSize: 11),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        request.category,
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),

                                // SPECS CELL
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'QTY ${request.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            request.date,
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 10, height: 1.1),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // STATUS CELL
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      request.status,
                                      style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5),
                                    ),
                                  ),
                                ),

                                // ACTIONS CELL
                                DataCell(
                                  Text(
                                    request.status, // "FULFILLED" text indicator
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}