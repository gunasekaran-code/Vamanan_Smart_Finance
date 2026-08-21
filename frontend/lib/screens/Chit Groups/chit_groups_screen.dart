import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/confirm_dialog.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_toast.dart';
import 'Gold_dashboard.dart';
import 'group_configuration_form.dart';

class ChitGroup {
  final String id;
  final String name;
  final String code;
  final double value;
  final double installment;
  final String duration;
  final String startDate;
  final String status;

  const ChitGroup({
    required this.id,
    required this.name,
    required this.code,
    required this.value,
    required this.installment,
    required this.duration,
    required this.startDate,
    required this.status,
  });
}

class ChitGroupsScreen extends StatefulWidget {
  const ChitGroupsScreen({super.key});

  @override
  State<ChitGroupsScreen> createState() => _ChitGroupsScreenState();
}

class _ChitGroupsScreenState extends State<ChitGroupsScreen> {
  final List<ChitGroup> _groups = [
    const ChitGroup(
      id: '1',
      name: 'Gold',
      code: 'CHIT-001',
      value: 25000.00,
      installment: 1000.00,
      duration: '25 Months',
      startDate: 'Apr 2026',
      status: 'ACTIVE',
    ),
    const ChitGroup(
      id: '2',
      name: 'Silver',
      code: 'CHIT-002',
      value: 25000.00,
      installment: 1000.00,
      duration: '25 Months',
      startDate: 'Apr 2026',
      status: 'ACTIVE',
    ),
  ];

  Future<void> _openGroupForm([ChitGroup? group]) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChitGroupFormSheet(group: group),
    );

    if (result == null) return;

    if (result is ChitGroup) {
      final isNew = group == null;
      setState(() {
        if (isNew) {
          _groups.add(result);
        } else {
          final index = _groups.indexWhere((g) => g.id == result.id);
          if (index != -1) _groups[index] = result;
        }
      });

      ToastService.show(
        title: isNew ? 'Chit Group Created' : 'Group Updated',
        message: isNew
            ? '${result.name} group has been successfully created.'
            : '${result.name} group details updated successfully.',
        type: ToastType.success,
      );
    } else {
      ToastService.show(
        title: 'Action Failed',
        message: result is String ? result : 'An error occurred while saving configuration.',
        type: ToastType.error,
      );
    }
  }

  Future<void> _handleDeleteGroup(ChitGroup group) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Chit Group',
      message: 'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true) {
      setState(() {
        _groups.removeWhere((g) => g.id == group.id);
      });

      ToastService.show(
        title: 'Group Removed',
        message: '${group.name} group has been deleted.',
        type: ToastType.success,
      );
    }
  }

  void _openDashboard(ChitGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoldDashboardScreen(group: group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Chit Groups',
      subtitle: 'Manage and monitor all active chit schemes.',
      children: [
        // Create Chit Group Action Button
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _openGroupForm(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Create Chit Group',
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

        // Table List
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
              columnSpacing: 24,
              headingRowHeight: 56,
              dataRowMinHeight: 68,
              dataRowMaxHeight: 68,
              columns: const [
                DataColumn(label: Text('GROUP NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                DataColumn(label: Text('VALUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                DataColumn(label: Text('INSTALLMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                DataColumn(label: Text('DURATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                DataColumn(label: Text('START DATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              ],
              rows: _groups.map((group) {
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'ID: ${group.code}',
                            style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        '₹${group.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '₹${group.installment.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    DataCell(Text(group.duration, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    DataCell(Text(group.startDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.kSuccess.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow, size: 12, color: AppColors.kSuccess),
                            const SizedBox(width: 2),
                            Text(
                              group.status,
                              style: const TextStyle(
                                color: AppColors.kSuccess,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              icon: const Icon(Icons.speed, size: 18, color: Colors.blue),
                              tooltip: 'Open Dashboard',
                              onPressed: () => _openDashboard(group),
                            ),
                            Container(width: 1, height: 20, color: Colors.grey.shade300),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                              tooltip: 'Edit Group',
                              onPressed: () => _openGroupForm(group),
                            ),
                          ],
                        ),
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