import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'customer_feedback_section.dart';
import '../../models/customer_profile_model.dart';
import '../../services/customer_profile_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// Profile page for the customer role.
///
/// Backed entirely by endpoints that already exist:
///   * `customer/profile.php`         — identity, KYC, bank, wallet, stats
///   * `customer/update_profile.php`  — the EDIT form
///   * `customer/change_password.php` — ACCOUNT SECURITY
///   * `customer/get_feedback.php` / `customer/submit_feedback.php`
///
/// AuditorProfileScreen cannot be reused: `auditor/profile.php` rejects any
/// account whose role is not `auditor`.
class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  // Design tokens, matching the rest of the portal.
  static const Color _navy = Color(0xFF1B233A);
  static const Color _royal = AppColors.kPrimary;
  static const Color _slate = AppColors.kTextMuted;
  static const Color _label = Color(0xFFCBD5E1);
  static const Color _hairline = Color(0xFFF1F5F9);

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNoCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  CustomerProfile? _profile;
  String? _loadError;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNoCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await CustomerProfileService.instance.fetchProfile();
      if (!mounted) return;
      _applyProfile(profile);
      setState(() {
        _profile = profile;
        _loadError = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loading = false;
      });
    }
  }

  void _applyProfile(CustomerProfile profile) {
    _nameCtrl.text = profile.name;
    _emailCtrl.text = profile.email;
    _phoneCtrl.text = profile.phone;
    _addressCtrl.text = profile.address;
    _bankNameCtrl.text = profile.bankName;
    _accountNoCtrl.text = profile.accountNo;
    _ifscCtrl.text = profile.ifscCode;
  }

  void _reload() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  Future<void> _save() async {
    final current = _profile;
    if (current == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final updated = await CustomerProfileService.instance.updateProfile(
        current: current,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        bankName: _bankNameCtrl.text.trim(),
        accountNo: _accountNoCtrl.text.trim(),
        ifscCode: _ifscCtrl.text.trim(),
      );

      // Keep the cached session in step so the header and drawer stop showing
      // the old name and email as soon as the save lands.
      final user = SessionService.instance.currentUser;
      if (user != null) {
        await SessionService.instance.updateCurrentUser(
          user.copyWith(
            name: updated.name,
            email: updated.email,
            phone: updated.phone,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _profile = updated;
        _saving = false;
        _editing = false;
      });
      ToastService.show(
        title: 'Saved',
        message: 'Your profile has been updated.',
        type: ToastType.success,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ToastService.show(
        title: 'Could not save',
        message: '$error',
        type: ToastType.error,
      );
    }
  }

  void _cancelEdit() {
    if (_profile != null) _applyProfile(_profile!);
    setState(() => _editing = false);
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (changed == true && mounted) {
      ToastService.show(
        title: 'Password updated',
        message: 'Use your new password the next time you sign in.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _terminateSession() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'END SESSION',
      message:
          'You will be signed out on this device. Your account and data are '
          'not affected.',
      confirmLabel: 'SIGN OUT',
    );
    if (confirmed == true) {
      // The router listens to SessionService, so clearing it redirects to
      // /login on its own.
      await SessionService.instance.logout();
    }
  }

  String _money(double value) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
          .format(value);

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // custom header, to match the rest of the portal
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800), 
            child: _body(),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
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
            const Icon(Icons.error_outline, color: AppColors.kDanger, size: 40),
            const SizedBox(height: 16),
            Text(
              _loadError ?? 'Could not load profile.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _reload, child: const Text('RETRY')),
          ],
        ),
      );
    }

    final profile = _profile!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(),
        const SizedBox(height: 24),
        _headerCard(profile),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _editing ? _attributesEdit() : _attributesView(profile),
        ),
        if (!_editing) ...[
          const SizedBox(height: 24),
          _verificationCard(profile),
          const SizedBox(height: 24),
          _summaryCard(profile),
          const SizedBox(height: 24),
          _securityCard(),
          const SizedBox(height: 24),
          const CustomerFeedbackSection(),
          const SizedBox(height: 40),
        ],
      ],
    );
  }

  // ==========================================================================
  // TITLE + HEADER
  // ==========================================================================

  Widget _title() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: AppColors.goldColor, size: 10),
            SizedBox(width: 6),
            Text(
              'MY ACCOUNT',
              style: TextStyle(
                color: AppColors.goldColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'MY PROFILE',
          style: TextStyle(
            color: _navy,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'MANAGE YOUR ACCOUNT DETAILS AND PASSWORD',
          style: TextStyle(
            color: _slate,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _headerCard(CustomerProfile profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_royal, AppColors.kPrimaryDark],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          _avatar(profile),
          const SizedBox(height: 16),
          Text(
            profile.name.isEmpty ? 'CUSTOMER' : profile.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _goldPill(
                'MEMBER ID: '
                '${profile.customerId.isEmpty ? 'NOT SET' : profile.customerId}',
              ),
              _goldPill(_kycLabel(profile.kycStatus)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'REFERRAL: '
              '${profile.referralCode.isEmpty ? 'NOT SET' : profile.referralCode}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(CustomerProfile profile) {
    final hasPhoto = profile.avatar.isNotEmpty;

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 4),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              ApiConfig.fileUrl(profile.avatar),
              fit: BoxFit.cover,
              // A missing or moved upload must not blank the header.
              errorBuilder: (_, __, ___) => _avatarFallback(profile),
            )
          : _avatarFallback(profile),
    );
  }

  Widget _avatarFallback(CustomerProfile profile) {
    return Container(
      color: const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            profile.initials,
            style: const TextStyle(
              color: _royal,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Text(
            'NO PHOTO',
            style: TextStyle(
              color: _label,
              fontSize: 6,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _goldPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.goldBadgeBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.goldColor,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _kycLabel(String status) => switch (status) {
        'verified' => 'KYC VERIFIED',
        'rejected' => 'KYC REJECTED',
        _ => 'KYC PENDING',
      };

  // ==========================================================================
  // PROFILE ATTRIBUTES
  // ==========================================================================

  Widget _attributesView(CustomerProfile profile) {
    return _card(
      key: const ValueKey('view'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.edit_outlined, 'PROFILE ATTRIBUTES'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => setState(() => _editing = true),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.kBackground,
                foregroundColor: _navy,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'EDIT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _viewField('FULL NAME', profile.name, Icons.person_outline_rounded),
          _viewField('EMAIL', profile.email, Icons.mail_outline_rounded),
          _viewField('PHONE NUMBER', profile.phone, Icons.phone_outlined),
          _viewField('ADDRESS', profile.address, Icons.location_on_outlined),
          _viewField(
              'BANK NAME', profile.bankName, Icons.account_balance_outlined),
          _viewField('ACCOUNT NUMBER', profile.accountNo, Icons.tag_rounded),
          _viewField('IFSC CODE', profile.ifscCode, Icons.qr_code_2_rounded,
              isLast: true),
        ],
      ),
    );
  }

  Widget _viewField(String label, String value, IconData icon,
      {bool isLast = false}) {
    final empty = value.trim().isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _label,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.kBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: empty ? _label : _slate),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    empty ? 'NOT ADDED' : value,
                    style: TextStyle(
                      color: empty ? _label : _navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
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

  Widget _attributesEdit() {
    return _card(
      key: const ValueKey('edit'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(Icons.edit, 'PROFILE ATTRIBUTES'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save, size: 16),
                    label: Text(
                      _saving ? 'SAVING…' : 'SAVE',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _cancelEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _royal,
                      side: const BorderSide(color: Color(0xFFEFF6FF), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _editField(
              'FULL NAME',
              Icons.person_outline_rounded,
              _nameCtrl,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Name is required.' : null,
            ),
            _editField(
              'EMAIL',
              Icons.mail_outline_rounded,
              _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Email is required.';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            _editField(
              'PHONE NUMBER',
              Icons.phone_outlined,
              _phoneCtrl,
              keyboardType: TextInputType.phone,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Phone is required.';
                if (value.replaceAll(RegExp(r'\D'), '').length < 10) {
                  return 'Enter a valid phone number.';
                }
                return null;
              },
            ),
            _editField(
              'ADDRESS',
              Icons.location_on_outlined,
              _addressCtrl,
              maxLines: 3,
            ),
            _editField(
                'BANK NAME', Icons.account_balance_outlined, _bankNameCtrl),
            _editField(
              'ACCOUNT NUMBER',
              Icons.tag_rounded,
              _accountNoCtrl,
              keyboardType: TextInputType.number,
            ),
            _editField(
              'IFSC CODE',
              Icons.qr_code_2_rounded,
              _ifscCtrl,
              textCapitalization: TextCapitalization.characters,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _label,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.goldColor, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.goldColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // VERIFICATION & BANK
  // ==========================================================================

  Widget _verificationCard(CustomerProfile profile) {
    final verified = profile.isKycVerified;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.verified_user_outlined, 'VERIFICATION & BANK'),
          const SizedBox(height: 24),
          const Text(
            'KYC STATUS',
            style: TextStyle(
              color: _label,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: verified
                    ? AppColors.kSuccess.withOpacity(0.10)
                    : AppColors.goldBadgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _kycLabel(profile.kycStatus),
                style: TextStyle(
                  color:
                      verified ? AppColors.kSuccess : AppColors.goldColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'AADHAAR: '
            '${profile.hasAadhar ? CustomerProfile.mask(profile.aadharNo) : 'NOT ADDED'}',
            style: const TextStyle(
              color: _slate,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          _walletTile(profile),
          const SizedBox(height: 16),
          _documentTile(
            icon: Icons.badge_outlined,
            title: 'AADHAAR CARD',
            value: profile.hasAadhar
                ? CustomerProfile.mask(profile.aadharNo)
                : 'NOT ADDED YET',
            added: profile.hasAadhar,
          ),
          const SizedBox(height: 10),
          _documentTile(
            icon: Icons.credit_card_outlined,
            title: 'PAN CARD',
            value: profile.hasPan
                ? CustomerProfile.mask(profile.panNo)
                : 'NOT ADDED YET',
            added: profile.hasPan,
          ),
        ],
      ),
    );
  }

  Widget _walletTile(CustomerProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kPrimaryDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WALLET BALANCE',
                  style: TextStyle(
                    color: AppColors.goldColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _money(profile.walletBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/auditor-wallets'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MANAGE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0,
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentTile({
    required IconData icon,
    required String title,
    required String value,
    required bool added,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      // KYC documents are uploaded on the KYC screen, not here.
      onTap: () => context.push('/auditor-kyc'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 18, color: added ? AppColors.kSuccess : _royal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: added ? _slate : _label,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _label, size: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // MY SUMMARY
  // ==========================================================================

  Widget _summaryCard(CustomerProfile profile) {
    final stats = profile.stats;
    final since = profile.createdAt;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.goldColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'MY SUMMARY',
                style: TextStyle(
                  color: _navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _summaryRow('TOTAL INVESTED', _money(stats.totalInvested),
              Icons.trending_up_rounded, AppColors.kInfo),
          _summaryRow('CASHBACK EARNED', _money(stats.totalCashback),
              Icons.savings_outlined, AppColors.kSuccess),
          _summaryRow('ACTIVE PLANS', '${stats.activeCycles}',
              Icons.shield_outlined, AppColors.kWarning),
          _summaryRow('REFERRALS', '${stats.referralCount}',
              Icons.emoji_events_outlined, _royal),
          _summaryRow(
            'MEMBER SINCE',
            since == null ? '—' : DateFormat('MMM yyyy').format(since),
            Icons.calendar_month_outlined,
            _slate,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, IconData icon, Color color,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _label,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ACCOUNT SECURITY
  // ==========================================================================

  Widget _securityCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.kPrimaryDark,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ACCOUNT\nSECURITY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Icon(Icons.shield_outlined,
                  color: Colors.white.withOpacity(0.25), size: 44),
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _changePassword,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'CHANGE PASSWORD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'TWO-FACTOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                // Sign-in already sends a one-time code (auth/verify_login_otp.php),
                // so this reports that rather than offering a toggle there is
                // no endpoint to back.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.goldColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _terminateSession,
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text(
                'TERMINATE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SHARED BITS
  // ==========================================================================

  Widget _card({required Widget child, Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _hairline, width: 2),
      ),
      child: child,
    );
  }

  Widget _cardHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.kPrimaryDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CHANGE PASSWORD
// ============================================================================

/// `customer/change_password.php` overwrites the password without checking
/// the old one, so the confirmation field is the only guard against a typo
/// locking the account out.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await CustomerProfileService.instance
          .changePassword(newPassword: _passwordCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ToastService.show(
        title: 'Could not update password',
        message: '$error',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'CHANGE PASSWORD',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'New password',
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v ?? '').length < 6 ? 'Use at least 6 characters.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscure,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              validator: (v) =>
                  v == _passwordCtrl.text ? null : 'Passwords do not match.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'SAVING…' : 'UPDATE'),
        ),
      ],
    );
  }
}
