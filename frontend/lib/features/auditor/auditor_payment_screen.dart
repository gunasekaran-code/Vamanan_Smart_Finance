import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/app_upload.dart'; 

class AuditorPaymentDetailsScreen extends StatefulWidget {
  final String assetType;
  final int weight;
  final double totalAmount;

  const AuditorPaymentDetailsScreen({
    super.key, 
    required this.assetType, 
    required this.weight, 
    required this.totalAmount,
  });

  @override
  State<AuditorPaymentDetailsScreen> createState() => _AuditorPaymentDetailsScreenState();
}

class _AuditorPaymentDetailsScreenState extends State<AuditorPaymentDetailsScreen> {
  String _activeTab = 'BANK TRANSFER'; // BANK TRANSFER, UPI SCAN

  final _nameCtrl = TextEditingController(text: 'TEST AUDITOR');
  final _phoneCtrl = TextEditingController();
  final _utrCtrl = TextEditingController();
  
  XFile? _uploadedScreenshot;

  final Color _navyBlue = AppColors.kPrimaryDark;
  final Color _lightBorder = const Color(0xFFF1F5F9);
  
  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _utrCtrl.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ToastService.show(title: 'Copied', message: 'Copied to clipboard: $text', type: ToastType.success);
  }

  Future<void> _handleUploadScreenshot() async {
    final file = await AppUpload.showImagePickerModal(context, title: 'Upload Payment Screenshot');
    if (file != null) {
      setState(() => _uploadedScreenshot = file);
    }
  }

  Future<void> _handlePlaceOrder() async {
    if (_utrCtrl.text.isEmpty || _uploadedScreenshot == null) {
      ToastService.show(title: 'Missing Details', message: 'Please provide UTR number and payment screenshot.', type: ToastType.warning);
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Confirm Payment',
      message: 'Are you sure you want to submit this payment for verification? Ensure your UTR is correct.',
      confirmLabel: 'Place Order',
      confirmButtonColor: _navyBlue,
    );

    if (confirmed == true) {
      ToastService.show(title: 'Order Placed', message: 'Your payment is under review. The asset will be allocated shortly.', type: ToastType.success);
      if (mounted) Navigator.pop(context); // Go back to buy screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // NAVY TOP SECTION
          SliverToBoxAdapter(
            child: Container(
              color: _navyBlue,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                left: 24, right: 24, bottom: 48,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header & Close Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.sync, color: Colors.white.withOpacity(0.3), size: 16),
                              const SizedBox(width: 8),
                              const Text('PAYMENT DETAILS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Tabs (Bank / UPI)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            _buildTopTab('BANK TRANSFER'),
                            _buildTopTab('UPI SCAN'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Bank Details Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBankRow('BENEFICIARY', 'VAMANAN ENTERPRISES V', null),
                            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 32),
                            _buildBankRow('BANK', 'CSB BANK LIMITED', null),
                            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 32),
                            _buildBankRow('ACCOUNT NO.', '0747020000114', '0747020000114'),
                            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 32),
                            _buildBankRow('IFSC', 'CSBK0000747', 'CSBK0000747', isGold: true),
                            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 32),
                            _buildBankRow('BRANCH', 'KRISHNAGIRI', null),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Amount Display
                      const Text('BANK TRANSFER', textAlign: TextAlign.center, style: TextStyle(color: AppColors.goldColor, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      const Text('AMOUNT PAYABLE (INCL. GST)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0)),
                      const SizedBox(height: 8),
                      Text('₹${widget.totalAmount.toStringAsFixed(2)}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
                      const SizedBox(height: 32),

                      // Secure Badge
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shield_outlined, color: AppColors.goldColor, size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('SAFE & SECURE', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                                Text('SECURE PAYMENT', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // WHITE BOTTOM SECTION
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('CONFIRM YOUR PAYMENT', style: TextStyle(color: AppColors.kPrimaryDark, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0)),
                      const SizedBox(height: 4),
                      const Text('ENTER YOUR PAYMENT DETAILS TO PLACE THE ORDER', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                      const SizedBox(height: 32),

                      // Info Banner
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: _lightBorder, width: 1.5)),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.blue, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('PRODUCT DELIVERED', style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                                  Text('WITHIN 7 WORKING DAYS', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                                  SizedBox(height: 8),
                                  Text('PAYOUT START', style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                                  Text('WITHIN 48 HOURS', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Fields
                      _buildInput('NAME', 'TEST AUDITOR', _nameCtrl, readOnly: true),
                      _buildInput('PHONE', 'MOBILE NUMBER', _phoneCtrl),
                      _buildInput('TRANSACTION ID (UTR)', 'ENTER UTR / REFERENCE NUMBER', _utrCtrl, isGoldFocus: true),
                      
                      const SizedBox(height: 8),
                      const Text('PAYMENT SCREENSHOT', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _handleUploadScreenshot,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: _lightBorder, width: 2)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _uploadedScreenshot != null ? _uploadedScreenshot!.name : 'Upload Screenshot', 
                                style: TextStyle(color: _uploadedScreenshot != null ? _navyBlue : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)
                              ),
                              Icon(_uploadedScreenshot != null ? Icons.check_circle : Icons.check_circle_outline, color: _uploadedScreenshot != null ? AppColors.kSuccess : const Color(0xFFE2E8F0), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Submit Button
                      ElevatedButton.icon(
                        onPressed: _handlePlaceOrder,
                        icon: const Icon(Icons.notifications_none, size: 18),
                        label: const Text('PLACE ORDER', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 14, letterSpacing: 2.0)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navyBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          elevation: 10,
                          shadowColor: _navyBlue.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      // Extra padding for bottom screen edge
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Top Navy Tabs
  Widget _buildTopTab(String title) {
    final isActive = _activeTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? AppColors.goldColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? _navyBlue : Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  // Helper for Bank Row Details
  Widget _buildBankRow(String label, String value, String? copyText, {bool isGold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: isGold ? AppColors.goldColor : _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
          ],
        ),
        if (copyText != null)
          InkWell(
            onTap: () => _copyToClipboard(copyText),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: _lightBorder)),
              child: const Icon(Icons.copy, size: 16, color: Color(0xFF94A3B8)),
            ),
          )
      ],
    );
  }

  // Helper for Input Fields
  Widget _buildInput(String label, String hint, TextEditingController controller, {bool readOnly = false, bool isGoldFocus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            style: TextStyle(color: readOnly ? const Color(0xFF94A3B8) : _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
              filled: true,
              fillColor: readOnly ? const Color(0xFFF1F5F9).withOpacity(0.5) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _lightBorder, width: 2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _lightBorder, width: 2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isGoldFocus ? AppColors.goldColor : AppColors.kPrimary, width: 2)),
            ),
          ),
        ],
      ),
    );
  }
}