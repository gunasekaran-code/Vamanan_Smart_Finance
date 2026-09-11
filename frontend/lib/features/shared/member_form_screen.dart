import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/app_upload.dart';
import 'members_screen.dart';

class MemberFormScreen extends StatefulWidget {
  final Member? member;

  const MemberFormScreen({super.key, this.member});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers: Basic Information ---
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController;
  late TextEditingController _emailController;
  late TextEditingController _streetController;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

  // --- Controllers: KYC & Banking Details ---
  late TextEditingController _idNumberController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscController;
  String? _kycFileName;

  // --- Controllers: Nominee Information ---
  late TextEditingController _nomineeNameController;
  late TextEditingController _nomineeRelationController;
  late TextEditingController _nomineePhoneController;
  late TextEditingController _nomineeIdController;

  // --- Controllers: Login Credentials ---
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  // --- Dropdown States ---
  String _selectedBranch = "Main Office";
  String _selectedStatus = "Active Member";
  String _selectedAccountType = "Gold";
  String _selectedIdType = "Aadhaar Card";

  final List<String> _branches = ["Main Office", "Teacher's Colony Branch"];
  final List<String> _statuses = [
    "Active Member",
    "Inactive Member",
    "Suspended"
  ];
  final List<String> _accountTypes = ["Gold", "Walk-in only", "Portal Active"];
  final List<String> _idProofTypes = [
    "Aadhaar Card",
    "PAN Card",
    "Voter ID",
    "Passport"
  ];

  bool get isEditMode => widget.member != null;

