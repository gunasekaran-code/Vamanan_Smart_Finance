import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/feedback_remarks_model.dart';
import '../../services/feedback_remarks_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class FeedbackRemarksScreen extends StatefulWidget {
  const FeedbackRemarksScreen({super.key});

  @override
  State<FeedbackRemarksScreen> createState() => _FeedbackRemarksScreenState();
}

class _FeedbackRemarksScreenState extends State<FeedbackRemarksScreen> {
  String _activeTab = 'CUSTOMER INBOX';

  String? _selectedCustomerId;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<CustomerOption> _customers = [];
  List<FeedbackItem> _inbox = [];
  List<FeedbackItem> _sent = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final feed = await FeedbackService.instance.fetchFeedback();
      final customers = await FeedbackService.instance.fetchCustomers();
      if (mounted) {
        setState(() {
          _inbox = feed.inbox;
          _sent = feed.sent;
          _customers = customers;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastService.show(title: 'Error', message: 'Could not load feedback: $e', type: ToastType.error);
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
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      ToastService.show(title: 'Success', message: 'Monthly yield processed successfully.', type: ToastType.success);
    }
  }

  Future<void> _handleSendMessage() async {
    if (_selectedCustomerId == null || _messageController.text.trim().isEmpty) {
      ToastService.show(title: 'Validation Error', message: 'Please select a customer and enter a message.', type: ToastType.error);
      return;
    }

    setState(() => _isSending = true);
    try {
      await FeedbackService.instance.sendReply(
        toUserId: _selectedCustomerId!,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );

      final name = _customers.firstWhere((c) => c.id == _selectedCustomerId).name;
      ToastService.show(title: 'Message Sent', message: 'Your remarks have been dispatched to $name.', type: ToastType.success);

      setState(() {
        _selectedCustomerId = null;
        _subjectController.clear();
        _messageController.clear();
      });
      await _loadAll();
    } catch (e) {
      ToastService.show(title: 'Error', message: 'Could not send: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleMarkRead(FeedbackItem item) async {
    try {
      await FeedbackService.instance.markRead(item.id);
      setState(() => _inbox = _inbox.map((f) => f.id == item.id
          ? FeedbackItem.fromJson({
              'id': f.id, 'from_user_id': f.fromUserId, 'to_user_id': f.toUserId,
              'from_name': f.fromName, 'to_name': f.toName, 'customer_id': f.customerId,
              'sender_role': f.senderRole, 'subject': f.subject, 'message': f.message,
              'rating': f.rating, 'is_read': '1', 'created_at': f.createdAt, 'direction': f.direction,
            })
          : f).toList());
    } catch (_) {}
  }

  Future<void> _handleDelete(FeedbackItem item) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'DELETE FEEDBACK',
      message: 'Remove this record permanently?',
      confirmLabel: 'DELETE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed != true) return;

    try {
      await FeedbackService.instance.deleteFeedback(item.id);
      setState(() {
        _inbox.removeWhere((f) => f.id == item.id);
        _sent.removeWhere((f) => f.id == item.id);
      });
      ToastService.show(title: 'Deleted', message: 'Record removed.', type: ToastType.success);
    } catch (e) {
      ToastService.show(title: 'Error', message: 'Could not delete: $e', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _handleProcessYield,
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('PROCESS MONTHLY YIELD', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text('FEEDBACK & REMARKS', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(
                'CUSTOMER FEEDBACK INBOX · SEND REMARKS TO CLIENTS${_inbox.where((f) => !f.isRead).isNotEmpty ? ' · ${_inbox.where((f) => !f.isRead).length} UNREAD' : ''}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.9), letterSpacing: 1.5),
              ),
              const SizedBox(height: 24),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildTabButton('CUSTOMER INBOX'),
                  _buildTabButton('SEND TO CUSTOMER'),
                  _buildTabButton('SENT HISTORY'),
                ],
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: AppLoader()))
              else
                _buildActiveTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title) {
    bool isActive = _activeTab == title;
    return InkWell(
      onTap: () => setState(() => _activeTab = title),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? const Color(0xFF2563EB) : AppColors.kBorder),
          boxShadow: isActive ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: isActive ? Colors.white : const Color(0xFF94A3B8), letterSpacing: 1)),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 'CUSTOMER INBOX':
        return _inbox.isEmpty
            ? _buildEmptyState(icon: Icons.inbox_outlined, message: 'NO CUSTOMER FEEDBACK YET')
            : _buildFeedbackList(_inbox, showMarkRead: true);
      case 'SEND TO CUSTOMER':
        return _buildSendForm();
      case 'SENT HISTORY':
        return _sent.isEmpty
            ? _buildEmptyState(icon: Icons.chat_bubble_outline, message: 'NO REMARKS SENT YET')
            : _buildFeedbackList(_sent, showMarkRead: false);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFeedbackList(List<FeedbackItem> items, {required bool showMarkRead}) {
    return Column(
      children: items.map((item) {
        final headline = showMarkRead ? (item.fromName ?? 'Customer') : (item.toName ?? 'Customer');
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(headline, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                        if (showMarkRead && !item.isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(4)),
                            child: const Text('NEW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                      ],
                    ),
                    if (item.subject.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item.subject, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                    ],
                    const SizedBox(height: 6),
                    Text(item.message, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748B), height: 1.4)),
                    if (item.rating != null) ...[
                      const SizedBox(height: 6),
                      Text('RATING: ${item.rating}/5', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  if (showMarkRead && !item.isRead)
                    InkWell(
                      onTap: () => _handleMarkRead(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.done, size: 14, color: Color(0xFF2563EB)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _handleDelete(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: const Color(0xFFCBD5E1).withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSendForm() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.kBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('TO CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 2)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCustomerId,
                onChanged: (val) => setState(() => _selectedCustomerId = val),
                icon: const Icon(Icons.unfold_more, color: Color(0xFF1E3A8A), size: 18),
                hint: const Text('Select a customer...', style: TextStyle(color: AppColors.kTextMuted, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, fontSize: 13)),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                decoration: _inputDecoration(),
                items: _customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              ),
              const SizedBox(height: 24),

              const Text('SUBJECT (OPTIONAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 2)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                decoration: _inputDecoration(hintText: 'e.g. Regarding your recent purchase'),
              ),
              const SizedBox(height: 24),

              const Text('MESSAGE / REMARKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 2)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                decoration: _inputDecoration(hintText: 'Write your feedback or remarks to the customer...'),
              ),
              const SizedBox(height: 32),

              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _handleSendMessage,
                  icon: _isSending
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, size: 14),
                  label: Text(_isSending ? 'SENDING...' : 'SEND TO CUSTOMER', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.kTextMuted, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, fontSize: 13),
      fillColor: const Color(0xFFF8FAFC),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
    );
  }
}