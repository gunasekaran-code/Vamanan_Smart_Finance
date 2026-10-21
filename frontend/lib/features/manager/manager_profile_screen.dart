import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/manager_profile_model.dart';
import '../../models/operational_footprint_model.dart';
import '../../services/manager_profile_service.dart';
import 'package:frontend/core/models/app_user.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({super.key});

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: _getTabContent(),
        ),
      ],
    );
  }

  Widget _buildTab(
      {required int index, required String title, required IconData icon}) {
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
            color: isActive
                ? AppColors.kPrimary
                : AppColors.kBorder.withOpacity(0.5),
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
            Icon(icon,
                size: 18,
                color: isActive
                    ? AppColors.goldColor
                    : AppColors.kTextMuted.withOpacity(0.6)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive
                    ? AppColors.goldColor
                    : AppColors.kTextMuted.withOpacity(0.6),
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
// IDENTITY & SECURITY WIDGET — now wired to the backend
// -----------------------------------------------------------------------------
class IdentitySecurityWidget extends StatefulWidget {
  const IdentitySecurityWidget({super.key});

  @override
  State<IdentitySecurityWidget> createState() => _IdentitySecurityWidgetState();
}

class _IdentitySecurityWidgetState extends State<IdentitySecurityWidget> {
  final _formKey = GlobalKey<FormState>();
  final ManagerProfileService _service = ManagerProfileService.instance;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _saving = false;
  ManagerProfile? _profile;

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9\s]{10,15}$');

  @override
  void initState() {
    super.initState();
    // Seeded from the cached session user — no fetch endpoint exists.
    _profile = _service.currentFromSession();
    _nameController = TextEditingController(text: _profile?.name ?? '');
    _emailController = TextEditingController(text: _profile?.email ?? '');
    _phoneController = TextEditingController(text: _profile?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Full name is required' : null;

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Official email is required';
    if (!_emailRegex.hasMatch(value.trim()))
      return 'Enter a valid email address';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Mobile number is required';
    if (!_phoneRegex.hasMatch(value.trim()))
      return 'Enter a valid mobile number';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    if (value.length < 8) return 'Access key must be at least 8 characters';
    return null;
  }

  Future<void> _handleSave() async {
    if (_profile == null) {
      ToastService.show(
        title: 'Not signed in',
        message: 'Could not find your session — please log in again.',
        type: ToastType.error,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ToastService.show(
        title: 'Invalid Details',
        message: 'Please correct the highlighted fields and try again.',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.updateProfile(
        id: _profile!.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        // Resend the saved preferences so this save doesn't reset them.
        notifyEmail: SessionService.instance.currentUser?.notifyEmail ?? true,
        notifySystem: SessionService.instance.currentUser?.notifySystem ?? true,
        password: _passwordController.text,
      );

      // Refresh the cached session so the rest of the app (e.g. a header
      // showing the manager's name) picks up the change immediately.
      final current = SessionService.instance.currentUser;
      if (current != null) {
        // TODO: replace with your AppUser's real copyWith/constructor —
        // this assumes AppUser exposes a copyWith with these field names.
        await SessionService.instance.updateCurrentUser(
          current.copyWith(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
          ),
        );
      }

      _passwordController.clear();
      if (!mounted) return;
      ToastService.show(
        title: 'Account Updated',
        message: 'Your account details have been saved successfully.',
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: 'Update failed',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
                      color: AppColors.kPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.account_circle_outlined,
                      color: AppColors.goldColor, size: 36),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACCOUNT DETAILS',
                        style: TextStyle(
                            color: AppColors.kPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.5),
                      ),
                      Text(
                        'KEEP YOUR MANAGER ACCOUNT DETAILS UPDATED',
                        style: TextStyle(
                            color: AppColors.kTextMuted.withOpacity(0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 1.0),
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
                final fieldWidth = isMobile
                    ? double.infinity
                    : (constraints.maxWidth - 24) / 2;

                return Wrap(
                  spacing: 24,
                  runSpacing: 32,
                  children: [
                    SizedBox(
                        width: fieldWidth,
                        child: _buildTextField('FULL NAME', _nameController,
                            validator: _validateName)),
                    SizedBox(
                        width: fieldWidth,
                        child: _buildTextField(
                            'OFFICIAL EMAIL', _emailController,
                            validator: _validateEmail,
                            keyboardType: TextInputType.emailAddress)),
                    SizedBox(
                        width: fieldWidth,
                        child: _buildTextField(
                            'MOBILE NUMBER', _phoneController,
                            validator: _validatePhone,
                            keyboardType: TextInputType.phone)),
                    SizedBox(
                        width: fieldWidth,
                        child: _buildPasswordField(
                            'CHANGE ACCESS KEY (OPTIONAL)', _passwordController,
                            validator: _validatePassword)),
                  ],
                );
              },
            ),
            const SizedBox(height: 48),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _handleSave,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined,
                        size: 20, color: Colors.white),
                label: Text(
                  _saving ? 'SAVING...' : 'SAVE ACCOUNT DETAILS',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
        Text(label,
            style: TextStyle(
                color: AppColors.kTextMuted.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.0)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.kPrimary),
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
        Text(label,
            style: TextStyle(
                color: AppColors.kTextMuted.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.0)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          obscureText: _obscurePassword,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.kPrimary,
              letterSpacing: 2.0),
          decoration: _inputDecoration().copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.kTextMuted.withOpacity(0.5)),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
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
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.kBorder.withOpacity(0.5))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.kBorder.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.kPrimary, width: 1.5)),
    );
  }
}

