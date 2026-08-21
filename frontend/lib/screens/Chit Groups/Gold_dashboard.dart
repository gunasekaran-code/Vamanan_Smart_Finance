import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/confirm_dialog.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_toast.dart';
import 'chit_groups_screen.dart';
import 'group_configuration_form.dart';

class RosterMember {
  final String id;
  final String name;
  final String phone;
  final String enrollmentDate;

  const RosterMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.enrollmentDate,
  });
}

class GoldDashboardScreen extends StatefulWidget {
  final ChitGroup group;

  const GoldDashboardScreen({
    super.key,
    required this.group,
  });

  @override
  State<GoldDashboardScreen> createState() => _GoldDashboardScreenState();
}

class _GoldDashboardScreenState extends State<GoldDashboardScreen> {
  late ChitGroup _currentGroup;

  final List<RosterMember> _roster = [
    const RosterMember(id: '1', name: 'Roki', phone: '9786204074', enrollmentDate: '08 Apr 2026'),
    const RosterMember(id: '2', name: 'Jessica', phone: '9512364870', enrollmentDate: '09 Apr 2026'),
    const RosterMember(id: '3', name: 'Varshini', phone: '7685940321', enrollmentDate: '26 Jun 2026'),
  ];

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.group;
  }

  Future<void> _openEditGroupForm() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChitGroupFormSheet(group: _currentGroup),
    );

    if (result is ChitGroup) {
      setState(() {
        _currentGroup = result;
      });

      ToastService.show(
        title: 'Group Configuration Updated',
        message: '${result.name} group configuration details have been updated.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _handleRemoveMember(RosterMember member) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Remove Member',
      message: 'Are you sure you want to remove ${member.name} from ${_currentGroup.name} Dashboard?',
      confirmLabel: 'Remove',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true) {
      setState(() {
        _roster.removeWhere((m) => m.id == member.id);
      });

      ToastService.show(
        title: 'Member Removed',
        message: '${member.name} removed from roster.',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '${_currentGroup.name} Dashboard',
      subtitleWidget: Row(
        children: [
          const Icon(Icons.location_city, size: 14, color: AppColors.kTextMuted),
          const SizedBox(width: 4),
          const Text('Main Branch', style: TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.kSuccess.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Live Status', style: TextStyle(color: AppColors.kSuccess, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openEditGroupForm,
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kSuccess,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Responsive Cards
        LayoutBuilder(
          builder: (context, constraints) {
            double cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatCard(
                  width: cardWidth,
                  icon: Icons.monetization_on_outlined,
                  iconColor: Colors.indigo,
                  iconBg: Colors.indigo.shade50,
                  label: 'CHIT VALUE',
                  value: '₹${_currentGroup.value.toStringAsFixed(2)}',
                  accentColor: Colors.blue.shade400,
                ),
                _buildStatCard(
                  width: cardWidth,
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: Colors.lightBlue.shade700,
                  iconBg: Colors.lightBlue.shade50,
                  label: 'INSTALLMENT',
                  value: '₹${_currentGroup.installment.toStringAsFixed(2)}',
                  accentColor: Colors.cyan.shade400,
                ),
                _buildStatCard(
                  width: cardWidth,
                  icon: Icons.calendar_month_outlined,
                  iconColor: Colors.amber.shade800,
                  iconBg: Colors.amber.shade50,
                  label: 'DURATION',
                  value: _currentGroup.duration,
                  accentColor: Colors.amber.shade400,
                ),
                _buildStatCard(
                  width: cardWidth,
                  icon: Icons.group_outlined,
                  iconColor: Colors.teal,
                  iconBg: Colors.teal.shade50,
                  label: 'ENROLLMENT',
                  value: '${_roster.length}/25',
                  accentColor: Colors.teal.shade400,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required double width,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 20, backgroundColor: iconBg, child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.kTextMuted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kTextDark)),
        ],
      ),
    );
  }
}