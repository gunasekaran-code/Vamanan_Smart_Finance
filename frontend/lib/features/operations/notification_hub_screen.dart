import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// ============================================================================
// DATA MODEL
// ============================================================================
class NotificationLog {
  final String id;
  final String title;
  final String message;
  final String recipient;
  final String priority;
  final String timestamp;

  NotificationLog({
    required this.id,
    required this.title,
    required this.message,
    required this.recipient,
    required this.priority,
    required this.timestamp,
  });
}

// ============================================================================
// SCREEN WIDGET
// ============================================================================
class NotificationHubScreen extends StatefulWidget {
  const NotificationHubScreen({super.key});

  @override
  State<NotificationHubScreen> createState() => _NotificationHubScreenState();
}

class _NotificationHubScreenState extends State<NotificationHubScreen> {
  // Form State
  String _selectedRecipient = 'GLOBAL BROADCAST (ALL INVESTORS)';
  String _selectedPriority = 'INFO';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<String> _recipients = [
    'GLOBAL BROADCAST (ALL INVESTORS)',
    'ACTIVE INVESTORS ONLY',
    'STAFF & ADMINS',
    'SPECIFIC USER (ID)',
  ];

  // Mock Logs State
  final List<NotificationLog> _logs = [
    NotificationLog(
      id: '1',
      title: 'REFERRAL STATUS UPDATED',
      message: 'Your referral commissions have been re-activated.',
      recipient: 'GUNA TEST (ID: 128)',
      priority: 'INFO',
      timestamp: '02 SEP AT 12:28 PM',
    ),
    NotificationLog(
      id: '2',
      title: 'REFERRAL STATUS UPDATED',
      message: 'Your referral commissions have been paused by the administrator.',
      recipient: 'GUNA TEST (ID: 128)',
      priority: 'WARNING',
      timestamp: '02 SEP AT 12:28 PM',
    ),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ACTION HANDLERS
  // ===========================================================================
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
      ToastService.show(
        title: 'Success', 
        message: 'Monthly yield processed successfully.', 
        type: ToastType.success
      );
    }
  }

  Future<void> _handleDispatch() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ToastService.show(
        title: 'Validation Error', 
        message: 'Title and message cannot be empty.', 
        type: ToastType.error
      );
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

    if (confirmed == true && mounted) {
      setState(() {
        _logs.insert(
          0,
          NotificationLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: _titleController.text.toUpperCase(),
            message: _messageController.text,
            recipient: _selectedRecipient,
            priority: _selectedPriority,
            timestamp: 'JUST NOW',
          ),
        );
        _titleController.clear();
        _messageController.clear();
        _selectedPriority = 'INFO';
      });

      ToastService.show(
        title: 'Dispatched', 
        message: 'Notification successfully sent to network.', 
        type: ToastType.success
      );
    }
  }

  void _handleEdit(NotificationLog log) {
    setState(() {
      _titleController.text = log.title;
      _messageController.text = log.message;
      _selectedPriority = log.priority;
    });
    ToastService.show(
      title: 'Edit Mode', 
      message: 'Loaded log into the dispatch form.', 
      type: ToastType.info
    );
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

    if (confirmed == true && mounted) {
      setState(() {
        _logs.removeWhere((l) => l.id == log.id);
      });
      ToastService.show(
        title: 'Log Deleted', 
        message: 'The communication record has been purged.', 
        type: ToastType.success
      );
    }
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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
                  bool isMobile = constraints.maxWidth < 900;
                  
                  if (isMobile) {
                    return Column(
                      children: [
                        _buildDispatchHub(),
                        const SizedBox(height: 32),
                        _buildLogsSection(),
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildDispatchHub()),
                        const SizedBox(width: 32),
                        Expanded(flex: 6, child: _buildLogsSection()),
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
          style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5)
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ===========================================================================
  // DISPATCH HUB COMPONENT (Dark Theme Form)
  // ===========================================================================
  Widget _buildDispatchHub() {
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
      padding: const EdgeInsets.all(32.0),
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
                    const Text('NOTIFICATION HUB', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      'NEURAL DISPATCH FOR INSTITUTIONAL COMMUNICATIONS', 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.7), letterSpacing: 0.5)
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Form Fields
          _buildDarkDropdown('RECIPIENT SELECTION', _selectedRecipient, _recipients, (val) => setState(() => _selectedRecipient = val!)),
          const SizedBox(height: 20),
          
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
              const SizedBox(width: 12),
              Expanded(child: _buildPriorityButton('SUCCESS')),
              const SizedBox(width: 12),
              Expanded(child: _buildPriorityButton('WARNING')),
            ],
          ),
          const SizedBox(height: 32),

          // Attention Banner
          Container(
            padding: const EdgeInsets.all(20),
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
                height: 1.6,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Dispatch Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleDispatch,
              icon: const Icon(Icons.bolt, size: 20),
              label: const Text('DISPATCH NOTIFICATION', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 2)),
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
  Widget _buildLogsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      padding: const EdgeInsets.all(32.0),
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
                    Text('HISTORICAL AUDIT OF INSTITUTIONAL COMMUNICATIONS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kTextMuted, letterSpacing: 0.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Text(
                  '${_logs.length} DISPATCHED',
                  style: const TextStyle(color: AppColors.kPrimary, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Logs List
          if (_logs.isEmpty)
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              fontSize: 11,
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
// CLEAN LOG CARD WIDGET
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
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
          const SizedBox(width: 16),
          
          // Content Data
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
                const SizedBox(height: 6),
                Text(
                  log.message, 
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.kTextMuted, height: 1.4)
                ),
                const SizedBox(height: 8),
                Text(
                  'RECIPIENT: ${log.recipient}', 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.goldColor)
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Actions & Timestamp
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                log.timestamp.replaceAll(' AT ', '\n'), 
                textAlign: TextAlign.right, 
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kTextMuted)
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.goldBg, 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: AppColors.goldBorder)
                      ),
                      child: const Icon(Icons.edit, size: 12, color: AppColors.goldColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.kDanger.withOpacity(0.05), 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: AppColors.kDanger.withOpacity(0.2))
                      ),
                      child: const Icon(Icons.delete_outline, size: 12, color: AppColors.kDanger),
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