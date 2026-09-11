import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

class AdvocateProfileScreen extends StatefulWidget {
  const AdvocateProfileScreen({super.key});

  @override
  State<AdvocateProfileScreen> createState() => _AdvocateProfileScreenState();
}

class _AdvocateProfileScreenState extends State<AdvocateProfileScreen> {
  // State variables
  String _activeTab = 'IDENTITY'; // 'IDENTITY' or 'SECURITY'
  
  // Security State
  bool _isChangingNode = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Identity State
  bool _isEditingIdentity = false;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;

  // Exact colors from your design
  final Color _navyBlue = const Color(0xFF1E3376); 
  final Color _goldAccent = const Color(0xFFDCA743);
  final Color _lightGoldBg = const Color(0xFFFFFBEB);
  final Color _slateText = const Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController();
    _bioCtrl = TextEditingController(
      text: 'Certified institutional advocate overseeing decentralized capital nodes for Vamanan Enterprises. Specialized in protocol ratification and institutional integrity monitoring.'
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // --- ACTIONS ---
  void _handleEditProfile() {
    setState(() {
      _isEditingIdentity = true;
    });
  }

  Future<void> _handleSaveIdentity() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Update Identity Node',
      message: 'Are you sure you want to commit these changes to your public identity protocol?',
      confirmLabel: 'Save Changes',
      confirmButtonColor: _navyBlue,
    );

