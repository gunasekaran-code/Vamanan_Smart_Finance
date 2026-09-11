import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class AuditorRequestScreen extends StatefulWidget {
  const AuditorRequestScreen({super.key});

  @override
  State<AuditorRequestScreen> createState() => _AuditorRequestScreenState();
}

class _AuditorRequestScreenState extends State<AuditorRequestScreen> {
  // Form Controllers
  final _productNameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'Gold'); // Default
  final _productModelCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();

  // State Variables
  int _quantity = 1;
  double _weight = 0.0;

  // Theme Colors based on your AppTheme
  final Color _navyBlue = AppColors.kPrimaryDark;
  final Color _slateText = AppColors.kTextMuted;
  final Color _lightBorder = const Color(0xFFF1F5F9);
  final Color _lightBg = const Color(0xFFF8FAFC);

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _categoryCtrl.dispose();
    _productModelCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  // --- ACTIONS ---
  Future<void> _handleSubmitRequest() async {
    if (_productNameCtrl.text.trim().isEmpty) {
      ToastService.show(
        title: 'Missing Details',
        message: 'Please provide a product name before submitting.',
        type: ToastType.warning,
      );
      return;
    }

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Submit Product Request',
      message: 'Are you sure you want to request the addition of "${_productNameCtrl.text}" to the catalogue?',
      confirmLabel: 'Submit Request',
      confirmButtonColor: _navyBlue,
    );

    if (confirmed == true) {
      ToastService.show(
        title: 'Request Submitted',
        message: 'Your product request has been forwarded to the admin team for review.',
        type: ToastType.success,
      );

      // Clear the form
      setState(() {
        _productNameCtrl.clear();
        _productModelCtrl.clear();
        _detailsCtrl.clear();
        _quantity = 1;
        _weight = 0.0;
      });
    }
  }

  void _incrementQuantity(int delta) {
    setState(() {
      if (_quantity + delta > 0) {
        _quantity += delta;
      }
    });
  }

  void _incrementWeight(double delta) {
    setState(() {
      if (_weight + delta >= 0) {
        _weight += delta;
      }
    });
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
                    Icon(Icons.star, color: AppColors.goldColor, size: 10),
                    SizedBox(width: 6),
                    Text(
                      'CATALOGUE',
                      style: TextStyle(color: AppColors.goldColor, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 2.0),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'REQUEST A PRODUCT',
                  style: TextStyle(color: _navyBlue, fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1.0),
                ),
                const SizedBox(height: 4),
                Text(
                  'CAN\'T FIND WHAT YOU WANT? REQUEST IT AND OUR TEAM WILL ADD IT',
                  style: TextStyle(color: _slateText, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0, height: 1.5),
                ),
                const SizedBox(height: 32),

                // 2. REQUESTED BY CARD
                _buildSectionCard(
                  title: 'REQUESTED BY',
                  icon: Icons.person_outline,
                  children: [
                    _buildReadOnlyField('CUSTOMER NAME', 'Test Auditor', Icons.person_outline),
                    _buildReadOnlyField('CUSTOMER ID', 'VEV104', Icons.badge_outlined),
                    _buildReadOnlyField('CUSTOMER E-MAIL ID', 'testauditor@gmail.com', Icons.mail_outline),
                    _buildReadOnlyField('PHONE NO', '+91 00000 00000', Icons.phone_outlined, isLast: true),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. PRODUCT DETAILS CARD
                _buildSectionCard(
                  title: 'PRODUCT DETAILS',
                  icon: Icons.shopping_bag_outlined,
                  children: [
                    _buildInputField('PRODUCT NAME *', 'E.g. 24K Gold Bar (10g)', Icons.inventory_2_outlined, _productNameCtrl),
                    _buildInputField('CATEGORY', 'Gold', Icons.category_outlined, _categoryCtrl),
                    _buildInputField('PRODUCT MODEL', 'E.g. 22K Gold Coin', Icons.branding_watermark_outlined, _productModelCtrl),
                    
                    // Quantity Counter
                    _buildCounterField(
                      label: 'QUANTITY',
                      value: '$_quantity',
                      onDecrement: () => _incrementQuantity(-1),
                      onIncrement: () => _incrementQuantity(1),
                    ),
                    
                    // Weight Counter
                    _buildCounterField(
                      label: 'WEIGHT (G) — OPTIONAL',
                      value: _weight.toStringAsFixed(1),
                      onDecrement: () => _incrementWeight(-0.5),
                      onIncrement: () => _incrementWeight(0.5),
                    ),

                    // Additional Details Area
                    _buildTextArea('ADDITIONAL DETAILS / SPECIFICATIONS', 'Describe the product you\'d like us to add (brand, purity, model, etc.).', _detailsCtrl),
                    
                    const SizedBox(height: 16),
                    
                    // Info Banner
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
                          const Icon(Icons.shield_outlined, color: AppColors.goldColor, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'YOUR REQUEST IS SENT TO THE ADMIN FOR REVIEW. ONCE APPROVED, THE PRODUCT WILL BE ADDED TO THE CATALOGUE FOR YOU TO PURCHASE.',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 9, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, letterSpacing: 0.5, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 4. SUBMIT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleSubmitRequest,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('SUBMIT REQUEST', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1.5)),
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
                const SizedBox(height: 32),

                // 5. YOUR REQUESTS CARD
                _buildSectionCard(
                  title: 'YOUR REQUESTS',
                  icon: Icons.access_time,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: const Color(0xFFCBD5E1).withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'NO PRODUCT REQUESTS YET',
                            style: TextStyle(color: const Color(0xFF94A3B8).withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  // Read-only field for User Info
  Widget _buildReadOnlyField(String label, String value, IconData icon, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _lightBorder, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFCBD5E1), size: 18),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(color: _navyBlue.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Standard Input Field
  Widget _buildInputField(String label, String hint, IconData icon, TextEditingController controller) {
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
            style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFFCBD5E1), size: 18),
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _lightBorder, width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _lightBorder, width: 1.5)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.kPrimary, width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Counter Field (Quantity / Weight)
  Widget _buildCounterField({required String label, required String value, required VoidCallback onDecrement, required VoidCallback onIncrement}) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _lightBorder, width: 1.5),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onDecrement,
                  icon: const Icon(Icons.remove, color: Color(0xFF94A3B8), size: 20),
                  style: IconButton.styleFrom(backgroundColor: _lightBg),
                ),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _navyBlue, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                  ),
                ),
                IconButton(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add, color: Color(0xFF94A3B8), size: 20),
                  style: IconButton.styleFrom(backgroundColor: _lightBg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Multi-line Text Area
  Widget _buildTextArea(String label, String hint, TextEditingController controller) {
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
            maxLines: 4,
            style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _lightBorder, width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _lightBorder, width: 1.5)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: AppColors.kPrimary, width: 2)),
            ),
          ),
        ],
      ),
    );
  }
}