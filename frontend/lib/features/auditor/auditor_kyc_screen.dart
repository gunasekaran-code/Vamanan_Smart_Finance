import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/app_upload.dart'; 

class AuditorKycScreen extends StatefulWidget {
  const AuditorKycScreen({super.key});

  @override
  State<AuditorKycScreen> createState() => _AuditorKycScreenState();
}

class _AuditorKycScreenState extends State<AuditorKycScreen> {
  // Form Controllers
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _aadhaarCtrl = TextEditingController();
  final TextEditingController _panCtrl = TextEditingController();
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _accNumCtrl = TextEditingController();
  final TextEditingController _ifscCtrl = TextEditingController();
  final TextEditingController _branchCtrl = TextEditingController();

  XFile? _uploadedDocument;

  // Exact Colors from the design
  final Color _navyBlue = const Color(0xFF1B233A);
  final Color _lightBorder = const Color(0xFFF1F5F9);
  final Color _lightBg = const Color(0xFFF8FAFC);
  final Color _slateText = const Color(0xFF94A3B8);

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _aadhaarCtrl.dispose();
    _panCtrl.dispose();
    _bankNameCtrl.dispose();
    _accNumCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  // --- ACTIONS ---
  Future<void> _handleUpload() async {
    final file = await AppUpload.showImagePickerModal(
      context, 
      title: 'Upload KYC Document'
    );
    if (file != null) {
      setState(() {
        _uploadedDocument = file;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_uploadedDocument == null) {
      ToastService.show(
        title: 'Missing Document',
        message: 'Please upload your KYC documents before submitting.',
        type: ToastType.warning,
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Submit KYC',
      message: 'Are you sure you want to submit these details for verification? Make sure all documents are clearly visible.',
      confirmLabel: 'Submit Documents',
      confirmButtonColor: _navyBlue,
    );

    if (confirmed == true) {
      ToastService.show(
        title: 'KYC Submitted',
        message: 'Your verification request is being processed. It usually takes 24-48 hours.',
        type: ToastType.success,
      );
      // Add logic to pop screen or change state here
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null, // Custom Header
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600), // Perfect for mobile & tablet
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. HEADER
                Row(
                  children: const [
                    Icon(Icons.star, color: AppColors.goldColor, size: 10),
                    SizedBox(width: 4),
                    Text('VERIFICATION', style: TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('KYC VERIFICATION', style: TextStyle(color: _navyBlue, fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('VERIFY YOUR IDENTITY TO UNLOCK WITHDRAWALS AND REWARDS', style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                const SizedBox(height: 32),

                // 2. PERSONAL DETAILS CARD
                _buildFormCard(
                  title: 'PERSONAL DETAILS',
                  icon: Icons.person_outline,
                  children: [
                    _buildInputField('PHONE NUMBER', '+91 00000 00000', Icons.phone_outlined, _phoneCtrl),
                    _buildInputField('ADDRESS', 'Your full address', Icons.location_on_outlined, _addressCtrl),
                    _buildInputField('AADHAAR NUMBER', '0000 0000 0000', Icons.fingerprint, _aadhaarCtrl),
                    _buildInputField('PAN NUMBER', 'ABCDE1234F', Icons.badge_outlined, _panCtrl),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. BANK DETAILS CARD
                _buildFormCard(
                  title: 'BANK DETAILS',
                  icon: Icons.account_balance_outlined,
                  children: [
                    _buildInputField('BANK NAME', 'E.G. STATE BANK OF INDIA', Icons.account_balance, _bankNameCtrl),
                    _buildInputField('ACCOUNT NUMBER', '00000000000', Icons.numbers, _accNumCtrl),
                    _buildInputField('IFSC CODE', 'SBIN0000000', Icons.code, _ifscCtrl),
                    _buildInputField('BRANCH NAME', 'E.G. CHENNAI MAIN', Icons.store_outlined, _branchCtrl),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. UPLOAD DOCUMENTS CARD
                _buildUploadCard(),
                const SizedBox(height: 16),

                // 5. SECURITY INFO BOX
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _navyBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.white.withOpacity(0.5), size: 24),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'YOUR DOCUMENTS ARE STORED SECURELY. VERIFICATION NORMALLY TAKES 24-48 HOURS.',
                          style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.8, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 6. SUBMIT BUTTON
                ElevatedButton.icon(
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('SUBMIT KYC DOCUMENTS', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 14, letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kSuccess, // Or _navyBlue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildFormCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _navyBlue, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField(String label, String hint, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFFCBD5E1), size: 18),
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
              filled: true,
              fillColor: Colors.white,
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

  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _lightBorder, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.goldBadgeBg, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.file_copy_outlined, color: AppColors.goldColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text('UPLOAD DOCUMENTS', style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.goldBadgeBg, borderRadius: BorderRadius.circular(12)),
                child: const Text('REQUIRED', style: TextStyle(color: AppColors.goldColor, fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              )
            ],
          ),
          const SizedBox(height: 32),
          
          // Checklist
          _buildChecklistItem('01', 'AADHAAR CARD', 'FRONT & BACK SIDE'),
          _buildChecklistItem('02', 'PAN CARD', 'FULL CLEAR PHOTO'),
          _buildChecklistItem('03', 'BANK PROOF', 'PASSBOOK / CHEQUE'),
          
          const SizedBox(height: 32),

          // Upload Box Area
          InkWell(
            onTap: _handleUpload,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: _lightBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _lightBorder, width: 2), // Mimicking the dashed box with a faint solid border
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _lightBorder)),
                    child: Icon(
                      _uploadedDocument != null ? Icons.check_circle : Icons.upload_file, 
                      color: _uploadedDocument != null ? AppColors.kSuccess : const Color(0xFFCBD5E1), 
                      size: 28
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _uploadedDocument != null ? 'DOCUMENT SELECTED' : 'CLICK TO UPLOAD', 
                    style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _uploadedDocument != null ? _uploadedDocument!.name : 'PDF / IMAGES CONTAINING ALL DOCS (MAX: 5MB)', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String number, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lightBorder),
      ),
      child: Row(
        children: [
          Text(number, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: _navyBlue, fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}