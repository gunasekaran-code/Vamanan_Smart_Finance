import 'dart:io';
import 'package:flutter/foundation.dart'; // Added to check if app is running on Web
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Added to use XFile
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/services/settings_service.dart';
import 'package:frontend/shared/widgets/app_upload.dart';
import 'package:frontend/shared/widgets/app_loader.dart';
import 'package:upi_payment_qrcode_generator/upi_payment_qrcode_generator.dart';

/// `name@handle`, e.g. `vamananenterprises.10027389@csb`.
final RegExp _upiIdPattern =
    RegExp(r'^[\w.\-]{2,256}@[a-zA-Z][a-zA-Z0-9]{1,64}$');

class PaymentGatewayWidget extends StatefulWidget {
  const PaymentGatewayWidget({super.key});

  @override
  State<PaymentGatewayWidget> createState() => _PaymentGatewayWidgetState();
}

class _PaymentGatewayWidgetState extends State<PaymentGatewayWidget> {
  final TextEditingController _upiCtrl =
      TextEditingController(text: 'VAMANANENTERPRISES.10027389@csb');
  final TextEditingController _bankNameCtrl =
      TextEditingController(text: 'CSB Bank Limited');
  final TextEditingController _holderNameCtrl =
      TextEditingController(text: 'Vamanan Enterprises V');
  final TextEditingController _accNumberCtrl =
      TextEditingController(text: '0747020000114');
  final TextEditingController _ifscCtrl =
      TextEditingController(text: 'CSBK0000747');
  final TextEditingController _branchCtrl =
      TextEditingController(text: 'Krishnagiri');

  bool _isLoading = true;
  bool _isSaving = false;

  // Changed from File? to XFile? for Web compatibility
  XFile? _selectedQrFile;
  String? _existingQrUrl;

  @override
  void initState() {
    super.initState();
    // The QR is generated from these two fields, so redraw it as they change.
    _upiCtrl.addListener(_onQrFieldChanged);
    _holderNameCtrl.addListener(_onQrFieldChanged);
    _loadSettings();
  }

  void _onQrFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService.instance.fetchSettings();
      if (!mounted) return;

      _upiCtrl.text = settings.value('upi_id', _upiCtrl.text);
      _bankNameCtrl.text = settings.value('bank_name', _bankNameCtrl.text);
      _holderNameCtrl.text =
          settings.value('bank_account_name', _holderNameCtrl.text);
      _accNumberCtrl.text =
          settings.value('bank_account_no', _accNumberCtrl.text);
      _ifscCtrl.text = settings.value('bank_ifsc', _ifscCtrl.text);
      _branchCtrl.text = settings.value('bank_branch', _branchCtrl.text);

      // Default to empty string instead of null to prevent null-safety errors
      _existingQrUrl = settings.value('qr_image_url', '');

