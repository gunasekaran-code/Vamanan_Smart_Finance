import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'genealogy_explorer_screen.dart'; // Just for the Fraud widget if kept in same file, otherwise import appropriately

// --- Tree Node Data Model ---
class TreeNodeData {
  final String name;
  final String systemId;
  final String level;
  final String? stats;
  final List<TreeNodeData> children;
  bool isExpanded;

  TreeNodeData({
    required this.name,
    required this.systemId,
    required this.level,
    this.stats,
    this.children = const [],
    this.isExpanded = false,
  });
}

class NetworkNodesScreen extends StatefulWidget {
  final String rootNodeName;
  final String rootNodeId;

  const NetworkNodesScreen({super.key, required this.rootNodeName, required this.rootNodeId});

  @override
  State<NetworkNodesScreen> createState() => _NetworkNodesScreenState();
}

class _NetworkNodesScreenState extends State<NetworkNodesScreen> {
  // Mocking the tree data matching the design image exactly
  late List<TreeNodeData> _treeNodes;

  @override
  void initState() {
    super.initState();
    _treeNodes = [
      TreeNodeData(
        name: 'SRIRAMA MOORTHI', systemId: 'VEV10146', level: 'L1',
        children: [
          TreeNodeData(name: 'SAMPATHRAJ.S', systemId: 'VEVQKNW0', level: 'L2'),
        ]
      ),
      TreeNodeData(name: 'SARANYA.S', systemId: 'VEVRNACY', level: 'L1'),
      TreeNodeData(
        name: 'SELVAM.M', systemId: 'VEVBZPSW', level: 'L1',
        children: [
          TreeNodeData(name: 'MUNIYAMMAL', systemId: 'VEVUXSOD', level: 'L2'),
        ]
      ),
      TreeNodeData(
        name: 'KUMARAN THANGAVELU', systemId: 'VEVSOLZW', level: 'L1', stats: '₹1,60,051.24', isExpanded: true,
        children: [
          TreeNodeData(name: 'GNANAPAZHAM THANGAVEL', systemId: 'VEV9YV40', level: 'L2', stats: '₹10,08,307.44'),
          TreeNodeData(name: 'BALAKRISHNAN.G', systemId: 'VEVUAHRO', level: 'L2'),
          TreeNodeData(name: 'THEEPAN.N THAMODHIRAN', systemId: 'VEVUGO9E', level: 'L2'),
          TreeNodeData(name: 'INDIRANI.M', systemId: 'VEVNUIUO', level: 'L2'),
        ]
      ),
      TreeNodeData(name: 'SOMASUNDARAM', systemId: 'VEVMI81D', level: 'L1'),
    ];
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
              // Header with Back Button and Search
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GENEALOGY EXPLORER', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                        const SizedBox(height: 4),
                        Text('AUDIT REFERRAL RELATIONSHIPS — FLAT 2% DIRECT COMMISSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Selected Root Node Header
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB), // Cream background
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: const Color(0xFF1E3A8A), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(widget.rootNodeName.substring(0, 1).toUpperCase(), style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SELECTED ROOT NODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706))),
                          Text(widget.rootNodeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                          const SizedBox(height: 4),
                          Text('${widget.rootNodeName.replaceAll(" ", "").toLowerCase()}123@gmail.com  ✦ ${widget.rootNodeId}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('REFERRAL MODEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                        const Text('Flat 2% Direct', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Your Referral Tree Section
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.kBorder)),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Inner Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(24)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('YOUR REFERRAL TREE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                              const SizedBox(height: 2),
                              Text('SEE YOUR DIRECT MEMBERS — FLAT 2% REFERRAL', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                            ],
                          ),
                          Row(
                            children: ['L1', 'L2', 'L3', 'L4', 'L5'].map((level) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: level == 'L1' ? const Color(0xFFFBBF24) : Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                child: Text(level, style: TextStyle(color: level == 'L1' ? const Color(0xFF1E3A8A) : Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            )).toList(),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recursive Tree Builder
                    ..._treeNodes.map((node) => _buildTreeNode(node, 0)).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Reusable Fraud Detection Widget
              const FraudDetectionWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreeNode(TreeNodeData node, int depth) {
    bool isL1 = depth == 0;
    
    return Padding(
      padding: EdgeInsets.only(left: depth * 24.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              if (node.children.isNotEmpty) {
                setState(() {
                  node.isExpanded = !node.isExpanded;
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isL1 ? const Color(0xFFFFFBEB) : const Color(0xFFEFF6FF), // Yellow for L1, Blue for L2
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isL1 ? const Color(0xFFFDE68A) : const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isL1 ? const Color(0xFFFDE68A) : const Color(0xFFBFDBFE)),
                    ),
                    child: Icon(
                      node.children.isEmpty
                          ? Icons.person_outline
                          : (node.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right),
                      size: 16,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(node.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                            const SizedBox(width: 8),
                            Text(node.level, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF3B82F6))),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(node.systemId, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                            if (node.stats != null) ...[
                              const SizedBox(width: 8),
                              Text(node.stats!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706))),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Children rendering if expanded
          if (node.isExpanded && node.children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: node.children.map((child) => _buildTreeNode(child, depth + 1)).toList(),
              ),
            )
        ],
      ),
    );
  }
}

// --- Reusable Fraud Detection Widget (Bottom Section) ---
class FraudDetectionWidget extends StatelessWidget {
  const FraudDetectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A), // Deep Navy Blue
        borderRadius: BorderRadius.circular(32),
        // Add a subtle inner shadow/watermark feel by using gradient or stack if needed, sticking to pure color for simplicity
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              const Text('FRAUD DETECTION INTELLIGENCE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 6),
          Text('NEURAL MONITORING FOR CIRCULAR REFERRAL PATTERNS AND MULTIPLE ACCOUNT ABUSE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.7), letterSpacing: 0.5)),
          const SizedBox(height: 24),

          // Responsive layout for the 3 inner cards
          LayoutBuilder(
            builder: (context, constraints) {
              // If width is tight (mobile portrait), stack them. If wide (tablet/landscape), put in a row.
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildFraudCard(icon: Icons.sync, title: 'CIRCULAR LINKS', value: '4 Detected', status: 'RISK FOUND', statusColor: const Color(0xFFF43F5E)),
                    const SizedBox(height: 12),
                    _buildFraudCard(icon: Icons.language, title: 'IP CLUSTERS', value: '8 Flagged', status: 'REVIEW NEEDED', statusColor: const Color(0xFFFBBF24)),
                    const SizedBox(height: 12),
                    _buildFraudCard(icon: Icons.show_chart, title: 'NODE VELOCITY', value: '0 New Today', status: 'HEALTHY', statusColor: const Color(0xFF10B981)),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: _buildFraudCard(icon: Icons.sync, title: 'CIRCULAR LINKS', value: '4 Detected', status: 'RISK FOUND', statusColor: const Color(0xFFF43F5E))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFraudCard(icon: Icons.language, title: 'IP CLUSTERS', value: '8 Flagged', status: 'REVIEW NEEDED', statusColor: const Color(0xFFFBBF24))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFraudCard(icon: Icons.show_chart, title: 'NODE VELOCITY', value: '0 New Today', status: 'HEALTHY', statusColor: const Color(0xFF10B981))),
                  ],
                );
              }
            },
          )
        ],
      ),
    );
  }

  Widget _buildFraudCard({required IconData icon, required String title, required String value, required String status, required Color statusColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08), // Glassy effect
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.5), size: 24),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.circle, size: 6, color: statusColor),
              const SizedBox(width: 6),
              Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: statusColor)),
            ],
          )
        ],
      ),
    );
  }
}