// -----------------------------------------------------------------------------
// PERMISSIONS / OPERATIONAL FOOTPRINT / NOTIFICATIONS
// -----------------------------------------------------------------------------
class PermissionsWidget extends StatelessWidget {
  const PermissionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> permissionsData = [
      {
        'title': 'USER DIRECTORY ACCESS',
        'status': 'Active',
        'desc': 'READ/WRITE ACCESS TO CUSTOMER INSTITUTIONAL PROFILES'
      },
      {
        'title': 'ASSET PROVISIONING',
        'status': 'Active',
        'desc': 'AUTHORIZED TO CREATE AND MANAGE INVESTMENT PRODUCTS'
      },
      {
        'title': 'KYC VERIFICATION',
        'status': 'Active',
        'desc': 'PRIMARY AUTHORITY FOR IDENTITY PROTOCOL VALIDATION'
      },
      {
        'title': 'LIQUIDITY CONTROL',
        'status': 'Restricted',
        'desc': 'APPROVAL AUTHORITY WITH SECONDARY AUDIT LAYER'
      },
      {
        'title': 'PLATFORM CONFIGURATION',
        'status': 'Locked',
        'desc': 'SUPERADMIN CLEARANCE REQUIRED FOR CORE SYSTEM CHANGES'
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.kPrimary,
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
              color: AppColors.kPrimary.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
              right: -30,
              top: 20,
              child: Icon(Icons.shield_outlined,
                  size: 350, color: Colors.white.withOpacity(0.03))),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                        width: 6,
                        height: 28,
                        decoration: BoxDecoration(
                            color: AppColors.goldColor,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 16),
                    const Text('PERMISSIONS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.5)),
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
                      height: 1.6),
                ),
                const SizedBox(height: 48),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final cardWidth = isMobile
                        ? double.infinity
                        : (constraints.maxWidth - 24) / 2;
                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: permissionsData
                          .map((data) => SizedBox(
                              width: cardWidth,
                              child: _buildPermissionCard(data)))
                          .toList(),
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
    Color badgeTextColor = data['status'] == 'Active'
        ? AppColors.goldColor
        : (data['status'] == 'Restricted'
            ? Colors.orangeAccent
            : Colors.grey.shade400);
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
              Expanded(
                  child: Text(data['title']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -0.5))),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(data['status']!,
                    style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(data['desc']!,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.8,
                  height: 1.4)),
        ],
      ),
    );
  }
}

class OperationalFootprintWidget extends StatefulWidget {
  const OperationalFootprintWidget({super.key});

  @override
  State<OperationalFootprintWidget> createState() =>
      _OperationalFootprintWidgetState();
}

