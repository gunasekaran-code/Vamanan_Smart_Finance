import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class VouchersViewWidget extends StatefulWidget {
  const VouchersViewWidget({super.key});

  @override
  State<VouchersViewWidget> createState() => _VouchersViewWidgetState();
}

class _VouchersViewWidgetState extends State<VouchersViewWidget> {
  String _selectedAutoGenerate = '+ AUTO-GENERATE FROM...';
  
  final List<String> _autoGenerateOptions = [
    '+ AUTO-GENERATE FROM...',
    'Sales Ledger',
    'Customer Ledger',
    'Inventory Ledger'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- 1. Voucher Management Action Card ---
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'VOUCHER MANAGEMENT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF1E3A8A), // Navy Blue
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '0 VOUCHERS · ₹0.00',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF94A3B8).withOpacity(0.8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),

              // Auto-Generate Dropdown
              Container(
                width: 250, // Keep dropdown relatively compact
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAutoGenerate,
                    icon: const Icon(Icons.unfold_more, size: 16, color: Color(0xFF1E3A8A)),
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF1E3A8A),
                    ),
                    items: _autoGenerateOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedAutoGenerate = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons Grid (Responsive Wrap)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // New Voucher
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('NEW VOUCHER', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                  
                  // Sync All
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.send, size: 14),
                    label: const Text('SYNC ALL', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB48A28), // Muted Gold/Mustard
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                  
                  // XML
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.code, size: 14),
                    label: const Text('XML', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                  
                  // Excel
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.table_view, size: 14),
                    label: const Text('EXCEL', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB48A28), // Muted Gold/Mustard
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),

                  // CSV
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.text_snippet_outlined, size: 14),
                    label: const Text('CSV', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: AppColors.kBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Preview Button (Below the main wrap as per design)
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: const Text('PREVIEW', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: AppColors.kBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- 2. Empty State Placeholder ---
        Container(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.kBorder),
          ),
          alignment: Alignment.center,
          child: const Text(
            'NO VOUCHERS YET — CREATE ONE OR AUTO-GENERATE FROM A LEDGER',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.5,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}