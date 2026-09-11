import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'identity_review_screen.dart';

class IdentityRequest {
  final String id;
  final String name;
  final String email;
  final String phone;

  const IdentityRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });
}

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  // Dummy data based on the design provided
  List<IdentityRequest> _requests = [
    const IdentityRequest(
      id: '1',
      name: 'ARUMUGAM PONNUSAMY',
      email: 'ARUMUGAMMONISH123@GMAIL.COM',
      phone: '9566788876',
    ),
    const IdentityRequest(
      id: '2',
      name: 'VASUNDHARA',
      email: 'SUNDARENTERPRISES17@GMAIL.COM',
      phone: '9566788876',
    ),
    const IdentityRequest(
      id: '3',
      name: 'VIGNESH',
      email: 'VIKY009426@GMAIL.COM',
      phone: '9566788876',
    ),
    const IdentityRequest(
      id: '4',
      name: 'JEEVITHA',
      email: 'NARASIMMANJEEVI@GMAIL.COM',
      phone: '9566788876',
    ),
  ];

  Future<void> _handleAction(IdentityRequest request, bool isApprove) async {
    final actionName = isApprove ? 'Approve' : 'Reject';
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: '$actionName Identity',
      message:
          'Are you sure you want to ${actionName.toLowerCase()} the identity verification for ${request.name}?',
      confirmLabel: actionName,
      confirmButtonColor: isApprove ? AppColors.kSuccess : AppColors.kDanger,
    );

    if (confirmed == true && mounted) {
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
      });

      ToastService.show(
        title: 'Identity ${isApprove ? 'Approved' : 'Rejected'}',
        message:
            '${request.name} has been successfully ${actionName.toLowerCase()}d.',
        type: isApprove ? ToastType.success : ToastType.error,
      );
    }
  }

  Future<void> _openReview(IdentityRequest request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdentityReviewScreen(request: request),
      ),
    );

    // If the review screen returns true (approved) or false (rejected)
    if (result != null && result is bool && mounted) {
      setState(() {
        _requests.removeWhere((r) => r.id == request.id);
      });
      ToastService.show(
        title: result ? 'Identity Approved' : 'Identity Rejected',
        message: '${request.name} has been successfully processed.',
        type: result ? ToastType.success : ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: null,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),

        if (_requests.isEmpty)
          _buildEmptyState()
        else
          ..._requests.map((request) => _buildVerificationCard(request)),

        const SizedBox(height: 40), // Bottom padding
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Icon(
            Icons.admin_panel_settings_outlined,
            color: AppColors.goldColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IDENTITY VERIFICATION',
                style: TextStyle(
                  color: AppColors.kPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'REVIEW AND MANAGE USER IDENTITY SUBMISSIONS',
                style: TextStyle(
                  color: AppColors.kTextMuted.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCard(IdentityRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Squircle
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.kPrimary.withOpacity(0.1)),
                ),
                alignment: Alignment.center,
                child: Text(
                  request.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.kPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Name and Email Data
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style: const TextStyle(
                        color: AppColors.kPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 12, color: AppColors.kTextMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            request.email.toLowerCase(),
                            style: const TextStyle(
                              color: AppColors.kTextMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () => _openReview(request),
                    icon: const Icon(
                      Icons.description_outlined,
                      size: 22,
                    ),
                    label: const Text(
                      'REVIEW DOCS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kPrimary,
                      side: BorderSide(
                        color: AppColors.kBorder.withOpacity(0.8),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                height: 42,
                child: _buildIconButton(
                  icon: Icons.check_rounded,
                  iconColor: Colors.white,
                  bgColor: AppColors.kPrimary,
                  tooltip: 'Approve',
                  onTap: () => _handleAction(request, true),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                height: 42,
                child: _buildIconButton(
                  icon: Icons.close_rounded,
                  iconColor: AppColors.kDanger,
                  bgColor: AppColors.kDanger.withOpacity(0.1),
                  tooltip: 'Reject',
                  onTap: () => _handleAction(request, false),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

 Widget _buildIconButton({
  required IconData icon,
  required Color iconColor,
  required Color bgColor,
  required String tooltip,
  required VoidCallback onTap,
}) {
  return Tooltip(
    message: tooltip,
    child: Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: Icon(
              icon,
              size: 25,
              color: iconColor,
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined,
              size: 80, color: AppColors.kTextMuted.withOpacity(0.15)),
          const SizedBox(height: 24),
          const Text(
            'NO PENDING VERIFICATIONS',
            style: TextStyle(
              color: AppColors.kTextMuted,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'All submitted identities have been processed.',
            style: TextStyle(
              color: AppColors.kTextMuted.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
