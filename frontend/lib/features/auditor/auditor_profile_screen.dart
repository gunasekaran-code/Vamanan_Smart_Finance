import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

import 'package:frontend/core/services/session_service.dart';

import '../../models/auditor_profile_model.dart';
import '../../services/auditor_profile_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class AuditorProfileScreen extends StatefulWidget {
  /// Optional explicit override. If omitted, the screen resolves the
  /// logged-in auditor's id from SessionService.
  final int? userId;

  const AuditorProfileScreen({super.key, this.userId});

  @override
  State<AuditorProfileScreen> createState() => _AuditorProfileScreenState();
}

class _AuditorProfileScreenState extends State<AuditorProfileScreen> {
  // State Variables
  bool _isEditingProfile = false;
  int _feedbackTab = 0; // 0 = Write, 1 = From Team, 2 = Submissions

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  AuditorProfile? _profile;

  // Controllers for Edit Profile
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _accNumCtrl;
  late TextEditingController _ifscCtrl;

  // Controller for Feedback
  late TextEditingController _feedbackSubjectCtrl;
  late TextEditingController _feedbackMsgCtrl;

  // Theme Colors matching the images
  final Color _navyBlue = const Color(0xFF1B233A);
  final Color _brightBlue = const Color(0xFF2563EB); // Used for active tabs
  final Color _slateText = const Color(0xFF94A3B8);

  int? get _resolvedUserId =>
      widget.userId ??
      int.tryParse(SessionService.instance.currentUser?.id ?? '');

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    // profile.php has no address/bank fields — kept local-only (not sent to backend).
    _addressCtrl = TextEditingController(text: 'NOT SET');
    _bankNameCtrl = TextEditingController(text: 'NOT SET');
    _accNumCtrl = TextEditingController(text: 'NOT SET');
    _ifscCtrl = TextEditingController(text: 'NOT SET');

