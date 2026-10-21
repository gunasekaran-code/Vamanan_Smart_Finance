import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../../models/asset_model.dart';
import '../../services/asset_service.dart';

/// Result of a successful stock update.
class StockUpdateResult {
  final int newQty;
  final String action;
  final int quantity;
  const StockUpdateResult({required this.newQty, required this.action, required this.quantity});
}

/// "Update Stock" dialog — add, remove or set the exact stock of one product
/// through `admin/inventory.php`. Pops a [StockUpdateResult] on success.
class StockUpdateDialog extends StatefulWidget {
  final Asset asset;
  const StockUpdateDialog({super.key, required this.asset});

  static Future<StockUpdateResult?> show(BuildContext context, Asset asset) => showDialog<StockUpdateResult>(
        context: context,
        builder: (_) => StockUpdateDialog(asset: asset),
      );

  @override
  State<StockUpdateDialog> createState() => _StockUpdateDialogState();
}

class _StockUpdateDialogState extends State<StockUpdateDialog> {
  static const _navy = Color(0xFF233A8B);
  static const _gold = Color(0xFFD1B04E);
  static const _fieldBg = Color(0xFFF8FAFC);
  static const _fieldBorder = Color(0xFFE2E8F0);
  static const _muted = Color(0xFF94A3B8);

  static const _actions = [('add', 'ADD'), ('remove', 'REMOVE'), ('set', 'SET EXACT')];

  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();
  String _action = 'add';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty < 0 || (qty == 0 && _action != 'set')) {
      setState(() => _error = _action == 'set' ? 'Enter a quantity of 0 or more.' : 'Enter a quantity greater than zero.');
      return;
    }
    if (_action == 'remove' && qty > widget.asset.stock) {
      setState(() => _error = 'Only ${widget.asset.stock} units in stock.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final notes = _notesController.text.trim();
      final newQty = await AssetService.instance.adjustStock(
        productId: widget.asset.id,
        action: _action,
        quantity: qty,
        notes: notes.isEmpty ? null : notes,
      );
      if (!mounted) return;
      Navigator.pop(context, StockUpdateResult(newQty: newQty, action: _action, quantity: qty));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildActionTabs(),
                    const SizedBox(height: 20),
                    _buildQuantityField(),
                    const SizedBox(height: 20),
                    _buildNotesField(),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.kDanger, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                    const SizedBox(height: 28),
                    _buildConfirmButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final asset = widget.asset;
    final (statusLabel, statusFg, statusBg) = switch (asset.stock <= 0
        ? 'out_of_stock'
        : asset.stock <= asset.lowStockThreshold
            ? 'low_stock'
            : 'in_stock') {
      'out_of_stock' => ('OUT OF STOCK', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
      'low_stock' => ('LOW STOCK', const Color(0xFFD97706), const Color(0xFFFFEDD5)),
      _ => ('IN STOCK', const Color(0xFFB8963A), const Color(0xFFFBF6E6)),
    };

    return CustomPaint(
      painter: _DotGridPainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.inventory_2_outlined, color: Colors.white.withValues(alpha: 0.6), size: 26),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UPDATE STOCK',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 3)),
                    const SizedBox(height: 6),
                    Text(asset.name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, height: 1.1)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Current: ${asset.stock} units',
                            style: const TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                          child: Text(statusLabel,
                              style: TextStyle(
                                  color: statusFg, fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Material(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _saving ? null : () => Navigator.pop(context),
                child: const SizedBox(width: 48, height: 48, child: Icon(Icons.close, color: Colors.white70, size: 22)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTabs() {
    return Row(
      children: [
        for (var i = 0; i < _actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _actionTab(_actions[i].$1, _actions[i].$2)),
        ],
      ],
    );
  }

  Widget _actionTab(String action, String label) {
    final selected = _action == action;
    return GestureDetector(
      onTap: _saving ? null : () => setState(() => _action = action),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _gold : _fieldBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _gold : const Color(0xFFEEF2F6), width: 2),
          boxShadow: selected ? [BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))] : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.5)),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, TextStyle hintStyle, EdgeInsets padding) => InputDecoration(
        hintText: hint,
        hintStyle: hintStyle,
        filled: true,
        fillColor: _fieldBg,
        contentPadding: padding,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: _fieldBorder, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: _navy, width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: _fieldBorder, width: 1.5)),
      );

  Widget _buildQuantityField() {
    const style = TextStyle(fontSize: 30, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E293B), letterSpacing: -1);
    return TextField(
      controller: _qtyController,
      enabled: !_saving,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: style,
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      onSubmitted: (_) => _confirm(),
      decoration: _fieldDecoration(
        _action == 'set' ? 'Enter exact stock...' : 'Enter quantity...',
        style.copyWith(color: const Color(0xFFA3A9B6)),
        const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      ),
    );
  }

  Widget _buildNotesField() {
    const style = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: Color(0xFF334155));
    return TextField(
      controller: _notesController,
      enabled: !_saving,
      minLines: 3,
      maxLines: 4,
      style: style,
      decoration: _fieldDecoration(
        'Reason for update (optional)...',
        style.copyWith(color: _muted),
        const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _navy.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Material(
        color: _navy,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _saving ? null : _confirm,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_saving)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                else
                  const Icon(Icons.bolt_outlined, color: _gold, size: 24),
                const SizedBox(width: 16),
                Text(_saving ? 'UPDATING...' : 'CONFIRM UPDATE',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navy background with a faint dot grid, as in the header mock-up.
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF233A8B));
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.08);
    const gap = 24.0;
    for (double y = gap / 2; y < size.height; y += gap) {
      for (double x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
