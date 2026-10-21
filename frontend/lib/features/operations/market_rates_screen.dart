import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import '../../models/market_rate_model.dart';
import '../../services/market_rates_service.dart';

class MarketRatesScreen extends StatefulWidget {
  const MarketRatesScreen({super.key});

  @override
  State<MarketRatesScreen> createState() => _MarketRatesScreenState();
}

class _MarketRatesScreenState extends State<MarketRatesScreen> {
  final TextEditingController _goldRateCtrl =
      TextEditingController(text: '15313.68');
  final TextEditingController _silverRateCtrl =
      TextEditingController(text: '300');

  final _service = MarketRatesService();

  bool _isSyncingGold = false;
  bool _isProcessingYield = false;
  DateTime? _goldLastSynced;

  @override
  void dispose() {
    _goldRateCtrl.dispose();
    _silverRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleProcessYield() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PROCESS MONTHLY YIELD',
      message:
          "Process this month's cashback? This credits one monthly installment (10%) to every cycle that is due, and can only run ONCE per calendar month.",
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );
    if (confirmed != true) return;

    setState(() => _isProcessingYield = true);
    try {
      final body = await _service.processMonthlyYield();
      final success = body['status'] == 'success';
      ToastService.show(
        title: success ? 'Success' : 'Failed',
        message: body['message']?.toString() ??
            'Monthly yield processed successfully.',
        type: success ? ToastType.success : ToastType.error,
      );
    } on MarketRateException catch (e) {
      ToastService.show(
          title: 'Failed', message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isProcessingYield = false);
    }
  }

  /// Only gold is wired — the backend pulls a live spot price itself and
  /// ignores whatever's typed in the field. Silver has no backend yet.
  Future<void> _handleFinalizeSynchronization() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'FINALIZE RATE SYNCHRONIZATION',
      message:
          'This pulls the current live gold spot price and updates the platform rate. It will immediately impact all active purchase simulations. Silver isn\'t connected to a live sync yet.',
      confirmLabel: 'SYNCHRONIZE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );
    if (confirmed != true) return;

    setState(() => _isSyncingGold = true);
    try {
      final result = await _service.syncGoldRate();
      setState(() {
        _goldRateCtrl.text = result.marketPricePerGram.toStringAsFixed(2);
        _goldLastSynced = result.updatedAt;
      });
      ToastService.show(
        title: 'Rates Synchronized',
        message:
            'Gold updated to ₹${result.marketPricePerGram.toStringAsFixed(2)}/gram '
            '(spot ₹${result.spotPricePerGram.toStringAsFixed(2)}). Silver was not changed.',
        type: ToastType.success,
      );
    } on MarketRateException catch (e) {
      ToastService.show(
          title: 'Sync Failed', message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSyncingGold = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isSmallMobile = width < 380;
            final isMobile = width < 600;
            final isTablet = width >= 600 && width < 1024;

            final double pagePadding =
                isSmallMobile ? 12 : (isMobile ? 16 : 24);
            final double cardPadding =
                isSmallMobile ? 16 : (isMobile ? 20 : (isTablet ? 24 : 32));
            // Side-by-side rate cards once there's room for both inputs.
            final bool sideBySide = width >= 720;

            final goldCard = _buildRateCard(
              title: 'GOLD PROTOCOL (24K)',
              icon: Icons.bolt,
              iconColor: const Color(0xFFD97706),
              controller: _goldRateCtrl,
              isSmallMobile: isSmallMobile,
              isMobile: isMobile,
              helperText:
                  'Editable. Live sync overwrites this with the spot price; manual values are not saved yet.',
            );
            final silverCard = _buildRateCard(
              title: 'SILVER PROTOCOL (PURE)',
              icon: Icons.link,
              iconColor: const Color(0xFF94A3B8),
              controller: _silverRateCtrl,
              isSmallMobile: isSmallMobile,
              isMobile: isMobile,
              helperText: 'No backend sync yet — this value is not saved.',
            );

            return SingleChildScrollView(
              padding: EdgeInsets.all(pagePadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
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
                            hintStyle: TextStyle(
                                color: AppColors.kTextMuted, fontSize: 14),
                            prefixIcon:
                                Icon(Icons.search, color: AppColors.kTextMuted),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: isMobile ? double.infinity : null,
                        child: Align(
                          alignment: isMobile
                              ? Alignment.center
                              : Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed:
                                _isProcessingYield ? null : _handleProcessYield,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallMobile ? 16 : 24,
                                  vertical: isSmallMobile ? 14 : 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              minimumSize: isMobile
                                  ? const Size(double.infinity, 0)
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _isProcessingYield
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.bolt, size: 16),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _isProcessingYield
                                        ? 'PROCESSING...'
                                        : 'PROCESS MONTHLY YIELD',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                        fontSize: isSmallMobile ? 11 : 12,
                                        letterSpacing: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppColors.kBorder),
                        ),
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF1E3A8A),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.show_chart,
                                      color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('MARKET RATE CONTROL',
                                          style: TextStyle(
                                              fontSize: isSmallMobile ? 18 : 22,
                                              fontWeight: FontWeight.w900,
                                              fontStyle: FontStyle.italic,
                                              color: const Color(0xFF1E3A8A))),
                                      const SizedBox(height: 4),
                                      Text(
                                        _goldLastSynced != null
                                            ? 'GOLD LAST SYNCED ${_formatTime(_goldLastSynced!)}'
                                            : 'REAL-TIME ASSET VALUATION ADJUSTMENTS',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                            color: const Color(0xFF94A3B8)
                                                .withOpacity(0.8),
                                            letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isMobile ? 24 : 40),
                            if (sideBySide)
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: goldCard),
                                    const SizedBox(width: 24),
                                    Expanded(child: silverCard),
                                  ],
                                ),
                              )
                            else ...[
                              goldCard,
                              SizedBox(height: isMobile ? 16 : 24),
                              silverCard,
                            ],
                            SizedBox(height: isMobile ? 24 : 40),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSyncingGold
                                    ? null
                                    : _handleFinalizeSynchronization,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      vertical: isMobile ? 18 : 24),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _isSyncingGold
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Icon(Icons.check_circle_outline,
                                            size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _isSyncingGold
                                            ? 'SYNCHRONIZING...'
                                            : 'FINALIZE RATE SYNCHRONIZATION',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                            fontSize: isSmallMobile ? 12 : 14,
                                            letterSpacing:
                                                isSmallMobile ? 0.8 : 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFD97706), size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'CRITICAL WARNING: MODIFYING MARKET RATES WILL IMMEDIATELY IMPACT ALL CUSTOMER PURCHASE SIMULATIONS. ENSURE CROSS-VALIDATION WITH GLOBAL SPOT PRICE NODES BEFORE EXECUTION.',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color:
                                      const Color(0xFFD97706).withOpacity(0.9),
                                  height: 1.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _buildRateCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required bool isSmallMobile,
    required bool isMobile,
    String? helperText,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 16 : (isMobile ? 20 : 24)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.kBorder)),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('ASSET BASE VALUE',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
            ],
            style: TextStyle(
              fontSize: isSmallMobile ? 20 : (isMobile ? 24 : 28),
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF1E3A8A),
            ),
            decoration: InputDecoration(
              isDense: isSmallMobile,
              prefixText: isMobile ? '₹ ' : '₹   ',
              prefixStyle: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  fontSize: isSmallMobile ? 16 : 24),
              suffix: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.unfold_more,
                      color: const Color(0xFF1E3A8A),
                      size: isSmallMobile ? 18 : 24),
                  SizedBox(width: isSmallMobile ? 6 : 12),
                  Text('/ GRAM',
                      style: TextStyle(
                          fontSize: isSmallMobile ? 10 : 12,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF94A3B8).withOpacity(0.8))),
                ],
              ),
              fillColor: Colors.white,
              filled: true,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallMobile ? 14 : 24,
                  vertical: isSmallMobile ? 18 : 24),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.kBorder)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.kBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 8),
            Text(
              helperText,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8).withOpacity(0.9)),
            ),
          ],
        ],
      ),
    );
  }
}
