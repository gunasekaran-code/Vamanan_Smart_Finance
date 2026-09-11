import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';

// -----------------------------------------------------------------------------
// MAIN PROFILE SCREEN WITH TAB NAVIGATION
// -----------------------------------------------------------------------------
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Start on the Permissions tab (index 1) to test it, or set to 0 for default
  int _currentTabIndex = 1;

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'IDENTITY & SECURITY', 'icon': Icons.account_circle_outlined},
    {'title': 'PERMISSIONS', 'icon': Icons.verified_user_outlined},
    {'title': 'OPERATIONAL FOOTPRINT', 'icon': Icons.insights_outlined},
    {'title': 'NOTIFICATIONS', 'icon': Icons.campaign_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '', // Custom headers are built inside
      children: [
        // Top Navigation Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12.0, bottom: 16.0),
                child: _buildTab(
                  index: index,
                  title: tab['title'],
                  icon: tab['icon'],
                ),
              );
            }),
          ),
        ),
        
        const SizedBox(height: 16),

        // Tab Content Switcher
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _getTabContent(),
        ),
      ],
    );
  }

  Widget _buildTab({required int index, required String title, required IconData icon}) {
    final isActive = _currentTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.kPrimary : AppColors.kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.kPrimary : AppColors.kBorder.withOpacity(0.5),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.kPrimary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.goldColor : AppColors.kTextMuted.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? AppColors.goldColor : AppColors.kTextMuted.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return const IdentitySecurityWidget();
      case 1:
        return const PermissionsWidget();
      case 2:
        return const OperationalFootprintWidget();
      case 3:
        return const NotificationsWidget();
      default:
        return const IdentitySecurityWidget();
    }
  }
}

// -----------------------------------------------------------------------------
// TAB 1: IDENTITY & SECURITY
// -----------------------------------------------------------------------------
class IdentitySecurityWidget extends StatefulWidget {
  const IdentitySecurityWidget({super.key});

  @override
  State<IdentitySecurityWidget> createState() => _IdentitySecurityWidgetState();
}

