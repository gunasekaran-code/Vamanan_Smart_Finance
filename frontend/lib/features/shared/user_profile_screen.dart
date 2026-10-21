import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/models/investment_history_model.dart'
    show InvestmentHistoryRecord;
import 'package:frontend/models/wallet_account_model.dart' show WalletAccount;
import 'package:frontend/services/wallet_account_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/admin_user_model.dart';
import '../../models/customer_profile_model.dart';
import '../../services/admin_users_service.dart';
import '../../services/customer_profile_service.dart';

/// Full profile of one platform user, opened from the investor directory.
///
/// Everything is read from existing endpoints — no backend change needed:
///   * customer/profile.php → contact, KYC, bank, referral code, stats
///   * admin/wallets.php    → total earned / withdrawn
///   * customer/orders.php  → purchases, total paid, cashback principal
///   * admin/all_users.php  → role, account status, referrer (only when the
///     directory didn't hand the user over, e.g. after a browser refresh)
///
/// The page polls every [_refreshInterval] so it stays live while open.
/// all_users.php and investment_history.php are deliberately kept out of the
/// poll: both call runMigrations(), which re-runs `ALTER TABLE users MODIFY`
/// on every request and locks the table — polling them stalled every other
/// screen (including the directory you return to) for seconds.
///
/// Opened as the `/users/profile?id=N` child route so the app header shows a
/// back arrow. [initialUser] (the route's `extra`) only fills the header
/// instantly — a browser refresh drops it and the page loads by [userId].
class UserProfileScreen extends StatefulWidget {
  final int userId;
  final AdminUserModel? initialUser;

  const UserProfileScreen({super.key, required this.userId, this.initialUser});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const Duration _refreshInterval = Duration(seconds: 15);

  static const Color _navy = Color(0xFF243D8F);
  static const Color _gold = Color(0xFFF7C948);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _placeholder = Color(0xFFCBD5E1);
  static const Color _border = Color(0xFFE8EEF6);
  static const Color _surface = Color(0xFFF8FAFC);

  final WalletService _walletService = WalletService();

  late AdminUserModel? _user = widget.initialUser;
  CustomerProfile? _profile;
  WalletAccount? _wallet;
  List<InvestmentHistoryRecord> _purchases = const [];

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  DateTime? _updatedAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(_refreshInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    final id = widget.userId.toString();
    String? profileError;

    // Fire the requests together. Only the profile is required — the
    // others keep their last known value if they fail.
    final profileFuture = CustomerProfileService.instance
        .fetchProfile(userId: id)
        .then<CustomerProfile?>((p) => p, onError: (Object e) {
      profileError = e is CustomerProfileException
          ? e.message
          : 'Could not load this profile.';
      return null;
    });
    final walletsFuture = _walletService
        .fetchWallets()
        .then<List<WalletAccount>?>((w) => w, onError: (Object _) => null);
    final ordersFuture = _fetchOrders(id);
    final usersFuture =
        _user == null ? AdminUsersService.instance.fetchUsers() : null;

    final profile = await profileFuture;
    final wallets = await walletsFuture;
    final orders = await ordersFuture;
    final users = await usersFuture;
    if (!mounted) return;

    setState(() {
      _refreshing = false;
      if (profile == null) {
        // Keep showing the last good data on a failed background poll; a
        // manual refresh tells the admin why nothing changed.
        _error = profileError;
        _loading = false;
        if (_profile != null && !silent) {
          ToastService.show(
              title: 'Refresh Failed',
              message: profileError ?? 'Could not refresh this profile.',
              type: ToastType.error);
        }
        return;
      }

      _profile = profile;
      _error = null;
      _loading = false;
      _updatedAt = DateTime.now();

      if (wallets != null) {
        _wallet = wallets.where((w) => w.userId == id).firstOrNull;
      }
      if (orders != null) {
        // Same scope as the investment-history view: approved purchases only.
        _purchases = orders.where((o) => o.status != 'pending').toList();
      }
      if (users != null && users.success && users.data != null) {
        final fresh = users.data!.where((u) => u.id == widget.userId).firstOrNull;
        if (fresh != null) _user = fresh;
      }
    });
  }

