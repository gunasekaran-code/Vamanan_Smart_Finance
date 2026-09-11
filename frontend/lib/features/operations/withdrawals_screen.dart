import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class WithdrawalsScreen extends StatefulWidget {
  const WithdrawalsScreen({super.key});

  @override
  State<WithdrawalsScreen> createState() => _WithdrawalsScreenState();
}

class _WithdrawalsScreenState extends State<WithdrawalsScreen> {
  
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
      ToastService.show(
        title: 'Success', 
        message: 'Monthly yield processed successfully.', 
        type: ToastType.success
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light crisp background matching design
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Global Search Bar ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users, orders, assets...',
                    hintStyle: TextStyle(
                      color: AppColors.kTextMuted, 
                      fontSize: 14
                    ),
                    prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 2. Action Header Bar (Process Yield) ---
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _handleProcessYield,
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text(
                    'PROCESS MONTHLY YIELD', 
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontStyle: FontStyle.italic, 
                      fontSize: 12, 
                      letterSpacing: 0.5
                    )
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 4,
                    shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. Main Data Container (Payout List) ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          bool isMobile = constraints.maxWidth < 600;
                          
                          Widget titleSection = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PAYOUT LIST',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF1E3A8A), // Navy Blue
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AUTHORIZED LIQUIDATION OF INVESTOR CAPITAL RESERVES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF94A3B8).withOpacity(0.9), // Slate grey
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          );

                          Widget badgeSection = Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF), // Light blue background
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFBFDBFE)), // Light blue border
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 6, color: Color(0xFF3B82F6)), // Blue dot
                                SizedBox(width: 8),
                                Text(
                                  '0 AWAITING LIQUIDATION',
                                  style: TextStyle(
                                    color: Color(0xFF3B82F6), // Blue text
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          );

                          // Handle responsive layout for header
                          if (isMobile) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                titleSection,
                                const SizedBox(height: 16),
                                badgeSection,
                              ],
                            );
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: titleSection),
                              badgeSection,
                            ],
                          );
                        }
                      ),
                    ),

                    // Divider
                    const Divider(height: 1, color: AppColors.kBorder),

                    // Scrollable Table Headers
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 48, 
                        ),
                        child: DataTable(
                          columnSpacing: 48,
                          headingRowHeight: 56,
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)), // Light grey header row
                          dividerThickness: 0,
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                          columns: const [
                            DataColumn(label: Text('CUSTOMER')),
                            DataColumn(label: Text('CHANNEL')),
                            DataColumn(label: Text('QUANTUM (₹)')),
                            DataColumn(label: Text('STATUS')),
                            DataColumn(label: Text('ACTIONS')),
                          ],
                          rows: const [], // Intentionally empty to show the empty state below
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.kBorder),
                    
                    // Empty State Area
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 24),
                      alignment: Alignment.center,
                      child: const Text(
                        'INSTITUTIONAL PAYOUT QUEUE IS CURRENTLY EMPTY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFCBD5E1), // Very light grey
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}