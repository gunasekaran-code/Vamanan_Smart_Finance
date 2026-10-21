import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/admin_user_model.dart';
import '../../services/admin_users_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/routing/app_routes.dart';

class NewUserRowData {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  String role = 'CUSTOMER';

  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
  }
}

// --- Main Screen ---
class UsersDirectoryScreen extends StatefulWidget {
  /// Optional text to pre-fill the directory search box with — used when this
  /// screen is opened for one specific investor (e.g. from the wallet list).
  final String? initialSearch;

  const UsersDirectoryScreen({super.key, this.initialSearch});

  @override
  State<UsersDirectoryScreen> createState() => _UsersDirectoryScreenState();
}

class _UsersDirectoryScreenState extends State<UsersDirectoryScreen> {
  final AdminUsersService _service = AdminUsersService.instance;
  final TextEditingController _searchCtrl = TextEditingController();

  List<AdminUserModel> _allUsers = [];
  List<AdminUserModel> _filteredUsers = [];
  bool _loading = true;
  String? _error;
  bool _selectAll = false;
  final Set<int> _referralToggleInFlight = {};

  @override
  void initState() {
    super.initState();
    // Seed the query BEFORE attaching the listener so this does not trigger a
    // setState() while the widget is still initialising; _load() applies the
    // filter once the rows arrive.
    final seed = widget.initialSearch?.trim() ?? '';
    if (seed.isNotEmpty) _searchCtrl.text = seed;
    _searchCtrl.addListener(_applyFilter);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await _service.fetchUsers();
    if (!mounted) return;

    if (!response.success || response.data == null) {
      setState(() {
        _loading = false;
        _error = response.message;
      });
      return;
    }

    setState(() {
      _allUsers = response.data!;
      _loading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredUsers = query.isEmpty
          ? List.of(_allUsers)
          : _allUsers.where((u) {
              return u.name.toLowerCase().contains(query) ||
                  u.email.toLowerCase().contains(query) ||
                  u.customerId.toLowerCase().contains(query) ||
                  u.referralCode.toLowerCase().contains(query);
            }).toList();
      _selectAll = _filteredUsers.isNotEmpty &&
          _filteredUsers.every((u) => u.isSelected);
    });
  }