class _IdentitySecurityWidgetState extends State<IdentitySecurityWidget> {
  final _nameController = TextEditingController(text: 'TEST MANAGER');
  final _emailController = TextEditingController(text: 'testmanager@gmail.com');
  final _phoneController = TextEditingController(text: '+91 XXXXX XXXXX');
  final _passwordController = TextEditingController(text: '12345678');
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(48), 
        border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: 20,
            child: Icon(Icons.account_circle, size: 250, color: AppColors.kTextMuted.withOpacity(0.04)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.kPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_circle_outlined, color: AppColors.goldColor, size: 36),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ACCOUNT DETAILS',
                            style: TextStyle(color: AppColors.kPrimary, fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                          ),
                          Text(
                            'KEEP YOUR MANAGER ACCOUNT DETAILS UPDATED',
                            style: TextStyle(color: AppColors.kTextMuted.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final fieldWidth = isMobile ? double.infinity : (constraints.maxWidth - 24) / 2;

                    return Wrap(
                      spacing: 24,
                      runSpacing: 32,
                      children: [
                        SizedBox(width: fieldWidth, child: _buildTextField('FULL NAME', _nameController)),
                        SizedBox(width: fieldWidth, child: _buildTextField('OFFICIAL EMAIL', _emailController)),
                        SizedBox(width: fieldWidth, child: _buildTextField('MOBILE NUMBER', _phoneController)),
                        SizedBox(width: fieldWidth, child: _buildPasswordField('CHANGE ACCESS KEY (OPTIONAL)', _passwordController)),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 48),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.save_outlined, size: 20, color: Colors.white),
                    label: const Text('SAVE ACCOUNT DETAILS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.kTextMuted.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        TextFormField(controller: controller, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kPrimary), decoration: _inputDecoration()),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.kTextMuted.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          obscureText: _obscurePassword,
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.kPrimary, letterSpacing: 2.0),
          decoration: _inputDecoration().copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.kTextMuted.withOpacity(0.5)),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.kBorder.withOpacity(0.5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.kBorder.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kPrimary, width: 1.5)),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: PERMISSIONS (New implementation based on the deep blue image)
// -----------------------------------------------------------------------------
class PermissionsWidget extends StatelessWidget {
  const PermissionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Data list matching the provided design
    final List<Map<String, String>> permissionsData = [
      {
        'title': 'USER DIRECTORY ACCESS',
        'status': 'Active',
        'desc': 'READ/WRITE ACCESS TO CUSTOMER INSTITUTIONAL PROFILES',
      },
      {
        'title': 'ASSET PROVISIONING',
        'status': 'Active',
        'desc': 'AUTHORIZED TO CREATE AND MANAGE INVESTMENT PRODUCTS',
      },
      {
        'title': 'KYC VERIFICATION',
        'status': 'Active',
        'desc': 'PRIMARY AUTHORITY FOR IDENTITY PROTOCOL VALIDATION',
      },
      {
        'title': 'LIQUIDITY CONTROL',
        'status': 'Restricted',
        'desc': 'APPROVAL AUTHORITY WITH SECONDARY AUDIT LAYER',
      },
      {
        'title': 'PLATFORM CONFIGURATION',
        'status': 'Locked',
        'desc': 'SUPERADMIN CLEARANCE REQUIRED FOR CORE SYSTEM CHANGES',
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.kPrimary, // Deep Royal Blue background
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimary.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Watermark Shield
          Positioned(
            right: -30,
            top: 20,
            child: Icon(
              Icons.shield_outlined,
              size: 350,
              color: Colors.white.withOpacity(0.03),
            ),
          ),
          
          // Main Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.goldColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'PERMISSIONS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'YOUR OPERATIONAL LEVEL PROVIDES HIGH-PRIORITY CLEARANCE FOR\nASSET MANAGEMENT, KYC VERIFICATION, AND LIQUIDITY PROCESSING.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5,
                    height: 1.6,
                  ),
                ),
                
                const SizedBox(height: 48),

                // Responsive Grid for Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final cardWidth = isMobile ? double.infinity : (constraints.maxWidth - 24) / 2;

                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: permissionsData.map((data) {
                        return SizedBox(
                          width: cardWidth,
                          child: _buildPermissionCard(data),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(Map<String, String> data) {
    // Determine badge colors based on status
    Color badgeTextColor;
    if (data['status'] == 'Active') {
      badgeTextColor = AppColors.goldColor;
    } else if (data['status'] == 'Restricted') {
      badgeTextColor = Colors.orangeAccent;
    } else {
      badgeTextColor = Colors.grey.shade400; // Locked
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04), // Slightly lighter overlay
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data['title']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data['status']!,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['desc']!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.8,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: OPERATIONAL FOOTPRINT (Placeholder)
// -----------------------------------------------------------------------------
class OperationalFootprintWidget extends StatelessWidget {
  const OperationalFootprintWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildEmptyState('OPERATIONAL FOOTPRINT', Icons.insights_outlined);
  }
}

// -----------------------------------------------------------------------------
// TAB 4: NOTIFICATIONS (Placeholder)
// -----------------------------------------------------------------------------
class NotificationsWidget extends StatelessWidget {
  const NotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildEmptyState('NOTIFICATIONS', Icons.campaign_outlined);
  }
}

// -----------------------------------------------------------------------------
// REUSABLE EMPTY STATE WIDGET
// -----------------------------------------------------------------------------
Widget _buildEmptyState(String title, IconData icon) {
  return Container(
    width: double.infinity,
    height: 400,
    decoration: BoxDecoration(
      color: AppColors.kSurface,
      borderRadius: BorderRadius.circular(48),
      border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.kTextMuted.withOpacity(0.1)),
          const SizedBox(height: 24),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppColors.kTextMuted.withOpacity(0.4),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    ),
  );
}