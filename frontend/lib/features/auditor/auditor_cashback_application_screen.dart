import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // Required for XFile
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/app_upload.dart';
import '../../models/auditor_cashback_application_model.dart';
import '../../services/auditor_cashback_application_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class AuditorCashbackApplicationScreen extends StatefulWidget {
  final int userId;

  const AuditorCashbackApplicationScreen({super.key, required this.userId});

  @override
  State<AuditorCashbackApplicationScreen> createState() => _AuditorCashbackApplicationScreenState();
}

class _AuditorCashbackApplicationScreenState extends State<AuditorCashbackApplicationScreen> {
  // --- Controllers for Card 1: Basic Details ---
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _customerIdCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();

  // --- Controllers for Card 2: Purchase Details ---
  final _invoiceAmountCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _dateOfPurchaseCtrl = TextEditingController();

  // --- Controllers for Card 3: Payment Details ---
  final _bankRecordNameCtrl = TextEditingController();
  final _accountNumCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankBranchCtrl = TextEditingController();

  // --- Controllers for Card 4: Agent Details ---
  final _agentNameCtrl = TextEditingController();
  final _agentIdCtrl = TextEditingController();

  // --- Controllers for Card 5: Declaration ---
  final _declDateCtrl = TextEditingController();
  final _declPlaceCtrl = TextEditingController();

  final Color _navyBlue = AppColors.kPrimaryDark;
  final Color _slateText = AppColors.kTextMuted;
  final Color _lightBorder = const Color(0xFFF1F5F9);
  final Color _lightBg = const Color(0xFFF8FAFC);

  final _apiDateFmt = DateFormat('yyyy-MM-dd');
  final _displayDateFmt = DateFormat('dd/MM/yyyy');

  DateTime? _purchaseDate;
  DateTime _declarationDate = DateTime.now();

  XFile? _uploadedInvoice; // client-side only — see note in _handleSubmitApplication

  bool _loading = true;
  bool _submitting = false;
  String? _loadError;
  CashbackApplication? _existingApplication;

  @override
  void initState() {
    super.initState();
    _declDateCtrl.text = _displayDateFmt.format(_declarationDate);
    _loadPrefill();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose(); _phoneCtrl.dispose();
    _aadhaarCtrl.dispose(); _panCtrl.dispose(); _customerIdCtrl.dispose();
    _branchCtrl.dispose(); _invoiceAmountCtrl.dispose();
    _productCtrl.dispose(); _dateOfPurchaseCtrl.dispose(); _bankRecordNameCtrl.dispose();
    _accountNumCtrl.dispose(); _ifscCtrl.dispose(); _bankNameCtrl.dispose();
    _bankBranchCtrl.dispose(); _agentNameCtrl.dispose(); _agentIdCtrl.dispose();
    _declDateCtrl.dispose(); _declPlaceCtrl.dispose();
    super.dispose();
  }

  // --- DATA LOADING ---

  Future<void> _loadPrefill() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final prefill = await AuditorCashbackApplicationService.fetchPrefill(widget.userId);
      final user = prefill.user;
      final app = prefill.application;
      _existingApplication = app;

      _nameCtrl.text = app?.customerName.isNotEmpty == true ? app!.customerName : user.name;
      _addressCtrl.text = app?.address.isNotEmpty == true ? app!.address : user.address;
      _phoneCtrl.text = app?.phone.isNotEmpty == true ? app!.phone : user.phone;
      _aadhaarCtrl.text = app?.aadharNo.isNotEmpty == true ? app!.aadharNo : user.aadharNo;
      _panCtrl.text = app?.panNo.isNotEmpty == true ? app!.panNo : user.panNo;
      _customerIdCtrl.text = app?.customerCode.isNotEmpty == true ? app!.customerCode : user.customerId;
      _branchCtrl.text = user.branchName;

