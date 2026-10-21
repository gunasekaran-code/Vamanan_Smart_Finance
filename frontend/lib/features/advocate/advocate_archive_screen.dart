import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/routing/app_routes.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import '../../models/advocate_archive_model.dart';
import '../../services/advocate_archive_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class ArchiveAgreementsScreen extends StatefulWidget {
  const ArchiveAgreementsScreen({super.key});

  @override
  State<ArchiveAgreementsScreen> createState() =>
      _ArchiveAgreementsScreenState();
}

class _ArchiveAgreementsScreenState extends State<ArchiveAgreementsScreen> {
  late Future<List<AgreementArchiveItem>> _archivesFuture;

  @override
  void initState() {
    super.initState();
    _archivesFuture = AdvocateArchiveService.fetchApprovedAgreements();
  }

  Future<void> _refresh() async {
    final future = AdvocateArchiveService.fetchApprovedAgreements();
    setState(() {
      _archivesFuture = future;
    });
    await future;
  }

  /// Opens the full deed as its own page inside the app shell (header back
  /// arrow + bottom nav), at `/archive/agreement?id=N`.
  void _openVerification(AgreementArchiveItem item) {
    context.push(AppRoutes.agreementVerificationFor(item.id), extra: item);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // Custom header built below
      children: [
        // 1. Header
        const Text(
          'APPROVED AGREEMENTS ARCHIVE',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            fontSize: 24,
            color: Color(0xFF1E293B), // Deep Navy
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 32),

        // 2. Main Rounded Table Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: FutureBuilder<List<AgreementArchiveItem>>(
            future: _archivesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: AppLoader()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFF94A3B8), size: 32),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load agreements.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('RETRY'),
                      ),
                    ],
                  ),
                );
              }

              final archives = snapshot.data ?? [];

              if (archives.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text(
                      'No approved agreements yet.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    // Tight width (not just minWidth): inside a horizontal
                    // SingleChildScrollView the incoming constraints are
                    // unbounded, and the header/data Rows below use Expanded,
                    // which needs a bounded width to lay out — minWidth alone
                    // leaves maxWidth at infinity and crashes the layout.
                    constraints: BoxConstraints.tightFor(
                      width: MediaQuery.of(context).size.width > 800
                          ? MediaQuery.of(context).size.width - 64
                          : 800,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Table Header Row
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 24),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC), // Very light tint
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(30)),
                          ),
                          child: Row(
                            children: [
                              _buildHeaderCell('CUSTOMER DETAILS', flex: 4),
                              _buildHeaderCell('AGREEMENT DETAILS', flex: 4),
                              _buildHeaderCell('STATUS', flex: 2),
                              _buildHeaderCell('ACTION',
                                  flex: 1, alignRight: true),
                            ],
                          ),
                        ),

                        // Table Data Rows
                        ...archives.map((item) => _buildDataRow(item)).toList(),

                        const SizedBox(height: 16), // Bottom padding
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TABLE HEADER CELL ---
  Widget _buildHeaderCell(String title,
      {required int flex, bool alignRight = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          fontSize: 10,
          color: Color(0xFF94A3B8), // Slate 400
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // --- TABLE DATA ROW ---
  Widget _buildDataRow(AgreementArchiveItem item) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Row(
            children: [
              // Column 1: Customer Details
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.customerName.isNotEmpty
                            ? item.customerName[0]
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Column 2: Agreement Details
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.agreementType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.referenceId,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                        color: AppColors.goldColor, // Gold ID
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Column 3: Status Badge
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.goldBadgeBg, // Light gold bg
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.goldBorder),
                    ),
                    child: Text(
                      item.status.isNotEmpty
                          ? item.status.toUpperCase()
                          : 'APPROVED',
                      style: const TextStyle(
                        color: AppColors.goldColor,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Column 4: Action (Eye Icon)
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove_red_eye_outlined,
                          size: 16, color: Color(0xFF94A3B8)),
                      onPressed: () => _openVerification(item),
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
