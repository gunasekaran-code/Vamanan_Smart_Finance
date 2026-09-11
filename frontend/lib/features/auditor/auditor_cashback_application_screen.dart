import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Required for XFile
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/app_upload.dart'; // Integrated AppUpload import

class AuditorCashbackApplicationScreen extends StatefulWidget {
  const AuditorCashbackApplicationScreen({super.key});

  @override
  State<AuditorCashbackApplicationScreen> createState() => _AuditorCashbackApplicationScreenState();
}

class _AuditorCashbackApplicationScreenState extends State<AuditorCashbackApplicationScreen> {
  // --- Controllers for Card 1: Basic Details ---
  final _nameCtrl = TextEditingController(text: 'Test Profile');
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController(); 
  final _panCtrl = TextEditingController();
  final _customerIdCtrl = TextEditingController(text: 'VEV099');
  final _branchCtrl = TextEditingController(text: 'VAMANAN KRISHNAGIRI');
  final _passwordCtrl = TextEditingController(text: 'VEV09924');

  // --- Controllers for Card 2: Purchase Details ---
  final _invoiceAmountCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _dateOfPurchaseCtrl = TextEditingController(text: '26/8/2026');

  // --- Controllers for Card 3: Payment Details ---
  final _bankRecordNameCtrl = TextEditingController(text: 'Test Auditor');
  final _accountNumCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankBranchCtrl = TextEditingController();

  // --- Controllers for Card 4: Agent Details ---
  final _agentNameCtrl = TextEditingController();
  final _agentIdCtrl = TextEditingController();

  // --- Controllers for Card 5: Declaration ---
  final _declDateCtrl = TextEditingController(text: '26/8/2026');
  final _declPlaceCtrl = TextEditingController();

  // Theme Constants based on your provided colors
  final Color _navyBlue = AppColors.kPrimaryDark;
  final Color _slateText = AppColors.kTextMuted;
  final Color _lightBorder = const Color(0xFFF1F5F9);
  final Color _lightBg = const Color(0xFFF8FAFC);
  
  bool _obsPassword = true;
  
