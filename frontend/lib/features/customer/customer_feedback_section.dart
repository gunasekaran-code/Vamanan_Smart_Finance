import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/customer_profile_model.dart';
import '../../services/customer_profile_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

// ============================================================================
// FEEDBACK & REMARKS
// ============================================================================

/// Three tabs over `customer/get_feedback.php` and
/// `customer/submit_feedback.php`: compose, what the team sent back, and what
/// this customer has sent.
class CustomerFeedbackSection extends StatefulWidget {
  const CustomerFeedbackSection({super.key});

  @override
  State<CustomerFeedbackSection> createState() => CustomerFeedbackSectionState();
}

class CustomerFeedbackSectionState extends State<CustomerFeedbackSection> {
  static const Color _navy = Color(0xFF1B233A);
  static const Color _royal = AppColors.kPrimary;
  static const Color _slate = AppColors.kTextMuted;
  static const Color _label = Color(0xFFCBD5E1);
  static const Color _hairline = Color(0xFFF1F5F9);

  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  int _tab = 0; // 0 = write, 1 = from team, 2 = my submissions
  int _rating = 0;
  bool _submitting = false;

  CustomerFeedbackThreads _threads = const CustomerFeedbackThreads();
  bool _loadingThreads = true;
  String? _threadsError;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadThreads() async {
    try {
      final threads = await CustomerProfileService.instance.fetchFeedback();
      if (!mounted) return;
      setState(() {
        _threads = threads;
        _threadsError = null;
        _loadingThreads = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _threadsError = '$error';
        _loadingThreads = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_messageCtrl.text.trim().isEmpty) {
      ToastService.show(
        title: 'Message required',
        message: 'Write a message before submitting.',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final message = await CustomerProfileService.instance.submitFeedback(
        subject: _subjectCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        rating: _rating == 0 ? null : _rating,
      );
      if (!mounted) return;

      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() {
        _rating = 0;
        _submitting = false;
        _tab = 2; // land on MY SUBMISSIONS so the new row is visible
      });
      ToastService.show(
        title: 'Feedback sent',
        message: message,
        type: ToastType.success,
      );
      await _loadThreads();
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ToastService.show(
        title: 'Could not submit',
        message: '$error',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _hairline, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimaryDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FEEDBACK & REMARKS',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SHARE YOUR THOUGHTS • SEE REPLIES FROM OUR TEAM',
                        style: TextStyle(
                          color: _slate.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: _hairline, height: 2, thickness: 2),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _tabButton(0, 'WRITE\nFEEDBACK'),
                const SizedBox(width: 10),
                _tabButton(1, 'FROM\nTEAM'),
                const SizedBox(width: 10),
                _tabButton(2, 'MY\nSUBMISSIONS'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: switch (_tab) {
              0 => _writeTab(),
              1 => _threadTab(
                  items: _threads.received,
                  emptyIcon: Icons.inbox_outlined,
                  emptyLabel: 'NO REPLIES FROM THE TEAM YET',
                  showSender: true,
                ),
              _ => _threadTab(
                  items: _threads.sent,
                  emptyIcon: Icons.chat_bubble_outline_rounded,
                  emptyLabel: "YOU HAVEN'T SENT ANY FEEDBACK YET",
                  showSender: false,
                ),
            },
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final selected = _tab == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _royal : AppColors.kBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : _slate,
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // WRITE
  // --------------------------------------------------------------------------

  Widget _writeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUBJECT (OPTIONAL)',
          style: TextStyle(
            color: _label,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _subjectCtrl,
          decoration: _inputDecoration('e.g. Payout query, Suggestion…'),
          style: const TextStyle(
            color: _navy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'YOUR MESSAGE',
          style: TextStyle(
            color: _label,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageCtrl,
          maxLines: 5,
          decoration:
              _inputDecoration('Write your feedback or remarks here…'),
          style: const TextStyle(
            color: _navy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'RATE US',
          style: TextStyle(
            color: _label,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                onPressed: () => setState(
                  // Tapping the current rating clears it — `rating` is
                  // nullable on the backend, so "no rating" is valid.
                  () => _rating = _rating == star ? 0 : star,
                ),
                padding: const EdgeInsets.only(right: 4),
                constraints: const BoxConstraints(),
                icon: Icon(
                  star <= _rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: star <= _rating ? AppColors.goldColor : _label,
                  size: 28,
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 16),
            label: Text(
              _submitting ? 'SENDING…' : 'SUBMIT FEEDBACK',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.0,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _royal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: _label,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: AppColors.kBackground,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _royal, width: 1.5),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // THREADS
  // --------------------------------------------------------------------------

  Widget _threadTab({
    required List<CustomerFeedback> items,
    required IconData emptyIcon,
    required String emptyLabel,
    required bool showSender,
  }) {
    if (_loadingThreads) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: AppLoader()),
      );
    }

    if (_threadsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 32, color: _label),
            const SizedBox(height: 12),
            Text(
              _threadsError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _slate, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadThreads, child: const Text('RETRY')),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(emptyIcon, size: 44, color: _label),
            const SizedBox(height: 16),
            Text(
              emptyLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _label,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _threadTile(item, showSender: showSender),
          ),
      ],
    );
  }

  Widget _threadTile(CustomerFeedback item, {required bool showSender}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.kBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.subject.isEmpty ? 'NO SUBJECT' : item.subject,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (item.createdAt != null)
                Text(
                  DateFormat('dd MMM yyyy').format(item.createdAt!),
                  style: const TextStyle(
                    color: _label,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.message,
            style: const TextStyle(color: _slate, fontSize: 12, height: 1.4),
          ),
          if (showSender && item.fromName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '— ${item.fromName}'
              '${item.senderRole.isEmpty ? '' : ' (${item.senderRole.toUpperCase()})'}',
              style: const TextStyle(
                color: _royal,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (item.rating != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                for (var star = 1; star <= 5; star++)
                  Icon(
                    star <= item.rating!
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color:
                        star <= item.rating! ? AppColors.goldColor : _label,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