  /// GET customer/orders.php?user_id=N — just this user's cashback cycles,
  /// so nothing platform-wide is downloaded on every poll. Null on failure.
  Future<List<InvestmentHistoryRecord>?> _fetchOrders(String userId) async {
    try {
      final uri = ApiConfig.endpoint(CustomerEndpoints.orders)
          .replace(queryParameters: {'user_id': userId});
      final res = await http.get(uri).timeout(ApiConfig.timeout);
      final body = jsonDecode(res.body);
      if (body is! Map || body['status'] != 'success') return null;
      final rows = body['data'];
      if (rows is! List) return null;
      return rows
          .whereType<Map>()
          .map((e) =>
              InvestmentHistoryRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          return Column(
            children: [
              _header(isTablet),
              Expanded(child: _body(isTablet)),
            ],
          );
        },
      ),
      bottomNavigationBar: _footer(),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _header(bool isTablet) {
    final p = _profile;
    final u = _user;
    final role = _role;
    final customerId = p?.customerId.isNotEmpty == true
        ? p!.customerId
        : (u == null || u.customerId.isEmpty ? '—' : u.customerId);
    final email = p?.email.isNotEmpty == true ? p!.email : (u?.email ?? '');
    final name = p?.name.isNotEmpty == true ? p!.name : (u?.name ?? '');

    return Container(
      width: double.infinity,
      color: _navy,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  isTablet ? 32 : 20, 20, isTablet ? 20 : 8, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isTablet ? 64 : 56,
                    height: isTablet ? 64 : 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.account_circle_outlined,
                        color: _gold, size: isTablet ? 34 : 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$role PROFILE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _gold,
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3)),
                        const SizedBox(height: 4),
                        Text(name.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 26 : 22,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        Text('$customerId · ${email.isEmpty ? '—' : email}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFFB9C5E5), fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _refreshing ? null : () => _load(),
                    icon: _refreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------

  Widget _body(bool isTablet) {
    if (_loading && _profile == null) {
      return const Center(child: AppLoader());
    }
    if (_profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Could not load this profile.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFDC2626))),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('RETRY')),
            ],
          ),
        ),
      );
    }

    final p = _profile!;
    final hPad = isTablet ? 32.0 : 20.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chips(p),
                const SizedBox(height: 28),
                _section('CONTACT'),
                _grid(2, [
                  _detail('CUSTOMER ID', p.customerId, icon: Icons.tag),
                  _detail('JOINED', _formatDate(p.createdAt ?? _user?.createdAt),
                      icon: Icons.calendar_today_outlined),
                  _detail('EMAIL', p.email, icon: Icons.mail_outline),
                  _detail('PHONE', p.phone, icon: Icons.phone_outlined),
                  _detail('ADDRESS', p.address,
                      icon: Icons.location_on_outlined),
                ]),
                const SizedBox(height: 28),
                _section('KYC & BANK'),
                _grid(2, [
                  _detail('AADHAAR', p.aadharNo),
                  _detail('PAN', p.panNo.toUpperCase()),
                  _detail('BANK', p.bankName,
                      icon: Icons.account_balance_outlined),
                  _detail('ACCOUNT / IFSC', _accountIfsc(p)),
                ]),
                const SizedBox(height: 28),
                _section('REFERRAL'),
                _grid(2, [
                  _detail('REFERRAL CODE', p.referralCode,
                      icon: Icons.people_outline),
                  _detail('REFERRED BY', _referredBy()),
                  _detail('DIRECT REFERRALS', '${p.stats.referralCount}'),
                ]),
                const SizedBox(height: 28),
                _section('WALLET & PURCHASES'),
                _stats(p, isTablet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chips(CustomerProfile p) {
    final role = _role;
    final status =
        (_user?.status ?? '').isEmpty ? 'ACTIVE' : _user!.status;
    final kyc = (p.kycStatus.isNotEmpty ? p.kycStatus : _user?.kycStatus ?? '')
        .toLowerCase();

    final (statusBg, statusFg) = switch (status) {
      'ACTIVE' => (const Color(0xFFECFDF5), const Color(0xFF047857)),
      'SUSPENDED' => (const Color(0xFFFEF2F2), const Color(0xFFB91C1C)),
      _ => (const Color(0xFFFFFBEB), const Color(0xFF9A6A14)),
    };
    final (kycBg, kycFg, kycIcon) = switch (kyc) {
      'verified' || 'approved' => (
          const Color(0xFFECFDF5),
          const Color(0xFF047857),
          Icons.verified_user_outlined
        ),
      'rejected' => (
          const Color(0xFFFEF2F2),
          const Color(0xFFB91C1C),
          Icons.gpp_bad_outlined
        ),
      _ => (
          const Color(0xFFFFFBEB),
          const Color(0xFF9A6A14),
          Icons.shield_outlined
        ),
    };

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip(role, const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
        _chip('ACCOUNT: $status', statusBg, statusFg),
        _chip('KYC ${(kyc.isEmpty ? 'pending' : kyc).toUpperCase()}', kycBg,
            kycFg,
            icon: kycIcon),
      ],
    );
  }

  Widget _stats(CustomerProfile p, bool isTablet) {
    final w = _wallet;
    final balance = w?.balance ?? p.walletBalance;
    final earned = w?.totalEarned ?? p.stats.totalEarned;
    final withdrawn = w?.totalWithdrawn ?? 0;
    final active = _purchases.where((x) => x.status == 'active').length;
    final totalPaid =
        _purchases.fold<double>(0, (sum, x) => sum + x.displayAmount);
    final principal =
        _purchases.fold<double>(0, (sum, x) => sum + x.cashbackEligibleAmount);

    return _grid(
      isTablet ? 3 : 2,
      [
        _stat('WALLET BALANCE', _inr(balance), _navy),
        _stat('TOTAL EARNED', _inr(earned), const Color(0xFFB98D13)),
        _stat('WITHDRAWN', _inr(withdrawn), _navy),
        _stat('PURCHASES', '${_purchases.length} ($active active)', _navy),
        _stat('TOTAL PAID (INCL. GST)', _inr(totalPaid), _navy),
        _stat('CASHBACK PRINCIPAL', _inr(principal), _navy),
      ],
      spacing: 14,
      runSpacing: 14,
    );
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _footer() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFF22C55E), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Live · refreshes every ${_refreshInterval.inSeconds}s',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _updatedAt == null
                    ? 'Updating…'
                    : 'Updated ${DateFormat('hh:mm:ss a').format(_updatedAt!)}',
                style: const TextStyle(
                    color: _muted, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------------

  /// Lays [children] out in [columns] equal columns, dropping to a single
  /// column on very narrow phones so long values never get squeezed.
  Widget _grid(int columns, List<Widget> children,
      {double spacing = 20, double runSpacing = 20}) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth < 320 ? 1 : columns;
      final width = (constraints.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    });
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(text,
            style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                fontSize: 14)),
      );

  Widget _chip(String text, Color bg, Color fg, {IconData? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fg.withValues(alpha: .18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(text,
                style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
          ],
        ),
      );

  Widget _detail(String label, String value, {IconData? icon}) {
    final empty = value.trim().isEmpty || value.trim() == '—';
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6)),
        const SizedBox(height: 4),
        Text(empty ? 'Not provided' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: empty ? _placeholder : _navy,
                fontSize: 16,
                fontWeight: empty ? FontWeight.w600 : FontWeight.w700)),
      ],
    );
    if (icon == null) return content;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Icon(icon, size: 18, color: _muted),
        ),
        const SizedBox(width: 14),
        Expanded(child: content),
      ],
    );
  }

  Widget _stat(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 2,
                style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------------

  String get _role =>
      (_user?.role ?? '').isEmpty ? 'CUSTOMER' : _user!.role;

  String _accountIfsc(CustomerProfile p) {
    final parts = [p.accountNo, p.ifscCode.toUpperCase()]
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.join(' / ');
  }

  String _referredBy() {
    final name = _user?.referrerName;
    if (name == null || name.trim().isEmpty) return '';
    final id = _user?.referrerCustomerId;
    return id == null || id.isEmpty ? name : '$name ($id)';
  }

  static String _formatDate(DateTime? d) =>
      d == null ? '' : DateFormat('dd MMM yyyy').format(d);

  /// ₹ with Indian digit grouping; paise only when there are any.
  static String _inr(double value) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: value == value.roundToDouble() ? 0 : 2,
      ).format(value);
}