  // File state variable to hold the uploaded document
  XFile? _uploadedInvoice;

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose(); _phoneCtrl.dispose();
    _aadhaarCtrl.dispose(); _panCtrl.dispose(); _customerIdCtrl.dispose();
    _branchCtrl.dispose(); _passwordCtrl.dispose(); _invoiceAmountCtrl.dispose();
    _productCtrl.dispose(); _dateOfPurchaseCtrl.dispose(); _bankRecordNameCtrl.dispose();
    _accountNumCtrl.dispose(); _ifscCtrl.dispose(); _bankNameCtrl.dispose();
    _bankBranchCtrl.dispose(); _agentNameCtrl.dispose(); _agentIdCtrl.dispose();
    _declDateCtrl.dispose(); _declPlaceCtrl.dispose();
    super.dispose();
  }

  // --- ACTIONS ---
  
  // Updated Upload Handler utilizing AppUpload
  Future<void> _handleUploadInvoice() async {
    final file = await AppUpload.showImagePickerModal(
      context,
      title: 'Upload Invoice Document',
    );
    
    if (file != null) {
      setState(() {
        _uploadedInvoice = file;
      });
      // Note: Toast is already handled inside your AppUpload class upon selection!
    }
  }

  Future<void> _handleSubmitApplication() async {
    if (_uploadedInvoice == null) {
      ToastService.show(
        title: 'Missing Document',
        message: 'Please upload the invoice/receipt before submitting.',
        type: ToastType.warning,
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Submit Application',
      message: 'Are you sure you want to submit this cashback application? Ensure all details and attachments are accurate.',
      confirmLabel: 'Submit Application',
      confirmButtonColor: _navyBlue,
    );

    if (confirmed == true) {
      ToastService.show(
        title: 'Application Submitted',
        message: 'Your cashback request has been successfully routed for verification.',
        type: ToastType.success,
      );
      // Logic to return to previous screen or reset form can go here
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // Custom Header
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800), // Mobile & Tablet constraints
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HEADER
                Row(
                  children: const [
                    Icon(Icons.folder_outlined, color: AppColors.goldColor, size: 12),
                    SizedBox(width: 6),
                    Text(
                      'APPLICATIONS / NEW',
                      style: TextStyle(color: AppColors.goldColor, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'CASHBACK APPLICATION',
                  style: TextStyle(color: _navyBlue, fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0),
                ),
                const SizedBox(height: 4),
                Text(
                  'SUBMIT YOUR PURCHASE DETAILS TO CLAIM CASHBACK REWARDS',
                  style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
                ),
                const SizedBox(height: 32),

                // 2. BASIC DETAILS CARD
                _buildSectionCard(
                  title: 'BASIC DETAILS',
                  icon: Icons.person_outline,
                  children: [
                    _buildInputField('FULL NAME / ENTITY', 'Test Profile', Icons.person_outline, _nameCtrl),
                    _buildInputField('ADDRESS', 'Full Address', Icons.location_on_outlined, _addressCtrl),
                    _buildInputField('PHONE NUMBER', '+91 00000 00000', Icons.phone_outlined, _phoneCtrl, isNumber: true),
                    _buildInputField('AADHAAR NUMBER', '[Aadhaar Redacted]', Icons.fingerprint, _aadhaarCtrl), // Security protocol compliance
                    _buildInputField('PAN NO', 'ABCDE1234F', Icons.badge_outlined, _panCtrl),
                    _buildInputField('CUSTOMER ID', 'VEV099', Icons.numbers, _customerIdCtrl),
                    _buildInputField('PURCHASE BRANCH', 'VAMANAN KRISHNAGIRI', Icons.store_outlined, _branchCtrl),
                    _buildPasswordField('CUSTOMER PASSWORD', '••••••••', Icons.lock_outline, _passwordCtrl),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. PURCHASE DETAILS CARD
                _buildSectionCard(
                  title: 'PURCHASE DETAILS',
                  icon: Icons.shopping_bag_outlined,
                  children: [
                    _buildInputField('TOTAL VALUE INVOICE AMOUNT (₹)', '0.00', Icons.currency_rupee, _invoiceAmountCtrl, isNumber: true),
                    _buildInputField('PURCHASED PRODUCT', 'E.g. 22K Gold Coin', Icons.workspace_premium_outlined, _productCtrl),
                    _buildInputField('DATE OF PURCHASE', 'DD/MM/YYYY', Icons.calendar_today_outlined, _dateOfPurchaseCtrl),
                    const SizedBox(height: 8),
                    _buildUploadBox(),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. PAYMENT DETAILS CARD
                _buildSectionCard(
                  title: 'PAYMENT DETAILS',
                  icon: Icons.account_balance_outlined,
                  children: [
                    _buildInputField('NAME (AS PER BANK RECORD)', 'Test Auditor', Icons.person_pin_outlined, _bankRecordNameCtrl),
                    _buildInputField('ACCOUNT NUMBER', '00000000000', Icons.numbers, _accountNumCtrl, isNumber: true),
                    _buildInputField('IFSC CODE', 'E.g. SBIN0000000', Icons.code, _ifscCtrl),
                    _buildInputField('BANK NAME', 'E.g. State Bank of India', Icons.account_balance, _bankNameCtrl),
                    _buildInputField('BANK BRANCH', 'E.g. Chennai Main', Icons.map_outlined, _bankBranchCtrl),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. AGENT / REFERRAL DETAILS CARD
                _buildSectionCard(
                  title: 'AGENT / REFERRAL DETAILS',
                  icon: Icons.handshake_outlined,
                  children: [
                    _buildInputField('AGENT NAME', 'Agent / Referrer Name', Icons.person_search_outlined, _agentNameCtrl),
                    _buildInputField('AGENT ID / REFERRAL CODE', 'Agent ID', Icons.badge_outlined, _agentIdCtrl),
                  ],
                ),
                const SizedBox(height: 24),

                // 6. DECLARATION CARD
                _buildSectionCard(
                  title: 'DECLARATION',
                  icon: Icons.gavel_outlined,
                  children: [
                    _buildInputField('DATE', 'DD/MM/YYYY', Icons.calendar_month_outlined, _declDateCtrl),
                    _buildInputField('PLACE', 'krishnagiri', Icons.place_outlined, _declPlaceCtrl),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _navyBlue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: _navyBlue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified_user_outlined, color: Colors.white70, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'I attest that the information provided is true and accurate. I agree to the platform\'s cashback processing timeline and terms of service.',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, letterSpacing: 0.5, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 7. SUBMIT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleSubmitApplication,
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    label: const Text('SUBMIT APPLICATION', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      elevation: 10,
                      shadowColor: _navyBlue.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // HELPER WIDGETS
  // ==========================================================================

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String hint, IconData icon, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFFCBD5E1), size: 18),
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
              filled: true,
              fillColor: _lightBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kPrimary, width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, String hint, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: _obsPassword,
            style: TextStyle(color: _navyBlue, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFFCBD5E1), size: 18),
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
              filled: true,
              fillColor: _lightBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kPrimary, width: 2)),
              suffixIcon: IconButton(
                icon: Icon(_obsPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFFCBD5E1), size: 18),
                onPressed: () => setState(() => _obsPassword = !_obsPassword),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox() {
    final hasFile = _uploadedInvoice != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UPLOAD INVOICE / RECEIPT',
          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _handleUploadInvoice,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: _lightBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _lightBorder, width: 2),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _lightBorder),
                  ),
                  child: Icon(
                    hasFile ? Icons.check_circle : Icons.cloud_upload_outlined,
                    color: hasFile ? AppColors.kSuccess : const Color(0xFFCBD5E1),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  hasFile ? 'INVOICE ATTACHED' : 'DROP FILE HERE OR TAP TO SELECT',
                  style: TextStyle(color: _navyBlue, fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  hasFile ? _uploadedInvoice!.name : 'SUPPORTED: PDF, JPG, PNG (MAX 5MB)',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _slateText, fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}