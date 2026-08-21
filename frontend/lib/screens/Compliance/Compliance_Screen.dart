import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/stat_card.dart';

class ComplianceMember {
  final String id;
  final String customId;
  final String name;
  final String phone;
  final String complianceStatus;
  final int verifiedDocs;
  final int totalDocs;
  final bool isBankConnected;
  final bool hasLoanRisk;

  const ComplianceMember({
    required this.id,
    required this.customId,
    required this.name,
    required this.phone,
    required this.complianceStatus,
    required this.verifiedDocs,
    required this.totalDocs,
    required this.isBankConnected,
    required this.hasLoanRisk,
  });
}

class ComplianceNexusScreen extends StatefulWidget {
  const ComplianceNexusScreen({super.key});

  @override
  State<ComplianceNexusScreen> createState() => _ComplianceNexusScreenState();
}

class _ComplianceNexusScreenState extends State<ComplianceNexusScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<ComplianceMember> _members = [
    const ComplianceMember(
      id: '2',
      customId: '#0002',
      name: 'Jessica',
      phone: '9512364870',
      complianceStatus: 'REJECTED',
      verifiedDocs: 0,
      totalDocs: 2,
      isBankConnected: false,
      hasLoanRisk: false,
    ),
    const ComplianceMember(
      id: '1',
      customId: '#0001',
      name: 'Roki',
      phone: '9786204074',
      complianceStatus: 'PARTIAL',
      verifiedDocs: 0,
      totalDocs: 0,
      isBankConnected: true,
      hasLoanRisk: true,
    ),
    const ComplianceMember(
      id: '3',
      customId: '#0003',
      name: 'Varshini',
      phone: '7685940321',
      complianceStatus: 'PARTIAL',
      verifiedDocs: 0,
      totalDocs: 0,
      isBankConnected: true,
      hasLoanRisk: true,
    ),
    const ComplianceMember(
      id: '5',
      customId: '#0005',
      name: 'VEERASAMY.K',
      phone: '9677490097',
      complianceStatus: 'PARTIAL',
      verifiedDocs: 0,
      totalDocs: 0,
      isBankConnected: true,
      hasLoanRisk: false,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleReviewFile(ComplianceMember member) {
    ToastService.show(
      title: 'Coming Soon',
      message: 'Compliance file review for ${member.name} will be available soon.',
      type: ToastType.info,
    );
  }

  List<ComplianceMember> get _filteredMembers {
    return _members.where((m) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = m.name.toLowerCase().contains(query) ||
          m.phone.contains(query) ||
          m.customId.toLowerCase().contains(query);

      if (_selectedFilter == 'All') return matchesSearch;
      return matchesSearch &&
          m.complianceStatus.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Compliance Nexus',
      subtitle:
          'Central Monitoring for Member KYC, Banking, and Financial Integrity',
      children: [
        // Responsive 2x2 Grid for Mobile & 4x1 for Desktop
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            return GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isMobile ? 1.35 : 1.8,
              children: [
                StatCard(
                  label: 'TOTAL MEMBERS',
                  value: '${_members.length}',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                StatCard(
                  label: 'FULLY COMPLIANT',
                  value:
                      '${_members.where((m) => m.complianceStatus == 'COMPLIANT').length}',
                  icon: Icons.check_circle,
                  color: AppColors.kSuccess,
                ),
                StatCard(
                  label: 'PENDING REVIEW',
                  value:
                      '${_members.where((m) => m.complianceStatus == 'PENDING').length}',
                  icon: Icons.hourglass_top_rounded,
                  color: Colors.amber.shade700,
                ),
                StatCard(
                  label: 'MISSING INFO',
                  value:
                      '${_members.where((m) => m.complianceStatus == 'REJECTED' || m.complianceStatus == 'PARTIAL').length}',
                  icon: Icons.warning_rounded,
                  color: AppColors.kDanger,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

      // Single Search Bar (Green & White Theme)
Container(
  height: 48,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.green, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const Icon(
        Icons.search,
        size: 20,
        color: Colors.green,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
          ),
          decoration: const InputDecoration(
            hintText: 'Search by name or phone...',
            hintStyle: TextStyle(
              color: AppColors.kTextMuted,
              fontSize: 15,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      if (_searchController.text.isNotEmpty)
        GestureDetector(
          onTap: () {
            _searchController.clear();
            setState(() {});
          },
          child: const Icon(
            Icons.close,
            size: 18,
            color: AppColors.kTextMuted,
          ),
        ),
    ],
  ),
),


        const SizedBox(height: 12),

        // Scrollable Filter Pills Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ['All', 'Compliant', 'Pending', 'Partial', 'Rejected']
                  .map((filter) {
                final isSelected = _selectedFilter == filter;
                return InkWell(
                  onTap: () => setState(() => _selectedFilter = filter),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.kSuccess
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Compliance Table Card with Empty State Handling
        Card(
          elevation: 0,
          color: AppColors.kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.kBorder),
          ),
          child: _filteredMembers.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: AppColors.kTextMuted.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No Data Found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'No compliance records match your current search or filter criteria.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.kTextMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 32,
                    headingRowHeight: 52,
                    dataRowMinHeight: 72,
                    dataRowMaxHeight: 72,
                    columns: const [
                      DataColumn(
                          label: Text('MEMBER IDENTITY',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.kTextMuted))),
                      DataColumn(
                          label: Text('COMPLIANCE STATUS',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.kTextMuted))),
                      DataColumn(
                          label: Text('DOCUMENT STACK',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.kTextMuted))),
                      DataColumn(
                          label: Text('BANK HEALTH',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.kTextMuted))),
                      DataColumn(
                          label: Text('LOAN RISK',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.kTextMuted))),
                      DataColumn(
                          label: Text('REVIEW ACTIONS',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.kTextMuted))),
                    ],
                    rows: _filteredMembers.map((member) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.indigo.shade50,
                                      child: Text(
                                        member.name.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                            color: Colors.indigo.shade700,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: AppColors.kSuccess,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(member.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text('ID: ${member.customId}',
                                        style: const TextStyle(
                                            color: AppColors.kTextMuted,
                                            fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          DataCell(_ComplianceBadge(status: member.complianceStatus)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (member.complianceStatus == 'REJECTED') ...[
                                  const Icon(Icons.cancel,
                                      size: 16, color: AppColors.kDanger),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.access_time_filled,
                                      size: 16, color: Colors.amber),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  '${member.verifiedDocs} / ${member.totalDocs} Verified',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Icon(
                              Icons.account_balance_rounded,
                              color: member.isBankConnected
                                  ? AppColors.kSuccess
                                  : Colors.grey.shade400,
                              size: 22,
                            ),
                          ),
                          DataCell(
                            member.hasLoanRisk
                                ? Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.kDanger,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.priority_high,
                                        color: Colors.white, size: 12),
                                  )
                                : const Icon(Icons.show_chart_rounded,
                                    color: Colors.blue, size: 22),
                          ),
                          DataCell(
                            OutlinedButton(
                              onPressed: () => _handleReviewFile(member),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Review File',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13)),
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

class _ComplianceBadge extends StatelessWidget {
  final String status;

  const _ComplianceBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    IconData? icon;

    switch (status.toUpperCase()) {
      case 'REJECTED':
        bg = const Color(0xFFFFE8E8);
        text = AppColors.kDanger;
        icon = Icons.cancel_outlined;
        break;
      case 'PARTIAL':
        bg = const Color(0xFFFFF4E5);
        text = Colors.amber.shade900;
        icon = Icons.remove_circle_outline;
        break;
      case 'COMPLIANT':
        bg = AppColors.kSuccess.withOpacity(0.12);
        text = AppColors.kSuccess;
        icon = Icons.check_circle_outline;
        break;
      default:
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            status.toUpperCase(),
            style: TextStyle(
                color: text, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}