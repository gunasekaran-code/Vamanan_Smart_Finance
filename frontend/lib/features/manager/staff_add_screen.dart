import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/models/staff_add_models.dart';
import 'package:frontend/services/staff_add_services.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

// -----------------------------------------------------------------------------
// MAIN SCREEN
// -----------------------------------------------------------------------------
class StaffInfrastructureScreen extends StatefulWidget {
  const StaffInfrastructureScreen({super.key});

  @override
  State<StaffInfrastructureScreen> createState() => _StaffInfrastructureScreenState();
}

class _StaffInfrastructureScreenState extends State<StaffInfrastructureScreen> {
  final List<Member> _members = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final members = await StaffAddService.instance.fetchStaff();
      if (!mounted) return;
      setState(() {
        _members
          ..clear()
          ..addAll(members);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _handleDelete(Member member) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Member',
      message: 'Are you sure you want to delete ${member.name}? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true) {
      try {
        await StaffAddService.instance.deleteStaff(member.id);
        if (!mounted) return;
        setState(() => _members.removeWhere((m) => m.id == member.id));
        ToastService.show(
          title: 'Member Deleted',
          message: '${member.name} has been successfully removed.',
          type: ToastType.success,
        );
      } catch (error) {
        if (!mounted) return;
        ToastService.show(
          title: 'Delete Failed',
          message: error.toString(),
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _openEditMember(Member member) async {
    final changes = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => StaffEditDialog(member: member),
    );
    if (changes == null) return;

    try {
      await StaffAddService.instance.updateStaff(
        id: member.id,
        role: changes['role'],
        status: changes['status'],
        password: changes['password'],
      );
      await _loadStaff();
      if (!mounted) return;
      ToastService.show(
        title: 'Member Updated',
        message: '${member.name} has been updated successfully.',
        type: ToastType.success,
      );
    } catch (error) {
      if (!mounted) return;
      ToastService.show(
        title: 'Update Failed',
        message: error.toString(),
        type: ToastType.error,
      );
    }
  }

  Future<void> _openPersonnelRegistration() async {
    final result = await showDialog<Member>(
      context: context,
      builder: (context) => const PersonnelRegistrationDialog(),
    );

    if (result != null) {
      await _loadStaff();
      // Success toast is already shown inside the dialog on a successful
      // API response, so we don't duplicate it here.
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
    if (_isLoading) {
      return const Center(child: AppLoader());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadStaff,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_members.isEmpty) {
      return const Center(child: Text('No staff members found.'));
    }

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
                          member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?',
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.kPrimary),
                        onPressed: () => _openEditMember(member),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.kDanger),
                        onPressed: () => _handleDelete(member),
                        tooltip: 'Delete',
                      ),
                    ],
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
// REGISTRATION DIALOG (MODAL) — wired to StaffAddService
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

  StaffRole _selectedRole = StaffRole.staff;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  final Set<String> _selectedPermissions = {...StaffPermission.defaultSelectedIds};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
      if (_selectedPermissions.length == StaffPermission.all.length) {
        _selectedPermissions.clear();
      } else {
        _selectedPermissions
          ..clear()
          ..addAll(StaffPermission.all.map((p) => p.id));
      }
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
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
      message: 'Are you sure you want to onboard $name as ${_selectedRole.label}?',
      confirmLabel: 'Confirm',
      confirmButtonColor: AppColors.kPrimary,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    final request = StaffRegistrationRequest(
      name: name,
      email: email,
      password: password,
      role: _selectedRole.value,
      permissions: _selectedPermissions.toList(),
    );

    final response = await StaffAddService.instance.registerStaff(request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response.success && response.data != null) {
      ToastService.show(
        title: 'Onboarding Complete',
        message: '${response.data!.name} has been successfully added to the system.',
        type: ToastType.success,
      );
      Navigator.pop(context, Member.fromRegistration(response.data!));
    } else {
      ToastService.show(
        title: 'Registration Failed',
        message: response.message,
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 800,
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
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(builder: (context, constraints) {
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
                                child: _buildRoleDropdown(),
                              ),
                              SizedBox(
                                width: isMobile ? double.infinity : (constraints.maxWidth - 24) / 2,
                                child: _buildPasswordField('ACCESS KEY (PASSWORD)', '••••••••', _passwordController),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 48),
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
                        LayoutBuilder(builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 600 ? 4 : (constraints.maxWidth > 400 ? 3 : 2);
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 2.2,
                            ),
                            itemCount: StaffPermission.all.length,
                            itemBuilder: (context, index) {
                              final p = StaffPermission.all[index];
                              final isSelected = _selectedPermissions.contains(p.id);
                              return _buildPermissionCard(
                                label: p.label,
                                icon: p.icon,
                                isSelected: isSelected,
                                onTap: () => _togglePermission(p.id),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
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
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.person_add_alt_1_outlined, size: 20),
                        label: Text(
                          _isSubmitting ? 'ONBOARDING...' : 'COMPLETE ONBOARDING',
                          style: const TextStyle(
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
          enabled: !_isSubmitting,
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
          enabled: !_isSubmitting,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
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

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OPERATIONAL ROLE',
          style: TextStyle(
            color: AppColors.kTextMuted.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<StaffRole>(
          value: _selectedRole,
          icon: Icon(Icons.unfold_more_rounded, color: AppColors.kTextMuted.withOpacity(0.7)),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.kPrimary,
            fontSize: 14,
          ),
          decoration: _inputDecoration(''),
          items: StaffRole.all
              .map((role) => DropdownMenuItem(value: role, child: Text(role.label)))
              .toList(),
          onChanged: _isSubmitting
              ? null
              : (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.kTextMuted.withOpacity(0.4),
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
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

  Widget _buildPermissionCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isSubmitting ? null : onTap,
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

class StaffEditDialog extends StatefulWidget {
  final Member member;

  const StaffEditDialog({required this.member, super.key});

  @override
  State<StaffEditDialog> createState() => _StaffEditDialogState();
}

class _StaffEditDialogState extends State<StaffEditDialog> {
  late StaffRole _role;
  late String _status;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _role = StaffRole.fromValue(widget.member.role);
    _status = widget.member.status.toLowerCase();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.member.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<StaffRole>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: StaffRole.all
                .map((role) => DropdownMenuItem(value: role, child: Text(role.label)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _role = value);
            },
          ),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _status = value);
            },
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New password (optional)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'role': _role.value,
            'status': _status,
            'password': _passwordController.text,
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}