class _OperationalFootprintWidgetState
    extends State<OperationalFootprintWidget> {
  final ManagerProfileService _service = ManagerProfileService.instance;
  late Future<List<OperationalFootprintEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _service.fetchOperationalFootprint();
  }

  void _reload() {
    setState(() => _entriesFuture = _service.fetchOperationalFootprint());
  }

  @override
  Widget build(BuildContext context) {
    return _BaseCardLayout(
      watermarkIcon: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ProfileSectionHeading(
              icon: Icons.insights_outlined, title: 'OPERATIONAL FOOTPRINT'),
          const SizedBox(height: 28),
          FutureBuilder<List<OperationalFootprintEntry>>(
            future: _entriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _ProfileLoadingState();
              }
              if (snapshot.hasError) {
                return _ProfileErrorState(onRetry: _reload);
              }
              final entries = snapshot.data ?? const [];
              if (entries.isEmpty) {
                return const _ProfileEmptyState(
                    message: 'NO OPERATIONAL RECORDS FOUND');
              }
              return Column(
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    _OperationalFootprintCard(entry: entries[index]),
                    if (index < entries.length - 1) const SizedBox(height: 14),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class NotificationsWidget extends StatefulWidget {
  const NotificationsWidget({super.key});

  @override
  State<NotificationsWidget> createState() => _NotificationsWidgetState();
}

/// Email / system-terminal alert preferences, saved through
/// `manager/update_profile.php` (the `users.notify_email` /
/// `users.notify_system` columns).
class _NotificationsWidgetState extends State<NotificationsWidget> {
  final ManagerProfileService _service = ManagerProfileService.instance;

  late bool _emailAlerts;
  late bool _systemAlerts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = SessionService.instance.currentUser;
    _emailAlerts = user?.notifyEmail ?? true;
    _systemAlerts = user?.notifySystem ?? true;
  }

  Future<void> _handleSave() async {
    final user = SessionService.instance.currentUser;
    if (user == null) {
      ToastService.show(
        title: 'Not signed in',
        message: 'Could not find your session — please log in again.',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // The endpoint updates the whole row, so the current identity fields
      // are sent back unchanged alongside the new preferences.
      final saved = await _service.updateProfile(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        notifyEmail: _emailAlerts,
        notifySystem: _systemAlerts,
      );

      // Trust what the server stored; fall back to what was sent.
      final emailOn = saved.containsKey('notify_email')
          ? AppUser.fromJson(saved).notifyEmail
          : _emailAlerts;
      final systemOn = saved.containsKey('notify_system')
          ? AppUser.fromJson(saved).notifySystem
          : _systemAlerts;

      await SessionService.instance.updateCurrentUser(
        user.copyWith(notifyEmail: emailOn, notifySystem: systemOn),
      );

      if (!mounted) return;
      setState(() {
        _emailAlerts = emailOn;
        _systemAlerts = systemOn;
      });
      ToastService.show(
        title: 'Notifications Updated',
        message: 'Your notification settings have been saved.',
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: 'Update failed',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return _BaseCardLayout(
      watermarkIcon: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ProfileSectionHeading(
              icon: Icons.campaign_outlined, title: 'NOTIFICATIONS'),
          SizedBox(height: isTablet ? 36 : 24),
          _NotificationToggleTile(
            icon: Icons.mail_outline_rounded,
            title: 'EMAIL ALERTS',
            subtitle: 'RECEIVE CRITICAL UPDATES VIA AUTHENTICATED EMAIL',
            value: _emailAlerts,
            compact: !isTablet,
            onChanged: _saving ? null : (v) => setState(() => _emailAlerts = v),
          ),
          SizedBox(height: isTablet ? 24 : 16),
          _NotificationToggleTile(
            icon: Icons.bolt_outlined,
            title: 'SYSTEM TERMINAL NOTIFICATIONS',
            subtitle: 'REAL-TIME ALERTS WITHIN THE OPERATIONS TERMINAL',
            value: _systemAlerts,
            compact: !isTablet,
            onChanged:
                _saving ? null : (v) => setState(() => _systemAlerts = v),
          ),
          SizedBox(height: isTablet ? 40 : 28),
          // Right-aligned on tablets, full width on phones.
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: isTablet ? null : double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.kPrimary.withOpacity(0.6),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48 : 20,
                    vertical: isTablet ? 26 : 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.kPrimary.withOpacity(0.3),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'SAVE NOTIFICATION SETTINGS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 12,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: isTablet ? 3 : 2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool compact;
  final ValueChanged<bool>? onChanged;

  const _NotificationToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.compact,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final iconBox = compact ? 44.0 : 56.0;

    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(compact ? 28 : 40),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 36,
          vertical: compact ? 18 : 36,
        ),
        decoration: BoxDecoration(
          color: AppColors.kBackground,
          borderRadius: BorderRadius.circular(compact ? 28 : 40),
          border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: AppColors.kSurface,
                borderRadius: BorderRadius.circular(compact ? 14 : 18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.kPrimary.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon,
                  color: AppColors.kPrimary, size: compact ? 22 : 26),
            ),
            SizedBox(width: compact ? 14 : 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.kPrimary,
                      fontSize: compact ? 14 : 18,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.kTextMuted.withOpacity(0.7),
                      fontSize: compact ? 9 : 10,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: compact ? 8 : 16),
            Transform.scale(
              scale: compact ? 1.0 : 1.2,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: AppColors.kPrimary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.kBorder,
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ProfileSectionHeading({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.goldColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
                color: AppColors.kPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5),
          ),
        ),
      ],
    );
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 56),
        child: Center(child: AppLoader()),
      );
}

class _ProfileEmptyState extends StatelessWidget {
  final String message;

  const _ProfileEmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.kTextMuted.withOpacity(0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.2)),
        ),
      );
}

