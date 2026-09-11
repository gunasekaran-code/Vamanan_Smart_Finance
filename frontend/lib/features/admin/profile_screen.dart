import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentTabIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'IDENTITY & SECURITY', 'icon': Icons.account_circle_outlined},
    {'title': 'PERMISSIONS', 'icon': Icons.verified_user_outlined},
    {'title': 'OPERATIONAL FOOTPRINT', 'icon': Icons.insights_outlined},
    {'title': 'NOTIFICATIONS', 'icon': Icons.campaign_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Profile',
      subtitle: 'Manage and update your personal information.',
      children: [
        // Responsive Tab Navigation
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

        // Tab Content Switcher with CrossFade animation
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
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
        return const IdentitySecurityWidget(key: ValueKey('tab0'));
      case 1:
        return const PermissionsWidget(key: ValueKey('tab1'));
      case 2:
        return const OperationalFootprintWidget(key: ValueKey('tab2'));
      case 3:
        return const NotificationsWidget(key: ValueKey('tab3'));
      default:
        return const IdentitySecurityWidget(key: ValueKey('tab0'));
    }
  }
}

// -----------------------------------------------------------------------------
// 2. IDENTITY & SECURITY WIDGET
// -----------------------------------------------------------------------------
class IdentitySecurityWidget extends StatefulWidget {
  const IdentitySecurityWidget({super.key});

  @override
  State<IdentitySecurityWidget> createState() => _IdentitySecurityWidgetState();
}

class _IdentitySecurityWidgetState extends State<IdentitySecurityWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'TEST MANAGER');
  final _emailController = TextEditingController(text: 'testmanager@gmail.com');
  final _phoneController = TextEditingController(text: '+91 6369235701');
  final _passwordController = TextEditingController(text: 'MANAGER');
  bool _obscurePassword = true;

  static final RegExp _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9\s]{10,15}$');

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Official email is required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid mobile number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return null; // optional field
    }
    if (value.length < 8) {
      return 'Access key must be at least 8 characters';
    }
    return null;
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      ToastService.show(
        title: 'Account Updated',
        message: 'Your account details have been saved successfully.',
        type: ToastType.success,
      );
    } else {
      ToastService.show(
        title: 'Invalid Details',
        message: 'Please correct the highlighted fields and try again.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseCardLayout(
      watermarkIcon: Icons.account_circle,
      child: Form(
        key: _formKey,
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
                      style: TextStyle(color: AppColors.kPrimary, fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5),
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
                  SizedBox(width: fieldWidth, child: _buildTextField('FULL NAME', _nameController, validator: _validateName)),
                  SizedBox(width: fieldWidth, child: _buildTextField('OFFICIAL EMAIL', _emailController, validator: _validateEmail, keyboardType: TextInputType.emailAddress)),
                  SizedBox(width: fieldWidth, child: _buildTextField('MOBILE NUMBER', _phoneController, validator: _validatePhone, keyboardType: TextInputType.phone)),
                  SizedBox(width: fieldWidth, child: _buildPasswordField('CHANGE ACCESS KEY (OPTIONAL)', _passwordController, validator: _validatePassword)),
                ],
              );
            }
          ),
          const SizedBox(height: 48),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _handleSave,
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
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.kTextMuted.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kPrimary),
          decoration: _inputDecoration(),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.kTextMuted.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          obscureText: _obscurePassword,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
