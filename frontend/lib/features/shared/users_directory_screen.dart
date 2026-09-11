import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// --- Data Models ---
class UserModel {
  final String id;
  final String name;
  final String systemId;
  final String email;
  final String joined;
  final String role;
  final String status;
  final double wallet;
  bool isSelected;

  UserModel({
    required this.id,
    required this.name,
    required this.systemId,
    required this.email,
    required this.joined,
    required this.role,
    required this.status,
    required this.wallet,
    this.isSelected = false,
  });
}

class NewUserRowData {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  String role = 'CUSTOMER';

  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
  }
}

// --- Main Screen ---
class UsersDirectoryScreen extends StatefulWidget {
  const UsersDirectoryScreen({super.key});

  @override
  State<UsersDirectoryScreen> createState() => _UsersDirectoryScreenState();
}

class _UsersDirectoryScreenState extends State<UsersDirectoryScreen> {
  bool _selectAll = false;

  final List<UserModel> _users = [
    UserModel(
      id: '128',
      name: 'GUNA SEKARAN V.',
      systemId: 'VEV100',
      email: 'gunateststaff@gmail.com',
      joined: '21 AUG',
      role: 'STAFF',
      status: 'ACTIVE',
      wallet: 0.0,
    ),
    UserModel(
      id: '129',
      name: 'SARANYA VENKAT',
      systemId: 'VEV099',
      email: 'saranya@example.com',
      joined: '13 AUG',
      role: 'CUSTOMER',
      status: 'PENDING REVIEW',
      wallet: 0.0,
    ),
  ];

  Future<void> _handleProcessYield() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PROCESS MONTHLY YIELD',
      message: "Process this month's cashback? This credits one monthly installment (10%) to every cycle that is due, and can only run ONCE per calendar month.",
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      ToastService.show(title: 'Success', message: 'Monthly yield processed successfully.', type: ToastType.success);
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      for (var user in _users) {
        user.isSelected = _selectAll;
      }
    });
  }

  void _openBulkAddModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BulkAddUsersModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Search Bar
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder)),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users, orders, assets...',
                    hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Process Monthly Yield Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _handleProcessYield,
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('PROCESS MONTHLY YIELD', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // White Directory Container
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.kBorder)),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INVESTOR DIRECTORY', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 4),
                    Text('UNIVERSAL REGISTRY OF ALL PLATFORM PARTICIPANTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                    const SizedBox(height: 24),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _openBulkAddModal, // Hooked up to open modal
                          icon: const Icon(Icons.person_add_alt_1, size: 16),
                          label: const Text('BULK ADD USERS', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        ),
                        InkWell(
                          onTap: () => _toggleSelectAll(!_selectAll),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(border: Border.all(color: AppColors.kBorder), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_selectAll ? Icons.check_box : Icons.check_box_outline_blank, size: 18, color: _selectAll ? const Color(0xFF1E3A8A) : AppColors.kTextMuted),
                                const SizedBox(width: 8),
                                const Text('SELECT ALL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder)),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'SEARCH BY IDENTITY...',
                          hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                          prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => _buildUserCard(_users[index]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    // ... (Keep existing _buildUserCard implementation identical to previous step)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(user.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(user.systemId, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706), fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('JOINED ${user.joined}', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 10)),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() => user.isSelected = !user.isSelected),
                child: Icon(user.isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: user.isSelected ? const Color(0xFF1E3A8A) : AppColors.kBorder),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('WALLET', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 4),
                      Text('₹${user.wallet.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ROLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 4),
                      Text(user.role, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.people_alt, size: 14, color: Color(0xFFFBBF24)),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REFERRED BY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                    SizedBox(height: 2),
                    Text('DIRECT — NO REFERRER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REFERRAL COMMISSION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                    SizedBox(height: 2),
                    Text('✦ EARNING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706))),
                  ],
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE11D48),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('STOP', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 10)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), border: Border.all(color: const Color(0xFFFDE68A)), borderRadius: BorderRadius.circular(20)),
                child: Text(user.status, style: const TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              ),
              InkWell(
                onTap: () {}, // Calibration modal logic
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.settings, color: Color(0xFF64748B), size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Bulk Add Users Modal ---
class BulkAddUsersModal extends StatefulWidget {
  const BulkAddUsersModal({super.key});

  @override
  State<BulkAddUsersModal> createState() => _BulkAddUsersModalState();
}

class _BulkAddUsersModalState extends State<BulkAddUsersModal> {
  final List<NewUserRowData> _rows = [NewUserRowData(), NewUserRowData()];
  final List<String> _roles = ['CUSTOMER', 'MANAGER', 'STAFF', 'ADVOCATE', 'AUDITOR'];

  @override
  void dispose() {
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(NewUserRowData());
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _handleSave() {
    Navigator.pop(context);
    ToastService.show(
      title: 'Success', 
      message: '${_rows.length} users have been successfully queued for addition.', 
      type: ToastType.success
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 900, // Max width for tablet/desktop
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.person_add_alt_1, color: Color(0xFFFBBF24), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BULK ADD USERS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                        const SizedBox(height: 4),
                        Text('ADD MULTIPLE CUSTOMERS AT ONCE · AUTO VEV ID + WALLET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // CSV Import Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.kBorder)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('IMPORT CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          child: const Text('CHOOSE FILE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                        ),
                        const Text('no file selected', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 12)),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.description_outlined, size: 16),
                          label: const Text('DOWNLOAD TEMPLATE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1E3A8A), side: const BorderSide(color: AppColors.kBorder), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Columns: name, email, phone, password, role, referral_code', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic Rows Section (Scrollable to prevent pixel overflow on mobile)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Key for mobile responsiveness
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table Headers
                      Row(
                        children: [
                          _buildHeader('NAME *', 200),
                          _buildHeader('EMAIL *', 200),
                          _buildHeader('PHONE *', 150),
                          _buildHeader('ROLE', 150),
                          const SizedBox(width: 48), // Delete icon space
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Input Rows
                      ..._rows.asMap().entries.map((entry) {
                        int idx = entry.key;
                        NewUserRowData rowData = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(rowData.nameCtrl, 'Full name', 200),
                              _buildTextField(rowData.emailCtrl, 'email@example.com', 200),
                              _buildTextField(rowData.phoneCtrl, 'Phone', 150),
                              _buildDropdown(rowData, 150),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () => _removeRow(idx),
                                icon: const Icon(Icons.delete_outline, color: Color(0xFF3B82F6), size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  padding: const EdgeInsets.all(12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      
                      const SizedBox(height: 12),
                      
                      // Add Row Button
                      TextButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add, size: 16, color: Color(0xFFD97706)),
                        label: const Text('ADD ROW', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.kBorder))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Password defaults to the phone number if left blank. Duplicate emails are skipped automatically.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          side: const BorderSide(color: AppColors.kBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _handleSave,
                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                        label: const Text('ADD USERS', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets for Table ---
  Widget _buildHeader(String title, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(right: 12),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(right: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.kTextMuted, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic),
          fillColor: const Color(0xFFF8FAFC),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
        ),
      ),
    );
  }

  Widget _buildDropdown(NewUserRowData rowData, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(right: 12),
      child: DropdownButtonFormField<String>(
        value: rowData.role,
        icon: const Icon(Icons.unfold_more, color: Color(0xFF1E3A8A), size: 16),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
        decoration: InputDecoration(
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
        ),
        items: _roles.map((role) {
          return DropdownMenuItem(value: role, child: Text(role));
        }).toList(),
        onChanged: (val) {
          setState(() {
            if (val != null) rowData.role = val;
          });
        },
      ),
    );
  }
}