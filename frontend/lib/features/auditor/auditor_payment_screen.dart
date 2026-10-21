import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:upi_payment_qrcode_generator/upi_payment_qrcode_generator.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/app_upload.dart';
import 'package:frontend/core/services/session_service.dart';
import 'package:frontend/services/settings_service.dart';
import 'package:frontend/models/settings_models.dart';
import 'package:frontend/core/utils/inr_format.dart';
import '../../models/auditor_buy_model.dart';
import '../../services/auditor_buy_service.dart';
import '../../services/cart_service.dart';

/// Pops with `true` once the order has been submitted.
class AuditorPaymentDetailsScreen extends StatefulWidget {
  final String assetType;
  final int weight;
  final double totalAmount;

  /// Product lines for a product order (Buy Now or cart checkout). When set,
  /// [assetType] and [weight] are only used for display.
  final List<PurchaseLine>? items;

  /// Whether [items] came from the cart, which is emptied once the order is
  /// accepted.
  final bool fromCart;

  const AuditorPaymentDetailsScreen({
    super.key,
    required this.assetType,
    required this.weight,
    required this.totalAmount,
    this.items,
    this.fromCart = false,
  });

  bool get isProductOrder => items != null && items!.isNotEmpty;

  @override
  State<AuditorPaymentDetailsScreen> createState() =>
      _AuditorPaymentDetailsScreenState();
}