    if (confirmed == true) {
      setState(() {
        _isEditingIdentity = false;
      });
      ToastService.show(
        title: 'Identity Updated',
        message: 'Your public identity protocol has been successfully updated.',
        type: ToastType.success,
      );
    }
  }

  Future<void> _handleUpdateSecurity() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Update Credentials',
      message: 'Are you sure you want to update your institutional access node? You will be required to use the new protocol key immediately.',
      confirmLabel: 'Update Protocol',
      confirmButtonColor: _navyBlue,
    );

    if (confirmed == true) {
      setState(() {
        _isChangingNode = false;
      });
      ToastService.show(
        title: 'Security Updated',
        message: 'Your institutional access node has been successfully updated.',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            if (isMobile) {
              // Mobile Layout: Stacked
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeaderCard(),
                  const SizedBox(height: 24),
                  _buildTabButton(
                    title: 'IDENTITY PROTOCOL',
                    subtitle: 'MANAGE PUBLIC INFO',
                    icon: Icons.person_outline,
                    isActive: _activeTab == 'IDENTITY',
                    onTap: () => setState(() {
                      _activeTab = 'IDENTITY';
                      _isChangingNode = false;
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildTabButton(
                    title: 'SECURITY HUB',
                    subtitle: 'UPDATE CREDENTIALS',
                    icon: Icons.lock_outline,
                    isActive: _activeTab == 'SECURITY',
                    onTap: () => setState(() {
                      _activeTab = 'SECURITY';
                      _isEditingIdentity = false;
                    }),
                  ),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _activeTab == 'IDENTITY' 
                        ? _buildIdentityContainer() 
                        : _buildSecurityHub(),
                  ),
                ],
              );
            } else {
              // Desktop/Tablet Layout: Side-by-Side
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Profile & Tabs
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _buildProfileHeaderCard(),
                        const SizedBox(height: 24),
                        _buildTabButton(
                          title: 'IDENTITY PROTOCOL',
                          subtitle: 'MANAGE PUBLIC INFO',
                          icon: Icons.person_outline,
                          isActive: _activeTab == 'IDENTITY',
                          onTap: () => setState(() {
                            _activeTab = 'IDENTITY';
                            _isChangingNode = false;
                          }),
                        ),
                        const SizedBox(height: 16),
                        _buildTabButton(
                          title: 'SECURITY HUB',
                          subtitle: 'UPDATE CREDENTIALS',
                          icon: Icons.lock_outline,
                          isActive: _activeTab == 'SECURITY',
                          onTap: () => setState(() {
                            _activeTab = 'SECURITY';
                            _isEditingIdentity = false;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right Column: Dynamic Content
                  Expanded(
                    flex: 7,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _activeTab == 'IDENTITY' 
                          ? _buildIdentityContainer() 
                          : _buildSecurityHub(),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  // ==========================================================================
  // WIDGETS
  // ==========================================================================

  // 1. Top Profile Header Card
  Widget _buildProfileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 30, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'V',
              style: TextStyle(color: _navyBlue, fontSize: 36, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'TEST ADVOCATE',
            style: TextStyle(color: _navyBlue, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _lightGoldBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _goldAccent.withOpacity(0.3)),
            ),
            child: Text(
              'LEAD ADVOCATE',
              style: TextStyle(color: _goldAccent, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Dedicated Legal Oversight • Vamanan Enterprises',
            textAlign: TextAlign.center,
            style: TextStyle(color: _slateText, fontSize: 12, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 2. Navigation Tab Buttons
  Widget _buildTabButton({required String title, required String subtitle, required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isActive ? _navyBlue : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: isActive ? [BoxShadow(color: _navyBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? _goldAccent : _lightGoldBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: isActive ? Colors.white : _goldAccent, size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: isActive ? Colors.white : _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: isActive ? Colors.white70 : _slateText, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isActive ? Colors.white54 : _slateText.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  // 3. Identity State Switcher
  Widget _buildIdentityContainer() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isEditingIdentity ? _buildIdentityEditMode() : _buildIdentityViewMode(),
    );
  }

  // 3a. Identity Details (View Mode)
  Widget _buildIdentityViewMode() {
    return Container(
      key: const ValueKey('IDENTITY_VIEW'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('IDENTITY DETAILS', style: TextStyle(color: _navyBlue, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
              InkWell(
                onTap: _handleEditProfile,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _lightGoldBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _goldAccent.withOpacity(0.3))),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 12, color: _goldAccent),
                      const SizedBox(width: 6),
                      Text('EDIT PROFILE', style: TextStyle(color: _goldAccent, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          _buildIdentityReadField('FULL NAME', 'TEST ADVOCATE'),
          const SizedBox(height: 24),
          _buildIdentityReadField('EMAIL NODE', 'TESTADVOCATE@GMAIL.COM'),
          const SizedBox(height: 24),
          _buildIdentityReadField('PHONE PROTOCOL', 'NOT SET'),
          const SizedBox(height: 24),
          _buildIdentityReadField('PROFESSIONAL BIO', 'Certified institutional advocate overseeing decentralized capital nodes for Vamanan Enterprises. Specialized in protocol ratification and institutional integrity monitoring.', isBio: true),
        ],
      ),
    );
  }

  Widget _buildIdentityReadField(String label, String value, {bool isBio = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: isBio ? _slateText : _navyBlue,
              fontSize: isBio ? 12 : 14,
              fontWeight: isBio ? FontWeight.w800 : FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: isBio ? 1.5 : 1.0,
              letterSpacing: isBio ? 0.0 : 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // 3b. Identity Details (Edit Mode from your latest image)
  Widget _buildIdentityEditMode() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      key: const ValueKey('IDENTITY_EDIT'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('IDENTITY DETAILS', style: TextStyle(color: _navyBlue, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
              InkWell(
                onTap: () => setState(() => _isEditingIdentity = false),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFBFDBFE))),
                  child: Row(
                    children: const [
                      Icon(Icons.close, size: 12, color: Color(0xFF3B82F6)),
                      SizedBox(width: 6),
                      Text('ABORT', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 32),

          // Top Fields (Row on Desktop, Stacked on Mobile)
          isMobile 
            ? Column(
                children: [
                  _buildEditField(label: 'FULL NAME', initialValue: 'TEST ADVOCATE', icon: Icons.person_outline, readOnly: true),
                  const SizedBox(height: 24),
                  _buildEditField(label: 'EMAIL NODE', initialValue: 'TESTADVOCATE@GMAIL.COM', icon: Icons.mail_outline, readOnly: true),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildEditField(label: 'FULL NAME', initialValue: 'TEST ADVOCATE', icon: Icons.person_outline, readOnly: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildEditField(label: 'EMAIL NODE', initialValue: 'TESTADVOCATE@GMAIL.COM', icon: Icons.mail_outline, readOnly: true)),
                ],
              ),
          
          const SizedBox(height: 24),
          _buildEditField(label: 'PHONE PROTOCOL', hint: 'ENTER CONTACT ID', icon: Icons.phone_outlined, controller: _phoneCtrl, isFocusedBorder: true),
          
          const SizedBox(height: 24),
          _buildEditField(label: 'PROFESSIONAL BIO', controller: _bioCtrl, maxLines: 4),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _handleSaveIdentity,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('SAVE IDENTITY NODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navyBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isEditingIdentity = false),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20)),
                  child: const Text('CANCEL', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEditField({
    required String label, 
    String? initialValue, 
    String? hint, 
    IconData? icon, 
    bool readOnly = false, 
    TextEditingController? controller, 
    bool isFocusedBorder = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          readOnly: readOnly,
          maxLines: maxLines,
          style: TextStyle(
            color: readOnly ? _navyBlue.withOpacity(0.8) : _navyBlue, 
            fontSize: maxLines > 1 ? 13 : 14, 
            fontWeight: maxLines > 1 ? FontWeight.w600 : FontWeight.w900, 
            fontStyle: FontStyle.italic,
            height: maxLines > 1 ? 1.5 : 1.0,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5),
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFFCBD5E1), size: 20) : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC), // Light grey matching image
            contentPadding: const EdgeInsets.all(20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.transparent)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20), 
              borderSide: BorderSide(color: isFocusedBorder ? _goldAccent : Colors.transparent, width: isFocusedBorder ? 2 : 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20), 
              borderSide: BorderSide(color: _goldAccent, width: 2), // Always gold on focus
            ),
          ),
        ),
      ],
    );
  }

  // 4. Security Hub View (Handles both Default & Changing Node states)
  Widget _buildSecurityHub() {
    return Container(
      key: const ValueKey('SECURITY'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SECURITY HUB', style: TextStyle(color: _navyBlue, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -0.5)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _goldAccent.withOpacity(0.5))),
                child: Icon(Icons.security, size: 16, color: _goldAccent),
              )
            ],
          ),
          const SizedBox(height: 32),
          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isChangingNode 
                ? _buildUpdateCredentialsCard() 
                : _buildAccessNodeCard(),
          ),
        ],
      ),
    );
  }

  // State 1: Default Security Card
  Widget _buildAccessNodeCard() {
    return Container(
      key: const ValueKey('DEFAULT_NODE'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.lock_outline, color: Color(0xFFCBD5E1), size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INSTITUTIONAL ACCESS NODE', style: TextStyle(color: _navyBlue, fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Text('UPDATE YOUR ENCRYPTED PROTOCOL KEYS', style: TextStyle(color: _slateText, fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0, height: 1.5)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _isChangingNode = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _navyBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('CHANGE NODE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
          ),
        ],
      ),
    );
  }

  // State 2: Changing Security Credentials Card
  Widget _buildUpdateCredentialsCard() {
    return Container(
      key: const ValueKey('EDIT_NODE'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Faint gold background for edit mode
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _goldAccent.withOpacity(0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_open, color: _goldAccent, size: 20),
                  const SizedBox(width: 12),
                  Text('UPDATE CREDENTIALS', style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                ],
              ),
              IconButton(
                onPressed: () => setState(() => _isChangingNode = false),
                icon: const Icon(Icons.close, color: Color(0xFFCBD5E1)),
              )
            ],
          ),
          const SizedBox(height: 24),
          
          _buildPasswordField('NEW ACCESS NODE', 'ENTER NEW PROTOCOL KEY...', _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
          const SizedBox(height: 24),
          _buildPasswordField('CONFIRM NEW ACCESS NODE', 'CONFIRM NEW PROTOCOL KEY...', _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ElevatedButton(
                onPressed: _handleUpdateSecurity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navyBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('UPDATE SECURITY PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              ),
              OutlinedButton(
                onPressed: () => setState(() => _isChangingNode = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _slateText,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ABORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.0)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, String hint, bool isObscured, VoidCallback onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          obscureText: isObscured,
          style: TextStyle(color: _navyBlue, fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFF1F5F9))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFF1F5F9))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: _goldAccent)),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFFCBD5E1), size: 20),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}