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
        // Minimalist Green & White Profile Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Clickable Avatar with Camera Badge
                  GestureDetector(
                    onTap: () => _showImagePickerModal(context),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.kPrimary,
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.kSurface,
                              shape: BoxShape.circle,
                            ),
                            child: const CircleAvatar(
                              radius: 9,
                              backgroundColor: AppColors.kPrimary,
                              child: Icon(Icons.camera_alt, size: 10, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.kTextDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(color: AppColors.kTextMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.kPrimaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.role.label,
                            style: const TextStyle(
                              color: AppColors.kPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Edit Profile Action Trigger
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showEditProfileDialog(context, user),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profile Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kPrimary,
                    side: const BorderSide(color: AppColors.kPrimaryLight),
                    backgroundColor: AppColors.kPrimaryLight.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
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

        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.kDanger,
              side: const BorderSide(color: AppColors.kDanger),
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
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }
}