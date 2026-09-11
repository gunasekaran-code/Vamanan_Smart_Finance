import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// -----------------------------------------------------------------------------
// DATA MODEL
// -----------------------------------------------------------------------------
class Member {
  final String id;
  final String name;
  final String phone;
  final String branch;
  final String status;
  final String accountType;
  final String dateJoined;

  const Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.branch,
    required this.status,
    required this.accountType,
    required this.dateJoined,
  });
}

// -----------------------------------------------------------------------------
// MAIN SCREEN
// -----------------------------------------------------------------------------
class StaffInfrastructureScreen extends StatefulWidget {
  const StaffInfrastructureScreen({super.key});

  @override
  State<StaffInfrastructureScreen> createState() => _StaffInfrastructureScreenState();
}

class _StaffInfrastructureScreenState extends State<StaffInfrastructureScreen> {
  // Local list of members
  List<Member> _members = [
    const Member(
      id: '1',
      name: 'Roki',
      phone: '9786204074',
      branch: "Teacher's Colony Branch",
      status: 'Active',
      accountType: 'Walk-in only',
      dateJoined: 'Apr 08, 2026',
    ),
    const Member(
      id: '2',
      name: 'Jessica',
      phone: '9512364870',
      branch: 'Main Office',
      status: 'Active',
      accountType: 'Portal Active',
      dateJoined: 'Apr 09, 2026',
    ),
    const Member(
      id: '3',
      name: 'Varshini',
      phone: '7685940321',
      branch: "Teacher's Colony Branch",
      status: 'Active',
      accountType: 'Walk-in only',
      dateJoined: 'Apr 15, 2026',
    ),
    const Member(
      id: '5',
      name: 'VEERASAMY.K',
      phone: '9677490097',
      branch: 'Main Office',
      status: 'Active',
      accountType: 'Portal Active',
      dateJoined: 'Jul 28, 2026',
    ),
  ];

  Future<void> _handleDelete(Member member) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Member',
      message: 'Are you sure you want to delete ${member.name}? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true) {
      setState(() {
        _members.removeWhere((m) => m.id == member.id);
      });

