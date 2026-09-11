import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class AccessControlWidget extends StatefulWidget {
  const AccessControlWidget({super.key});

  @override
  State<AccessControlWidget> createState() => _AccessControlWidgetState();
}

class _AccessControlWidgetState extends State<AccessControlWidget> {
  // State
  String? _selectedStaff;
  final Set<String> _selectedPermissions = {'dashboard', 'investments', 'assets', 'invoices'};

  // Mock Data
  final List<String> _staffMembers = [
    'GUNA TEST · STAFF · GUNATESTSTAFF@GMAIL.COM',
    'ADMINISTRATOR · ADMIN · ADMIN@MAKKALGOLD.COM',
    'SUPPORT USER · STAFF · SUPPORT@MAKKALGOLD.COM',
  ];

  final List<Map<String, dynamic>> _permissions = [
    {'id': 'dashboard', 'label': 'DASHBOARD', 'icon': Icons.bar_chart},
    {'id': 'investments', 'label': 'INVESTMENTS', 'icon': Icons.shopping_cart_outlined},
    {'id': 'assets', 'label': 'ASSETS', 'icon': Icons.shopping_bag_outlined},
    {'id': 'invoices', 'label': 'INVOICES', 'icon': Icons.receipt_long_outlined},
    {'id': 'gstr', 'label': 'GSTR FILING', 'icon': Icons.request_quote_outlined},
    {'id': 'entities', 'label': 'ENTITIES', 'icon': Icons.people_outline},
    {'id': 'genealogy', 'label': 'GENEALOGY', 'icon': Icons.account_tree_outlined},
    {'id': 'wallets', 'label': 'WALLETS', 'icon': Icons.account_balance_wallet_outlined},
    {'id': 'kyc', 'label': 'KYC', 'icon': Icons.verified_user_outlined},
    {'id': 'withdrawals', 'label': 'WITHDRAWALS', 'icon': Icons.account_balance_outlined},
    {'id': 'notifications', 'label': 'NOTIFICATIONS', 'icon': Icons.campaign_outlined},
    {'id': 'market_rates', 'label': 'MARKET RATES', 'icon': Icons.trending_up},
    {'id': 'staffing', 'label': 'STAFFING', 'icon': Icons.person_add_outlined},
    {'id': 'settings', 'label': 'SETTINGS', 'icon': Icons.language},
  ];

  // --- Handlers ---

  void _handleSavePermissions() {
    if (_selectedStaff == null) return;
    
    ToastService.show(
      title: 'Permissions Saved', 
      message: 'Access control updated successfully for ${_selectedStaff!.split(' · ').first}.', 
      type: ToastType.success
    );
  }

  void _togglePermission(String id) {
    setState(() {
      if (_selectedPermissions.contains(id)) {
        _selectedPermissions.remove(id);
      } else {
        _selectedPermissions.add(id);
      }
    });
  }

  void _toggleAllPermissions() {
    setState(() {
      if (_selectedPermissions.length == _permissions.length) {
        _selectedPermissions.clear(); // Deselect all if all are currently selected
      } else {
        _selectedPermissions.addAll(_permissions.map((p) => p['id'] as String));
      }
    });
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
          // --- 1. Header ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A), // Navy Blue
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security, color: Color(0xFFFBBF24), size: 24), // Gold shield icon
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACCESS CONTROL',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MANUALLY ASSIGN PERMISSION-BASED ACCESS TO STAFF MEMBERS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // --- 2. Staff Selection Dropdown ---
          const Text(
            'SELECT STAFF MEMBER',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedStaff,
            onChanged: (val) => setState(() => _selectedStaff = val),
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFCBD5E1), size: 20),
            hint: const Text(
              '— CHOOSE A STAFF MEMBER —', 
              style: TextStyle(color: Color(0xFF1E3A8A), fontStyle: FontStyle.italic, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)
            ),
            isExpanded: true,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
            decoration: InputDecoration(
              fillColor: const Color(0xFFF8FAFC),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
            ),
            items: _staffMembers.map((staff) {
              return DropdownMenuItem(value: staff, child: Text(staff, overflow: TextOverflow.ellipsis));
            }).toList(),
          ),

          // --- 3. Permissions Grid (Revealed upon selection) ---
          if (_selectedStaff != null) ...[
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PERMISSION-BASED ACCESS CONTROL',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.5),
                ),
                TextButton(
                  onPressed: _toggleAllPermissions,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    _selectedPermissions.length == _permissions.length ? 'DESELECT ALL' : 'SELECT ALL ACCESS',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706), letterSpacing: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Responsive Grid for Permissions
            LayoutBuilder(
              builder: (context, constraints) {
                // Adjust number of columns based on screen width
                int crossAxisCount = 4;
                if (constraints.maxWidth < 400) {
                  crossAxisCount = 2;
                } else if (constraints.maxWidth < 600) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth > 900) {
                  crossAxisCount = 5;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.4, // Width/Height ratio to make rectangular buttons
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _permissions.length,
                  itemBuilder: (context, index) {
                    final perm = _permissions[index];
                    final isSelected = _selectedPermissions.contains(perm['id']);
                    
                    return InkWell(
                      onTap: () => _togglePermission(perm['id']),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          boxShadow: isSelected 
                              ? [BoxShadow(color: const Color(0xFF1E3A8A).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              perm['icon'], 
                              color: isSelected ? Colors.white : const Color(0xFF94A3B8), 
                              size: 20
                            ),
                            const SizedBox(height: 8),
                            Text(
                              perm['label'],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleSavePermissions,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text(
                  'SAVE ACCESS PERMISSIONS', 
                  style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 1.5)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}