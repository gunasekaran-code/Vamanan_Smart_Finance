import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

import '../../models/auditor_request_model.dart';
import '../../models/auditor_buy_model.dart' show AuditorSession;
import '../../services/auditor_request_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

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
  bool _isSubmitting = false;

  // Loaded prefill/history state
  CustomerInfo? _customer;
  List<ProductRequestItem> _requests = [];
  bool _isLoadingPrefill = true;
  String? _prefillError;

  // Theme Colors based on your AppTheme
  final Color _navyBlue = AppColors.kPrimaryDark;
  final Color _slateText = AppColors.kTextMuted;
  final Color _lightBorder = const Color(0xFFF1F5F9);
  final Color _lightBg = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadPrefill();
  }

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _categoryCtrl.dispose();
    _productModelCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefill() async {
    final userId = AuditorSession.currentUserId;
    if (userId == null) {
      setState(() {
        _isLoadingPrefill = false;
        _prefillError = 'You are not signed in. Sign in again to continue.';
      });
      return;
    }

    setState(() {
      _isLoadingPrefill = true;
      _prefillError = null;
    });

    try {
      final prefill = await AuditorRequestService.fetchPrefill(userId);
      if (!mounted) return;
      setState(() {
        _customer = prefill.user;
        _requests = prefill.requests;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _prefillError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingPrefill = false);
    }
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

    final userId = AuditorSession.currentUserId;
    if (userId == null || _customer == null) {
      ToastService.show(
        title: 'Not Signed In',
        message: 'Could not determine the logged-in customer. Please re-login and try again.',
        type: ToastType.error,
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

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      await AuditorRequestService.submitRequest(
        userId: userId,
        customerName: _customer!.name,
        customerCode: _customer!.customerId,
        customerEmail: _customer!.email,
        phone: _customer!.phone,
        productName: _productNameCtrl.text.trim(),
        model: _productModelCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isEmpty ? 'Gold' : _categoryCtrl.text.trim(),
        quantity: _quantity,
        weight: _weight,
        description: _detailsCtrl.text.trim(),
      );

      if (!mounted) return;
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
        _categoryCtrl.text = 'Gold';
        _quantity = 1;
        _weight = 0.0;
      });

      // Refresh the request history so the new one appears immediately
      await _loadPrefill();
    } catch (e) {
      if (!mounted) return;
      ToastService.show(
        title: 'Submission Failed',
        message: e.toString(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                        constraints: const BoxConstraints(maxWidth: 800), 
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
                  children: _isLoadingPrefill
                      ? [const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: AppLoader()))]
                      : _prefillError != null
                          ? [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  children: [
                                    Text(_prefillError!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                                    const SizedBox(height: 12),
                                    TextButton(onPressed: _loadPrefill, child: const Text('RETRY')),
                                  ],
                                ),
                              )
                            ]
                          : [
                              _buildReadOnlyField('CUSTOMER NAME', _customer?.name ?? '—', Icons.person_outline),
                              _buildReadOnlyField('CUSTOMER ID', _customer?.customerId ?? '—', Icons.badge_outlined),
                              _buildReadOnlyField('CUSTOMER E-MAIL ID', _customer?.email ?? '—', Icons.mail_outline),
                              _buildReadOnlyField('PHONE NO', (_customer?.phone == null || _customer!.phone!.isEmpty) ? 'NOT SET' : _customer!.phone!, Icons.phone_outlined, isLast: true),
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
                    onPressed: _isSubmitting ? null : _handleSubmitRequest,
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.arrow_forward, size: 16),
                    label: Text(
                      _isSubmitting ? 'SUBMITTING...' : 'SUBMIT REQUEST',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1.5),
                    ),
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
                  children: [_buildRequestsList()],
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
  // REQUEST HISTORY
  // ==========================================================================

  Widget _buildRequestsList() {
    if (_isLoadingPrefill) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: AppLoader()),
      );
    }

    if (_requests.isEmpty) {
      return Container(
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
      );
    }

    return Column(
      children: _requests.map((r) => _buildRequestTile(r)).toList(),
    );
  }

  Widget _buildRequestTile(ProductRequestItem r) {
    Color statusColor;
    switch (r.status.toLowerCase()) {
      case 'approved':
      case 'fulfilled':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      case 'reviewing':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = AppColors.goldColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _lightBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lightBorder, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _lightBorder)),
            alignment: Alignment.center,
            child: const Icon(Icons.inventory_2_outlined, color: AppColors.goldColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.productName, style: TextStyle(color: _navyBlue, fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Text(
                  '${r.category.toUpperCase()} • QTY ${r.quantity}${r.weight > 0 ? ' • ${r.weight}G' : ''}',
                  style: TextStyle(color: _slateText, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                ),
                if (r.adminNote != null && r.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('ADMIN NOTE: ${r.adminNote}', style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 9, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.3))),
            child: Text(r.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
          ),
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