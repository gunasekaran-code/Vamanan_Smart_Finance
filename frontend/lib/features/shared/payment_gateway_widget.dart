import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class PaymentGatewayWidget extends StatefulWidget {
  const PaymentGatewayWidget({super.key});

  @override
  State<PaymentGatewayWidget> createState() => _PaymentGatewayWidgetState();
}

class _PaymentGatewayWidgetState extends State<PaymentGatewayWidget> {
  // Form Controllers initialized with data from the design
  final TextEditingController _upiCtrl = TextEditingController(text: 'VAMANANENTERPRISES.10027389@csb');
  final TextEditingController _bankNameCtrl = TextEditingController(text: 'CSB Bank Limited');
  final TextEditingController _holderNameCtrl = TextEditingController(text: 'Vamanan Enterprises V');
  final TextEditingController _accNumberCtrl = TextEditingController(text: '0747020000114');
  final TextEditingController _ifscCtrl = TextEditingController(text: 'CSBK0000747');
  final TextEditingController _branchCtrl = TextEditingController(text: 'Krishnagiri');

  @override
  void dispose() {
    _upiCtrl.dispose();
    _bankNameCtrl.dispose();
    _holderNameCtrl.dispose();
    _accNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  // --- Handlers ---

  Future<void> _handleDeployPaymentNode() async {
    // Basic validation
    if (_upiCtrl.text.isEmpty || _accNumberCtrl.text.isEmpty || _ifscCtrl.text.isEmpty) {
      ToastService.show(
        title: 'Validation Error', 
        message: 'UPI Identifier, Account Number, and IFSC are mandatory.', 
        type: ToastType.error
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'DEPLOY PAYMENT NODE',
      message: 'Deploying these payment details will instantly update the institutional banking channels used by all customer nodes. Proceed with deployment?',
      confirmLabel: 'DEPLOY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFFD97706),
    );

    if (confirmed == true) {
      ToastService.show(
        title: 'Node Deployed', 
        message: 'Payment Gateway channels successfully synchronized.', 
        type: ToastType.success
      );
    }
  }

  void _handleUploadQR() {
    ToastService.show(
      title: 'Upload Initiated', 
      message: 'Select a static QR image from your local file system.', 
      type: ToastType.info
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A), // Deep Navy Blue Background
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Watermark Icon
          Positioned(
            right: -20,
            top: 20,
            child: Icon(
              Icons.credit_card_outlined,
              size: 160,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
          
          // Main Content
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 1. Header ---
                const Text(
                  'PAYMENT NODE CONFIGURATION',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'MANAGEMENT OF INSTITUTIONAL PAYMENT CHANNELS AND QR SYNCHRONIZATION',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // --- 2. UPI Identifier ---
                _buildDarkInputField(
                  label: 'INSTITUTIONAL UPI IDENTIFIER',
                  controller: _upiCtrl,
                  prefixIcon: Icons.bolt,
                  isGoldText: true, // Special styling for UPI
                ),
                const SizedBox(height: 32),

                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 32),

                // --- 3. Bank Details Section ---
                const Text(
                  'INSTITUTIONAL BANK DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = constraints.maxWidth < 600;

                    Widget row1 = Row(
                      children: [
                        Expanded(child: _buildDarkInputField(label: 'BANK NAME', controller: _bankNameCtrl)),
                        if (!isMobile) const SizedBox(width: 16),
                        if (!isMobile) Expanded(child: _buildDarkInputField(label: 'ACCOUNT HOLDER NAME', controller: _holderNameCtrl)),
                      ],
                    );

                    Widget row2 = Row(
                      children: [
                        Expanded(child: _buildDarkInputField(label: 'ACCOUNT NUMBER', controller: _accNumberCtrl)),
                        if (!isMobile) const SizedBox(width: 16),
                        if (!isMobile) Expanded(child: _buildDarkInputField(label: 'IFSC CODE', controller: _ifscCtrl)),
                      ],
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDarkInputField(label: 'BANK NAME', controller: _bankNameCtrl),
                          const SizedBox(height: 16),
                          _buildDarkInputField(label: 'ACCOUNT HOLDER NAME', controller: _holderNameCtrl),
                          const SizedBox(height: 16),
                          _buildDarkInputField(label: 'ACCOUNT NUMBER', controller: _accNumberCtrl),
                          const SizedBox(height: 16),
                          _buildDarkInputField(label: 'IFSC CODE', controller: _ifscCtrl),
                          const SizedBox(height: 16),
                          _buildDarkInputField(label: 'BRANCH NAME', controller: _branchCtrl),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        row1,
                        const SizedBox(height: 16),
                        row2,
                        const SizedBox(height: 16),
                        _buildDarkInputField(label: 'BRANCH NAME', controller: _branchCtrl),
                      ],
                    );
                  }
                ),
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
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.6), letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _handleUploadQR,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Upload Static QR Code',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.9)),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.add, color: Color(0xFFD97706), size: 18),
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
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.6), letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.qr_code_2,
                            size: 80,
                            color: Color(0xFF1E3A8A),
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

                // --- 5. Deploy Action Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleDeployPaymentNode,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text(
                      'DEPLOY PAYMENT NODE', 
                      style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1.5)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706), // Gold / Mustard
                      foregroundColor: const Color(0xFF1E3A8A), // Navy text for contrast
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  // --- Helper Widget for Dark Inputs ---

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
            color: Colors.white.withOpacity(0.6), // Light greyish-blue label
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: isGoldText ? const Color(0xFFFBBF24) : Colors.white, // Gold for UPI, White for rest
          ),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null 
                ? Icon(prefixIcon, color: Colors.white.withOpacity(0.3), size: 18) 
                : null,
            fillColor: Colors.white.withOpacity(0.05), // Slightly lighter blue background for the input
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFBBF24)), // Highlight border in gold on focus
            ),
          ),
        ),
      ],
    );
  }
}