      _invoiceAmountCtrl.text = (app?.purchaseAmount ?? 0) > 0 ? app!.purchaseAmount.toStringAsFixed(2) : '';
      _productCtrl.text = app?.purchasedProduct ?? '';
      _purchaseDate = app?.purchaseDate;
      _dateOfPurchaseCtrl.text = _purchaseDate != null ? _displayDateFmt.format(_purchaseDate!) : '';

      _bankRecordNameCtrl.text = app?.bankAccountName.isNotEmpty == true ? app!.bankAccountName : user.name;
      _accountNumCtrl.text = app?.accountNo.isNotEmpty == true ? app!.accountNo : user.accountNo;
      _ifscCtrl.text = app?.ifscCode.isNotEmpty == true ? app!.ifscCode : user.ifscCode;
      _bankNameCtrl.text = app?.bankName.isNotEmpty == true ? app!.bankName : user.bankName;
      _bankBranchCtrl.text = app?.bankBranch ?? '';

      _agentNameCtrl.text = app?.agentName ?? '';
      _agentIdCtrl.text = app?.agentId ?? '';

      _declPlaceCtrl.text = app?.place ?? 'Krishnagiri';

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Failed to load your details. Pull to refresh or try again.';
      });
    }
  }

  // --- ACTIONS ---

  Future<void> _handleUploadInvoice() async {
    final file = await AppUpload.showImagePickerModal(
      context,
      title: 'Upload Invoice Document',
    );
    if (file != null) {
      setState(() => _uploadedInvoice = file);
    }
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
        _dateOfPurchaseCtrl.text = _displayDateFmt.format(picked);
      });
    }
  }

  Future<void> _pickDeclarationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _declarationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _declarationDate = picked;
        _declDateCtrl.text = _displayDateFmt.format(picked);
      });
    }
  }

  bool get _canSubmit => _existingApplication == null || _existingApplication!.isRejected;

  Future<void> _handleSubmitApplication() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _invoiceAmountCtrl.text.trim().isEmpty ||
        _accountNumCtrl.text.trim().isEmpty ||
        _ifscCtrl.text.trim().isEmpty) {
      ToastService.show(
        title: 'Missing Details',
        message: 'Name, phone, purchase amount, account number and IFSC code are required.',
        type: ToastType.warning,
      );
      return;
    }

    final amount = double.tryParse(_invoiceAmountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ToastService.show(
        title: 'Invalid Amount',
        message: 'Enter a valid invoice amount.',
        type: ToastType.warning,
      );
      return;
    }

    // NOTE: /customer/cashback_application.php has no file-upload field yet —
    // the invoice picker is captured client-side only until a multipart
    // upload endpoint exists. We still require a selection so the auditor
    // has the document in hand before submitting.
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
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      final request = CashbackApplicationRequest(
        userId: widget.userId,
        customerName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        purchaseAmount: amount,
        accountNo: _accountNumCtrl.text.trim(),
        ifscCode: _ifscCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        aadharNo: _aadhaarCtrl.text.trim(),
        panNo: _panCtrl.text.trim(),
        customerCode: _customerIdCtrl.text.trim(),
        purchasedProduct: _productCtrl.text.trim(),
        purchaseDate: _purchaseDate != null ? _apiDateFmt.format(_purchaseDate!) : null,
        bankAccountName: _bankRecordNameCtrl.text.trim(),
        bankName: _bankNameCtrl.text.trim(),
        bankBranch: _bankBranchCtrl.text.trim(),
        agentName: _agentNameCtrl.text.trim(),
        agentId: _agentIdCtrl.text.trim(),
        place: _declPlaceCtrl.text.trim(),
        applicationDate: _apiDateFmt.format(_declarationDate),
      );

      await AuditorCashbackApplicationService.submit(request);

      if (!mounted) return;
      ToastService.show(
        title: 'Application Submitted',
        message: 'Your cashback request has been successfully routed for verification.',
        type: ToastType.success,
      );
      await _loadPrefill(); // refresh status banner with the new pending record
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: 'Submission Failed',
        message: e.toString().replaceFirst('Exception: ', ''),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

