import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:intl/intl.dart';
import '../../models/offer_model.dart';
import '../../services/offer_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedCategory = 'FESTIVAL';
  final List<String> _categories = ['FESTIVAL', 'PROMO', 'ANNOUNCEMENT'];

  final List<Color> _accentColors = [
    const Color(0xFF60A5FA), // blue
    const Color(0xFFD97706), // amber
    const Color(0xFF34D399), // emerald
    const Color(0xFFFB7185), // red/rose
    const Color(0xFFC084FC), // purple
  ];
  late Color _selectedColor;

  bool _showSuccessHint = false;
  bool _isLoading = true;
  bool _isPublishing = false;

  List<AppOffer> _activeOffers = [];

  @override
  void initState() {
    super.initState();
    _selectedColor = _accentColors[1];
    _loadOffers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    setState(() => _isLoading = true);
    try {
      final offers = await OfferService.instance.fetchOffers();
      if (mounted) setState(() => _activeOffers = offers);
    } catch (e) {
      if (mounted) {
        ToastService.show(title: 'Error', message: 'Could not load offers: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      ToastService.show(title: 'Success', message: 'Monthly yield processed successfully.', type: ToastType.success);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _handlePublish() async {
    if (_titleController.text.isEmpty || _detailsController.text.isEmpty) {
      ToastService.show(title: 'Validation Error', message: 'Please fill in all offer details.', type: ToastType.error);
      return;
    }

    setState(() => _isPublishing = true);
    try {
      await OfferService.instance.createOffer(
        title: _titleController.text,
        details: _detailsController.text,
        category: _selectedCategory,
        colorName: AppOffer.nameFromColor(_selectedColor),
        endsAt: _selectedDate == null ? null : DateFormat('yyyy-MM-dd').format(_selectedDate!),
      );

      _titleController.clear();
      _detailsController.clear();
      setState(() {
        _selectedDate = null;
        _dateController.clear();
        _showSuccessHint = true;
      });
      await _loadOffers();

      ToastService.show(title: 'Offer Published', message: 'The offer is now live for customers.', type: ToastType.success);

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSuccessHint = false);
      });
    } catch (e) {
      ToastService.show(title: 'Error', message: 'Could not publish offer: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _handleDeleteOffer(AppOffer offer) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'DELETE OFFER',
      message: 'Are you sure you want to permanently remove this offer?',
      confirmLabel: 'DELETE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed != true) return;

    try {
      await OfferService.instance.deleteOffer(offer.id);
      setState(() => _activeOffers.removeWhere((o) => o.id == offer.id));
      ToastService.show(title: 'Deleted', message: 'Offer has been removed.', type: ToastType.success);
    } catch (e) {
      ToastService.show(title: 'Error', message: 'Could not delete offer: $e', type: ToastType.error);
    }
  }

  Future<void> _toggleHideOffer(AppOffer offer) async {
    final previous = offer.isHidden;
    setState(() => offer.isHidden = !offer.isHidden);
    try {
      await OfferService.instance.toggleOffer(offer.id);
      ToastService.show(
        title: offer.isHidden ? 'Offer Hidden' : 'Offer Visible',
        message: offer.isHidden ? 'Customers will no longer see this.' : 'Offer is live again.',
        type: ToastType.info,
      );
    } catch (e) {
      setState(() => offer.isHidden = previous);
      ToastService.show(title: 'Error', message: 'Could not update offer: $e', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _handleProcessYield,
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('PROCESS MONTHLY YIELD', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 4,
                    shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text('OFFERS & FESTIVAL BANNERS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(
                'ACTIVE OFFERS POP UP WHEN CUSTOMERS LOG IN',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.9), letterSpacing: 1.5),
              ),
              const SizedBox(height: 24),

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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.card_giftcard, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 16),
                        const Text('NEW OFFER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildTextInput(controller: _titleController, hintText: 'Offer title (e.g. Diwali Gold Bonanza)'),
                    const SizedBox(height: 16),
                    _buildTextInput(controller: _detailsController, hintText: 'Offer details / message...', maxLines: 4),
                    const SizedBox(height: 16),

                    LayoutBuilder(builder: (context, constraints) {
                      bool isMobile = constraints.maxWidth < 500;
                      Widget categoryDropdown = _buildDropdown();
                      Widget datePicker = _buildDatePicker();

                      if (isMobile) {
                        return Column(children: [categoryDropdown, const SizedBox(height: 16), datePicker]);
                      }
                      return Row(children: [Expanded(child: categoryDropdown), const SizedBox(width: 16), Expanded(child: datePicker)]);
                    }),
                    const SizedBox(height: 24),

                    const Text('ACCENT COLOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 2)),
                    const SizedBox(height: 12),
                    Row(children: _accentColors.map((color) => _buildColorCircle(color)).toList()),
                    const SizedBox(height: 24),

                    if (_showSuccessHint) ...[
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                          const SizedBox(width: 8),
                          const Text('OFFER PUBLISHED — IT WILL SHOW ON CUSTOMER LOGIN.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF10B981), letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    ElevatedButton.icon(
                      onPressed: _isPublishing ? null : _handlePublish,
                      icon: _isPublishing
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add, size: 16),
                      label: Text(_isPublishing ? 'PUBLISHING...' : 'PUBLISH OFFER', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 13, letterSpacing: 1.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: AppLoader()))
              else if (_activeOffers.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _activeOffers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildActiveOfferCard(_activeOffers[index]),
                )
              else
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.kBorder),
                  ),
                  child: const Text('NO ACTIVE OFFERS', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kTextMuted)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput({required TextEditingController controller, required String hintText, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.kTextMuted, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, fontSize: 13),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB))),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      onChanged: (val) => setState(() => _selectedCategory = val!),
      icon: const SizedBox.shrink(),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB))),
      ),
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
    );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      onTap: () => _selectDate(context),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF3B82F6)),
      decoration: InputDecoration(
        hintText: 'Expiry date (optional)',
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB))),
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    bool isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: const Color(0xFFFDE68A), width: 3) : null,
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
      ),
    );
  }

  Widget _buildActiveOfferCard(AppOffer offer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: offer.accentColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(offer.category, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                      child: Text(offer.isHidden ? 'HIDDEN' : 'ACTIVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: offer.isHidden ? AppColors.kTextMuted : const Color(0xFF10B981))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(offer.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                const SizedBox(height: 8),
                Text(offer.details, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                if (offer.expiryDate != null)
                  Text('ENDS ${offer.expiryDate}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider(height: 1, color: AppColors.kBorder)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _toggleHideOffer(offer),
                      icon: Icon(offer.isHidden ? Icons.visibility : Icons.visibility_off_outlined, size: 14),
                      label: Text(offer.isHidden ? 'SHOW' : 'HIDE', style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        backgroundColor: const Color(0xFFF8FAFC),
                        side: const BorderSide(color: Colors.transparent),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _handleDeleteOffer(offer),
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}