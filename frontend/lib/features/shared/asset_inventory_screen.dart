import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'asset_form_screen.dart'; 

class Asset {
  final String id;
  final String name;
  final String category;
  final String metric;
  final double valuation;
  final int stock;
  final bool isActive;
  final bool isPreciousMetal;
  
  const Asset({
    required this.id,
    required this.name,
    required this.category,
    required this.metric,
    required this.valuation,
    required this.stock,
    required this.isActive,
    required this.isPreciousMetal,
  });
}

class AssetInventoryScreen extends StatefulWidget {
  const AssetInventoryScreen({super.key});

  @override
  State<AssetInventoryScreen> createState() => _AssetInventoryScreenState();
}

class _AssetInventoryScreenState extends State<AssetInventoryScreen> {
  // Mock data based on the provided images
  List<Asset> _assets = [
    const Asset(
      id: '1',
      name: 'ELECTRIC SCOOTER',
      category: 'VEHICLES\n(2 WHEELER/4 WHEELER)',
      metric: 'OG • ELECTRIC SCOOTER',
      valuation: 200000.0,
      stock: 6,
      isActive: true,
      isPreciousMetal: false,
    ),
    const Asset(
      id: '2',
      name: 'MACHINE',
      category: 'VEHICLES\n(2 WHEELER/4 WHEELER)',
      metric: 'OG • MACHINE',
      valuation: 350000.0,
      stock: 10,
      isActive: true,
      isPreciousMetal: false,
    ),
    const Asset(
      id: '3',
      name: 'ROYAL ENFIELD',
      category: 'VEHICLES\n(2 WHEELER/4 WHEELER)',
      metric: 'OG • ROYAL ENFIELD',
      valuation: 350000.0,
      stock: 11,
      isActive: true,
      isPreciousMetal: false,
    ),
    const Asset(
      id: '4',
      name: 'SCHOOL FEES',
      category: 'SCHOOL FEES',
      metric: 'OG • SCHOOL FEES',
      valuation: 100000.0,
      stock: 0,
      isActive: true,
      isPreciousMetal: false,
    ),
  ];

  // Helper to format currency
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

    if (confirmed == true) {
      setState(() {
        _assets.removeWhere((a) => a.id == asset.id);
      });
      
      ToastService.show(
        title: 'Asset Deleted',
        message: '${asset.name} has been removed from inventory.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _openAssetForm([Asset? asset]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssetFormScreen(asset: asset),
      ),
    );

    if (result == null) return;

    if (result is Asset) {
      final isNew = asset == null;
      setState(() {
        if (isNew) {
          _assets.insert(0, result); 
        } else {
          final index = _assets.indexWhere((a) => a.id == result.id);
          if (index != -1) {
            _assets[index] = result;
          }
        }
      });

      ToastService.show(
        title: isNew ? 'Asset Provisioned' : 'Asset Updated',
        message: isNew 
            ? 'New asset has been successfully provisioned.'
            : 'Asset details have been successfully updated.',
        type: ToastType.success,
      );
    }
  }

  // Bulk Upload Modal
  void _showImportDialog() {
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
                    Text('IMPORT MULTIPLE PRODUCTS VIA CSV', style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              )
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
                  const Text('STEP 1 · DOWNLOAD THE TEMPLATE, FILL YOUR PRODUCTS', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('DOWNLOAD CSV TEMPLATE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: AppColors.kTextDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('STEP 2 · UPLOAD YOUR FILLED CSV', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(border: Border.all(color: AppColors.kBorder, style: BorderStyle.solid), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file, color: AppColors.kTextMuted, size: 20),
                    SizedBox(width: 8),
                    Text('Choose a CSV file...', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: AppColors.kTextDark)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B98C6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // History Modal
  void _showHistoryDialog(Asset asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1E3A8A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.history, color: Colors.orangeAccent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MOVEMENT HISTORY', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(asset.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        content: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 40, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text('NO MOVEMENTS RECORDED YET', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 16), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Asset Inventory',
      subtitle: 'Manage all products, vehicles, and precious metals.',
      children: [
        // Action Buttons Header
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

        // Asset Cards List (Replaces DataTable)
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _assets.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _AssetCard(
              asset: _assets[index],
              onHistory: () => _showHistoryDialog(_assets[index]),
              onEdit: () => _openAssetForm(_assets[index]),
              onDelete: () => _handleDelete(_assets[index]),
              formatCurrency: _formatCurrency,
            );
          },
        ),
        const SizedBox(height: 24), // Bottom Padding
      ],
    );
  }
}

// ============================================================================
// CLEAN ASSET CARD WIDGET
// ============================================================================
class _AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback onHistory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(double) formatCurrency;

  const _AssetCard({
    required this.asset,
    required this.onHistory,
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Icon, Title, and Status Badge
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A8A),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${asset.id.padLeft(4, '0')}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    asset.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(
                      color: Color(0xFFD97706),
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
          
          // DETAILS: 2x2 Grid using Rows and Expanded
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDetailSection(
                        label: 'CLASSIFICATION',
                        value: asset.category.replaceAll('\n', ' '), // Clean up multi-line
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailSection(
                        label: 'METRIC / PURITY',
                        value: asset.metric,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDetailSection(
                        label: 'MARKET VALUE',
                        value: formatCurrency(asset.valuation),
                        isHighlight: true,
                      ),
                    ),
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

          // FOOTER: Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  icon: Icons.history,
                  color: const Color(0xFF64748B),
                  backgroundColor: const Color(0xFFF1F5F9),
                  onPressed: onHistory,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.settings_outlined,
                  color: Colors.white,
                  backgroundColor: const Color(0xFF1E3A8A),
                  onPressed: onEdit,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.delete_outline,
                  color: Colors.blue,
                  backgroundColor: Colors.white,
                  borderColor: const Color(0xFFE2E8F0),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for small data sections within the card
  Widget _buildDetailSection({
    required String label,
    required String value,
    bool isHighlight = false,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: valueColor ?? const Color(0xFF1E3A8A),
            fontSize: isHighlight ? 18 : 14,
          ),
        ),
      ],
    );
  }
}

// Internal action button widget matching the design
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}