import 'package:flutter/material.dart';
import 'investment_history_model.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';

class InvestmentHistoryScreen extends StatefulWidget {
  const InvestmentHistoryScreen({super.key});

  @override
  State<InvestmentHistoryScreen> createState() => _InvestmentHistoryScreenState();
}

class _InvestmentHistoryScreenState extends State<InvestmentHistoryScreen> {
  // Sample Data matching the provided reference images
  final List<InvestmentHistoryRecord> _records = [
    InvestmentHistoryRecord(
      id: 'REC-1',
      processDate: '31 Aug 2026',
      processTime: '11:28 AM',
      customerName: 'NANDHA KUMAR.M',
      customerEmail: 'n2348979@gmail.com',
      assetType: '22K GOLD ASSET',
      assetWeight: '40.000 GRAMS',
      capitalAmount: '₹8,40,006.2',
      dailyAmount: 'DAILY: ₹16310.8',
      paymentMethod: 'BANK TRANSFER',
      utrNumber: '123456',
      statusCode: 'ACTIVE',
      receiptUrl: '#',
    ),
    InvestmentHistoryRecord(
      id: 'REC-2',
      processDate: '31 Aug 2026',
      processTime: '11:28 AM',
      customerName: 'PRAKASH.A',
      customerEmail: 'prakashaugust19@gmail.com',
      assetType: '22K GOLD ASSET',
      assetWeight: '8.000 GRAMS',
      capitalAmount: '₹1,68,001.24',
      dailyAmount: 'DAILY: ₹3262.16',
      paymentMethod: 'BANK TRANSFER',
      utrNumber: '123456',
      statusCode: 'ACTIVE',
      receiptUrl: '#',
    ),
    InvestmentHistoryRecord(
      id: 'REC-3',
      processDate: '31 Aug 2026',
      processTime: '11:34 AM',
      customerName: 'SOMASUNDARAM.S',
      customerEmail: 'somaskm0504@gmail.com',
      assetType: '22K GOLD ASSET',
      assetWeight: '8.000 GRAMS',
      capitalAmount: '₹1,68,001.24',
      dailyAmount: 'DAILY: ₹3262.16',
      paymentMethod: 'BANK TRANSFER',
      utrNumber: '123456',
      statusCode: 'ACTIVE',
      receiptUrl: '#',
    ),
    InvestmentHistoryRecord(
      id: 'REC-4',
      processDate: '31 Aug 2026',
      processTime: '11:36 AM',
      customerName: 'KANAGARAJ K',
      customerEmail: 'kanagu2024k@gmail.com',
      assetType: '22K GOLD ASSET',
      assetWeight: '32.000 GRAMS',
      capitalAmount: '₹6,72,004.96',
      dailyAmount: 'DAILY: ₹13048.64',
      paymentMethod: 'BANK TRANSFER',
      utrNumber: '123456',
      statusCode: 'ACTIVE',
      receiptUrl: '#',
    ),
    InvestmentHistoryRecord(
      id: 'REC-5',
      processDate: '31 Aug 2026',
      processTime: '11:36 AM',
      customerName: 'KUMARAN THANGAVELU',
      customerEmail: 'kk3927893@gmail.com',
      assetType: '22K GOLD ASSET',
      assetWeight: '8.000 GRAMS',
      capitalAmount: '₹1,68,001.24',
      dailyAmount: 'DAILY: ₹3262.16',
      paymentMethod: 'BANK TRANSFER',
      utrNumber: '123456',
      statusCode: 'ACTIVE',
      receiptUrl: '#',
    ),
    InvestmentHistoryRecord(
      id: 'REC-6',
      processDate: '31 Aug 2026',
      processTime: '11:37 AM',
      customerName: 'ARUN.K',
      customerEmail: 'arunkrishnan775@gmail.com',
      assetType: '22K GOLD ASSET',
      assetWeight: '40.000 GRAMS',
      capitalAmount: '₹8,40,006.2',
      dailyAmount: 'DAILY: ₹16310.8',
      paymentMethod: 'BANK TRANSFER',
      utrNumber: '123456',
      statusCode: 'ACTIVE',
      receiptUrl: '#',
    ),
  ];

