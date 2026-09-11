import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'member_form_screen.dart'; // Make sure this matches your new file's location

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

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  // Removed 'final' so we can modify the list locally
  // TODO: replace with a paginated list from GET /members.
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

  // Updated function to handle full-page navigation for create/edit
  Future<void> _openMemberForm([Member? member]) async {
    // Push the full page onto the navigation stack
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberFormScreen(member: member),
      ),
    );

    // If the screen was dismissed via back button without taking action, result will be null.
    if (result == null) return;

    // Check if a saved Member object was returned from the form
    if (result is Member) {
      final isNew = member == null;
      
      // Update the local list so the UI reflects the change immediately
      setState(() {
        if (isNew) {
          _members.add(result);
        } else {
          final index = _members.indexWhere((m) => m.id == result.id);
          if (index != -1) {
            _members[index] = result;
          }
        }
      });

      ToastService.show(
        title: isNew ? 'Member Created' : 'Profile Updated',
        message: isNew 
            ? 'New member has been successfully added to the system.'
            : 'Member details have been successfully updated.',
        type: ToastType.success,
      );
      
    } else {
      // If the form returns an error string
      ToastService.show(
        title: 'Action Failed',
        message: result is String ? result : 'An unexpected error occurred while saving.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Member Universe',
      subtitle: 'Visible to Super Admin, Admin and Staff only.',
      children: [
        // Add Member Button
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _openMemberForm(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Add Member',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kSuccess, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Data Table Card
        Card(
          elevation: 0,
          color: AppColors.kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.kBorder),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 28,
              headingRowHeight: 56,
              dataRowMinHeight: 72,
              dataRowMaxHeight: 72,
              columns: const [
                DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                DataColumn(label: Text('Member Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                DataColumn(label: Text('Branch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                DataColumn(label: Text('Account Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                DataColumn(label: Text('Date Joined', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ],
              rows: _members.map((member) {
                return DataRow(
                  cells: [
                    DataCell(Text(member.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.kPrimary.withOpacity(0.12),
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
                              Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.kTextMuted),
                                  const SizedBox(width: 4),
                                  Text(member.phone, style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(member.branch, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.kSuccess.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          member.status,
                          style: const TextStyle(color: AppColors.kSuccess, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    DataCell(
                      member.accountType == 'Portal Active'
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_outline, size: 14, color: Colors.blue.shade700),
                                  const SizedBox(width: 4),
                                  Text('Portal Active', style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )
                          : Text(member.accountType, style: const TextStyle(color: AppColors.kTextMuted, fontSize: 14)),
                    ),
                    DataCell(Text(member.dateJoined, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(
                            icon: Icons.edit_note,
                            color: Colors.blue,
                            backgroundColor: Colors.blue.shade50,
                            onPressed: () => _openMemberForm(member), // Opens form in Edit mode
                          ),
                          const SizedBox(width: 8),
                          _ActionButton(
                            icon: Icons.delete_outline,
                            color: AppColors.kDanger,
                            backgroundColor: AppColors.kDanger.withOpacity(0.08),
                            onPressed: () => _handleDelete(member),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

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
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}