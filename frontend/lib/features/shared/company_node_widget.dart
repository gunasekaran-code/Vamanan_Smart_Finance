import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class CompanyNodeWidget extends StatefulWidget {
  const CompanyNodeWidget({super.key});

  @override
  State<CompanyNodeWidget> createState() => _CompanyNodeWidgetState();
}

class _CompanyNodeWidgetState extends State<CompanyNodeWidget> {
  // Form Controllers initialized with the data from the design
  final TextEditingController _companyNameCtrl = TextEditingController(text: 'VAMANAN ENTERPRISES V');
  final TextEditingController _addressCtrl = TextEditingController(text: '123, Gold Plaza, Main Road, City, State, 600001');
  final TextEditingController _phoneCtrl = TextEditingController(text: '+91 90000 00000');
  final TextEditingController _emailCtrl = TextEditingController(text: 'support@makkalgold.com');

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _handleSynchronizeNodeInfo() {
    // Basic validation
    if (_companyNameCtrl.text.isEmpty || _addressCtrl.text.isEmpty) {
      ToastService.show(
        title: 'Validation Error', 
        message: 'Company nomenclature and headquarters address are mandatory.', 
        type: ToastType.error
      );
      return;
    }

    ToastService.show(
      title: 'Node Synchronized', 
      message: 'Company institutional details have been updated globally.', 
      type: ToastType.success
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Company Name Field
          _buildInputField(
            label: 'INSTITUTIONAL NOMENCLATURE (COMPANY NAME)',
            controller: _companyNameCtrl,
          ),
          const SizedBox(height: 24),

          // 2. Headquarters Address Field
          _buildInputField(
            label: 'HEADQUARTERS LOCATION ADDRESS',
            controller: _addressCtrl,
            maxLines: 4, // Multiline textarea as seen in design
          ),
          const SizedBox(height: 24),

          // 3. Contact Info (Responsive Row)
          LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;

              Widget phoneInput = _buildInputField(
                label: 'SUPPORT DISPATCH HOTLINE',
                controller: _phoneCtrl,
                prefixIcon: Icons.phone_outlined,
              );

              Widget emailInput = _buildInputField(
                label: 'INSTITUTIONAL SUPPORT EMAIL',
                controller: _emailCtrl,
                prefixIcon: Icons.email_outlined,
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    phoneInput,
                    const SizedBox(height: 24),
                    emailInput,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: phoneInput),
                  const SizedBox(width: 24),
                  Expanded(child: emailInput),
                ],
              );
            }
          ),
          const SizedBox(height: 40),

          // 4. Action Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _handleSynchronizeNodeInfo,
              icon: const Icon(Icons.language, size: 16), // Globe/Node icon
              label: const Text(
                'SYNCHRONIZE NODE INFO', 
                style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.5)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: const Color(0xFF1E3A8A).withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget ---

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.w900, 
            fontStyle: FontStyle.italic, 
            color: Color(0xFF94A3B8), 
            letterSpacing: 1,
            height: 1.5,
          )
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: maxLines > 1 ? 14 : 16, // Slightly larger font for single line inputs to match design
            fontWeight: FontWeight.w900, 
            fontStyle: FontStyle.italic, 
            color: const Color(0xFF1E3A8A),
          ),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null 
                ? Icon(prefixIcon, color: const Color(0xFFCBD5E1), size: 20) 
                : null,
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: const BorderSide(color: AppColors.kBorder)
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: const BorderSide(color: AppColors.kBorder)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: const BorderSide(color: Color(0xFF1E3A8A))
            ),
          ),
        ),
      ],
    );
  }
}