  // Define strict column widths for the horizontal scrolling table
  final double _colNodeWidth = 120.0;
  final double _colCustomerWidth = 220.0;
  final double _colPortfolioWidth = 160.0;
  final double _colCapitalWidth = 160.0;
  final double _colUtrWidth = 150.0;
  final double _colStatusWidth = 110.0;
  final double _colActionWidth = 70.0;

  Future<void> _handleDeleteRecord(InvestmentHistoryRecord record) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'DELETE AUDIT RECORD',
      message: 'Are you sure you want to remove the history record for ${record.customerName}?',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true && mounted) {
      setState(() {
        _records.removeWhere((item) => item.id == record.id);
      });

      ToastService.show(
        title: 'Record Removed',
        message: 'Successfully deleted history log for ${record.customerName}',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search users, orders, assets...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
                  prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Processed Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF8BA2CE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'PROCESSED · UNLOCKS 01 SEP 2026',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'INVESTMENT\nAUDIT HISTORY',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: AppColors.kPrimary,
                          letterSpacing: 0.5,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'INSTITUTIONAL LOG OF ALL\nPROCESSED GOLD ASSET\nACQUISITIONS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.kTextMuted,
                          letterSpacing: 0.8,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_records.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.kTextDark,
                        ),
                      ),
                      const Text(
                        'RECORDS\nDETECTED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.kTextDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Responsive Data Table Wrapper
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: _colNodeWidth +
                          _colCustomerWidth +
                          _colPortfolioWidth +
                          _colCapitalWidth +
                          _colUtrWidth +
                          _colStatusWidth +
                          _colActionWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTableHeader(),
                        if (_records.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'No audit records found.',
                                style: TextStyle(color: AppColors.kTextMuted),
                              ),
                            ),
                          )
                        else
                          ..._records.map((record) => _buildTableRow(record)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          _headerCell('PROCESSING\nNODE', _colNodeWidth),
          _headerCell('CUSTOMER', _colCustomerWidth),
          _headerCell('PORTFOLIO\nINSIGHT', _colPortfolioWidth),
          _headerCell('CAPITAL MATRIX', _colCapitalWidth),
          _headerCell('UTR /\nREFERENCE', _colUtrWidth),
          _headerCell('STATUS CODE', _colStatusWidth),
          _headerCell('ACTION', _colActionWidth),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double width) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
          color: AppColors.kTextMuted,
          letterSpacing: 1.0,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildTableRow(InvestmentHistoryRecord record) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Processing Node
          SizedBox(
            width: _colNodeWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.processDate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.processTime,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kTextMuted,
                  ),
                ),
              ],
            ),
          ),

          // 2. Customer
          SizedBox(
            width: _colCustomerWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.customerEmail,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kTextDark,
                  ),
                ),
              ],
            ),
          ),

          // 3. Portfolio Insight
          SizedBox(
            width: _colPortfolioWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.assetType,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_outlined, size: 12, color: Color(0xFFC59B27)),
                    const SizedBox(width: 4),
                    Text(
                      record.assetWeight,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFC59B27),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Capital Matrix
          SizedBox(
            width: _colCapitalWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.capitalAmount,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.dailyAmount,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFC59B27),
                  ),
                ),
              ],
            ),
          ),

          // 5. UTR / Reference
          SizedBox(
            width: _colUtrWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.paymentMethod,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFC59B27),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.utrNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () {
                    ToastService.show(
                      title: 'Receipt Viewer',
                      message: 'Opening receipt for ${record.customerName}',
                      type: ToastType.info,
                    );
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.receipt_long_outlined, size: 12, color: Color(0xFFC59B27)),
                      SizedBox(width: 4),
                      Text(
                        'VIEW RECEIPT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC59B27),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          // 6. Status Code
          SizedBox(
            width: _colStatusWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFBE4A0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFFC59B27)),
                  const SizedBox(width: 6),
                  Text(
                    record.statusCode,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC59B27),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 7. Action
          SizedBox(
            width: _colActionWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF6366F1)),
                  onPressed: () => _handleDeleteRecord(record),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}