    _feedbackSubjectCtrl = TextEditingController();
    _feedbackMsgCtrl = TextEditingController();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bankNameCtrl.dispose();
    _accNumCtrl.dispose();
    _ifscCtrl.dispose();
    _feedbackSubjectCtrl.dispose();
    _feedbackMsgCtrl.dispose();
    super.dispose();
  }

  // --- DATA LOADING ---
  Future<void> _loadProfile() async {
    final userId = _resolvedUserId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _loadError = 'No logged-in user id found.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final profile = await AuditorProfileService.instance.fetchProfile(userId);
      _applyProfile(profile);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  void _applyProfile(AuditorProfile profile) {
    _profile = profile;
    _nameCtrl.text = profile.name;
    _emailCtrl.text = profile.email;
    _phoneCtrl.text = profile.phone;
  }

  // --- ACTIONS ---
  Future<void> _handleSaveProfile() async {
    final userId = _resolvedUserId;
    if (userId == null) {
      ToastService.show(
          title: 'Error',
          message: 'No logged-in user id found.',
          type: ToastType.error);
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      ToastService.show(
          title: 'Error', message: 'Name is required.', type: ToastType.error);
      return;
    }
    if (!_emailCtrl.text.contains('@')) {
      ToastService.show(
          title: 'Error',
          message: 'A valid email is required.',
          type: ToastType.error);
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Save Profile Changes',
      message: 'Are you sure you want to update your profile attributes?',
      confirmLabel: 'Save Changes',
      confirmButtonColor: _navyBlue,
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final updated = await AuditorProfileService.instance.updateProfile(
        userId: userId,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      setState(() {
        _applyProfile(updated);
        _isEditingProfile = false;
        _isSaving = false;
      });
      ToastService.show(
          title: 'Profile Updated',
          message: 'Your profile attributes have been successfully saved.',
          type: ToastType.success);
    } catch (e) {
      setState(() => _isSaving = false);
      ToastService.show(
          title: 'Error', message: e.toString(), type: ToastType.error);
    }
  }

  Future<void> _handleDeactivate() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Deactivate Account',
      message:
          'Are you sure you want to deactivate your auditor account? This action requires admin approval to reverse.',
      confirmLabel: 'Deactivate',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true) {
      // profile.php has no deactivate action — wire this to a real endpoint
      // when one exists. For now this is UI-only, as requested.
      ToastService.show(
          title: 'Account Deactivated',
          message: 'Your account is now inactive.',
          type: ToastType.warning);
    }
  }

  void _openChangePasswordModal() {
    final userId = _resolvedUserId;
    final profile = _profile;
    if (userId == null || profile == null) {
      ToastService.show(
          title: 'Error',
          message: 'Profile not loaded yet.',
          type: ToastType.error);
      return;
    }
    showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(
        userId: userId,
        name: profile.name,
        email: profile.email,
        phone: profile.phone == 'NOT SET' ? '' : profile.phone,
      ),
    );
  }

  void _submitFeedback() {
    if (_feedbackSubjectCtrl.text.isEmpty || _feedbackMsgCtrl.text.isEmpty) {
      ToastService.show(
          title: 'Error',
          message: 'Please fill in all feedback fields.',
          type: ToastType.error);
      return;
    }
    // No feedback.php wiring specified for auditors yet — kept as local UI
    // behavior, same as before.
    ToastService.show(
        title: 'Feedback Submitted',
        message: 'Your feedback has been sent to the team.',
        type: ToastType.success);
    _feedbackSubjectCtrl.clear();
    _feedbackMsgCtrl.clear();
    setState(() => _feedbackTab = 2); // Switch to submissions tab
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null,
      children: [
        Center(
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: 600), // Mobile-first constraint
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 120),
        child: Center(child: AppLoader()),
      );
    }

    if (_loadError != null || _profile == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppColors.kDanger, size: 40),
            const SizedBox(height: 16),
            Text(_loadError ?? 'Could not load profile.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: _navyBlue, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadProfile, child: const Text('RETRY')),
          ],
        ),
      );
    }

    final profile = _profile!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('MY PROFILE',
            style: TextStyle(
                color: Color(0xFF1B233A),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('MANAGE YOUR ACCOUNT DATA AND CREDENTIALS',
            style: TextStyle(
                color: _slateText,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.0)),
        const SizedBox(height: 24),
        _buildHeaderCard(profile),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isEditingProfile
              ? _buildProfileEditMode()
              : _buildProfileViewMode(),
        ),
        const SizedBox(height: 24),
        if (!_isEditingProfile) ...[
          _buildPerformanceStats(profile),
          const SizedBox(height: 24),
          _buildMetricSummary(),
          const SizedBox(height: 24),
          _buildAccountSecurity(),
          const SizedBox(height: 24),
          _buildFeedbackSection(),
          const SizedBox(height: 40),
        ]
      ],
    );
  }

  // ==========================================================================
  // 1. HEADER CARD
  // ==========================================================================
  Widget _buildHeaderCard(AuditorProfile profile) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ]),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
            alignment: Alignment.center,
            child: Text(profile.initial,
                style: TextStyle(
                    color: _brightBlue,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 16),
          Text(profile.name.toUpperCase(),
              style: TextStyle(
                  color: _navyBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _navyBlue,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('INTERNAL AUDITOR',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5))),
              const SizedBox(width: 8),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.goldBadgeBg,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('ID: ${profile.id}',
                      style: const TextStyle(
                          color: AppColors.goldColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5))),
            ],
          ),
          const SizedBox(height: 16),
          Text('DATE JOINED: ${profile.dateJoinedLabel}',
              style: TextStyle(
                  color: _slateText,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.0)),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2a. PROFILE ATTRIBUTES (VIEW MODE)
  // ==========================================================================
  Widget _buildProfileViewMode() {
    return Container(
      key: const ValueKey('VIEW'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: _navyBlue,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.person_outline,
                          color: Colors.white, size: 16)),
                  const SizedBox(width: 12),
                  Text('PROFILE ATTRIBUTES',
                      style: TextStyle(
                          color: _navyBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5)),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _isEditingProfile = true),
                child: Text('EDIT',
                    style: TextStyle(
                        color: _brightBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.underline)),
              )
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), thickness: 2),
          const SizedBox(height: 24),
          _buildViewField('FULL NAME', _nameCtrl.text),
          _buildViewField('EMAIL', _emailCtrl.text),
          _buildViewField('PHONE NUMBER', _phoneCtrl.text),
          _buildViewField('ADDRESS', _addressCtrl.text),
          _buildViewField('BANK NAME', _bankNameCtrl.text),
          _buildViewField('ACCOUNT NUMBER', _accNumCtrl.text),
          _buildViewField('IFSC CODE', _ifscCtrl.text, isLast: true),
        ],
      ),
    );
  }

  Widget _buildViewField(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.0)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.check, color: _slateText.withOpacity(0.5), size: 14),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(value,
                      style: TextStyle(
                          color: _navyBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic))),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2b. PROFILE ATTRIBUTES (EDIT MODE)
  // ==========================================================================
  Widget _buildProfileEditMode() {
    return Container(
      key: const ValueKey('EDIT'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 10))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: _navyBlue, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16)),
              const SizedBox(width: 12),
              Text('PROFILE ATTRIBUTES',
                  style: TextStyle(
                      color: _navyBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSaveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save, size: 16),
                  label: Text(_isSaving ? 'SAVING...' : 'SAVE',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _navyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          // Revert any unsaved edits back to the last loaded profile.
                          if (_profile != null) _applyProfile(_profile!);
                          setState(() => _isEditingProfile = false);
                        },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _brightBlue,
                      side:
                          const BorderSide(color: Color(0xFFEFF6FF), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('CANCEL',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildEditField('FULL NAME', Icons.person_outline, _nameCtrl),
          _buildEditField('EMAIL', Icons.mail_outline, _emailCtrl),
          _buildEditField('PHONE NUMBER', Icons.phone_outlined, _phoneCtrl),
          _buildEditField('ADDRESS', Icons.location_on_outlined, _addressCtrl),
          _buildEditField(
              'BANK NAME', Icons.account_balance_outlined, _bankNameCtrl),
          _buildEditField('ACCOUNT NUMBER', Icons.numbers, _accNumCtrl),
          _buildEditField('IFSC CODE', Icons.verified_user_outlined, _ifscCtrl,
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildEditField(
      String label, IconData icon, TextEditingController controller,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.0)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            style: TextStyle(
                color: _navyBlue,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.goldColor, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.goldColor, width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 3. PERFORMANCE STATS & METRICS
  // ==========================================================================
  Widget _buildPerformanceStats(AuditorProfile profile) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: Color(0xFF94A3B8), size: 16)),
              const SizedBox(width: 12),
              Text('PERFORMANCE & GAINS',
                  style: TextStyle(
                      color: _slateText,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('WALLET BALANCE',
              style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.goldBadgeBg,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('PAYOUT ELIGIBLE',
                  style: TextStyle(
                      color: AppColors.goldColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: _navyBlue, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WALLET BALANCE',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Text('₹${profile.walletBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child:
                      _buildActionBtn(Icons.account_balance, 'BANK DETAILS')),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildActionBtn(Icons.credit_card, 'PAN DETAILS')),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 2)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: _slateText),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: _slateText,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // NOTE: profile.php has no audited/verified/plans/payouts counters, so this
  // section stays static (same placeholder values as before) until a stats
  // endpoint is exposed for auditors.
  Widget _buildMetricSummary() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.bar_chart,
                      color: Color(0xFF94A3B8), size: 16)),
              const SizedBox(width: 12),
              Text('METRIC SUMMARY',
                  style: TextStyle(
                      color: _slateText,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 24),
          _buildMetricRow('TOTAL AUDITED', '40', Icons.fact_check_outlined),
          const SizedBox(height: 24),
          _buildMetricRow('DOCUMENT VERIFIED', '40', Icons.file_copy_outlined),
          const SizedBox(height: 24),
          _buildMetricRow('ACTIVE PLANS', '0', Icons.play_circle_outline),
          const SizedBox(height: 24),
          _buildMetricRow('PAYOUTS', '0', Icons.payments_outlined),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: _navyBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic)),
          ],
        ),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _brightBlue, size: 20)),
      ],
    );
  }

  // ==========================================================================
  // 4. ACCOUNT SECURITY
  // ==========================================================================
  Widget _buildAccountSecurity() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: _navyBlue, borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACCOUNT\nSECURITY',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5)),
              Icon(Icons.shield_outlined,
                  color: Colors.white.withOpacity(0.2), size: 48),
            ],
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: _openChangePasswordModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('CHANGE PASSWORD',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic)),
                  Icon(Icons.chevron_right, color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _handleDeactivate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DEACTIVATE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic)),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.kDanger.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('DANGER',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 5. FEEDBACK & REMARKS
  // ==========================================================================
  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: _navyBlue,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.goldColor, size: 18)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FEEDBACK & REMARKS',
                        style: TextStyle(
                            color: _navyBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('SHARE YOUR THOUGHTS • SEE REPLIES FROM OUR TEAM',
                        style: TextStyle(
                            color: _slateText,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), thickness: 2),
          const SizedBox(height: 24),

          // Feedback Segmented Tabs
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildFeedbackTabBtn(0, 'WRITE\nFEEDBACK'),
                _buildFeedbackTabBtn(1, 'FROM\nTEAM'),
                _buildFeedbackTabBtn(2, 'MY\nSUBMISSIONS'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Feedback Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildFeedbackContent(),
          )
        ],
      ),
    );
  }

  Widget _buildFeedbackTabBtn(int index, String title) {
    final isActive = _feedbackTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _feedbackTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: isActive ? _brightBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: _brightBlue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]
                  : []),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isActive ? Colors.white : _slateText,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackContent() {
    if (_feedbackTab == 0) {
      // WRITE FEEDBACK
      return Column(
        key: const ValueKey('WRITE'),
        children: [
          TextField(
            controller: _feedbackSubjectCtrl,
            style: TextStyle(
                color: _navyBlue,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              hintText: 'SUBJECT (E.G. PAYOUT QUERY)',
              hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _feedbackMsgCtrl,
            maxLines: 4,
            style: TextStyle(
                color: _navyBlue,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              hintText: 'YOUR MESSAGE...',
              hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitFeedback,
              icon: const Icon(Icons.send, size: 16),
              label: const Text('SUBMIT FEEDBACK',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.0)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _brightBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
            ),
          )
        ],
      );
    } else if (_feedbackTab == 1) {
      // FROM TEAM
      return Container(
        key: const ValueKey('TEAM'),
        padding: const EdgeInsets.symmetric(vertical: 40),
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.inbox_outlined,
                size: 48, color: const Color(0xFFCBD5E1).withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('NO REPLIES FROM THE TEAM YET',
                style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0)),
          ],
        ),
      );
    } else {
      // MY SUBMISSIONS
      return Container(
        key: const ValueKey('SUBMISSIONS'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                    children: List.generate(
                        5,
                        (index) => const Icon(Icons.star,
                            color: AppColors.goldColor, size: 16))),
                const Text('4/9/2026, 3:45:48 PM',
                    style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Payout Query',
                style: TextStyle(
                    color: _navyBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            Text("Hello, it's a test message",
                style: TextStyle(
                    color: _navyBlue.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }
  }
}

// ============================================================================
// CHANGE PASSWORD DIALOG — now calls auditor/profile.php (POST with password)
// ============================================================================
class _ChangePasswordDialog extends StatefulWidget {
  final int userId;
  final String name;
  final String email;
  final String phone;

  const _ChangePasswordDialog({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  bool _obsNew = true;
  bool _obsConf = true;
  bool _isSubmitting = false;

  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (newPass.isEmpty) {
      ToastService.show(
          title: 'Error',
          message: 'Enter a new password.',
          type: ToastType.error);
      return;
    }
    if (newPass != confirmPass) {
      ToastService.show(
          title: 'Error',
          message: 'Passwords do not match.',
          type: ToastType.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuditorProfileService.instance.updateProfile(
        userId: widget.userId,
        name: widget.name,
        email: widget.email,
        phone: widget.phone,
        password: newPass,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ToastService.show(
          title: 'Password Updated',
          message: 'Your login credentials have been changed successfully.',
          type: ToastType.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ToastService.show(
          title: 'Error', message: e.toString(), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navyBlue = const Color(0xFF1B233A);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(32)),
        child: Stack(
          children: [
            // Faint watermark mimicking the hashtag in the design
            Positioned(
              right: 0,
              top: 20,
              child: Icon(Icons.tag,
                  size: 80, color: const Color(0xFFF1F5F9).withOpacity(0.5)),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CHANGE PASSWORD',
                              style: TextStyle(
                                  color: navyBlue,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          const Text('UPDATE YOUR LOGIN PASSWORD',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 1.0)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close,
                          color: Color(0xFF94A3B8), size: 18),
                      style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF8FAFC),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.all(8)),
                    )
                  ],
                ),
                const SizedBox(height: 32),
                const Text('NEW PASSWORD',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.0)),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPassCtrl,
                  obscureText: _obsNew,
                  style: TextStyle(
                      color: navyBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 2.0),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide:
                            BorderSide(color: AppColors.kPrimary, width: 2)),
                    suffixIcon: IconButton(
                        icon: Icon(
                            _obsNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFFCBD5E1),
                            size: 18),
                        onPressed: () => setState(() => _obsNew = !_obsNew)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('CONFIRM PASSWORD',
                    style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.0)),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPassCtrl,
                  obscureText: _obsConf,
                  style: TextStyle(
                      color: navyBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 2.0),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide:
                            BorderSide(color: AppColors.kPrimary, width: 2)),
                    suffixIcon: IconButton(
                        icon: Icon(
                            _obsConf
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFFCBD5E1),
                            size: 18),
                        onPressed: () => setState(() => _obsConf = !_obsConf)),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.security, size: 16),
                  label: Text(_isSubmitting ? 'UPDATING...' : 'UPDATE PASSWORD',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