      setState(() => _isLoading = false);
    } catch (error) {
      if (mounted) setState(() => _isLoading = false);
      ToastService.show(
          title: 'Load Failed',
          message: error.toString(),
          type: ToastType.error);
    }
  }

  @override
  void dispose() {
    _upiCtrl.removeListener(_onQrFieldChanged);
    _holderNameCtrl.removeListener(_onQrFieldChanged);
    _upiCtrl.dispose();
    _bankNameCtrl.dispose();
    _holderNameCtrl.dispose();
    _accNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleDeployPaymentNode() async {
    if (_upiCtrl.text.isEmpty ||
        _accNumberCtrl.text.isEmpty ||
        _ifscCtrl.text.isEmpty) {
      ToastService.show(
          title: 'Validation Error',
          message: 'UPI Identifier, Account Number, and IFSC are mandatory.',
          type: ToastType.error);
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'DEPLOY PAYMENT NODE',
      message:
          'Deploying these payment details will instantly update the institutional banking channels used by all customer nodes. Proceed with deployment?',
      confirmLabel: 'DEPLOY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFFD97706),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        await SettingsService.instance.saveSettings(
          {
            'upi_id': _upiCtrl.text.trim(),
            'bank_name': _bankNameCtrl.text.trim(),
            'bank_account_name': _holderNameCtrl.text.trim(),
            'bank_account_no': _accNumberCtrl.text.trim(),
            'bank_ifsc': _ifscCtrl.text.trim(),
            'bank_branch': _branchCtrl.text.trim(),
          },
          qrImage: _selectedQrFile, // Pass the XFile directly
        );

        if (!mounted) return;
        ToastService.show(
            title: 'Node Deployed',
            message: 'Payment Gateway channels successfully synchronized.',
            type: ToastType.success);
      } catch (error) {
        if (mounted)
          ToastService.show(
              title: 'Save Failed',
              message: error.toString(),
              type: ToastType.error);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleUploadQR() async {
    final selectedFile = await AppUpload.showImagePickerModal(
      context,
      title: 'Upload QR Code',
    );

    if (selectedFile != null) {
      setState(() {
        _selectedQrFile = selectedFile; // Store as XFile, not File
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: AppLoader())
          : Stack(
              children: [
                Positioned(
                  right: -20,
                  top: 20,
                  child: Icon(
                    Icons.credit_card_outlined,
                    size: 160,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'PAYMENT NODE CONFIGURATION',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'MANAGEMENT OF INSTITUTIONAL PAYMENT CHANNELS AND QR SYNCHRONIZATION',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 40),

                      _buildDarkInputField(
                        label: 'INSTITUTIONAL UPI IDENTIFIER',
                        controller: _upiCtrl,
                        prefixIcon: Icons.bolt,
                        isGoldText: true,
                      ),
                      const SizedBox(height: 32),

                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 32),

                      const Text(
                        'INSTITUTIONAL BANK DETAILS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 24),

                      LayoutBuilder(builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 600;

                        Widget row1 = Row(
                          children: [
                            Expanded(
                                child: _buildDarkInputField(
                                    label: 'BANK NAME',
                                    controller: _bankNameCtrl)),
                            if (!isMobile) const SizedBox(width: 16),
                            if (!isMobile)
                              Expanded(
                                  child: _buildDarkInputField(
                                      label: 'ACCOUNT HOLDER NAME',
                                      controller: _holderNameCtrl)),
                          ],
                        );

                        Widget row2 = Row(
                          children: [
                            Expanded(
                                child: _buildDarkInputField(
                                    label: 'ACCOUNT NUMBER',
                                    controller: _accNumberCtrl)),
                            if (!isMobile) const SizedBox(width: 16),
                            if (!isMobile)
                              Expanded(
                                  child: _buildDarkInputField(
                                      label: 'IFSC CODE',
                                      controller: _ifscCtrl)),
                          ],
                        );

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDarkInputField(
                                  label: 'BANK NAME',
                                  controller: _bankNameCtrl),
                              const SizedBox(height: 16),
                              _buildDarkInputField(
                                  label: 'ACCOUNT HOLDER NAME',
                                  controller: _holderNameCtrl),
                              const SizedBox(height: 16),
                              _buildDarkInputField(
                                  label: 'ACCOUNT NUMBER',
                                  controller: _accNumberCtrl),
                              const SizedBox(height: 16),
                              _buildDarkInputField(
                                  label: 'IFSC CODE', controller: _ifscCtrl),
                              const SizedBox(height: 16),
                              _buildDarkInputField(
                                  label: 'BRANCH NAME',
                                  controller: _branchCtrl),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            row1,
                            const SizedBox(height: 16),
                            row2,
                            const SizedBox(height: 16),
                            _buildDarkInputField(
                                label: 'BRANCH NAME', controller: _branchCtrl),
                          ],
                        );
                      }),
                      const SizedBox(height: 32),

                      // --- 4. QR Code Section ---
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isMobile = constraints.maxWidth < 500;

                          Widget uploadButton = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATIC QR NODE (OPTIONAL)',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white.withOpacity(0.6),
                                    letterSpacing: 1),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: _handleUploadQR,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedQrFile != null
                                            ? 'Change QR Image'
                                            : 'Upload Static QR Code',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color:
                                                Colors.white.withOpacity(0.9)),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                          _selectedQrFile != null
                                              ? Icons.edit
                                              : Icons.add,
                                          color: const Color(0xFFD97706),
                                          size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );

                          Widget qrPreview = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT DYNAMIC PREVIEW',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white.withOpacity(0.6),
                                    letterSpacing: 1),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: _qrBoxSize,
                                height: _qrBoxSize,
                                padding: const EdgeInsets.all(10),
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: _buildQrPreviewImage(),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: _qrBoxSize,
                                child: Text(
                                  _qrCaption,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white.withOpacity(0.6),
                                      letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          );

                          if (isMobile) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                uploadButton,
                                const SizedBox(height: 24),
                                qrPreview,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(child: uploadButton),
                              const SizedBox(width: 32),
                              qrPreview,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 48),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isSaving ? null : _handleDeployPaymentNode,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF1E3A8A), strokeWidth: 2))
                              : const Icon(Icons.save, size: 16),
                          label: Text(
                              _isSaving
                                  ? 'DEPLOYING...'
                                  : 'DEPLOY PAYMENT NODE',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                  letterSpacing: 1.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
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

  static const double _qrBoxSize = 160;
  static const double _qrInnerSize = _qrBoxSize - 20;

  String get _upiId => _upiCtrl.text.trim();
  bool get _hasValidUpi => _upiIdPattern.hasMatch(_upiId);
  bool get _hasUploadedQr =>
      _existingQrUrl != null && _existingQrUrl!.isNotEmpty;

  String get _qrCaption {
    if (_selectedQrFile != null) return 'NEW QR IMAGE (UNSAVED)';
    if (_hasUploadedQr) return 'UPLOADED STATIC QR';
    if (_hasValidUpi) return 'SCAN TO PAY · ${_upiId.toUpperCase()}';
    if (_upiId.isEmpty) return 'ENTER A UPI ID TO GENERATE QR';
    return 'INVALID UPI ID';
  }

  // Cross-Platform Image Preview Handler.
  // Order: newly picked image -> uploaded image from the backend -> QR
  // generated from the UPI ID stored in platform_settings.
  Widget _buildQrPreviewImage() {
    if (_selectedQrFile != null) {
      if (kIsWeb) {
        // Flutter Web supports Network image natively from the ImagePicker Blob URL
        return Image.network(
          _selectedQrFile!.path,
          fit: BoxFit.contain,
          width: _qrInnerSize,
          height: _qrInnerSize,
        );
      }
      // Mobile uses dart:io File
      return Image.file(
        File(_selectedQrFile!.path),
        fit: BoxFit.contain,
        width: _qrInnerSize,
        height: _qrInnerSize,
      );
    }

    if (_hasUploadedQr) {
      return Image.network(
        _existingQrUrl!,
        fit: BoxFit.contain,
        width: _qrInnerSize,
        height: _qrInnerSize,
        // A stale/missing upload falls back to the generated UPI QR.
        errorBuilder: (_, __, ___) => _buildGeneratedUpiQr(),
      );
    }

    return _buildGeneratedUpiQr();
  }

  /// A scannable UPI QR (no fixed amount, so the payer enters it) built from
  /// the UPI ID and account holder name.
  Widget _buildGeneratedUpiQr() {
    if (!_hasValidUpi) {
      return const Icon(
        Icons.qr_code_2,
        size: 80,
        color: Color(0xFF1E3A8A),
      );
    }

    final holder = _holderNameCtrl.text.trim();
    return UPIPaymentQRCode(
      upiDetails: UPIDetails(
        upiID: _upiId,
        // The package puts these straight into the upi:// URI, so encode
        // them to keep spaces from breaking the link in UPI apps.
        payeeName: Uri.encodeComponent(
            holder.isEmpty ? 'Vamanan Enterprises' : holder),
        amount: null,
      ),
      size: _qrInnerSize,
      upiQRErrorCorrectLevel: UPIQRErrorCorrectLevel.medium,
    );
  }

  Widget _buildDarkInputField({
    required String label,
    required TextEditingController controller,
    IconData? prefixIcon,
    bool isGoldText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: isGoldText ? const Color(0xFFFBBF24) : Colors.white),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    color: Colors.white.withOpacity(0.3), size: 18)
                : null,
            fillColor: Colors.white.withOpacity(0.05),
            filled: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFBBF24))),
          ),
        ),
      ],
    );
  }
}
