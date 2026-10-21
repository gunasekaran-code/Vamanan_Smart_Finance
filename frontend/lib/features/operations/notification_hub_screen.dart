import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/admin_user_model.dart';
import '../../models/notification_hub_model.dart';
import '../../services/admin_users_service.dart';
import '../../services/notification_hub_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class NotificationHubScreen extends StatefulWidget {
  const NotificationHubScreen({super.key});

  @override
  State<NotificationHubScreen> createState() => _NotificationHubScreenState();
}

// ============================================================================
// SCREEN WIDGET
// ============================================================================
class _NotificationHubScreenState extends State<NotificationHubScreen> {
  String _selectedRecipient = 'GLOBAL BROADCAST (ALL INVESTORS)';
  String _selectedPriority = 'INFO';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  final FocusNode _userSearchFocus = FocusNode();

  static const String _specificUser = 'SPECIFIC USER (ID)';

  final List<String> _recipients = [
    'GLOBAL BROADCAST (ALL INVESTORS)',
    'ACTIVE INVESTORS ONLY',
    'STAFF & ADMINS',
    _specificUser,
  ];

  List<NotificationLog> _logs = [];
  List<AdminUserModel> _users = [];
  bool _isLoadingUsers = false;
  AdminUserModel? _selectedUser;
  bool _isLoading = true;
  bool _isDispatching = false;
  NotificationLog? _editingLog;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _userSearchController.dispose();
    _userSearchFocus.dispose();
    super.dispose();
  }

  /// Loads the user directory once, the first time a specific user is needed.
  Future<void> _ensureUsersLoaded() async {
    if (_users.isNotEmpty || _isLoadingUsers) return;
    setState(() => _isLoadingUsers = true);
    final response = await AdminUsersService.instance.fetchUsers();
    if (!mounted) return;
    setState(() {
      _isLoadingUsers = false;
      if (response.success && response.data != null) {
        _users = response.data!..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }
    });
    if (!response.success) {
      ToastService.show(title: 'Error', message: 'Could not load users: ${response.message}', type: ToastType.error);
    }
  }

  String _userLabel(AdminUserModel user) =>
      user.customerId.isNotEmpty ? '${user.name} (${user.customerId})' : user.name;

  /// Names starting with the query come first, then any other name,
  /// customer ID or email containing it.
  Iterable<AdminUserModel> _filterUsers(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _users;
    final startsWith = <AdminUserModel>[];
    final contains = <AdminUserModel>[];
    for (final user in _users) {
      final name = user.name.toLowerCase();
      if (name.startsWith(q)) {
        startsWith.add(user);
      } else if (name.contains(q) ||
          user.customerId.toLowerCase().contains(q) ||
          user.email.toLowerCase().contains(q)) {
        contains.add(user);
      }
    }
    return [...startsWith, ...contains];
  }

  void _selectUser(AdminUserModel? user) {
    setState(() => _selectedUser = user);
    _userSearchController.text = user == null ? '' : _userLabel(user);
  }

  void _handleRecipientChanged(String? value) {
    if (value == null) return;
    setState(() => _selectedRecipient = value);
    if (value == _specificUser) {
      _ensureUsersLoaded();
    } else {
      _selectUser(null);
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await NotificationService.instance.fetchLogs();
      if (mounted) setState(() => _logs = logs);
    } catch (e) {
      if (mounted) {
        ToastService.show(title: 'Error', message: 'Could not load logs: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleProcessYield() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PROCESS MONTHLY YIELD',
      message: "Process this month's cashback? This credits one monthly installment (10%) to every cycle that is due, and can only run ONCE per calendar month.",
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kPrimary,
    );

    if (confirmed == true && mounted) {
      ToastService.show(title: 'Success', message: 'Monthly yield processed successfully.', type: ToastType.success);
    }
  }

  Future<void> _handleDispatch() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ToastService.show(title: 'Validation Error', message: 'Title and message cannot be empty.', type: ToastType.error);
      return;
    }
    if (_selectedRecipient == _specificUser && _selectedUser == null) {
      ToastService.show(title: 'Validation Error', message: 'Select a user to send this notification to.', type: ToastType.error);
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'DISPATCH NOTIFICATION',
      message: 'Are you sure you want to broadcast this message to the selected recipients? This action cannot be undone.',
      confirmLabel: 'DISPATCH',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.goldColor,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDispatching = true);
    try {
      final title = _titleController.text.trim().toUpperCase();
      final message = _messageController.text.trim();
      final service = NotificationService.instance;
      final isEditing = _editingLog != null;
      final userId = _selectedRecipient == _specificUser ? _selectedUser?.id.toString() : null;

      if (_editingLog == null) {
        await service.dispatch(
          title: title,
          message: message,
          recipient: _selectedRecipient,
          priority: _selectedPriority,
          userId: userId,
        );
      } else {
        await service.updateLog(
          id: _editingLog!.id,
          title: title,
          message: message,
          recipient: _selectedRecipient,
          priority: _selectedPriority,
          userId: userId,
        );
      }

      await _loadLogs();
      if (!mounted) return;
      setState(() {
        _editingLog = null;
        _titleController.clear();
        _messageController.clear();
        _selectedPriority = 'INFO';
      });
      _selectUser(null);

      ToastService.show(
        title: isEditing ? 'Updated' : 'Dispatched',
        message: isEditing
            ? 'Notification updated successfully.'
            : 'Notification successfully sent to network.',
        type: ToastType.success,
      );
    } catch (e) {
      ToastService.show(title: 'Error', message: 'Dispatch failed: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isDispatching = false);
    }
  }

  Future<void> _handleEdit(NotificationLog log) async {
    final isSpecific = log.userId != null;
    setState(() {
      _editingLog = log;
      _titleController.text = log.title;
      _messageController.text = log.message;
      _selectedRecipient = isSpecific
          ? _specificUser
          : (_recipients.contains(log.recipient) ? log.recipient : 'GLOBAL BROADCAST (ALL INVESTORS)');
      _selectedPriority = log.priority;
    });
    ToastService.show(title: 'Edit Mode', message: 'Loaded log into the dispatch form.', type: ToastType.info);

    if (!isSpecific) {
      _selectUser(null);
      return;
    }
    await _ensureUsersLoaded();
    if (!mounted || _editingLog != log) return;
    final matches = _users.where((u) => u.id.toString() == log.userId);
    _selectUser(matches.isEmpty ? null : matches.first);
  }

  Future<void> _handleDelete(NotificationLog log) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'DELETE LOG',
      message: 'Remove this historical communication from the audit trail?',
      confirmLabel: 'DELETE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed != true || !mounted) return;

    try {
      await NotificationService.instance.deleteLog(log.id);
      setState(() => _logs.removeWhere((l) => l.id == log.id));
      ToastService.show(title: 'Log Deleted', message: 'The communication record has been purged.', type: ToastType.success);
    } catch (e) {
      ToastService.show(title: 'Error', message: 'Delete failed: $e', type: ToastType.error);
    }
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          // Adjusted padding for mobile screens
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopSearchBar(),
              const SizedBox(height: 16),
              
              _buildProcessYieldButton(),
              const SizedBox(height: 24),

              // Responsive Layout (Hub on left/top, Logs on right/bottom)
              LayoutBuilder(
                builder: (context, constraints) {
                  if (isMobile) {
                    return Column(
                      children: [
                        _buildDispatchHub(isMobile: true),
                        const SizedBox(height: 24),
                        _buildLogsSection(isMobile: true),
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildDispatchHub(isMobile: false)),
                        const SizedBox(width: 32),
                        Expanded(flex: 6, child: _buildLogsSection(isMobile: false)),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP COMPONENTS
  // ===========================================================================
  Widget _buildTopSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
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
    );
  }

  Widget _buildProcessYieldButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _handleProcessYield,
        icon: const Icon(Icons.bolt, size: 16, color: AppColors.goldColor),
        label: const Text(
          'PROCESS MONTHLY YIELD', 
          style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 0.5)
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ===========================================================================
  // DISPATCH HUB COMPONENT (Dark Theme Form)
  // ===========================================================================
  Widget _buildDispatchHub({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kPrimary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0), // Responsive padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.goldColor, 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: const Icon(Icons.campaign, color: AppColors.kPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NOTIFICATION HUB', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      'NEURAL DISPATCH FOR INSTITUTIONAL COMMUNICATIONS', 
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.7), letterSpacing: 0.5)
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Form Fields
          _buildDarkDropdown('RECIPIENT SELECTION', _selectedRecipient, _recipients, _handleRecipientChanged),
          const SizedBox(height: 20),

          if (_selectedRecipient == _specificUser) ...[
            _buildUserPicker(),
            const SizedBox(height: 20),
          ],
          
          _buildDarkInput('COMMUNICATION TITLE', 'E.G., SYSTEM UPGRADE SUCCESSFUL', _titleController),
          const SizedBox(height: 20),
          
          _buildDarkInput('NEURAL MESSAGE', 'Draft your institutional announcement here...', _messageController, maxLines: 5),
          const SizedBox(height: 24),

          // Priority Protocol Toggle
          Text('PRIORITY PROTOCOL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPriorityButton('INFO')),
              const SizedBox(width: 8),
              Expanded(child: _buildPriorityButton('SUCCESS')),
              const SizedBox(width: 8),
              Expanded(child: _buildPriorityButton('WARNING')),
            ],
          ),
          const SizedBox(height: 32),

          // Attention Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Text(
              'ATTENTION: DISPATCHING THIS NOTIFICATION WILL IMMEDIATELY UPDATE THE NEURAL INTERFACE OF THE SELECTED RECIPIENT(S). ENSURE ALL TECHNICAL DATA IS VERIFIED BEFORE EXECUTION.',
              style: TextStyle(
                color: AppColors.goldColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                height: 1.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Dispatch Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDispatching ? null : _handleDispatch,
              icon: _isDispatching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.bolt, size: 20),
              label: Text(
                _editingLog == null ? 'DISPATCH NOTIFICATION' : 'UPDATE NOTIFICATION',
                style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldColor, 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NEURAL LOGS SECTION
  // ===========================================================================
  Widget _buildLogsSection({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0), // Responsive padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NEURAL LOGS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kPrimary)),
                    const SizedBox(height: 4),
                    Text('HISTORICAL AUDIT OF COMMUNICATIONS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kTextMuted, letterSpacing: 0.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Text(
                  '${_logs.length} SENT',
                  style: const TextStyle(color: AppColors.kPrimary, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Logs List
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: AppLoader()),
            )
          else if (_logs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'NO LOGS FOUND',
                  style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kTextMuted, letterSpacing: 1),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _NotificationLogCard(
                  log: _logs[index],
                  onEdit: () => _handleEdit(_logs[index]),
                  onDelete: () => _handleDelete(_logs[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DARK THEME FORM HELPERS
  // ===========================================================================
  Widget _buildDarkInput(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.normal, fontStyle: FontStyle.italic, fontSize: 13),
            fillColor: Colors.white.withOpacity(0.05),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.goldColor)),
          ),
        ),
      ],
    );
  }

  Widget _buildDarkDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          icon: Icon(Icons.unfold_more, color: Colors.white.withOpacity(0.5), size: 18),
          isExpanded: true,
          dropdownColor: AppColors.kPrimary,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white),
          decoration: InputDecoration(
            fillColor: Colors.white.withOpacity(0.05),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.goldColor)),
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis));
          }).toList(),
        ),
      ],
    );
  }

  /// Type-ahead over all users: typing "a" lists names starting with A first.
  Widget _buildUserPicker() {
    final borderSide = BorderSide(color: Colors.white.withOpacity(0.15));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('USER NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth;
            return RawAutocomplete<AdminUserModel>(
              textEditingController: _userSearchController,
              focusNode: _userSearchFocus,
              displayStringForOption: _userLabel,
              optionsBuilder: (value) => _filterUsers(value.text),
              onSelected: (user) => setState(() => _selectedUser = user),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !_isLoadingUsers,
                  onSubmitted: (_) => onFieldSubmitted(),
                  onChanged: (text) {
                    // Editing the text after picking someone un-picks them.
                    setState(() {
                      if (_selectedUser != null && text != _userLabel(_selectedUser!)) {
                        _selectedUser = null;
                      }
                    });
                  },
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _isLoadingUsers ? 'Loading users...' : 'Search by name, customer ID or email',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.normal, fontStyle: FontStyle.italic, fontSize: 13),
                    prefixIcon: Icon(Icons.person_search, color: Colors.white.withOpacity(0.5), size: 18),
                    suffixIcon: _isLoadingUsers
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldColor)),
                          )
                        : (controller.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: Colors.white.withOpacity(0.5), size: 18),
                                onPressed: () => _selectUser(null),
                              )
                            : null),
                    fillColor: Colors.white.withOpacity(0.05),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: borderSide),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: borderSide),
                    disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: borderSide),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.goldColor)),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                final highlighted = AutocompleteHighlightedOption.of(context);
                return Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Material(
                      color: AppColors.kPrimary,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 260, maxWidth: fieldWidth),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final user = options.elementAt(index);
                            final subtitle = [user.customerId, user.email].where((s) => s.isNotEmpty).join(' • ');
                            return InkWell(
                              onTap: () => onSelected(user),
                              child: Container(
                                color: index == highlighted ? Colors.white.withOpacity(0.08) : null,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                                    if (subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(subtitle, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.5))),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        if (_selectedUser != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, size: 14, color: AppColors.goldColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'SENDING TO ${_selectedUser!.name.toUpperCase()}${_selectedUser!.role.isNotEmpty ? ' • ${_selectedUser!.role}' : ''}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.goldColor, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPriorityButton(String label) {
    bool isActive = _selectedPriority == label;
    return InkWell(
      onTap: () => setState(() => _selectedPriority = label),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.goldColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppColors.goldColor : Colors.white.withOpacity(0.2)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CLEAN LOG CARD WIDGET (RESTRUCTURED FOR MOBILE RESPONSIVENESS)
// ============================================================================
class _NotificationLogCard extends StatelessWidget {
  final NotificationLog log;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NotificationLogCard({
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Title/Priority + Timestamp
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Avatar
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.kInfo.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: const Icon(Icons.graphic_eq, size: 16, color: AppColors.kInfo),
              ),
              const SizedBox(width: 12),
              
              // Title & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          log.title, 
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kPrimary)
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: log.priority == 'WARNING' ? AppColors.kDanger : AppColors.kInfo, 
                            borderRadius: BorderRadius.circular(4)
                          ),
                          child: Text(
                            log.priority, 
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.timestamp.replaceAll(' AT ', ' • '), 
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kTextMuted)
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Message Content
          Text(
            log.message, 
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.kTextMuted, height: 1.4)
          ),
          
          const SizedBox(height: 16),
          
          // Bottom Row: Recipient & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'RECIPIENT:\n${log.recipient}', 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.goldColor, height: 1.3)
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.goldBg, 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: AppColors.goldBorder)
                      ),
                      child: const Icon(Icons.edit, size: 14, color: AppColors.goldColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.kDanger.withOpacity(0.05), 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: AppColors.kDanger.withOpacity(0.2))
                      ),
                      child: const Icon(Icons.delete_outline, size: 14, color: AppColors.kDanger),
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