      ToastService.show(
        title: 'Member Deleted',
        message: '${member.name} has been successfully removed.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _openPersonnelRegistration() async {
    final result = await showDialog<Member>(
      context: context,
      builder: (context) => const PersonnelRegistrationDialog(),
    );

    if (result != null) {
      setState(() {
        _members.add(result);
      });

      ToastService.show(
        title: 'Onboarding Complete',
        message: '${result.name} has been successfully added to the system.',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Staff Infrastructure',
      subtitle: 'Manage and review staff infrastructure details.',
      children: [
        _buildCustomHeader(),
        const SizedBox(height: 32),
        _buildDataTable(),
      ],
    );
  }

  Widget _buildCustomHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Side: Icon + Title
            Expanded(
              flex: isMobile ? 0 : 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6.0),
                    child: Icon(Icons.people_outline, color: AppColors.goldColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'STAFF INFRASTRUCTURE:\nOPERATIONS TEAM',
                      style: const TextStyle(
                        color: AppColors.kPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (isMobile) const SizedBox(height: 20),

            // Right Side: Register Button
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.kPrimary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _openPersonnelRegistration,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 20, color: Colors.white),
                label: const Text(
                  'REGISTER\nPERSONNEL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataTable() {
    return Card(
      elevation: 0,
      color: AppColors.kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.kBorder.withOpacity(0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          headingRowHeight: 56,
          dataRowMaxHeight: 72,
          dataRowMinHeight: 72,
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Member Details', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Branch', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _members.map((member) {
            return DataRow(
              cells: [
                DataCell(Text(member.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.kPrimary.withOpacity(0.1),
                        child: Text(
                          member.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: AppColors.kPrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(member.phone, style: const TextStyle(color: AppColors.kTextMuted, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(Text(member.branch, style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.kSuccess.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      member.status,
                      style: const TextStyle(color: AppColors.kSuccess, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.kDanger),
                    onPressed: () => _handleDelete(member),
                    tooltip: 'Delete',
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// REGISTRATION DIALOG (MODAL)
// -----------------------------------------------------------------------------
class PersonnelRegistrationDialog extends StatefulWidget {
  const PersonnelRegistrationDialog({super.key});

  @override
  State<PersonnelRegistrationDialog> createState() => _PersonnelRegistrationDialogState();
}

class _PersonnelRegistrationDialogState extends State<PersonnelRegistrationDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'OPERATIONS STAFF';
  bool _obscurePassword = true;

  // Permissions Data
  final List<Map<String, dynamic>> _permissions = [
    {'id': 'dashboard', 'label': 'DASHBOARD', 'icon': Icons.bar_chart},
    {'id': 'investments', 'label': 'INVESTMENTS', 'icon': Icons.shopping_cart_outlined},
    {'id': 'assets', 'label': 'ASSETS', 'icon': Icons.shopping_bag_outlined},
    {'id': 'entities', 'label': 'ENTITIES', 'icon': Icons.people_outline},
    {'id': 'genealogy', 'label': 'GENEALOGY', 'icon': Icons.account_tree_outlined},
    {'id': 'wallets', 'label': 'WALLETS', 'icon': Icons.account_balance_wallet_outlined},
    {'id': 'kyc', 'label': 'KYC', 'icon': Icons.verified_user_outlined},
    {'id': 'withdrawals', 'label': 'WITHDRAWALS', 'icon': Icons.account_balance_outlined},
    {'id': 'notifications', 'label': 'NOTIFICATIONS', 'icon': Icons.campaign_outlined},
    {'id': 'market_rates', 'label': 'MARKET RATES', 'icon': Icons.trending_up},
    {'id': 'staffing', 'label': 'STAFFING', 'icon': Icons.person_add_outlined},
    {'id': 'settings', 'label': 'SETTINGS', 'icon': Icons.language},
  ];

  final Set<String> _selectedPermissions = {'dashboard', 'kyc', 'notifications'}; // Default selections

  void _togglePermission(String id) {
    setState(() {
      if (_selectedPermissions.contains(id)) {
        _selectedPermissions.remove(id);
      } else {
        _selectedPermissions.add(id);
      }
    });
  }

  void _selectAllPermissions() {
    setState(() {
      if (_selectedPermissions.length == _permissions.length) {
        _selectedPermissions.clear();
      } else {
        _selectedPermissions.addAll(_permissions.map((p) => p['id'] as String));
      }
    });
  }

  Future<void> _submit() async {
    // Basic validation
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ToastService.show(
        title: 'Missing Fields',
        message: 'Please fill out all required fields.',
        type: ToastType.error,
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Confirm Registration',
      message: 'Are you sure you want to onboard ${_nameController.text} as $_selectedRole?',
      confirmLabel: 'Confirm',
      confirmButtonColor: AppColors.kPrimary,
    );

    if (confirmed == true && mounted) {
      final newMember = Member(
        id: DateTime.now().millisecondsSinceEpoch.toString().substring(7),
        name: _nameController.text,
        phone: 'N/A', // Omitted in the new design, mock value provided
        branch: 'Main Office',
        status: 'Active',
        accountType: 'Portal Active',
        dateJoined: 'Today',
      );
      Navigator.pop(context, newMember);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 800, // Max width for tablet/desktop
        decoration: BoxDecoration(
          color: AppColors.kSurface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                // Header (Title & Close Button)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PERSONNEL REGISTRATION',
                              style: TextStyle(
                                color: AppColors.kPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ADD A NEW STAFF MEMBER',
                              style: TextStyle(
                                color: AppColors.kTextMuted.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.kBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close, color: AppColors.kTextMuted, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Form Body (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Input Fields
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 500;
                            return Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              children: [
                                SizedBox(
                                  width: isMobile ? double.infinity : (constraints.maxWidth - 24) / 2,
                                  child: _buildTextField('PERSONNEL NAME', 'E.G. OFFICER RAJESH', _nameController),
                                ),
                                SizedBox(
                                  width: isMobile ? double.infinity : (constraints.maxWidth - 24) / 2,
                                  child: _buildTextField('EMAIL', 'staff@makkalgold.com', _emailController),
                                ),
                                SizedBox(
                                  width: isMobile ? double.infinity : (constraints.maxWidth - 24) / 2,
                                  child: _buildDropdownField('OPERATIONAL ROLE'),
                                ),
                                SizedBox(
                                  width: isMobile ? double.infinity : (constraints.maxWidth - 24) / 2,
                                  child: _buildPasswordField('ACCESS KEY (PASSWORD)', '••••••••', _passwordController),
                                ),
                              ],
                            );
                          }
                        ),
                        
                        const SizedBox(height: 48),

                        // Permissions Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PERMISSION-BASED ACCESS CONTROL',
                              style: TextStyle(
                                color: AppColors.kTextMuted.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 1.0,
                              ),
                            ),
                            TextButton(
                              onPressed: _selectAllPermissions,
                              child: const Text(
                                'SELECT ALL ACCESS',
                                style: TextStyle(
                                  color: AppColors.goldColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Permissions Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = constraints.maxWidth > 600 ? 4 : (constraints.maxWidth > 400 ? 3 : 2);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 2.2, // Width to height ratio
                              ),
                              itemCount: _permissions.length,
                              itemBuilder: (context, index) {
                                final p = _permissions[index];
                                final isSelected = _selectedPermissions.contains(p['id']);
                                return _buildPermissionCard(
                                  label: p['label'],
                                  icon: p['icon'],
                                  isSelected: isSelected,
                                  onTap: () => _togglePermission(p['id']),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer (Submit Button)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.kPrimary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
                        label: const Text(
                          'COMPLETE ONBOARDING',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget: Standard TextField
  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.kTextMuted.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: AppColors.kPrimary,
          ),
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  // Helper Widget: Password Field
  Widget _buildPasswordField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.kTextMuted.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: _obscurePassword,
          style: const TextStyle(
            fontWeight: FontWeight.w900, // Thicker dots
            color: AppColors.kPrimary,
          ),
          decoration: _inputDecoration(hint).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.kTextMuted.withOpacity(0.5),
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widget: Dropdown
  Widget _buildDropdownField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.kTextMuted.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRole,
          icon: Icon(Icons.unfold_more_rounded, color: AppColors.kTextMuted.withOpacity(0.7)),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.kPrimary,
            fontSize: 14,
          ),
          decoration: _inputDecoration(''),
          items: ['OPERATIONS STAFF', 'ADMINISTRATOR', 'MANAGER']
              .map((role) => DropdownMenuItem(value: role, child: Text(role)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedRole = val);
          },
        ),
      ],
    );
  }

  // Shared Input Decoration
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.kTextMuted.withOpacity(0.4),
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC), // Very light cool grey matching the image
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.kBorder.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.kBorder.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.kPrimary, width: 1.5),
      ),
    );
  }

  // Helper Widget: Permission Card (Grid Item)
  Widget _buildPermissionCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kPrimary : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.kPrimary : AppColors.kBorder.withOpacity(0.5),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.kPrimary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.goldColor : AppColors.kTextMuted.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.kTextMuted.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}