class _AuditorPaymentDetailsScreenState
    extends State<AuditorPaymentDetailsScreen> {
  String _activeTab = 'BANK TRANSFER'; // BANK TRANSFER, UPI SCAN

  final _nameCtrl = TextEditingController(text: 'TEST AUDITOR');
  final _phoneCtrl = TextEditingController();
  final _utrCtrl = TextEditingController();

  XFile? _uploadedScreenshot;
  bool _isSubmitting = false;
  bool _isLoadingGateway = true;
  String? _gatewayError;
  PlatformSettings? _gatewaySettings;

  final Color _navyBlue = AppColors.kPrimaryDark;
  final Color _lightBorder = const Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    final user = SessionService.instance.currentUser;
    _nameCtrl.text = user?.name ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _loadGatewaySettings();
  }

  Future<void> _loadGatewaySettings() async {
    try {
      final settings = await SettingsService.instance.fetchSettings();
      if (!mounted) return;
      setState(() {
        _gatewaySettings = settings;
        _gatewayError = null;
        _isLoadingGateway = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _gatewayError = error.toString();
        _isLoadingGateway = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _utrCtrl.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ToastService.show(
        title: 'Copied',
        message: 'Copied to clipboard: $text',
        type: ToastType.success);
  }

  Future<void> _handleUploadScreenshot() async {
    final file = await AppUpload.showImagePickerModal(context,
        title: 'Upload Payment Screenshot');
    if (file != null) {
      setState(() => _uploadedScreenshot = file);
    }
  }

  Future<void> _handlePlaceOrder() async {
    if (_utrCtrl.text.isEmpty || _uploadedScreenshot == null) {
      ToastService.show(
          title: 'Missing Details',
          message: 'Please provide UTR number and payment screenshot.',
          type: ToastType.warning);
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Confirm Payment',
      message:
          'Are you sure you want to submit this payment for verification? Ensure your UTR is correct.',
      confirmLabel: 'Place Order',
      confirmButtonColor: _navyBlue,
    );

    if (confirmed != true) return;

    final userId = int.tryParse(SessionService.instance.currentUser?.id ?? '');
    if (userId == null) {
      ToastService.show(
          title: 'Session Expired',
          message: 'Please sign in again before placing an order.',
          type: ToastType.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final paymentMode = _activeTab == 'UPI SCAN' ? 'upi' : 'bank';
      if (widget.isProductOrder) {
        await AuditorBuyService.submitPurchase(
          userId: userId,
          assetType: 'product',
          weight: 1, // purchase.php requires the field; ignored for items
          items: widget.items,
          paymentMode: paymentMode,
          transactionId: _utrCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          screenshot: _uploadedScreenshot,
        );
        if (widget.fromCart) await CartService.instance.clear();
      } else {
        final assetType = widget.assetType.toLowerCase().contains('silver')
            ? 'silver'
            : 'gold';
        await AuditorBuyService.submitPurchase(
          userId: userId,
          assetType: assetType,
          weight: widget.weight.toDouble(),
          paymentMode: paymentMode,
          transactionId: _utrCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          screenshot: _uploadedScreenshot,
        );
      }
      if (!mounted) return;
      ToastService.show(
          title: 'Order Placed',
          message: widget.isProductOrder
              ? 'Your payment is under review. Your order will be delivered within 7 working days of approval.'
              : 'Your payment is under review. The asset will be allocated shortly.',
          type: ToastType.success);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
          title: 'Order Failed', message: e.toString(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                left: 24,
                right: 24,
                bottom: 48,
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
                              Icon(Icons.sync,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 16),
                              const SizedBox(width: 8),
                              const Text('PAYMENT DETAILS',
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: 1.5)),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle),
                            child: IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Tabs (Bank / UPI)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            _buildTopTab('BANK TRANSFER'),
                            _buildTopTab('UPI SCAN'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      _buildGatewayDetailsCard(),
                      const SizedBox(height: 32),

                      // Amount Display
                      Text(_activeTab == 'UPI SCAN' ? 'SCAN & PAY' : _activeTab,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.goldColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      if (_activeTab == 'UPI SCAN') ...[
                        Text(
                          _gatewaySettings?.value('upi_id') ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text('AMOUNT PAYABLE (INCL. GST)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 2.0)),
                      const SizedBox(height: 8),
                      Text(formatInr(widget.totalAmount),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -1.0)),
                      const SizedBox(height: 32),

                      // Secure Badge
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shield_outlined,
                                color: AppColors.goldColor, size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('SAFE & SECURE',
                                    style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                        letterSpacing: 1.0)),
                                Text('SECURE PAYMENT',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                        letterSpacing: 0.5)),
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
                      const Text('CONFIRM YOUR PAYMENT',
                          style: TextStyle(
                              color: AppColors.kPrimaryDark,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: -1.0)),
                      const SizedBox(height: 4),
                      const Text(
                          'ENTER YOUR PAYMENT DETAILS TO PLACE THE ORDER',
                          style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 32),

                      // Info Banner
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: _lightBorder, width: 1.5)),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: Colors.blue, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('PRODUCT DELIVERED',
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: 1.0)),
                                  Text('WITHIN 7 WORKING DAYS',
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic)),
                                  SizedBox(height: 8),
                                  Text('PAYOUT START',
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: 1.0)),
                                  Text('WITHIN 48 HOURS',
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (widget.isProductOrder) ...[
                        _buildOrderSummary(),
                        const SizedBox(height: 32),
                      ],

                      // Form Fields
                      _buildInput('NAME', 'TEST AUDITOR', _nameCtrl,
                          readOnly: true),
                      _buildInput('PHONE', 'MOBILE NUMBER', _phoneCtrl),
                      _buildInput('TRANSACTION ID (UTR)',
                          'ENTER UTR / REFERENCE NUMBER', _utrCtrl,
                          isGoldFocus: true),

                      const SizedBox(height: 8),
                      const Text('PAYMENT SCREENSHOT',
                          style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _handleUploadScreenshot,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: _lightBorder, width: 2)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  _uploadedScreenshot != null
                                      ? _uploadedScreenshot!.name
                                      : 'Upload Screenshot',
                                  style: TextStyle(
                                      color: _uploadedScreenshot != null
                                          ? _navyBlue
                                          : const Color(0xFF94A3B8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic)),
                              Icon(
                                  _uploadedScreenshot != null
                                      ? Icons.check_circle
                                      : Icons.check_circle_outline,
                                  color: _uploadedScreenshot != null
                                      ? AppColors.kSuccess
                                      : const Color(0xFFE2E8F0),
                                  size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Submit Button
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handlePlaceOrder,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.notifications_none, size: 18),
                        label: Text(
                            _isSubmitting ? 'SUBMITTING...' : 'PLACE ORDER',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                                letterSpacing: 2.0)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navyBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          elevation: 10,
                          shadowColor: _navyBlue.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      // Extra padding for bottom screen edge
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 20),
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

  Widget _buildGatewayDetailsCard() {
    if (_isLoadingGateway) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const CircularProgressIndicator(),
      );
    }

    if (_gatewayError != null || _gatewaySettings == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: Color(0xFF94A3B8), size: 28),
            const SizedBox(height: 12),
            const Text('PAYMENT DETAILS UNAVAILABLE',
                style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            TextButton(
                onPressed: _loadGatewaySettings, child: const Text('RETRY')),
          ],
        ),
      );
    }

    final settings = _gatewaySettings!;
    final accountNumber = settings.value('bank_account_no');
    final ifsc = settings.value('bank_ifsc');
    final upiId = settings.value('upi_id');

    if (_activeTab == 'UPI SCAN') {
      return _buildUpiQrCode(upiId, settings.value('bank_account_name'));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBankRow(
              'BENEFICIARY', settings.value('bank_account_name'), null),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 32),
          _buildBankRow('BANK', settings.value('bank_name'), null),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 32),
          _buildBankRow('ACCOUNT NO.', accountNumber, accountNumber),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 32),
          _buildBankRow('IFSC', ifsc, ifsc, isGold: true),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 32),
          _buildBankRow('BRANCH', settings.value('bank_branch'), null),
        ],
      ),
    );
  }

