import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/app_page.dart';
import 'package:frontend/shared/widgets/empty_state_card.dart';
import '../../models/advocate_disputes_model.dart';
import '../../services/advocate_disputes_service.dart';
import 'package:frontend/shared/widgets/app_loader.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  final DisputesService _service = DisputesService();

  bool _isLoading = true;
  String? _error;
  List<DisputeModel> _disputes = [];

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final disputes = await _service.fetchDisputes();
      setState(() {
        _disputes = disputes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Disputes',
      subtitle: 'Customer disputes and their resolution status.',
      children: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60.0),
            child: Center(child: AppLoader()),
          )
        else if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load disputes:\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _loadDisputes, child: const Text('Retry')),
                ],
              ),
            ),
          )
        else if (_disputes.isEmpty)
          const EmptyStateCard(
            headerIcon: Icons.balance_outlined,
            headerLabel: 'DISPUTES',
            emptyIcon: Icons.gavel_outlined,
            emptyLabel: 'NO OPEN DISPUTES',
          )
        else
          Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              ..._disputes.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _DisputeCard(dispute: d),
                  )),
            ],
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.balance_outlined, size: 18, color: AppColors.kPrimary),
            SizedBox(width: 8),
            Text(
              'DISPUTES',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: AppColors.kPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Text(
          '${_disputes.length} TOTAL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DISPUTE CARD
// ============================================================================
class _DisputeCard extends StatelessWidget {
  final DisputeModel dispute;

  const _DisputeCard({required this.dispute});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.kPrimary,
                    borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(
                  dispute.customerName.isNotEmpty
                      ? dispute.customerName[0]
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dispute.subject,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text(
                      '${dispute.customerName} • ${dispute.createdDate}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(dispute.status),
            ],
          ),
          if (dispute.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),
            Text(
              dispute.description,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                  height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg, text;
    switch (status) {
      case 'OPEN':
        bg = const Color(0xFFFEF2F2);
        text = const Color(0xFFB91C1C);
        break;
      case 'IN RESOLUTION':
        bg = const Color(0xFFFFFBEB);
        text = AppColors.goldColor;
        break;
      case 'RESOLVED':
      case 'CLOSED':
        bg = const Color(0xFFF0FDF4);
        text = const Color(0xFF16A34A);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              color: text,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 9,
              letterSpacing: 0.5)),
    );
  }
}
