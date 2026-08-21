import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_toast.dart';
import '../../routes/app_routes.dart';

// --- MODELS ---

class ChitPayment {
  final String id;
  final String name;
  final String memberId;
  final String group;
  final String installment;
  final String branch;
  final double amount;
  final double? penalty;
  final String date;
  final String processedBy;
  final String status;

  ChitPayment({
    required this.id,
    required this.name,
    required this.memberId,
    required this.group,
    required this.installment,
    required this.branch,
    required this.amount,
    this.penalty,
    required this.date,
    required this.processedBy,
    required this.status,
  });
}

class LoanPayment {
  final String id;
  final String name;
  final String accountId;
  final String loanType;
  final String branch;
  final double emiPaid;
  final String date;
  final String processedBy;
  final String mode;

  LoanPayment({
    required this.id,
    required this.name,
    required this.accountId,
    required this.loanType,
    required this.branch,
    required this.emiPaid,
    required this.date,
    required this.processedBy,
    required this.mode,
  });
}

// --- MAIN SCREEN ---

class FinanceStreamScreen extends StatefulWidget {
  const FinanceStreamScreen({super.key});

  @override
  State<FinanceStreamScreen> createState() => _FinanceStreamScreenState();
}

class _FinanceStreamScreenState extends State<FinanceStreamScreen> {
  int _currentTabIndex = 0; // 0 for Chit, 1 for Loan

  // Dummy Data
  final List<ChitPayment> _chitPayments = [
    ChitPayment(
        id: '1',
        name: 'Jessica',
        memberId: '#0002',
        group: 'Gold',
        installment: 'Inst #3',
        branch: 'Main',
        amount: 1000.00,
        penalty: 1600.00,
        date: '10 Jul 2026',
        processedBy: 'admin',
        status: 'VERIFIED'),
    ChitPayment(
        id: '2',
        name: 'Roki',
        memberId: '#0001',
        group: 'Silver',
        installment: 'Inst #1',
        branch: 'Main',
        amount: 1000.00,
        date: '20 Apr 2026',
        processedBy: 'System',
        status: 'VERIFIED'),
    ChitPayment(
        id: '3',
        name: 'Varshini',
        memberId: '#0003',
        group: 'Silver',
        installment: 'Inst #1',
        branch: 'Main',
        amount: 1000.00,
        date: '20 Apr 2026',
        processedBy: 'System',
        status: 'VERIFIED'),
    ChitPayment(
        id: '4',
        name: 'Jessica',
        memberId: '#0002',
        group: 'Gold',
        installment: 'Inst #2',
        branch: 'Main',
        amount: 1000.00,
        date: '15 Apr 2026',
        processedBy: 'admin',
        status: 'VERIFIED'),
    ChitPayment(
        id: '5',
        name: 'Jessica',
        memberId: '#0002',
        group: 'Gold',
        installment: 'Inst #1',
        branch: 'Main',
        amount: 1000.00,
        date: '10 Apr 2026',
        processedBy: 'System',
        status: 'VERIFIED'),
  ];

  final List<LoanPayment> _loanPayments = [
    LoanPayment(
        id: '1',
        name: 'Roki',
        accountId: 'LN-2026-0001',
        loanType: 'Personal Loan',
        branch: 'Main Office',
        emiPaid: 2063.22,
        date: '10 Aug 2026',
        processedBy: 'admin',
        mode: 'CASH'),
    LoanPayment(
        id: '2',
        name: 'Varshini',
        accountId: 'LN-2026-0002',
        loanType: 'Personal Loan',
        branch: "Teacher's Colony Branch",
        emiPaid: 2996.26,
        date: '10 Jul 2026',
        processedBy: 'admin',
        mode: 'CASH'),
    LoanPayment(
        id: '3',
        name: 'Jessica',
        accountId: 'LN-2026-0003',
        loanType: 'Personal Loan',
        branch: 'Main Office',
        emiPaid: 5000.00,
        date: '10 Jul 2026',
        processedBy: 'admin',
        mode: 'CASH'),
    LoanPayment(
        id: '4',
        name: 'Jessica',
        accountId: 'LN-2026-0003',
        loanType: 'Personal Loan',
        branch: 'Main Office',
        emiPaid: 508.33,
        date: '10 Jul 2026',
        processedBy: 'admin',
        mode: 'CASH'),
    LoanPayment(
        id: '5',
        name: 'Jessica',
        accountId: 'LN-2026-0003',
        loanType: 'Personal Loan',
        branch: 'Main Office',
        emiPaid: 508.33,
        date: '10 Jul 2026',
        processedBy: 'admin',
        mode: 'UPI'),
  ];

