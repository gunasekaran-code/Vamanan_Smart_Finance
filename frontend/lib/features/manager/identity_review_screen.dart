import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../../models/identity_verification_model.dart';
import '../../services/identity_verification_service.dart';

/// The review sheet for one KYC submission.
///
/// The list endpoint (`admin/all_users.php`) only carries the status and the
/// document path, so the Aadhaar, PAN, address and bank fields are read here
/// from `customer/kyc.php?user_id=N`. Before this they were hardcoded 'N/A'.
///
/// Pops `true` to approve and `false` to reject; the caller performs the write.
class IdentityReviewScreen extends StatefulWidget {
  final IdentityRequest request;

  const IdentityReviewScreen({super.key, required this.request});

  @override
  State<IdentityReviewScreen> createState() => _IdentityReviewScreenState();
}

class _IdentityReviewScreenState extends State<IdentityReviewScreen> {
  late IdentityRequest _request = widget.request;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detailed =
          await IdentityVerificationService.instance.fetchDetails(_request);
      if (!mounted) return;
      setState(() {
        _request = detailed;
        _loading = false;
      });
    } on IdentityVerificationException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 600;
    final hPad = isTablet ? 32.0 : 16.0;
    final gap = isTablet ? 24.0 : 16.0;

    final identityCard = _buildSectionCard(
      title: 'IDENTITY DETAILS',
      children: [
        _buildDetailRow('CONTACT LINE', _request.phone),
        _buildDetailRow('AADHAR REFERENCE', _request.aadharNo),
        _buildDetailRow('PAN NUMBER', _request.panNo),
        _buildDetailRow('ADDRESS', _request.address, isLast: true),
      ],
    );
    final bankCard = _buildSectionCard(
      title: 'BANK INFRASTRUCTURE',
      children: [
        _buildDetailRow('INSTITUTION', _request.bankName),
        _buildDetailRow('VAULT NUMBER', _request.accountNo),
        _buildDetailRow('IFSC CODE', _request.ifscCode),
        _buildDetailRow('BRANCH DESIGNATION', _request.branchName,
            isLast: true),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.kSurface,
      body: SafeArea(
        // One scroll view for the whole sheet, so the actions sit directly
        // below the bank card instead of being pinned to the bottom.
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, isTablet ? 24 : 16, hPad, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  SizedBox(height: gap),
                  _buildDocumentPanel(height: isTablet ? 320 : 220),
                  SizedBox(height: gap),
                  if (_error != null) ...[
                    _buildErrorBanner(_error!),
                    SizedBox(height: gap),
                  ],
                  // Side by side on tablets, stacked on phones.
                  if (isTablet)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: identityCard),
                          SizedBox(width: gap),
                          Expanded(child: bankCard),
                        ],
                      ),
                    )
                  else ...[
                    identityCard,
                    SizedBox(height: gap),
                    bankCard,
                  ],
                  SizedBox(height: isTablet ? 32 : 24),
                  _buildActions(isTablet: isTablet),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IDENTITY REVIEW',
                        style: TextStyle(
                          color: AppColors.kPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _request.customerId.isEmpty
                            ? 'REVIEW FOR: ${_request.name}'
                            : 'REVIEW FOR: ${_request.name} · ${_request.customerId}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  /// The uploaded document, served from `uploads/kyc/` off the site root.
  Widget _buildDocumentPanel({required double height}) {
    final url = _request.documentUrl;

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF070B1F), // Very dark navy
        borderRadius: BorderRadius.circular(24),
      ),
      child: url == null
          ? _buildNoDocument()
          : Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.kPrimary)),
              // A PDF or a path that no longer resolves lands here, so the
              // reviewer is told the file exists but cannot be previewed.
              errorBuilder: (context, _, __) => _buildDocumentFallback(url),
            ),
    );
  }

  Widget _buildNoDocument() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.warning_amber_rounded,
            color: Colors.blue.shade600, size: 48),
        const SizedBox(height: 16),
        Text(
          'NO DIGITAL ARTIFACT FOUND',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentFallback(String url) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined,
              color: Colors.blue.shade300, size: 44),
          const SizedBox(height: 14),
          Text(
            'DOCUMENT ON FILE · PREVIEW UNAVAILABLE',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            url,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kDanger.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kDanger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.kDanger.withOpacity(0.8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not load the KYC details. $message',
              style: const TextStyle(
                color: AppColors.kTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: _loadDetails, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildActions({required bool isTablet}) {
    final approve = ElevatedButton(
      // Returning true indicates approval
      onPressed: () => Navigator.pop(context, true),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.kPrimary,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: AppColors.kPrimary.withOpacity(0.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'APPROVE IDENTITY',
              style: TextStyle(
                color: Colors.amber.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    final reject = OutlinedButton(
      // Returning false indicates rejection
      onPressed: () => Navigator.pop(context, false),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        side: BorderSide(color: Colors.grey.shade200, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'REJECT REQUEST',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (isTablet) {
      return Row(
        children: [
          Expanded(child: approve),
          const SizedBox(width: 16),
          Expanded(child: reject),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        approve,
        const SizedBox(height: 12),
        reject,
      ],
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB), // Light greyish background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300, height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {bool isLast = false}) {
    // While the detail fetch is in flight the value is unknown rather than
    // empty, so the row says so instead of printing a dash.
    final text = _loading && !_request.detailsLoaded
        ? 'LOADING…'
        : IdentityRequest.display(value);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              color: text == '—' || text == 'LOADING…'
                  ? Colors.grey.shade400
                  : AppColors.kPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
