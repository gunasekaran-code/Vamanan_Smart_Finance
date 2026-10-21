import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import '../../models/support_model.dart';
import '../../services/support_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _service = SupportService.instance;

  bool _loading = true;
  String? _error;
  List<SupportNotification> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _service.fetchNotifications();

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _items = res.data ?? [];
      } else {
        _error = res.message ?? 'Failed to load support requests.';
      }
    });
  }

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
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      height: screenHeight * 0.65,
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(48),
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
                  color: AppColors.goldColor,
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
                  color: AppColors.kPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: AppLoader());
    }

    if (_error != null) {
      return _buildEmptyState(
        icon: Icons.error_outline,
        title: 'COULD NOT LOAD REQUESTS',
        subtitle: _error!,
        action: TextButton(onPressed: _load, child: const Text('Retry')),
      );
    }

    if (_items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.verified_user_outlined,
        title: 'NO ACTIVE SUPPORT REQUESTS',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _buildRow(_items[i]),
      ),
    );
  }

  Widget _buildRow(SupportNotification item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread,
            color: item.isRead ? Colors.grey : AppColors.goldColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title.isNotEmpty ? item.title : 'Untitled',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    Text(
                      item.type,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                if (item.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${item.userName.isNotEmpty ? item.userName : 'User #${item.userId ?? '-'}'}  ·  ${item.createdAt}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 72,
            color: AppColors.kPrimary.withOpacity(0.06),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: AppColors.kTextMuted.withOpacity(0.5),
              letterSpacing: 2.0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.kTextMuted.withOpacity(0.7)),
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 12),
            action,
          ],
        ],
      ),
    );
  }
}