  Future<void> _openPaymentForm({bool isLoan = false, Object? record}) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentForm(isLoan: isLoan, record: record),
    );

    if (result == true) {
      ToastService.show(
        title: record == null ? 'Payment Recorded' : 'Payment Updated',
        message: 'The transaction has been successfully saved to the ledger.',
        type: ToastType.success,
      );
      // In a real app, you would setState here to refresh your lists
    } else if (result is String) {
      ToastService.show(
        title: 'Action Failed',
        message: result,
        type: ToastType.error,
      );
    }
  }

  void _openLoanPage() {
    context.go(AppRoutes.loans);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Finance Stream',
      subtitle: 'Unified monitoring for both Chit and Loan revenue streams.',
      children: [
        // Top Action Bar (Search & Record Button)
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search across streams...',
                    hintStyle: const TextStyle(color: AppColors.kTextMuted),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.kTextMuted),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Dropdown logic for "+ Record"
              PopupMenuButton<int>(
                tooltip: 'Record transaction',
                offset: const Offset(0, 54),
                position: PopupMenuPosition.under,
                color: Colors.white,
                elevation: 14,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                menuPadding: const EdgeInsets.symmetric(vertical: 8),
                constraints: const BoxConstraints(minWidth: 260),
                onSelected: (value) {
                  if (value == 0) {
                    _openPaymentForm(isLoan: false);
                  }
                  if (value == 1) {
                    _openLoanPage();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 0,
                    height: 52,
                    child: Row(
                      children: [
                        _RecordMenuIcon(
                          icon: Icons.savings_outlined,
                          backgroundColor: Color(0xFFEAF7EF),
                          iconColor: AppColors.kSuccess,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Chit Group Installment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF101828),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    enabled: false,
                    height: 8,
                    padding: EdgeInsets.zero,
                    child: Divider(
                        height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                  ),
                  const PopupMenuItem(
                    value: 1,
                    height: 52,
                    child: Row(
                      children: [
                        _RecordMenuIcon(
                          icon: Icons.account_balance_outlined,
                          backgroundColor: Color(0xFFE8F1FF),
                          iconColor: AppColors.kInfo,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Loan EMI Payment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF101828),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.kSuccess.withOpacity(0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Record',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Summary Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            if (isWide) {
              return Row(
                children: [
                  Expanded(child: _buildRevenueCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPendingCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildHealthCard()),
                ],
              );
            }
            return Column(
              children: [
                _buildRevenueCard(),
                const SizedBox(height: 16),
                _buildPendingCard(),
                const SizedBox(height: 16),
                _buildHealthCard(),
              ],
            );
          },
        ),

        const SizedBox(height: 32),

        // Stream Tabs
        Row(
          children: [
            _buildTab(
              title: 'Chit Stream',
              icon: Icons.play_circle_outline,
              index: 0,
              activeColor: Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildTab(
              title: 'Loan Stream',
              icon: Icons.account_balance_outlined,
              index: 1,
              activeColor: Colors.black,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Data Table
        Card(
          elevation: 0,
          color: AppColors.kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.kBorder),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child:
                _currentTabIndex == 0 ? _buildChitTable() : _buildLoanTable(),
          ),
        ),
      ],
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            const Color(0xFF16A364), // Exactly matching the screenshot's green
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL COMBINED REVENUE',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              Icon(Icons.money, color: Colors.white70, size: 20),
            ],
          ),
          SizedBox(height: 12),
          Text('₹21676',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('+₹0 received today (Total)',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPendingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AGGREGATED PENDING',
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              Icon(Icons.access_time, color: Colors.orangeAccent, size: 20),
            ],
          ),
          SizedBox(height: 12),
          Text('₹4357792',
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('0 Chits & 102 Loan EMIs',
              style: TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHealthCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SYSTEM HEALTH',
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              Icon(Icons.show_chart, color: Colors.blueAccent, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('0.5%',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('+0.4%',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Recovery rate across all assets',
              style: TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTab(
      {required String title,
      required IconData icon,
      required int index,
      required Color activeColor}) {
    final isActive = _currentTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentTabIndex = index),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: isActive
                  ? activeColor.withOpacity(0.3)
                  : Colors.grey.shade200),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: activeColor.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18, color: isActive ? activeColor : Colors.black87),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? activeColor : Colors.black87,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TABLES ---

  Widget _buildChitTable() {
    return DataTable(
      columnSpacing: 28,
      headingRowHeight: 56,
      dataRowMinHeight: 76,
      dataRowMaxHeight: 76,
      columns: const [
        DataColumn(
            label: Text('MEMBER PROFILE',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54))),
        DataColumn(
            label: Text('CHIT PORTFOLIO',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54))),
        DataColumn(
            label: Text('AMOUNT',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54))),
        DataColumn(
            label: Text('TIMELINE',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54))),
        DataColumn(
            label: Text('STATUS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54))),
        DataColumn(
            label: Text('MANAGE',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54))),
      ],
      rows: _chitPayments.map((payment) {
        return DataRow(
          cells: [
            // Member Profile
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.green.shade50,
                    child: Text(
                      payment.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('ID: ${payment.memberId}',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            // Chit Portfolio
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.group,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${payment.installment} • ${payment.branch}',
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            // Amount
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₹${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (payment.penalty != null) ...[
                    const SizedBox(height: 2),
                    Text('+₹${payment.penalty!.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            // Timeline
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.date,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(payment.processedBy,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            // Status
            DataCell(
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  payment.status,
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Manage
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIcon(
                    icon: Icons.edit_note,
                    color: Colors.blue,
                    bgColor: Colors.blue.shade50,
                    onTap: () =>
                        _openPaymentForm(isLoan: false, record: payment),
                  ),
                  const SizedBox(width: 8),
                  _ActionIcon(
                    icon: Icons.print_outlined,
                    color: Colors.green,
                    bgColor: Colors.green.shade50,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLoanTable() {
    return DataTable(
      columnSpacing: 28,
      headingRowHeight: 56,
      dataRowMinHeight: 76,
      dataRowMaxHeight: 76,
      columns: const [
        DataColumn(
            label: Text('CUSTOMER',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54))),
        DataColumn(
            label: Text('LOAN ACCOUNT',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54))),
        DataColumn(
            label: Text('EMI PAID',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54))),
        DataColumn(
            label: Text('COLLECTED DATE',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54))),
        DataColumn(
            label: Text('MODE',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54))),
        DataColumn(
            label: Text('MANAGE',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54))),
      ],
      rows: _loanPayments.map((payment) {
        return DataRow(
          cells: [
            // Customer Profile
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      payment.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(payment.accountId,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            // Loan Account
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.loanType,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(payment.branch,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            // EMI Paid
            DataCell(
              Text('₹${payment.emiPaid.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
            // Collected Date
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payment.date,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('By: ${payment.processedBy}',
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            // Mode
            DataCell(
              Text(payment.mode,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            // Manage
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIcon(
                    icon: Icons.edit_note,
                    color: Colors.blue,
                    bgColor: Colors.blue.shade50,
                    onTap: () =>
                        _openPaymentForm(isLoan: true, record: payment),
                  ),
                  const SizedBox(width: 8),
                  _ActionIcon(
                    icon: Icons.print_outlined,
                    color: Colors.deepPurpleAccent,
                    bgColor: Colors.deepPurpleAccent.withOpacity(0.1),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _RecordMenuIcon extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const _RecordMenuIcon({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: iconColor),
    );
  }
}

// Helper Action Icon for Datatables
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionIcon(
      {required this.icon,
      required this.color,
      required this.bgColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// --- WORKABLE FORM WIDGET ---

class PaymentForm extends StatefulWidget {
  final bool isLoan;
  final Object? record;

  const PaymentForm({super.key, required this.isLoan, this.record});

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _idController;
  String _selectedMode = 'CASH';

  @override
  void initState() {
    super.initState();

    // Pre-fill form if editing an existing record
    if (widget.record != null) {
      if (widget.isLoan) {
        final r = widget.record as LoanPayment;
        _nameController = TextEditingController(text: r.name);
        _amountController = TextEditingController(text: r.emiPaid.toString());
        _idController = TextEditingController(text: r.accountId);
        _selectedMode = r.mode;
      } else {
        final r = widget.record as ChitPayment;
        _nameController = TextEditingController(text: r.name);
        _amountController = TextEditingController(text: r.amount.toString());
        _idController = TextEditingController(text: r.memberId);
      }
    } else {
      _nameController = TextEditingController();
      _amountController = TextEditingController();
      _idController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      // Logic for saving would go here.
      // Returning 'true' flags success to the parent triggering ToastService
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // ClipRRect ensures the header's background color respects the top rounded corners
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header Section
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                color: const Color(
                    0xFFEDF2FA), // Light blue background matching the image
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '₹',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Details',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Record and verify chit collection data',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chit Group
                      DropdownButtonFormField<String>(
                        value: 'Gold', // Replace with your state variable
                        decoration: InputDecoration(
                          labelText: 'Chit Group',
                          prefixIcon:
                              const Icon(Icons.cases_outlined, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                        ),
                        items: ['Gold', 'Silver', 'Bronze'].map((group) {
                          return DropdownMenuItem(
                              value: group, child: Text(group));
                        }).toList(),
                        onChanged: (val) {
                          // Handle change
                        },
                      ),
                      const SizedBox(height: 16),

                      // Member Name
                      DropdownButtonFormField<String>(
                        value: 'Roki', // Replace with your state variable
                        decoration: InputDecoration(
                          labelText: 'Member Name',
                          prefixIcon:
                              const Icon(Icons.badge_outlined, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                        ),
                        items: ['Roki', 'John', 'Doe'].map((name) {
                          return DropdownMenuItem(
                              value: name, child: Text(name));
                        }).toList(),
                        onChanged: (val) {
                          // Handle change
                        },
                      ),
                      const SizedBox(height: 16),

                      // Installment Number
                      TextFormField(
                        initialValue: '1', // Replace with your controller/value
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Installment Number',
                          suffixIcon: const Icon(Icons.unfold_more, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Amount
                      TextFormField(
                        initialValue: '0', // Replace with your controller/value
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount (₹)',
                          prefixIcon:
                              const Icon(Icons.payments_outlined, size: 20),
                          suffixIcon: const Icon(Icons.unfold_more, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment Date
                      TextFormField(
                        initialValue:
                            '13/08/2026', // Replace with your controller/value
                        decoration: InputDecoration(
                          labelText: 'Payment Date',
                          prefixIcon: const Icon(Icons.calendar_today_outlined,
                              size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                        ),
                        readOnly:
                            true, // Typically date pickers are read-only text fields
                        onTap: () {
                          // Handle date picker
                        },
                      ),
                      const SizedBox(height: 16),

                      // Transaction Status
                      DropdownButtonFormField<String>(
                        value: 'Pending', // Replace with your state variable
                        decoration: InputDecoration(
                          labelText: 'Transaction Status',
                          prefixIcon:
                              const Icon(Icons.gpp_maybe_outlined, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                        ),
                        items: ['Pending', 'Success', 'Failed'].map((status) {
                          return DropdownMenuItem(
                              value: status, child: Text(status));
                        }).toList(),
                        onChanged: (val) {
                          // Handle change
                        },
                      ),
                      const SizedBox(height: 32),

                      // Divider Line
                      const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                      const SizedBox(height: 16),

                      // Bottom Action Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {}, // Replace with your _saveForm
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Colors.white, size: 20),
                              label: const Text(
                                'Confirm Transaction',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                    0xFF16A34A), // Green color matching the image
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(
                                    color: Color(0xFFE2E8F0), width: 1.5),
                              ),
                              child: const Text(
                                'Discard',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