  @override
  void initState() {
    super.initState();
    // Initialize Basic Info
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _phoneController = TextEditingController(text: widget.member?.phone ?? '');
    _altPhoneController = TextEditingController();
    _emailController = TextEditingController();
    _streetController = TextEditingController();
    _landmarkController = TextEditingController();
    _cityController = TextEditingController(text: 'Tuticorin');
    _stateController = TextEditingController(text: 'Tamil Nadu');
    _pincodeController = TextEditingController(text: '628002');

    // Initialize KYC & Bank Info
    _idNumberController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _ifscController = TextEditingController();

    // Initialize Nominee Info
    _nomineeNameController = TextEditingController();
    _nomineeRelationController = TextEditingController();
    _nomineePhoneController = TextEditingController();
    _nomineeIdController = TextEditingController();

    // Initialize Credentials
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();

    if (isEditMode) {
      if (_branches.contains(widget.member!.branch)) {
        _selectedBranch = widget.member!.branch;
      }
      if (_statuses.contains(widget.member!.status)) {
        _selectedStatus = widget.member!.status;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();

    _idNumberController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();

    _nomineeNameController.dispose();
    _nomineeRelationController.dispose();
    _nomineePhoneController.dispose();
    _nomineeIdController.dispose();

    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final updatedMember = Member(
        id: isEditMode
            ? widget.member!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        branch: _selectedBranch,
        status: _selectedStatus.contains('Active') ? 'Active' : 'Inactive',
        accountType: _selectedAccountType,
        dateJoined: isEditMode ? widget.member!.dateJoined : 'Aug 24, 2026',
      );

      Navigator.pop(context, updatedMember);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Crisp layout background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Text(
          isEditMode ? 'Edit Member' : 'Add New Member',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.kTextDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Members'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.kTextDark,
                side: const BorderSide(color: AppColors.kBorder),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.kBorder, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- 1. BASIC INFORMATION CARD ---
              _buildSectionCard(
                icon: Icons.badge_outlined,
                iconBgColor: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4F46E5),
                title: 'Basic Information',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Avatar with Image Picker Badge
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                AppUpload.showImagePickerModal(context),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 46,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  child: Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : 'M',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.kTextMuted,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.kSuccess,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'PNG, JPG up to 5MB',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.kTextMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildInputField(
                      label: 'Full Name',
                      controller: _nameController,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    _buildInputField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    _buildInputField(
                      label: 'Alternate Phone',
                      controller: _altPhoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildInputField(
                      label: 'Email Address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildInputField(
                      label: 'Door No / Street',
                      controller: _streetController,
                    ),
                    _buildInputField(
                      label: 'Landmark / Area',
                      controller: _landmarkController,
                    ),
                    _buildInputField(
                      label: 'City / Town',
                      controller: _cityController,
                    ),
                    _buildInputField(
                      label: 'State',
                      controller: _stateController,
                    ),
                    _buildInputField(
                      label: 'Pincode',
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                    ),
                    _buildDropdownField(
                      label: 'Assigned Branch',
                      value: _selectedBranch,
                      items: _branches,
                      onChanged: (val) =>
                          setState(() => _selectedBranch = val!),
                    ),
                    _buildDropdownField(
                      label: 'Status',
                      value: _selectedStatus,
                      items: _statuses,
                      onChanged: (val) =>
                          setState(() => _selectedStatus = val!),
                    ),
                    _buildDropdownField(
                      label: 'Account Status / Type',
                      value: _selectedAccountType,
                      items: _accountTypes,
                      onChanged: (val) =>
                          setState(() => _selectedAccountType = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 2. KYC & BANKING DETAILS CARD ---
              _buildSectionCard(
                icon: Icons.shield_outlined,
                iconBgColor: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF10B981),
                title: 'KYC & Banking Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDropdownField(
                      label: 'ID Proof Type',
                      value: _selectedIdType,
                      items: _idProofTypes,
                      onChanged: (val) =>
                          setState(() => _selectedIdType = val!),
                    ),
                    _buildInputField(
                      label: 'ID Number',
                      controller: _idNumberController,
                    ),

                    // File Upload Input Placeholder
                    // --- KYC DOC ATTACHMENT (Updated with AppUpload integration) ---
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KYC DOC ATTACHMENT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kTextMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () {
                              // Open the AppUpload modal
                              AppUpload.showImagePickerModal(context);

                              // Set mock uploaded file name
                              setState(() {
                                _kycFileName = "aadhaar_card_proof.pdf";
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.kBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.kPrimaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.upload_file_outlined,
                                      size: 20,
                                      color: AppColors.kPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _kycFileName ?? 'Upload KYC Document',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: _kycFileName != null
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: _kycFileName != null
                                                ? AppColors.kTextDark
                                                : AppColors.kTextMuted,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _kycFileName != null
                                              ? 'Tap to change document'
                                              : 'PDF, PNG, or JPG up to 5MB',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.kTextMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_kycFileName != null)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _kycFileName = null;
                                        });
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.cancel,
                                          size: 20,
                                          color: AppColors.kDanger,
                                        ),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: AppColors.kTextMuted,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildInputField(
                      label: 'Bank Name',
                      controller: _bankNameController,
                    ),
                    _buildInputField(
                      label: 'Account Number',
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                    ),
                    _buildInputField(
                      label: 'IFSC Code',
                      controller: _ifscController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 3. NOMINEE INFORMATION CARD ---
              _buildSectionCard(
                icon: Icons.face_outlined,
                iconBgColor: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFF97316),
                title: 'Nominee Information',
                child: Column(
                  children: [
                    _buildInputField(
                      label: 'Nominee Full Name',
                      controller: _nomineeNameController,
                    ),
                    _buildInputField(
                      label: 'Relationship',
                      controller: _nomineeRelationController,
                    ),
                    _buildInputField(
                      label: 'Nominee Phone Number',
                      controller: _nomineePhoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildInputField(
                      label: 'Nominee ID (Aadhaar/PAN)',
                      controller: _nomineeIdController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 4. LOGIN CREDENTIALS CONTAINER ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.lock_outline,
                              size: 20, color: Color(0xFF0284C7)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Login Credentials',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      label: 'Login Username',
                      controller: _usernameController,
                    ),
                    _buildInputField(
                      label: 'Set/Reset Password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.kTextMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- ACTION BUTTONS ---
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kSuccess,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save Member Details',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextDark,
                      side: const BorderSide(color: AppColors.kBorder),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget: Section Card Wrapper
  Widget _buildSectionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // Helper Widget: Standard Input Field
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.kTextMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: const TextStyle(fontSize: 14, color: AppColors.kTextDark),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              fillColor: Colors.white,
              filled: true,
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.kPrimary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget: Standard Dropdown Field
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.kTextMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : items.first,
            onChanged: onChanged,
            icon: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.kTextMuted),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.kPrimary, width: 1.5),
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style:
                      const TextStyle(fontSize: 14, color: AppColors.kTextDark),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
