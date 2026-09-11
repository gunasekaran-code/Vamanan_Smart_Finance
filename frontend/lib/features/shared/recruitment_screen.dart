import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class RecruitmentScreen extends StatefulWidget {
  const RecruitmentScreen({super.key});

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'STAFF';
  final List<String> _roles = ['STAFF', 'MANAGER', 'ADMINISTRATOR', 'AUDITOR'];

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  void _handleFinalizeOnboarding() {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ToastService.show(
        title: 'Validation Error', 
        message: 'Please complete all identity and security credential fields.', 
        type: ToastType.error
      );
      return;
    }

    ToastService.show(
      title: 'Onboarding Complete', 
      message: '${_nameController.text} has been successfully added to the platform management staff.', 
      type: ToastType.success
    );

    // Clear form after success
    setState(() {
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _selectedRole = 'STAFF';
    });
  }

  void _handleCancel() {
    setState(() {
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _selectedRole = 'STAFF';
    });
    ToastService.show(title: 'Cancelled', message: 'Form cleared.', type: ToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light crisp background
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

              // --- 2. Process Monthly Yield Button ---
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _handleProcessYield,
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('PROCESS MONTHLY YIELD', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 4,
                    shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. Main Onboarding Form Card ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.kBorder),
                ),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Area
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A), // Navy Blue
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PERSONNEL RECRUITMENT',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'ADMINISTRATIVE INTERFACE FOR ONBOARDING ELITE PLATFORM MANAGEMENT STAFF',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.9), letterSpacing: 1, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Form Fields
                    _buildInputField(
                      label: 'FULL IDENTITY',
                      controller: _nameController,
                      hintText: 'E.G. MARCUS AURELIUS',
                    ),
                    const SizedBox(height: 24),
                    
                    _buildInputField(
                      label: 'EMAIL',
                      controller: _emailController,
                      hintText: 'staff.node@makkalgold.com',
                      keyboardType: TextInputType.emailAddress,
                      isLowercaseHint: true,
                    ),
                    const SizedBox(height: 24),

                    _buildDropdownField(
                      label: 'SYSTEM ROLE',
                      value: _selectedRole,
                      items: _roles,
                      onChanged: (val) => setState(() => _selectedRole = val!),
                      helperText: 'ACCESS PERMISSIONS ARE ASSIGNED MANUALLY IN SETTINGS → ACCESS CONTROL',
                    ),
                    const SizedBox(height: 24),

                    _buildInputField(
                      label: 'SECURITY CREDENTIALS',
                      controller: _passwordController,
                      hintText: '••••••••',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFFCBD5E1), size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Protocol Authorization Note Banner
                    Container(
                      clipBehavior: Clip.antiAlias, // To clip the watermark icon
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB), // Light amber tint
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Stack(
                        children: [
                          // Watermark Icon
                          Positioned(
                            right: -20,
                            top: -20,
                            bottom: -20,
                            child: Icon(
                              Icons.security,
                              size: 140,
                              color: const Color(0xFFD97706).withOpacity(0.05),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 18),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'PROTOCOL AUTHORIZATION NOTE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFD97706),
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'NEWLY ONBOARDED STAFF WILL BE REQUIRED TO INITIALIZE SECONDARY ENCRYPTION AND SYNCHRONIZE CREDENTIALS UPON THEIR PRIMARY SESSION ENTRY. VERIFICATION OF NODE EMAIL IS MANDATORY.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF475569), // Darker slate for readability
                                    height: 1.6,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Action Buttons (Responsive Layout)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 500;
                        
                        Widget finalizeBtn = ElevatedButton.icon(
                          onPressed: _handleFinalizeOnboarding,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('FINALIZE ONBOARDING', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 2)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        );

                        Widget cancelBtn = OutlinedButton(
                          onPressed: _handleCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF94A3B8),
                            side: const BorderSide(color: AppColors.kBorder),
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1)),
                        );

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              finalizeBtn,
                              const SizedBox(height: 16),
                              cancelBtn,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(flex: 3, child: finalizeBtn),
                            const SizedBox(width: 16),
                            Expanded(flex: 1, child: cancelBtn),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    bool isLowercaseHint = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.kTextMuted.withOpacity(0.8), 
              fontWeight: FontWeight.w900, 
              fontStyle: isLowercaseHint ? FontStyle.normal : FontStyle.italic, // Keep emails non-italic if preferred, though design shows it italic
              fontSize: 14
            ),
            suffixIcon: suffixIcon,
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          icon: const Icon(Icons.verified_user_outlined, color: Color(0xFFD97706), size: 18), // Amber shield icon
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
          decoration: InputDecoration(
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 8),
          Text(helperText, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
        ]
      ],
    );
  }
}