class _ProfileErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: AppColors.kTextMuted, size: 30),
            const SizedBox(height: 12),
            const Text('UNABLE TO LOAD DATA',
                style: TextStyle(
                    color: AppColors.kTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 14),
            OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('RETRY')),
          ],
        ),
      );
}

class _OperationalFootprintCard extends StatelessWidget {
  final OperationalFootprintEntry entry;

  const _OperationalFootprintCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return _ProfileDataCard(
      icon: _iconForActivity(entry.type),
      title: entry.title,
      description: entry.description,
      timestamp: _formatTimestamp(entry.time),
    );
  }
}

class _ProfileDataCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String timestamp;

  const _ProfileDataCard(
      {required this.icon,
      required this.title,
      required this.description,
      required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.kBorder.withOpacity(0.55))),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final details = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.kPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(description,
                      style: const TextStyle(
                          color: AppColors.kTextMuted,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          height: 1.4)),
                ],
              ],
            ),
          );

          final timestampWidget = Text(timestamp,
              textAlign: compact ? TextAlign.left : TextAlign.right,
              style: const TextStyle(
                  color: AppColors.kPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic));
          return compact
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _ProfileIcon(icon: icon),
                    const SizedBox(width: 14),
                    details
                  ]),
                  const SizedBox(height: 12),
                  Padding(
                      padding: const EdgeInsets.only(left: 54),
                      child: timestampWidget)
                ])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _ProfileIcon(icon: icon),
                  const SizedBox(width: 16),
                  details,
                  const SizedBox(width: 16),
                  timestampWidget
                ]);
        },
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  final IconData icon;

  const _ProfileIcon({required this.icon});

  @override
  Widget build(BuildContext context) => Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: AppColors.kPrimary, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: AppColors.goldColor, size: 24));
}

IconData _iconForActivity(String type) {
  switch (type.toLowerCase()) {
    case 'user':
      return Icons.person_add_alt_1_outlined;
    case 'investment':
      return Icons.verified_outlined;
    case 'withdrawal':
      return Icons.account_balance_wallet_outlined;
    default:
      return Icons.tag;
  }
}

String _formatTimestamp(DateTime? value) {
  if (value == null) return 'TIME UNAVAILABLE';
  return DateFormat('d/M/y, h:mm:ss a').format(value.toLocal());
}

class _BaseCardLayout extends StatelessWidget {
  final Widget child;
  final IconData? watermarkIcon;

  const _BaseCardLayout({required this.child, this.watermarkIcon});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(isTablet ? 48 : 32),
        border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (watermarkIcon != null)
            Positioned(
                right: -20,
                top: 20,
                child: Icon(watermarkIcon,
                    size: 250, color: AppColors.kTextMuted.withOpacity(0.04))),
          Padding(
              padding: isTablet
                  ? const EdgeInsets.symmetric(horizontal: 48, vertical: 56)
                  : const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: child),
        ],
      ),
    );
  }
}
