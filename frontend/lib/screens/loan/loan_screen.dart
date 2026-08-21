import 'package:flutter/material.dart';

// Assuming these exist in your project based on your provided code
import '../../theme/app_theme.dart';
import '../../theme/confirm_dialog.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_toast.dart';

// ==========================================
// 1. LOAN DATA MODEL
// ==========================================
class Loan {
  final String id;
  final String loanType;
  final String date;
  final String customerName;
  final String customerPhone;
  final String branch;
  final double principal;
  final double monthlyEmi;
  final double outstanding;
  final String status;

  const Loan({
    required this.id,
    required this.loanType,
    required this.date,
    required this.customerName,
    required this.customerPhone,
    required this.branch,
    required this.principal,
    required this.monthlyEmi,
    required this.outstanding,
    required this.status,
  });
}

// ==========================================
// 2. MAIN LOAN SCREEN (MOBILE RESPONSIVE CARDS)
// ==========================================
class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  // Only 2 sample data points as requested
  final List<Loan> _loans = [
    const Loan(
      id: 'LN-2026-0006',
      loanType: 'Personal Loan',
      date: '29 Jul 2026',
      customerName: 'Jessica',
      customerPhone: '9512364870',
      branch: 'Main Office',
      principal: 50000,
      monthlyEmi: 4667,
      outstanding: 56000,
      status: 'Approved',
    ),
    const Loan(
      id: 'LN-2026-0003',
      loanType: 'Personal Loan',
      date: '29 May 2026',
      customerName: 'Jessica',
      customerPhone: '9512364870',
      branch: 'Main Office',
      principal: 5000,
      monthlyEmi: 508,
      outstanding: 3558,
      status: 'Active / Disbursed',
    ),
  ];

  Future<void> _openLoanForm([Loan? loan]) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StylishLoanForm(loan: loan);
      },
    );

    if (result == null) return;

    if (result == true || result is Loan) {
      ToastService.show(
        title: 'Application Submitted',
        message: 'The loan application has been successfully created.',
        type: ToastType.success,
      );
    } else {
      ToastService.show(
        title: 'Action Failed',
        message: result is String ? result : 'An unexpected error occurred.',
        type: ToastType.error,
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.deepPurple;
      case 'Active / Disbursed':
        return AppColors.kSuccess; // Green
      case 'Pending Approval':
        return Colors.orange;
      case 'Closed':
        return Colors.grey;
      case 'Default':
      case 'Rejected':
        return AppColors.kDanger;
      default:
        return AppColors.kPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Loan Portfolio',
      subtitle: 'Manage and track all customer loans across branches',
      children: [
        // Top Action Bar
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _openLoanForm(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'New Loan Application',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kSuccess, // Stylish Green
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Mobile Responsive Card List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _loans.length,
          itemBuilder: (context, index) {
            final loan = _loans[index];
            final statusColor = _getStatusColor(loan.status);

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              color: AppColors.kSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.kBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: ID & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            loan.id,
                            style: TextStyle(
                              color: Colors.deepPurple.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            loan.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Customer & Loan Type Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.kPrimary.withOpacity(0.1),
                          child: Text(
                            loan.customerName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.kPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan.customerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined,
                                      size: 14, color: AppColors.kTextMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    loan.customerPhone,
                                    style: const TextStyle(
                                        color: AppColors.kTextMuted,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_balance_wallet,
                                    size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  loan.loanType,
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 14, color: AppColors.kTextMuted),
                                const SizedBox(width: 4),
                                Text(
                                  loan.date,
                                  style: const TextStyle(
                                      color: AppColors.kTextMuted,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: AppColors.kBorder),
                    ),

                    // Financials Data
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFinancialColumn('Principal',
                            '₹${loan.principal.toInt()}', Colors.black87),
                        _buildFinancialColumn('Monthly EMI',
                            '₹${loan.monthlyEmi.toInt()}', AppColors.kSuccess),
                        _buildFinancialColumn('Outstanding',
                            '₹${loan.outstanding.toInt()}', AppColors.kDanger),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 16, color: AppColors.kTextMuted),
                            const SizedBox(width: 4),
                            Text(
                              loan.branch,
                              style: const TextStyle(
                                  color: AppColors.kTextMuted,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        // Actions
                        Row(
                          children: [
                            _ActionButton(
                              icon: Icons.visibility_outlined,
                              color: Colors.blue,
                              backgroundColor: Colors.blue.shade50,
                              onPressed: () {}, // View Details Logic
                            ),
                            if (loan.status == 'Active / Disbursed') ...[
                              const SizedBox(width: 8),
                              _ActionButton(
                                icon: Icons.payments_outlined,
                                color: Colors.orange,
                                backgroundColor: Colors.orange.shade50,
                                onPressed: () {}, // Make Payment Logic
                              ),
                            ]
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFinancialColumn(String label, String amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.kTextMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

// Action button helper
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ==========================================
// 3. NEW LOAN APPLICATION FORM (MODAL)
// ==========================================
class StylishLoanForm extends StatefulWidget {
  final Loan? loan;

  const StylishLoanForm({super.key, this.loan});

  @override
  State<StylishLoanForm> createState() => _StylishLoanFormState();
}

class _StylishLoanFormState extends State<StylishLoanForm> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _tenureController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _penaltyController = TextEditingController();
  final TextEditingController _gracePeriodController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Dropdown Values
  String? _selectedCustomer;
  String? _selectedBranch;
  String? _selectedLoanType;
  String? _selectedInterestType;
  String? _selectedDisbursementMode;
  String? _selectedStatus = 'Pending Approval'; // Default

  // Dropdown Options
  final List<String> branches = ['Main Office', "Teacher's Colony Branch"];
  final List<String> statuses = [
    'Pending Approval',
    'Approved',
    'Active / Disbursed',
    'Closed',
    'Default',
    'Rejected'
  ];
  final List<String> loanTypes = [
    'Personal Loan',
    'Home Loan',
    'Auto Loan',
    'Other'
  ];
  final List<String> interestTypes = ['Reducing Balance', 'Flat Rate'];
  final List<String> disbursementModes = ['Bank Transfer', 'Cash', 'Cheque'];

  @override
  void initState() {
    super.initState();
    // Pre-fill Start Date with today
    _startDateController.text =
        "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
  }

  @override
  void dispose() {
    _amountController.dispose();
    _interestRateController.dispose();
    _tenureController.dispose();
    _startDateController.dispose();
    _penaltyController.dispose();
    _gracePeriodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.kSuccess, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDateController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.kTextMuted, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.kSuccess, width: 2),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple.shade300),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
              color: Colors.deepPurple.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.kBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.note_add_outlined, color: Colors.black87),
                    SizedBox(width: 12),
                    Text(
                      'New Loan Application',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scrollable Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: CUSTOMER & BRANCH ---
                    _buildSectionHeader(
                        'Customer & Branch', Icons.person_outline),

                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Select Customer *'),
                      value: _selectedCustomer,
                      icon: const Icon(Icons.unfold_more, color: Colors.grey),
                      items: ['Jessica', 'Roki', 'Varshini', 'VEERASAMY.K']
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCustomer = val),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Lending Branch *'),
                      value: _selectedBranch,
                      icon: const Icon(Icons.unfold_more, color: Colors.grey),
                      items: branches
                          .map(
                              (b) => DropdownMenuItem(value: b, child: Text(b)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedBranch = val),
                    ),

                    // --- SECTION 2: LOAN PARAMETERS ---
                    _buildSectionHeader('Loan Parameters',
                        Icons.account_balance_wallet_outlined),

                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Loan Type *'),
                      value: _selectedLoanType,
                      icon: const Icon(Icons.unfold_more, color: Colors.grey),
                      items: loanTypes
                          .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedLoanType = val),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Loan Amount (₹) *'),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _interestRateController,
                            keyboardType: TextInputType.number,
                            decoration:
                                _inputDecoration('Interest Rate (% p.a.) *'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _tenureController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Tenure (Months) *'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Interest Type *'),
                      value: _selectedInterestType,
                      icon: const Icon(Icons.unfold_more, color: Colors.grey),
                      items: interestTypes
                          .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedInterestType = val),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectDate(context),
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _startDateController,
                                decoration:
                                    _inputDecoration('Start Date *').copyWith(
                                  suffixIcon: const Icon(Icons.calendar_today,
                                      color: Colors.grey, size: 20),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: _inputDecoration('Status *'),
                            value: _selectedStatus,
                            icon: const Icon(Icons.unfold_more,
                                color: Colors.grey),
                            items: statuses
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedStatus = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Disbursement Mode'),
                      value: _selectedDisbursementMode,
                      icon: const Icon(Icons.unfold_more, color: Colors.grey),
                      items: disbursementModes
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDisbursementMode = val),
                    ),

                    // --- SECTION 3: RECOVERY POLICY ---
                    _buildSectionHeader(
                        'Recovery Policy', Icons.policy_outlined),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _penaltyController,
                            keyboardType: TextInputType.number,
                            decoration:
                                _inputDecoration('Penalty Rate (% p.m.)'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _gracePeriodController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Grace Period (Days)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: _inputDecoration('Application Notes'),
                    ),

                    const SizedBox(height: 32),

// --- LIVE ESTIMATE CARD ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calculate_outlined,
                                  color: Colors.indigo.shade400, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Live Estimate',
                                style: TextStyle(
                                  color: Colors.indigo.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // MONTHLY EMI BOX
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  'MONTHLY EMI',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '₹ --', // Update via state based on inputs
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // TOTAL PAYABLE ROW
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Payable',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87)),
                                Text('₹ --',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // INTEREST AMOUNT ROW
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Interest Amount',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87)),
                                Text('₹ --',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.red.shade600)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // PROVISIONAL INFO BOX
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info,
                                    color: Colors.teal.shade700, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This is a provisional estimate. Final schedule is generated upon disbursement.',
                                    style: TextStyle(
                                        color: Colors.teal.shade900,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // CALCULATION FORMULA BOX
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'CALCULATION FORMULA',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                      letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'E = P x r x (1+r)ⁿ / ((1+r)ⁿ - 1)',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                      fontFamily: 'monospace'),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'P: Principal | r: Monthly Rate | n: Tenure',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.kBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context,
                            true); // Returns true on success to show toast
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Submit Application',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.kSuccess, // Green color as requested
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