// 3. PERMISSIONS WIDGET (Deep Blue Theme)
// -----------------------------------------------------------------------------
class PermissionsWidget extends StatelessWidget {
  const PermissionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> permissionsData = [
      {'title': 'USER DIRECTORY ACCESS', 'status': 'Active', 'desc': 'READ/WRITE ACCESS TO CUSTOMER INSTITUTIONAL PROFILES'},
      {'title': 'ASSET PROVISIONING', 'status': 'Active', 'desc': 'AUTHORIZED TO CREATE AND MANAGE INVESTMENT PRODUCTS'},
      {'title': 'KYC VERIFICATION', 'status': 'Active', 'desc': 'PRIMARY AUTHORITY FOR IDENTITY PROTOCOL VALIDATION'},
      {'title': 'LIQUIDITY CONTROL', 'status': 'Restricted', 'desc': 'APPROVAL AUTHORITY WITH SECONDARY AUDIT LAYER'},
      {'title': 'PLATFORM CONFIGURATION', 'status': 'Locked', 'desc': 'SUPERADMIN CLEARANCE REQUIRED FOR CORE SYSTEM CHANGES'},
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.kPrimary, // Dark theme for permissions
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(color: AppColors.kPrimary.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: 20,
            child: Icon(Icons.shield_outlined, size: 350, color: Colors.white.withOpacity(0.03)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(width: 6, height: 28, decoration: BoxDecoration(color: AppColors.goldColor, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 16),
                    const Text('PERMISSIONS', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'YOUR OPERATIONAL LEVEL PROVIDES HIGH-PRIORITY CLEARANCE FOR\nASSET MANAGEMENT, KYC VERIFICATION, AND LIQUIDITY PROCESSING.',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, letterSpacing: 1.5, height: 1.6),
                ),
                const SizedBox(height: 48),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final cardWidth = isMobile ? double.infinity : (constraints.maxWidth - 24) / 2;

                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: permissionsData.map((data) => SizedBox(width: cardWidth, child: _buildPermissionCard(data))).toList(),
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
    Color badgeTextColor = data['status'] == 'Active' ? AppColors.goldColor : (data['status'] == 'Restricted' ? Colors.orangeAccent : Colors.grey.shade400);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(data['title']!, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5))),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(data['status']!, style: TextStyle(color: badgeTextColor, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(data['desc']!, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, letterSpacing: 0.8, height: 1.4)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. OPERATIONAL FOOTPRINT WIDGET
// -----------------------------------------------------------------------------
class OperationalFootprintWidget extends StatelessWidget {
  const OperationalFootprintWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseCardLayout(
      watermarkIcon: null, // Empty per image
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 2.0),
                child: Icon(Icons.insights_outlined, color: AppColors.goldColor, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'OPERATIONAL FOOTPRINT',
                style: TextStyle(color: AppColors.kPrimary, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5),
              ),
            ],
          ),
          
          // Empty State
          Container(
            height: 300,
            alignment: Alignment.center,
            child: Text(
              'NO OPERATIONAL RECORDS FOUND',
              style: TextStyle(color: AppColors.kTextMuted.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0),
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 5. NOTIFICATIONS WIDGET
// -----------------------------------------------------------------------------
class NotificationsWidget extends StatefulWidget {
  const NotificationsWidget({super.key});

  @override
  State<NotificationsWidget> createState() => _NotificationsWidgetState();
}

class _NotificationsWidgetState extends State<NotificationsWidget> {
  bool emailAlerts = true;
  bool systemTerminal = true;

  @override
  Widget build(BuildContext context) {
    return _BaseCardLayout(
      watermarkIcon: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 2.0),
                child: Icon(Icons.campaign_outlined, color: AppColors.goldColor, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'NOTIFICATIONS',
                style: TextStyle(color: AppColors.kPrimary, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          _buildToggleCard(
            icon: Icons.mail_outline,
            title: 'EMAIL ALERTS',
            subtitle: 'RECEIVE CRITICAL UPDATES VIA AUTHENTICATED EMAIL',
            value: emailAlerts,
            onChanged: (val) => setState(() => emailAlerts = val),
          ),
          const SizedBox(height: 24),
          _buildToggleCard(
            icon: Icons.bolt_outlined,
            title: 'SYSTEM TERMINAL NOTIFICATIONS',
            subtitle: 'REAL-TIME ALERTS WITHIN THE OPERATIONS TERMINAL',
            value: systemTerminal,
            onChanged: (val) => setState(() => systemTerminal = val),
          ),

          const SizedBox(height: 48),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                ToastService.show(
                  title: 'Notification Settings Updated',
                  message: 'Your notification preferences have been saved.',
                  type: ToastType.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('SAVE NOTIFICATION SETTINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({required IconData icon, required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.kBorder.withOpacity(0.5))),
            child: Icon(icon, color: AppColors.kPrimary),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.kPrimary, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: AppColors.kTextMuted.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.kPrimary,
            inactiveTrackColor: AppColors.kBorder,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SHARED BASE CARD LAYOUT 
// -----------------------------------------------------------------------------
class _BaseCardLayout extends StatelessWidget {
  final Widget child;
  final IconData? watermarkIcon;

  const _BaseCardLayout({required this.child, this.watermarkIcon});

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
          if (watermarkIcon != null)
            Positioned(
              right: -20,
              top: 20,
              child: Icon(watermarkIcon, size: 250, color: AppColors.kTextMuted.withOpacity(0.04)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
            child: child,
          ),
        ],
      ),
    );
  }
}