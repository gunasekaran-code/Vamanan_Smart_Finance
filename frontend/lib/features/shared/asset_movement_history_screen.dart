import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../../models/asset_model.dart';
import '../../services/asset_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

/// Stock movement history for one product. Opens inside the app shell (as a
/// child of the asset inventory route), so the header shows a back button.
class AssetMovementHistoryScreen extends StatefulWidget {
  final int productId;
  final String productName;

  const AssetMovementHistoryScreen({super.key, required this.productId, required this.productName});

  @override
  State<AssetMovementHistoryScreen> createState() => _AssetMovementHistoryScreenState();
}

class _AssetMovementHistoryScreenState extends State<AssetMovementHistoryScreen> {
  static const _navy = Color(0xFF1E3A8A);
  static const _muted = Color(0xFF94A3B8);

  bool _loading = true;
  String? _error;
  List<StockMovement> _movements = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final movements = await AssetService.instance.fetchMovements(productId: widget.productId);
      if (!mounted) return;
      setState(() {
        _movements = movements;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.kBackground,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    ..._buildBody(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.history, color: AppColors.goldColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MOVEMENT HISTORY',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 3)),
                const SizedBox(height: 4),
                Text(widget.productName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody() {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Center(child: AppLoader()),
        ),
      ];
    }
    if (_error != null) {
      return [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.kDanger, fontWeight: FontWeight.bold)),
        ),
      ];
    }
    if (_movements.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            children: [
              Icon(Icons.history, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('NO MOVEMENTS RECORDED YET',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 14, letterSpacing: 1)),
            ],
          ),
        ),
      ];
    }
    return [
      for (var i = 0; i < _movements.length; i++) ...[
        if (i > 0) const SizedBox(height: 16),
        _MovementTile(movement: _movements[i]),
      ],
    ];
  }
}

class _MovementTile extends StatelessWidget {
  final StockMovement movement;
  const _MovementTile({required this.movement});

  static const _gold = Color(0xFFB08A2E);
  static const _goldBg = Color(0xFFFBF1D0);
  static const _blue = Color(0xFF2563EB);
  static const _blueBg = Color(0xFFDFE9FB);
  static const _slate = Color(0xFF475569);
  static const _slateBg = Color(0xFFE2E8F0);
  static const _muted = Color(0xFF94A3B8);
  static const _dark = Color(0xFF1E293B);

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];

  String get _date => '${movement.createdAt.day} ${_months[movement.createdAt.month - 1]}';

  String get _time {
    final t = movement.createdAt;
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'am' : 'pm'}';
  }

  @override
  Widget build(BuildContext context) {
    final type = movement.movementType.toLowerCase();
    final delta = movement.newQty - movement.previousQty;
    final increase = delta > 0 || (delta == 0 && const ['add', 'initial', 'return'].contains(type));
    final neutral = (type == 'set' || type == 'adjust') && delta == 0;

    final color = neutral ? _slate : (increase ? _gold : _blue);
    final bg = neutral ? _slateBg : (increase ? _goldBg : _blueBg);
    final icon = neutral ? Icons.tune : (increase ? Icons.add : Icons.remove);
    final sign = neutral ? '' : (increase ? '+' : '−');
    final units = delta != 0 ? delta.abs() : movement.quantity;
    final by = (movement.createdByName ?? '').trim();

    const label = TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                      child: Text('${sign.isEmpty ? '' : '$sign '}${type.toUpperCase()}',
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                    Text('$sign$units units',
                        style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                  ],
                ),
                if (by.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('BY ${by.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _muted, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
                ],
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Before: ', style: label),
                    Text('${movement.previousQty}', style: label.copyWith(color: _dark, fontWeight: FontWeight.w900)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward, size: 14, color: Color(0xFFCBD5E1)),
                    ),
                    const Text('After: ', style: label),
                    Text('${movement.newQty}', style: label.copyWith(color: color, fontWeight: FontWeight.w900)),
                  ],
                ),
                if ((movement.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(movement.notes!.trim(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_date, style: const TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              const SizedBox(height: 2),
              Text(_time,
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }
}
