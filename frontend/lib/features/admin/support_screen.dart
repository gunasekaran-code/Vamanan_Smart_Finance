import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Support',
      subtitle: 'Manage and review your support requests.',
      children: [
        _buildSupportCard(context),
      ],
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    // Dynamically calculate height to make it feel spacious on any screen size
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      width: double.infinity,
      height: screenHeight * 0.65, // Takes up ~65% of the screen height for a roomy feel
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(48), // Large, smooth rounded corners matching the image
        border: Border.all(
          color: AppColors.kBorder.withOpacity(0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimary.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 2.0),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.goldColor, // Gold accent from AppColors
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'SUPPORT CENTER',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppColors.kPrimary, // Deep royal blue
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Empty State Section (Centered vertically and horizontally)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shield with a checkmark icon
                  Icon(
                    Icons.verified_user_outlined, 
                    size: 72,
                    color: AppColors.kPrimary.withOpacity(0.06), // Very faint watermark look
                  ),
                  const SizedBox(height: 24),
                  
                  // Stylized Empty State Text
                  Text(
                    'NO ACTIVE SUPPORT REQUESTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppColors.kTextMuted.withOpacity(0.5), // Faint greyish-blue text
                      letterSpacing: 2.0, // Wide letter spacing matching the design
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}