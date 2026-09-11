import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';
import 'network_nodes_screen.dart';


class ExplorerNode {
  final String id;
  final String name;
  final String systemId;

  ExplorerNode({required this.id, required this.name, required this.systemId});
}

class GenealogyExplorerScreen extends StatefulWidget {
  const GenealogyExplorerScreen({super.key});

  @override
  State<GenealogyExplorerScreen> createState() => _GenealogyExplorerScreenState();
}

class _GenealogyExplorerScreenState extends State<GenealogyExplorerScreen> {
  final List<ExplorerNode> _nodes = [
    ExplorerNode(id: '1', name: 'VAMANAN ENTERPRISES V', systemId: 'VEV100'),
    ExplorerNode(id: '2', name: 'AUDITOR', systemId: 'VEV_AUDITOR'),
    ExplorerNode(id: '3', name: 'TIRUCHENDUR MURUGAN', systemId: 'VEV2T8ZY'),
    ExplorerNode(id: '4', name: 'TIRUCHENGODU VELMURUGAN', systemId: 'VEV2T8ZZ'),
    ExplorerNode(id: '5', name: 'PALANI MURUGAN', systemId: 'VEV_PALANI'),
    ExplorerNode(id: '6', name: 'SWAMIMALAI MURUGAN', systemId: 'VEV_SWAMI'),
  ];

  Future<void> _handleProcessYield() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'PROCESS MONTHLY YIELD',
      message: "Process this month's cashback? This credits one monthly installment (10%) to every cycle that is due, and can only run ONCE per calendar month.",
      confirmLabel: 'OKAY',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      ToastService.show(title: 'Success', message: 'Monthly yield processed.', type: ToastType.success);
    }
  }

  void _navigateToNetworkNodes(ExplorerNode node) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NetworkNodesScreen(rootNodeName: node.name, rootNodeId: node.systemId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Global Search
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder)),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users, orders, assets...',
                    hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Process Yield Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _handleProcessYield,
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('PROCESS MONTHLY YIELD', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Main Explorer Content
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.kBorder)),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GENEALOGY EXPLORER', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 4),
                    Text('AUDIT REFERRAL RELATIONSHIPS — FLAT 2% DIRECT COMMISSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                    const SizedBox(height: 24),

                    // Node Search
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.kBorder)),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'SEARCH INVESTOR NODE...',
                          hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                          prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Node List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _nodes.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildNodeCard(_nodes[index]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const FraudDetectionWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeCard(ExplorerNode node) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(node.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node.name, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(node.systemId, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          InkWell(
            onTap: () => _navigateToNetworkNodes(node),
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('INSPECT TREE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
                  Icon(Icons.account_tree_outlined, size: 16, color: const Color(0xFF94A3B8).withOpacity(0.5)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}