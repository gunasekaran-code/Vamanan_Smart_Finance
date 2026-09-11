import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class FeedbackRemarksScreen extends StatefulWidget {
  const FeedbackRemarksScreen({super.key});

  @override
  State<FeedbackRemarksScreen> createState() => _FeedbackRemarksScreenState();
}

class _FeedbackRemarksScreenState extends State<FeedbackRemarksScreen> {
  // Navigation State
  String _activeTab = 'CUSTOMER INBOX';

  // Form State
  String? _selectedCustomer;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<String> _customers = [
    'Nandha Kumar.M',
    'Prakash.A',
    'Saranya Venkat',
    'Guna Sekaran V.',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // --- Handlers ---

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
      ToastService.show(
        title: 'Success', 
        message: 'Monthly yield processed successfully.', 
        type: ToastType.success
      );
    }
  }

  void _handleSendMessage() {
    if (_selectedCustomer == null || _messageController.text.trim().isEmpty) {
      ToastService.show(
        title: 'Validation Error', 
        message: 'Please select a customer and enter a message.', 
        type: ToastType.error
      );
      return;
    }

    ToastService.show(
      title: 'Message Sent', 
      message: 'Your remarks have been dispatched to $_selectedCustomer.', 
      type: ToastType.success
    );

    // Clear form after sending
    setState(() {
      _selectedCustomer = null;
      _subjectController.clear();
      _messageController.clear();
      // Optional: switch to history tab to show the user it was logged
      // _activeTab = 'SENT HISTORY'; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Crisp light background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Global Search Bar ---
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

              // --- 2. Action Button ---
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _handleProcessYield,
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text(
                    'PROCESS MONTHLY YIELD', 
                    style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. Page Header ---
              const Text(
                'FEEDBACK & REMARKS',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'CUSTOMER FEEDBACK INBOX · SEND REMARKS TO CLIENTS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF94A3B8).withOpacity(0.9),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // --- 4. Navigation Tabs ---
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

              // --- 5. Dynamic Content Area ---
              _buildActiveTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Sub-Components ---

  Widget _buildTabButton(String title) {
    bool isActive = _activeTab == title;
    return InkWell(
      onTap: () => setState(() => _activeTab = title),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.white, // Bright Blue for active
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? const Color(0xFF2563EB) : AppColors.kBorder),
          boxShadow: isActive 
              ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: isActive ? Colors.white : const Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 'CUSTOMER INBOX':
        return _buildEmptyState(
          icon: Icons.inbox_outlined,
          message: 'NO CUSTOMER FEEDBACK YET',
        );
      case 'SEND TO CUSTOMER':
        return _buildSendForm();
      case 'SENT HISTORY':
        return _buildEmptyState(
          icon: Icons.chat_bubble_outline,
          message: 'NO REMARKS SENT YET',
        );
      default:
        return const SizedBox.shrink();
    }
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
          Icon(
            icon,
            size: 40,
            color: const Color(0xFFCBD5E1).withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSendForm() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500), // Prevents form from getting too wide on desktop
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Dropdown
              const Text('TO CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 2)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCustomer,
                onChanged: (val) => setState(() => _selectedCustomer = val),
                icon: const Icon(Icons.unfold_more, color: Color(0xFF1E3A8A), size: 18),
                hint: const Text('Select a customer...', style: TextStyle(color: AppColors.kTextMuted, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, fontSize: 13)),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                decoration: _inputDecoration(),
                items: _customers.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              ),
              const SizedBox(height: 24),

              // Subject Input
              const Text('SUBJECT (OPTIONAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 2)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                decoration: _inputDecoration(hintText: 'e.g. Regarding your recent purchase'),
              ),
              const SizedBox(height: 24),

              // Message Textarea
              const Text('MESSAGE / REMARKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 2)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                decoration: _inputDecoration(hintText: 'Write your feedback or remarks to the customer...'),
              ),
              const SizedBox(height: 32),

              // Send Button
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _handleSendMessage,
                  icon: const Icon(Icons.send, size: 14),
                  label: const Text('SEND TO CUSTOMER', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), // Bright Blue
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