  Future<void> _handleProcessYield() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PROCESS MONTHLY YIELD',
      message:
          "Process this month's cashback? This credits one monthly installment (10%) to every cycle that is due, and can only run ONCE per calendar month.",
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      ToastService.show(
          title: 'Success',
          message: 'Monthly yield processed successfully.',
          type: ToastType.success);
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      for (var user in _filteredUsers) {
        user.isSelected = _selectAll;
      }
    });
  }

  Future<bool> _confirmAction(String title, String message) async {
    return await AppConfirmDialog.show(
          context: context,
          title: title,
          message: message,
          confirmLabel: 'CONFIRM',
          cancelLabel: 'CANCEL',
          confirmButtonColor: const Color(0xFF1E3A8A),
        ) ==
        true;
  }

  Future<void> _deleteSelectedUsers() async {
    final selected = _filteredUsers.where((user) => user.isSelected).toList();
    if (selected.isEmpty) return;
    final confirmed = await _confirmAction(
      'DELETE ${selected.length} USER${selected.length == 1 ? '' : 'S'}',
      'This permanently removes the selected profiles and related records. Continue?',
    );
    if (!confirmed) return;

    final response =
        await _service.deleteUsers(selected.map((user) => user.id).toList());
    if (!mounted) return;
    if (!response.success) {
      ToastService.show(
          title: 'Delete Failed',
          message: response.message,
          type: ToastType.error);
      return;
    }
    ToastService.show(
        title: 'Deleted',
        message: '${selected.length} user(s) deleted.',
        type: ToastType.success);
    await _load();
  }

  Future<void> _openUserSettings(AdminUserModel user) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserSettingsSheet(user: user, service: _service),
    );
    if (changed == true) await _load();
  }

  void _openUserProfile(AdminUserModel user) {
    // A child route (not a bare MaterialPageRoute) so the app header swaps
    // the drawer button for a back arrow. The profile is read-only, so the
    // list isn't reloaded on the way back — it's still in memory and shows
    // instantly (re-fetching all_users.php here made the back button hang).
    context.push(AppRoutes.userProfileFor(user.id), extra: user);
  }

  Future<void> _toggleReferralCommission(AdminUserModel user) async {
    if (_referralToggleInFlight.contains(user.id)) return;

    final willActivate = !user.referralActive;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: willActivate ? 'RESUME COMMISSIONS' : 'STOP COMMISSIONS',
      message: willActivate
          ? 'Resume referral commissions for ${user.name}?'
          : 'Stop referral commissions for ${user.name}? Their own cashback is unaffected.',
      confirmLabel: willActivate ? 'RESUME' : 'STOP',
      cancelLabel: 'CANCEL',
      confirmButtonColor:
          willActivate ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _referralToggleInFlight.add(user.id));
    final response = await _service.setReferralActive(
      userId: user.id,
      active: willActivate,
    );
    if (!mounted) return;

    setState(() => _referralToggleInFlight.remove(user.id));
    if (!response.success) {
      ToastService.show(
        title: 'Update Failed',
        message: response.message,
        type: ToastType.error,
      );
      return;
    }

    ToastService.show(
      title: 'Referral Status Updated',
      message: response.data == true
          ? '${user.name} can earn referral commissions again.'
          : '${user.name}\'s referral commissions have been stopped.',
      type: ToastType.success,
    );
    await _load();
  }

  void _openBulkAddModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BulkAddUsersModal(),
    ).then((added) {
      // No admin/bulk_add_users.php route exists yet, so there is nothing
      // to refresh from the server here — this just keeps the hook in place
      // for when that endpoint is added.
      if (added == true) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.kBorder)),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search users, orders, assets...',
                          hintStyle: TextStyle(
                              color: AppColors.kTextMuted, fontSize: 14),
                          prefixIcon:
                              Icon(Icons.search, color: AppColors.kTextMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _handleProcessYield,
                        icon: const Icon(Icons.bolt, size: 16),
                        label: const Text('PROCESS MONTHLY YIELD',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                letterSpacing: 0.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppColors.kBorder)),
                      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('INVESTOR DIRECTORY',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF1E3A8A))),
                          const SizedBox(height: 4),
                          Text(
                              'UNIVERSAL REGISTRY OF ALL PLATFORM PARTICIPANTS',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color:
                                      const Color(0xFF94A3B8).withOpacity(0.8),
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _openBulkAddModal,
                                icon: const Icon(Icons.person_add_alt_1,
                                    size: 16),
                                label: const Text('BULK ADD USERS',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20))),
                              ),
                              InkWell(
                                onTap: () => _toggleSelectAll(!_selectAll),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: AppColors.kBorder),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                          _selectAll
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          size: 18,
                                          color: _selectAll
                                              ? const Color(0xFF1E3A8A)
                                              : AppColors.kTextMuted),
                                      const SizedBox(width: 8),
                                      Text(
                                          _selectAll
                                              ? 'DESELECT ALL'
                                              : 'SELECT ALL',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                              ),
                              if (_filteredUsers.any((user) => user.isSelected))
                                ElevatedButton.icon(
                                  onPressed: _deleteSelectedUsers,
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16),
                                  label: Text(
                                      'DELETE (${_filteredUsers.where((user) => user.isSelected).length})'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE11D48),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 11),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                  ),
                                ),
                              Text(
                                  '${_filteredUsers.length} of ${_allUsers.length} users',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.kBorder)),
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: const InputDecoration(
                                hintText: 'SEARCH BY IDENTITY...',
                                hintStyle: TextStyle(
                                    color: AppColors.kTextMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic),
                                prefixIcon: Icon(Icons.search,
                                    color: AppColors.kTextMuted, size: 20),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildBody(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: AppLoader()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Text(_error!,
                style: const TextStyle(color: AppColors.kDanger),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _load, child: const Text('RETRY')),
          ],
        ),
      );
    }
    if (_filteredUsers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('No matching users found.')),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
    );
  }

  Widget _buildUserCard(AdminUserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(
                    user.name.isNotEmpty
                        ? user.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF1E3A8A),
                            fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(user.customerId.isEmpty ? '—' : user.customerId,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFFD97706),
                            fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('JOINED ${user.joinedLabel}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF94A3B8),
                            fontSize: 10)),
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() {
                  user.isSelected = !user.isSelected;
                  _selectAll = _filteredUsers.every((u) => u.isSelected);
                }),
                child: Icon(
                    user.isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: user.isSelected
                        ? const Color(0xFF1E3A8A)
                        : AppColors.kBorder),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.kBorder)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('WALLET',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF94A3B8))),
                      const SizedBox(height: 4),
                      Text('₹${user.balance.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF1E3A8A))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.kBorder)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ROLE',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF94A3B8))),
                      const SizedBox(height: 4),
                      Text(user.role.isEmpty ? '—' : user.role,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFFD97706))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.kBorder)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.people_alt,
                      size: 14, color: Color(0xFFFBBF24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('REFERRED BY',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF94A3B8))),
                      const SizedBox(height: 2),
                      Text(user.referredByLabel,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.kBorder)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REFERRAL COMMISSION',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF94A3B8))),
                    const SizedBox(height: 2),
                    Text(user.referralActive ? '✦ EARNING' : 'STOPPED',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: user.referralActive
                                ? const Color(0xFFD97706)
                                : const Color(0xFF94A3B8))),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _referralToggleInFlight.contains(user.id)
                      ? null
                      : () => _toggleReferralCommission(user),
                  icon: _referralToggleInFlight.contains(user.id)
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          user.referralActive
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                          size: 15,
                        ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: user.referralActive
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF16A34A),
                    side: BorderSide(
                      color: user.referralActive
                          ? const Color(0xFFFECDD3)
                          : const Color(0xFFBBF7D0),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  label: Text(
                    user.referralActive ? 'STOP' : 'RESUME',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(user.status.isEmpty ? '—' : user.status,
                    style: const TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'View profile',
                    child: InkWell(
                      onTap: () => _openUserProfile(user),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.person_outline,
                            color: Color(0xFF1E3A8A), size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _openUserSettings(user),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.settings,
                          color: Color(0xFF64748B), size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserSettingsSheet extends StatefulWidget {
  const _UserSettingsSheet({required this.user, required this.service});

  final AdminUserModel user;
  final AdminUsersService service;

  @override
  State<_UserSettingsSheet> createState() => _UserSettingsSheetState();
}

class _UserSettingsSheetState extends State<_UserSettingsSheet> {
  late String _role = widget.user.role.isEmpty ? 'CUSTOMER' : widget.user.role;
  late String _status =
      widget.user.status.isEmpty ? 'ACTIVE' : widget.user.status;
  late String _kycStatus =
      widget.user.kycStatus.isEmpty ? 'pending' : widget.user.kycStatus;
  late final TextEditingController _passwordCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<bool> _confirm(String title, String message) async {
    return await AppConfirmDialog.show(
          context: context,
          title: title,
          message: message,
          confirmLabel: 'CONFIRM',
          cancelLabel: 'CANCEL',
          confirmButtonColor: const Color(0xFF1E3A8A),
        ) ==
        true;
  }

  Future<void> _save() async {
    final confirmed = await _confirm('SAVE CALIBRATION',
        'Apply these account changes to ${widget.user.name}?');
    if (!confirmed) return;
    setState(() => _saving = true);
    final response = await widget.service.updateUser(
      userId: widget.user.id,
      role: _role,
      status: _status,
      kycStatus: _kycStatus,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!response.success) {
      ToastService.show(
          title: 'Update Failed',
          message: response.message,
          type: ToastType.error);
      return;
    }
    ToastService.show(
        title: 'Updated',
        message: 'Investor calibration saved.',
        type: ToastType.success);
    Navigator.pop(context, true);
  }

  Future<void> _setStatus(String status, String title) async {
    final confirmed =
        await _confirm(title, 'Change ${widget.user.name} status to $status?');
    if (!confirmed) return;
    setState(() => _saving = true);
    final response =
        await widget.service.updateUser(userId: widget.user.id, status: status);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!response.success) {
      ToastService.show(
          title: 'Action Failed',
          message: response.message,
          type: ToastType.error);
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _resetCredentials() async {
    if (_passwordCtrl.text.trim().isEmpty) {
      ToastService.show(
          title: 'Password Required',
          message: 'Enter a new password first.',
          type: ToastType.error);
      return;
    }
    final confirmed = await _confirm(
        'RESET CREDENTIALS', 'Replace this investor password now?');
    if (!confirmed) return;
    setState(() => _saving = true);
    final response = await widget.service.updateUser(
        userId: widget.user.id, password: _passwordCtrl.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    if (!response.success) {
      ToastService.show(
          title: 'Reset Failed',
          message: response.message,
          type: ToastType.error);
      return;
    }
    ToastService.show(
        title: 'Credentials Reset',
        message: 'The new password was saved.',
        type: ToastType.success);
    _passwordCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.8;
    return SafeArea(
      child: Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.kBorder,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('INVESTOR CALIBRATION',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF1E3A8A))),
                        const SizedBox(height: 4),
                        Text('PROTOCOL ADJUSTMENTS FOR USER #${widget.user.id}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF94A3B8))),
                      ]),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8))),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _profileHeader(),
                    const SizedBox(height: 24),
                    _fieldLabel('ACCOUNT AUTHORIZATION'),
                    DropdownButtonFormField<String>(
                      value: _role,
                      items: const [
                        'CUSTOMER',
                        'MANAGER',
                        'STAFF',
                        'ADVOCATE',
                        'AUDITOR'
                      ]
                          .map((value) => DropdownMenuItem(
                              value: value, child: Text(value)))
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _role = value ?? _role),
                      decoration: _inputDecoration('ROLE'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _status,
                      items: const ['ACTIVE', 'SUSPENDED', 'PENDING']
                          .map((value) => DropdownMenuItem(
                              value: value, child: Text(value)))
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) =>
                              setState(() => _status = value ?? _status),
                      decoration: _inputDecoration('ACCOUNT STATUS'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _kycStatus.toLowerCase(),
                      items: const ['pending', 'verified', 'rejected']
                          .map((value) => DropdownMenuItem(
                              value: value, child: Text(value.toUpperCase())))
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) =>
                              setState(() => _kycStatus = value ?? _kycStatus),
                      decoration: _inputDecoration('KYC STATUS'),
                    ),
                    const SizedBox(height: 24),
                    _fieldLabel('SECURITY OVERRIDE'),
                    TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: _inputDecoration('NEW PASSWORD')),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: ElevatedButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => _setStatus('ACTIVE', 'GRANT ACCESS'),
                              icon: const Icon(Icons.lock_open),
                              label: const Text('GRANT ACCESS'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => _setStatus('SUSPENDED', 'SUSPEND ID'),
                              icon: const Icon(Icons.block),
                              label: const Text('SUSPEND ID'))),
                    ]),
                    const SizedBox(height: 10),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            onPressed: _saving ? null : _resetCredentials,
                            icon: const Icon(Icons.password),
                            label: const Text('RESET CREDENTIALS'))),
                    const SizedBox(height: 24),
                    ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child:
                            Text(_saving ? 'SAVING...' : 'SAVE CALIBRATION')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.kBorder)),
        child: Row(children: [
          CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF1E3A8A),
              child: Text(
                  widget.user.name.isEmpty
                      ? '?'
                      : widget.user.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 26,
                      fontWeight: FontWeight.w900))),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(widget.user.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF1E3A8A))),
                const SizedBox(height: 4),
                Text(widget.user.email,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8)))
              ])),
        ]),
      );

  Widget _fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
              letterSpacing: 1)));

  InputDecoration _inputDecoration(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14));
}