@override
  Widget build(BuildContext context) {
    return AppPage(
      title: null,
      children: [
        Center(
          child: Container(
                        constraints: const BoxConstraints(maxWidth: 800), 
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: AppLoader()),
                  )
                : Column(
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
                      const SizedBox(height: 24),

                      if (_loadError != null) _buildErrorBanner(),
                      if (_existingApplication != null) _buildStatusBanner(_existingApplication!),
                      const SizedBox(height: 8),

                      // 2. BASIC DETAILS CARD
                      _buildSectionCard(
                        title: 'BASIC DETAILS',
                        icon: Icons.person_outline,
                        children: [
                          _buildInputField('FULL NAME / ENTITY', 'Full Name', Icons.person_outline, _nameCtrl),
                          _buildInputField('ADDRESS', 'Full Address', Icons.location_on_outlined, _addressCtrl),
                          _buildInputField('PHONE NUMBER', '+91 00000 00000', Icons.phone_outlined, _phoneCtrl, isNumber: true),
                          _buildInputField('AADHAAR NUMBER', 'Aadhaar Number', Icons.fingerprint, _aadhaarCtrl),
                          _buildInputField('PAN NO', 'ABCDE1234F', Icons.badge_outlined, _panCtrl),
                          _buildInputField('CUSTOMER ID', 'Customer ID', Icons.numbers, _customerIdCtrl),
                          _buildInputField('PURCHASE BRANCH', 'Branch', Icons.store_outlined, _branchCtrl, readOnly: true),
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
                          _buildDateField('DATE OF PURCHASE', Icons.calendar_today_outlined, _dateOfPurchaseCtrl, _pickPurchaseDate),
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
                          _buildInputField('NAME (AS PER BANK RECORD)', 'Name as per bank', Icons.person_pin_outlined, _bankRecordNameCtrl),
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
                          _buildDateField('DATE', Icons.calendar_month_outlined, _declDateCtrl, _pickDeclarationDate),
                          _buildInputField('PLACE', 'Krishnagiri', Icons.place_outlined, _declPlaceCtrl),
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
                          onPressed: (!_canSubmit || _submitting) ? null : _handleSubmitApplication,
                          icon: _submitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          label: Text(
                            _canSubmit ? 'SUBMIT APPLICATION' : 'APPLICATION ${_existingApplication!.status.toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _navyBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _navyBlue.withOpacity(0.4),
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
  // STATUS / ERROR BANNERS
  // ==========================================================================
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFECACA))),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(_loadError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w700))),
          TextButton(onPressed: _loadPrefill, child: const Text('RETRY')),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(CashbackApplication app) {
    final Color color = app.isApproved
        ? const Color(0xFF16A34A)
        : app.isRejected
            ? const Color(0xFFDC2626)
            : const Color(0xFFF59E0B);
    final String label = app.isApproved
        ? 'Your last cashback application was approved.'
        : app.isRejected
            ? 'Your last application was rejected — you can submit a new one below.'
            : 'You already have an application pending verification.';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(app.isApproved ? Icons.check_circle_outline : app.isRejected ? Icons.cancel_outlined : Icons.hourglass_top_outlined, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800))),
        ],
      ),
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
              Text(title, style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String hint, IconData icon, TextEditingController controller, {bool isNumber = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
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

  Widget _buildDateField(String label, IconData icon, TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFFCBD5E1), size: 18),
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFFCBD5E1)),
              hintText: 'DD/MM/YYYY',
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

  Widget _buildUploadBox() {
    final hasFile = _uploadedInvoice != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('UPLOAD INVOICE / RECEIPT', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _handleUploadInvoice,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _lightBorder, width: 2)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _lightBorder)),
                  child: Icon(hasFile ? Icons.check_circle : Icons.cloud_upload_outlined, color: hasFile ? AppColors.kSuccess : const Color(0xFFCBD5E1), size: 24),
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