/// Generates a standard `upi://pay` QR with a stylish responsive border
  Widget _buildUpiQrCode(String upiId, String payeeName) {
    if (upiId.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Text(
          'UPI ID IS NOT CONFIGURED',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final upiDetails = UPIDetails(
      upiID: upiId.trim(),
      payeeName: payeeName.trim().isEmpty ? 'Vamanan Enterprises' : payeeName,
      amount: widget.totalAmount,
      transactionNote:
          widget.isProductOrder ? 'Product purchase' : '${widget.assetType} purchase',
    );

    // Responsive sizing: 55% of screen width, clamped between 150 and 240
    final screenWidth = MediaQuery.of(context).size.width;
    final double qrSize = (screenWidth * 0.55).clamp(150.0, 240.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _navyBlue.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Stylish Border Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.goldColor.withOpacity(0.6),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldColor.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: UPIPaymentQRCode(
                upiDetails: upiDetails,
                size: qrSize,
                embeddedImagePath: 'assets/images/logo.png',
                embeddedImageSize: const Size(40, 40),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Helper Text with Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, color: AppColors.goldColor, size: 16),
              const SizedBox(width: 8),
              const Text(
                'SCAN WITH ANY UPI APP',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final items = widget.items!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _lightBorder, width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ORDER SUMMARY (${items.length} ${items.length == 1 ? 'ITEM' : 'ITEMS'})',
              style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5)),
          const SizedBox(height: 12),
          for (final line in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(line.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: _navyBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(width: 12),
                  Text('× ${line.quantity}',
                      style: const TextStyle(
                          color: AppColors.goldColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1.5, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL (INCL. GST)',
                  style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.0)),
              Text(formatInr(widget.totalAmount),
                  style: TextStyle(
                      color: _navyBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for Bank Row Details
  Widget _buildBankRow(String label, String value, String? copyText,
      {bool isGold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: isGold ? AppColors.goldColor : _navyBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic)),
          ],
        ),
        if (copyText != null)
          InkWell(
            onTap: () => _copyToClipboard(copyText),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _lightBorder)),
              child: const Icon(Icons.copy, size: 16, color: Color(0xFF94A3B8)),
            ),
          )
      ],
    );
  }

  // Helper for Input Fields
  Widget _buildInput(
      String label, String hint, TextEditingController controller,
      {bool readOnly = false, bool isGoldFocus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            style: TextStyle(
                color: readOnly ? const Color(0xFF94A3B8) : _navyBlue,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic),
              filled: true,
              fillColor: readOnly
                  ? const Color(0xFFF1F5F9).withOpacity(0.5)
                  : Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _lightBorder, width: 2)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _lightBorder, width: 2)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isGoldFocus
                          ? AppColors.goldColor
                          : AppColors.kPrimary,
                      width: 2)),
            ),
          ),
        ],
      ),
    );
  }
}