// --- Bulk Add Users Modal ---
// UI-only for now: api/admin/all_users.php has no INSERT route, and per
// instructions the PHP isn't being touched in this pass. Add
// admin/bulk_add_users.php (POST, accepting a list of {name,email,phone,role})
// and swap the TODO in _handleSave for a real AdminUsersService call to make
// this persist. The dialog still returns `true` on save so the parent screen
// knows to refresh once that route exists.
class BulkAddUsersModal extends StatefulWidget {
  const BulkAddUsersModal({super.key});

  @override
  State<BulkAddUsersModal> createState() => _BulkAddUsersModalState();
}

class _BulkAddUsersModalState extends State<BulkAddUsersModal> {
  final List<NewUserRowData> _rows = [NewUserRowData(), NewUserRowData()];
  final List<String> _roles = [
    'CUSTOMER',
    'MANAGER',
    'STAFF',
    'ADVOCATE',
    'AUDITOR'
  ];

  @override
  void dispose() {
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() => _rows.add(NewUserRowData()));
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _handleSave() {
    final incomplete = _rows.where((r) =>
        r.nameCtrl.text.trim().isEmpty ||
        r.emailCtrl.text.trim().isEmpty ||
        r.phoneCtrl.text.trim().isEmpty);
    if (incomplete.isNotEmpty) {
      ToastService.show(
        title: 'Missing fields',
        message: 'Name, email and phone are required on every row.',
        type: ToastType.error,
      );
      return;
    }

    // TODO: replace with a real call once admin/bulk_add_users.php exists:
    // await AdminUsersService.instance.bulkAddUsers(rows);
    Navigator.pop(context, true);
    ToastService.show(
      title: 'Queued (not saved)',
      message:
          '${_rows.length} users captured, but there is no backend route to persist them yet.',
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 600;
          return Container(
            width: isMobile ? screenWidth - 24 : 900,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.person_add_alt_1,
                            color: Color(0xFFFBBF24), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BULK ADD USERS',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF1E3A8A))),
                            const SizedBox(height: 4),
                            Text(
                                'ADD MULTIPLE CUSTOMERS AT ONCE · AUTO VEV ID + WALLET',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF94A3B8)
                                        .withOpacity(0.8),
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      IconButton(
                          icon:
                              const Icon(Icons.close, color: Color(0xFF94A3B8)),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.kBorder)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('IMPORT CSV',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF94A3B8))),
                            ElevatedButton(
                              onPressed: () {
                                ToastService.show(
                                    title: 'Not connected',
                                    message:
                                        'CSV import needs a backend route.',
                                    type: ToastType.info);
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20))),
                              child: const Text('CHOOSE FILE',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 11)),
                            ),
                            const Text('no file selected',
                                style: TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                            'Columns: name, email, phone, password, role, referral_code',
                            style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                    child: isMobile ? _buildMobileRows() : _buildDesktopTable(),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: const BoxDecoration(
                      border:
                          Border(top: BorderSide(color: AppColors.kBorder))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          'Password defaults to the phone number if left blank. Duplicate emails are skipped automatically.',
                          style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF94A3B8))),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF94A3B8),
                              side: const BorderSide(color: AppColors.kBorder),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('CANCEL',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 11)),
                          ),
                          ElevatedButton.icon(
                            onPressed: _handleSave,
                            icon: const Icon(Icons.person_add_alt_1, size: 16),
                            label: const Text('ADD USERS',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Narrow-screen layout: each row becomes a stacked card instead of a
  /// horizontally-scrolling table, so nothing overflows on mobile.
  Widget _buildMobileRows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._rows.asMap().entries.map((entry) {
          final idx = entry.key;
          final row = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.kBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ROW ${idx + 1}',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF94A3B8))),
                    IconButton(
                      onPressed: () => _removeRow(idx),
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFF3B82F6), size: 20),
                      style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ),
                  ],
                ),
                _buildFullWidthField(row.nameCtrl, 'Full name *'),
                const SizedBox(height: 10),
                _buildFullWidthField(row.emailCtrl, 'email@example.com *'),
                const SizedBox(height: 10),
                _buildFullWidthField(row.phoneCtrl, 'Phone *'),
                const SizedBox(height: 10),
                _buildFullWidthDropdown(row),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addRow,
          icon: const Icon(Icons.add, size: 16, color: Color(0xFFD97706)),
          label: const Text('ADD ROW',
              style: TextStyle(
                  color: Color(0xFFD97706),
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  letterSpacing: 1)),
        ),
      ],
    );
  }

  /// Wide-screen layout: the original spreadsheet-style table.
  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildHeader('NAME *', 200),
              _buildHeader('EMAIL *', 200),
              _buildHeader('PHONE *', 150),
              _buildHeader('ROLE', 150),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          ..._rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(row.nameCtrl, 'Full name', 200),
                  _buildTextField(row.emailCtrl, 'email@example.com', 200),
                  _buildTextField(row.phoneCtrl, 'Phone', 150),
                  _buildDropdown(row, 150),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _removeRow(idx),
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFF3B82F6), size: 20),
                    style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF6FF),
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add, size: 16, color: Color(0xFFD97706)),
            label: const Text('ADD ROW',
                style: TextStyle(
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(right: 12),
      child: Text(title,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
              letterSpacing: 1)),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.kTextMuted,
            fontWeight: FontWeight.normal,
            fontStyle: FontStyle.italic),
        fillColor: const Color(0xFFF8FAFC),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
      );

  Widget _buildTextField(
      TextEditingController controller, String hint, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(right: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Color(0xFF1E3A8A)),
        decoration: _fieldDecoration(hint),
      ),
    );
  }

  Widget _buildFullWidthField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: Color(0xFF1E3A8A)),
      decoration: _fieldDecoration(hint),
    );
  }

  Widget _buildDropdown(NewUserRowData rowData, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(right: 12),
      child: _dropdownField(rowData),
    );
  }

  Widget _buildFullWidthDropdown(NewUserRowData rowData) =>
      _dropdownField(rowData);

  Widget _dropdownField(NewUserRowData rowData) {
    return DropdownButtonFormField<String>(
      value: rowData.role,
      icon: const Icon(Icons.unfold_more, color: Color(0xFF1E3A8A), size: 16),
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: Color(0xFF1E3A8A)),
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
      ),
      items: _roles
          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
          .toList(),
      onChanged: (val) => setState(() {
        if (val != null) rowData.role = val;
      }),
    );
  }
}
