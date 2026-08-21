import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_role.dart';
import '../../routes/app_routes.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/stylish_form.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Modal Sheet for Profile Picture Options
  void _showImagePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Update Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kTextDark,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.kPrimaryLight,
                    child: Icon(Icons.camera_alt_outlined, color: AppColors.kPrimary),
                  ),
                  title: const Text(
                    'Open Camera',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.kTextDark),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ToastService.show(
                      title: 'Camera Opened',
                      message: 'Capturing new profile picture...',
                      type: ToastType.info,
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.kPrimaryLight,
                    child: Icon(Icons.photo_library_outlined, color: AppColors.kPrimary),
                  ),
                  title: const Text(
                    'Upload Image',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.kTextDark),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ToastService.show(
                      title: 'Image Selected',
                      message: 'Profile picture updated successfully.',
                      type: ToastType.success,
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextMuted,
                      side: const BorderSide(color: AppColors.kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Edit Profile Dialog using stylish_form.dart
  void _showEditProfileDialog(BuildContext context, dynamic user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.kSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kTextDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.kTextMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StylishTextField(
                  controller: nameController,
                  labelText: 'Full Name',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                StylishTextField(
                  controller: emailController,
                  labelText: 'Email Address',
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ToastService.show(
                      title: 'Profile Updated',
                      message: 'Your profile changes have been saved.',
                      type: ToastType.success,
                    );
                  },
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.currentUser!;

    return AppPage(
      title: 'My Profile',
      children: [
        // -------------------------------------------------------------
        // TOP PROFILE HEADER CARD
        // -------------------------------------------------------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Avatar with Crown Accent Ring & Camera Badge
              GestureDetector(
                onTap: () => _showImagePickerModal(context),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37), width: 2), // Gold ring accent
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.kPrimary,
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: AppColors.kPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextDark,
                ),
              ),
              const SizedBox(height: 10),

              // Status Chips (SUPERADMIN & VERIFIED ACCOUNT)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7F6), // Light violet
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 13, color: Color(0xFF673AB7)),
                        const SizedBox(width: 4),
                        Text(
                          user.role.label.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF673AB7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), // Light green
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 13, color: Color(0xFF2E7D32)),
                        SizedBox(width: 4),
                        Text(
                          'VERIFIED ACCOUNT',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Joined Date Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.kBorder.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Joined Apr 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.kTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Email & UID info row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined, size: 14, color: AppColors.kTextMuted),
                  const SizedBox(width: 4),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 13, color: AppColors.kTextMuted),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.badge_outlined, size: 14, color: AppColors.kTextMuted),
                  const SizedBox(width: 4),
                  const Text(
                    'UID: 0001',
                    style: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Edit Profile Button
              OutlinedButton.icon(
                onPressed: () => _showEditProfileDialog(context, user),
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.kTextDark,
                  side: BorderSide(color: AppColors.kBorder.withOpacity(0.8)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // -------------------------------------------------------------
        // ACCOUNT IDENTITY CARD
        // -------------------------------------------------------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_pin_outlined, color: AppColors.kPrimary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Account Identity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kTextDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // OFFICIAL USERNAME
              const Text(
                'OFFICIAL USERNAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${user.name.toLowerCase().replaceAll(' ', '')}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextDark,
                ),
              ),
              const SizedBox(height: 16),

              // LOGIN CREDENTIAL
              const Text(
                'LOGIN CREDENTIAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextDark,
                ),
              ),
              const SizedBox(height: 16),

              // PASSWORD STATUS
              const Text(
                'PASSWORD STATUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
                  SizedBox(width: 6),
                  Text(
                    'Encrypted & Secured',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // -------------------------------------------------------------
        // UNIFIED PORTFOLIO CONTEXT CARD
        // -------------------------------------------------------------
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.grid_view_rounded, color: AppColors.kTextDark, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Unified Portfolio Context',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kTextDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chit Fund Member Block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F9F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.savings_outlined, color: Color(0xFF2E7D32), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Chit Fund Member',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No active chit membership',
                      style: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Loan Portfolio Block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance_outlined, color: Color(0xFF5C6BC0), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Loan Portfolio',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kTextDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No linked member profile',
                      style: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Access Recovery & Security Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F7),
                    foregroundColor: AppColors.kTextDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    ToastService.show(
                      title: 'Security',
                      message: 'Accessing recovery options...',
                      type: ToastType.info,
                    );
                  },
                  icon: const Icon(Icons.vpn_key_outlined, size: 18),
                  label: const Text(
                    'Access Recovery & Security',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // System Exit Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.kDanger,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    SessionService.instance.logout();
                    ToastService.show(
                      title: 'Signed Out',
                      message: 'You have been signed out successfully.',
                      type: ToastType.info,
                    );
                    context.go(AppRoutes.login);
                  },
                  icon: const Icon(Icons.logout, size: 16, color: AppColors.kDanger),
                  label: const Text(
                    'System Exit',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // -------------------------------------------------------------
        // SWITCH DEMO ROLE (DEV HELPER)
        // -------------------------------------------------------------
        const Text('Switch Demo Role', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 4),
        const Text(
          'Frontend-only helper for exercising RBAC — remove once real '
          'authentication is wired up.',
          style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final role in UserRole.values)
              ChoiceChip(
                label: Text(role.label),
                selected: user.role == role,
                selectedColor: AppColors.kPrimaryLight,
                labelStyle: TextStyle(
                  color: user.role == role ? AppColors.kPrimary : AppColors.kTextDark,
                  fontWeight: user.role == role ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) {
                  SessionService.instance.login(
                    username: role.apiValue.toLowerCase(),
                    password: 'demo',
                  );
                  ToastService.show(
                    title: 'Role Switched',
                    message: 'Switched session role to ${role.label}',
                    type: ToastType.info,
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}