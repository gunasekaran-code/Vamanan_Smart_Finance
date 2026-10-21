import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/routing/app_routes.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'package:frontend/shared/widgets/product_thumbnail.dart';
import 'stock_update_dialog.dart';
import '../../models/asset_model.dart';
import 'package:frontend/shared/widgets/stat_card.dart';
import '../../services/asset_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class AssetInventoryScreen extends StatefulWidget {
  const AssetInventoryScreen({super.key});

  @override
  State<AssetInventoryScreen> createState() => _AssetInventoryScreenState();
}

class _AssetInventoryScreenState extends State<AssetInventoryScreen> {
  bool _loading = true;
  String? _error;
  List<Asset> _assets = [];
  InventorySummary _summary = InventorySummary.empty;
  List<String> _categories = [];

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _search = '';
  String _category = '';
  String _stockFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await AssetService.instance.fetchAssets(
        search: _search,
        category: _category,
        stockFilter: _stockFilter,
      );
      if (!mounted) return;
      setState(() {
        _assets = result.assets;
        _summary = result.summary;
        // Keep the last non-empty category list so the dropdown does not
        // collapse while a narrow search is active.
        if (result.categories.isNotEmpty) _categories = result.categories;
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

  void _onSearchChanged(String value) {
    setState(() {}); // reveals/hides the clear button as you type
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || value.trim() == _search) return;
      _search = value.trim();
      _load();
    });
  }

  void _applyFilter({String? stockFilter, String? category}) {
    setState(() {
      if (stockFilter != null) _stockFilter = stockFilter;
      if (category != null) _category = category;
    });
    _load();
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Future<void> _handleDelete(Asset asset) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete Asset',
      message: 'Are you sure you want to delete this product?',
      confirmLabel: 'Delete',
      confirmButtonColor: AppColors.kDanger,
    );
    if (confirmed != true) return;

    try {
      await AssetService.instance.deleteAsset(asset.id);
      if (!mounted) return;
      setState(() => _assets.removeWhere((a) => a.id == asset.id));
      unawaited(_load()); // keeps the summary tiles in step with the list
      ToastService.show(
        title: 'Asset Deleted',
        message: '${asset.name} has been removed from inventory.',
        type: ToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      ToastService.show(title: 'Delete Failed', message: e.toString(), type: ToastType.error);
    }
  }

  Future<void> _openAssetForm([Asset? asset]) async {
    final result = await context.push<bool>(
      asset == null ? AppRoutes.assetNew : AppRoutes.assetEdit,
      extra: asset,
    );
    if (result == null) return;
    // Form screen now saves to the backend itself and pops `true` on success.
    if (result == true) {
      await _load();
      ToastService.show(
        title: asset == null ? 'Asset Provisioned' : 'Asset Updated',
        message: asset == null ? 'New asset has been successfully provisioned.' : 'Asset details have been successfully updated.',
        type: ToastType.success,
      );
    }
  }

  void _showImportDialog() {
    // unchanged — bulk CSV import wiring is a separate endpoint you'll plug in later.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E3A8A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.description_outlined, color: Colors.orangeAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BULK PRODUCT UPLOAD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('IMPORT MULTIPLE PRODUCTS VIA CSV',
                        style:
                            TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STEP 1 · DOWNLOAD THE TEMPLATE, FILL YOUR PRODUCTS',
                      style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download, size: 18),
                      label:
                          const Text('DOWNLOAD CSV TEMPLATE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                      style:
                          OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: AppColors.kTextDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('STEP 2 · UPLOAD YOUR FILLED CSV',
                style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(border: Border.all(color: AppColors.kBorder), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, color: AppColors.kTextMuted, size: 20),
                    SizedBox(width: 8),
                    Text('Choose a CSV file...',
                        style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: AppColors.kTextDark)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('IMPORT PRODUCTS', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B98C6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openStockUpdate(Asset asset) async {
    final result = await StockUpdateDialog.show(context, asset);
    if (result == null || !mounted) return;
    await _load();
    final verb = switch (result.action) { 'add' => 'Added ${result.quantity} units', 'remove' => 'Removed ${result.quantity} units', _ => 'Stock set' };
    ToastService.show(
      title: 'Stock Updated',
      message: '$verb — ${asset.name} now has ${result.newQty} units.',
      type: ToastType.success,
    );
  }

  void _showHistory(Asset asset) {
    context.push(AppRoutes.assetMovementHistoryFor(id: asset.id, name: asset.name));
  }

  Widget _buildSummary() {
    final tiles = <Widget>[
      StatCard(
        label: 'PRODUCTS',
        value: '${_summary.totalProducts}',
        icon: Icons.inventory_2_outlined,
        color: AppColors.kPrimary,
      ),
      StatCard(
        label: 'UNITS IN STOCK',
        value: '${_summary.totalUnits}',
        icon: Icons.layers_outlined,
        color: AppColors.kInfo,
      ),
      StatCard(
        label: 'LOW STOCK',
        value: '${_summary.lowStock}',
        icon: Icons.trending_down,
        color: AppColors.kWarning,
      ),
      StatCard(
        label: 'OUT OF STOCK',
        value: '${_summary.outOfStock}',
        icon: Icons.remove_shopping_cart_outlined,
        color: AppColors.kDanger,
      ),
      StatCard(
        label: 'STOCK VALUE',
        value: _formatCurrency(_summary.totalStockValue),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.kSuccess,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two tiles per row on phones, four on anything wider.
        final perRow = constraints.maxWidth < 560 ? 2 : 4;
        const gap = 12.0;
        final tileWidth = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    const statuses = <String, String>{
      'all': 'All',
      'in_stock': 'In stock',
      'low_stock': 'Low stock',
      'out_of_stock': 'Out of stock',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search by name, category or code...',
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.kTextMuted),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _search = '';
                      _load();
                    },
                    color: AppColors.kTextMuted,
                  ),
            filled: true,
            fillColor: AppColors.kSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.kBorder),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in statuses.entries) ...[
                _FilterChip(
                  label: entry.value,
                  selected: _stockFilter == entry.key,
                  onTap: () => _applyFilter(stockFilter: entry.key),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        if (_categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _category.isEmpty ? '' : _category,
                icon: const Icon(Icons.expand_more, color: AppColors.kTextMuted),
                style: const TextStyle(color: AppColors.kTextDark, fontWeight: FontWeight.w700, fontSize: 14),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All classifications')),
                  for (final c in _categories) DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (value) => _applyFilter(category: value ?? ''),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Asset Inventory',
      subtitle: 'Manage all products, vehicles, and precious metals.',
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _showImportDialog,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Import', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kTextDark,
                  side: const BorderSide(color: AppColors.kBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openAssetForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Provision Asset', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        _buildSummary(),
        const SizedBox(height: 16),
        _buildFilters(),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: AppLoader()))
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_off_outlined, color: AppColors.kDanger, size: 32),
                const SizedBox(height: 12),
                const Text("Couldn't load inventory",
                    style: TextStyle(color: AppColors.kTextDark, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 6),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.kTextMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        else if (_assets.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                _search.isEmpty && _category.isEmpty && _stockFilter == 'all' ? 'No assets yet.' : 'No assets match these filters.',
                style: const TextStyle(color: AppColors.kTextMuted, fontWeight: FontWeight.w700),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _assets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _AssetCard(
                asset: _assets[index],
                onHistory: () => _showHistory(_assets[index]),
                onStock: () => _openStockUpdate(_assets[index]),
                onEdit: () => _openAssetForm(_assets[index]),
                onDelete: () => _handleDelete(_assets[index]),
                formatCurrency: _formatCurrency,
              );
            },
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E3A8A) : AppColors.kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF1E3A8A) : AppColors.kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : AppColors.kTextMuted,
          ),
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback onHistory;
  final VoidCallback onStock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(double) formatCurrency;

  const _AssetCard({
    required this.asset,
    required this.onHistory,
    required this.onStock,
    required this.onEdit,
    required this.onDelete,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumbnail(
                  key: ValueKey('asset-img-${asset.id}-${asset.imageUrl}'),
                  url: asset.imageUrl,
                  width: 64,
                  height: 64,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 18)),
                      const SizedBox(height: 4),
                      Text('ID: ${asset.id.toString().padLeft(4, '0')}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: asset.stockStatus == 'out_of_stock' ? const Color(0xFFFEE2E2) : const Color(0xFFFFFBEB),
                    border: Border.all(color: asset.stockStatus == 'out_of_stock' ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    !asset.isActive
                        ? 'INACTIVE'
                        : asset.stockStatus == 'out_of_stock'
                            ? 'OUT OF STOCK'
                            : asset.stockStatus == 'low_stock'
                                ? 'LOW STOCK'
                                : 'ACTIVE',
                    style: TextStyle(
                      color: asset.stockStatus == 'out_of_stock' ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDetailSection(label: 'CLASSIFICATION', value: asset.category)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDetailSection(label: 'METRIC / PURITY', value: asset.metric)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDetailSection(label: 'MARKET VALUE', value: formatCurrency(asset.valuation), isHighlight: true)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailSection(
                        label: 'STOCK',
                        value: '${asset.stock} UNITS',
                        valueColor: asset.stock > 0 ? const Color(0xFFD97706) : const Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                    icon: Icons.history, color: const Color(0xFF64748B), backgroundColor: const Color(0xFFF1F5F9), onPressed: onHistory),
                const SizedBox(width: 12),
                _ActionButton(
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFFB8963A),
                    backgroundColor: const Color(0xFFFBF6E6),
                    borderColor: const Color(0xFFF1E3B8),
                    onPressed: onStock),
                const SizedBox(width: 12),
                _ActionButton(
                    icon: Icons.edit_outlined, color: Colors.white, backgroundColor: const Color(0xFF1E3A8A), onPressed: onEdit),
                const SizedBox(width: 12),
                _ActionButton(
                    icon: Icons.delete_outline,
                    color: Colors.blue,
                    backgroundColor: Colors.white,
                    borderColor: const Color(0xFFE2E8F0),
                    onPressed: onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({required String label, required String value, bool isHighlight = false, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: valueColor ?? const Color(0xFF1E3A8A),
                fontSize: isHighlight ? 18 : 14)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.color, required this.backgroundColor, this.borderColor, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: backgroundColor, shape: BoxShape.circle, border: borderColor != null ? Border.all(color: borderColor!) : null),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
