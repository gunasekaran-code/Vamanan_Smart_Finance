import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'company_node_widget.dart';
import 'security_protocols_widget.dart';
import 'finance_parameters_widget.dart';
import 'payment_gateway_widget.dart';
import 'access_control_widget.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {

  String _activeTab = 'ADMIN PROFILE';

  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _nodeEmailController = TextEditingController();
  final TextEditingController _securityKeyController = TextEditingController();

  final List<String> _tabs = [
    'ADMIN PROFILE',
    'COMPANY NODE',
    'SECURITY PROTOCOLS',
    'FINANCE PARAMETERS',
    'PAYMENT GATEWAY',
    'ACCESS CONTROL',
  ];

  @override
  void dispose() {
    _adminNameController.dispose();
    _nodeEmailController.dispose();
    _securityKeyController.dispose();
    super.dispose();
  }

  // --- Action Handlers ---

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

  void _handleSynchronizeProfile() {
    ToastService.show(
      title: 'Profile Synchronized', 
      message: 'Administrator profile parameters have been updated across all nodes.', 
      type: ToastType.success
    );
    
    // Clear password field after save
    setState(() {
      _securityKeyController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light crisp background
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
                    hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 2. Process Monthly Yield Button ---
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _handleProcessYield,
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('PROCESS MONTHLY YIELD', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5)),
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

              // --- 3. System Calibration Header Card ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.kBorder),
                ),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A), // Navy Blue
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.settings, color: Color(0xFFFBBF24), size: 24), // Gold Icon
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SYSTEM CALIBRATION',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'AUTHORIZED MODIFICATION OF PLATFORM OPERATIONAL PARAMETERS',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Sub-navigation Tabs
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _tabs.map((tab) => _buildNavTab(
                        label: tab,
                        icon: _getIconForTab(tab),
                        isActive: _activeTab == tab,
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

             if (_activeTab == 'ADMIN PROFILE')
                _buildAdminProfileContent()
              else if (_activeTab == 'COMPANY NODE')     
                const CompanyNodeWidget()                
              else if (_activeTab == 'SECURITY PROTOCOLS') 
                const SecurityProtocolsWidget()
              else if (_activeTab == 'FINANCE PARAMETERS') 
                const FinanceParametersWidget()
              else if (_activeTab == 'PAYMENT GATEWAY')    
                const PaymentGatewayWidget()               
              else if (_activeTab == 'ACCESS CONTROL')     // <-- ADD THIS CONDITION
                const AccessControlWidget()                // <-- LOAD THE NEW WIDGET
              else
                _buildPlaceholderContent(),
                
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Builders & Sub-Components ---

  IconData _getIconForTab(String tab) {
    switch (tab) {
      case 'ADMIN PROFILE': return Icons.account_circle_outlined;
      case 'COMPANY NODE': return Icons.domain;
      case 'SECURITY PROTOCOLS': return Icons.security;
      case 'FINANCE PARAMETERS': return Icons.bolt;
      case 'PAYMENT GATEWAY': return Icons.payment;
      case 'ACCESS CONTROL': return Icons.vpn_key_outlined;
      default: return Icons.circle_outlined;
    }
  }

  Widget _buildNavTab({required String label, required IconData icon, required bool isActive}) {
    return InkWell(
      onTap: () => setState(() => _activeTab = label),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? const Color(0xFF1E3A8A) : Colors.transparent,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminProfileContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Deep Blue Banner
          Container(
            clipBehavior: Clip.antiAlias, // To clip the watermark
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(32.0),
            child: Stack(
              children: [
                // Watermark Icon
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 180,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
                
                // Banner Content
                Row(
                  children: [
                    // Large V Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'V',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // Profile Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VAMANAN ENT...',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ADMINISTRATOR ACCOUNT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFFFBBF24), // Gold
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Badges (Responsive Wrap)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildBannerBadge('ADMIN@MAKKALGOLD.COM'),
                              _buildBannerBadge('AUTHENTICATED SESSION'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 2. Input Fields (Responsive Layout)
          LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;
              
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInputField('ADMINISTRATOR NAME', _adminNameController),
                    const SizedBox(height: 24),
                    _buildInputField('NODE EMAIL ADDRESS', _nodeEmailController),
                  ],
                );
              }
              
              return Row(
                children: [
                  Expanded(child: _buildInputField('ADMINISTRATOR NAME', _adminNameController)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildInputField('NODE EMAIL ADDRESS', _nodeEmailController)),
                ],
              );
            }
          ),
          const SizedBox(height: 24),

          // Password Field
          _buildInputField(
            'UPDATE SECURITY KEY (LEAVE BLANK TO\nMAINTAIN CURRENT)', 
            _securityKeyController, 
            isObscure: true,
            hintText: '••••••••',
            maxWidth: 400, // Limit width on large screens to match design proportion
          ),
          const SizedBox(height: 40),

          // 3. Action Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _handleSynchronizeProfile,
              icon: const Icon(Icons.save, size: 16),
              label: const Text('SYNCHRONIZE PROFILE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: const Color(0xFF1E3A8A).withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.construction, size: 48, color: AppColors.kTextMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'MODULE UNDER CONSTRUCTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.kTextMuted,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildBannerBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool isObscure = false, String? hintText, double? maxWidth}) {
    Widget inputContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.w900, 
            fontStyle: FontStyle.italic, 
            color: Color(0xFF94A3B8), 
            letterSpacing: 1,
            height: 1.5,
          )
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.kTextMuted, fontWeight: FontWeight.normal, fontStyle: FontStyle.italic, fontSize: 13),
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
          ),
        ),
      ],
    );

    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: inputContent,
      );
    }
    return inputContent;
  }
}