import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// --- Mock Data Model ---
class ProtocolEntry {
  final String initial;
  final String name;
  final String email;
  final String ref;
  final String value;

  ProtocolEntry(this.initial, this.name, this.email, this.ref, this.value);
}

class InvestmentReportsScreen extends StatefulWidget {
  const InvestmentReportsScreen({super.key});

  @override
  State<InvestmentReportsScreen> createState() => _InvestmentReportsScreenState();
}

class _InvestmentReportsScreenState extends State<InvestmentReportsScreen> {
  // Search Controller for the Registry
  final TextEditingController _registrySearchController = TextEditingController();

  final List<ProtocolEntry> _entries = [
    ProtocolEntry('N', 'NANDHA KUMAR.M', 'n2348979@gmail.com', '123456', '₹8,40,000.00'),
    ProtocolEntry('P', 'PRAKASH.A', 'prakashaugust19@gmail.com', '123456', '₹1,68,001.24'),
    ProtocolEntry('S', 'SOMASUNDARAM.S', 'somaskm0504@gmail.com', '123456', '₹1,68,001.24'),
    ProtocolEntry('K', 'KANAGARAJ.K', 'kanagu2024k@gmail.com', '123456', '₹6,72,004.96'),
    ProtocolEntry('N', 'NARASIMHAN THANGAVELU', 'narasimhan@gmail.com', '123456', '₹1,68,001.24'),
    ProtocolEntry('A', 'ARUN.K', 'arunkumar89@gmail.com', '123456', '₹8,40,000.00'),
    ProtocolEntry('V', 'VIGNESH', 'vignesh9426@gmail.com', '123456', '₹1,26,000.00'),
  ];

  @override
  void dispose() {
    _registrySearchController.dispose();
    super.dispose();
  }

  // --- Handlers ---
  void _handleRefreshProtocol() {
    ToastService.show(
      title: 'Protocol Refreshed',
      message: 'Investment intelligence data synced with the global node.',
      type: ToastType.success,
    );
  }

  Future<void> _handleExportLedger() async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'EXPORT LEDGER',
      message: 'Generate a full data dump of the investment node registry?',
      confirmLabel: 'EXPORT',
      cancelLabel: 'CANCEL',
      confirmButtonColor: const Color(0xFF1E3A8A),
    );

    if (confirmed == true) {
      ToastService.show(
        title: 'Export Initiated',
        message: 'The investment ledger is being prepared for download.',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light crisp background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Global Search Bar ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kBorder),
                ),
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
              const SizedBox(height: 32),

              // --- 2. Header Section ---
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 600;

                  Widget titleContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 32, height: 2, color: const Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          const Text(
                            'ANALYTICAL COMMAND NODE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFFD97706), // Gold
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 32, height: 2, color: const Color(0xFFD97706)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'INVESTMENT',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF1E3A8A), // Navy
                          height: 0.9,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'REPORTS',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFD97706), // Gold
                          height: 0.9,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'HIGH-FIDELITY FISCAL INTELLIGENCE & ASSET OVERSIGHT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF94A3B8).withOpacity(0.8),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  );

                  Widget actionContent = Column(
                    crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _handleRefreshProtocol,
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text(
                          'REFRESH PROTOCOL',
                          style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFD97706), // Gold text
                          side: const BorderSide(color: Color(0xFFFDE68A)), // Light gold border
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                          elevation: 2,
                          shadowColor: const Color(0xFFD97706).withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'LAST UPDATED: JUST NOW',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF94A3B8).withOpacity(0.7),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleContent,
                        const SizedBox(height: 24),
                        actionContent,
                      ],
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: titleContent),
                      actionContent,
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // --- 3. Transmission Velocity Chart Card ---
              _buildTransmissionVelocityCard(),
              const SizedBox(height: 24),

              // --- 4. Market Trajectory & Data Dump Row ---
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 800;

                  Widget marketCard = _buildMarketTrajectoryCard();
                  Widget dataDumpCard = _buildGlobalDataDumpCard();

                  if (isMobile) {
                    return Column(
                      children: [
                        marketCard,
                        const SizedBox(height: 24),
                        dataDumpCard,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: marketCard),
                      const SizedBox(width: 24),
                      Expanded(child: dataDumpCard),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),

              // --- 5. Protocol History Table ---
              _buildProtocolHistoryCard(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Sub-Components ---

  Widget _buildTransmissionVelocityCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TRANSMISSION VELOCITY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  Text('TEMPORAL YIELD ANALYSIS (30 CYCLES)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 1)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Color(0xFFD97706)),
                    SizedBox(width: 6),
                    Text('LIVE NODE ACTIVE', style: TextStyle(color: Color(0xFFD97706), fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Simulated Line Chart
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _ChartPainter(),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(height: 1, color: AppColors.kBorder),
          const SizedBox(height: 24),
          
          // Footer Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVelocityStat('AGGREGATE VALUE', '₹1,95,36,477.75', const Color(0xFF1E3A8A)),
              _buildVelocityStat('NODE COUNT', '43', const Color(0xFF1E3A8A)),
              _buildVelocityStat('PROTOCOL STATUS', 'OPTIMAL', const Color(0xFFD97706)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: valueColor)),
      ],
    );
  }

  Widget _buildMarketTrajectoryCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFC29B38), // Mustard Gold
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFFD97706).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.show_chart, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 24),
          const Text('MARKET TRAJECTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('43.3%', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white, height: 1)),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.arrow_right, color: Colors.white, size: 14),
              Text('INSTITUTIONAL GRADE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.8), letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalDataDumpCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
            child: const Icon(Icons.hub_outlined, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(height: 24),
          const Text('GLOBAL OPERATIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('43 NODE REGISTRY', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleExportLedger,
              icon: const Icon(Icons.download, size: 14),
              label: const Text('EXPORT LEDGER', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolHistoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 600;
                
                Widget titleArea = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.receipt_long_outlined, color: Color(0xFFD97706), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROTOCOL\nHISTORY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), height: 1.1)),
                          const SizedBox(height: 4),
                          Text('IMMUTABLE TRANSACTION REGISTRY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ],
                );

                Widget searchArea = Column(
                  children: [
                    SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _registrySearchController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'SEARCH REGISTRY...',
                          hintStyle: const TextStyle(color: AppColors.kTextMuted, fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900),
                          prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.kTextMuted),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.kBorder)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.kBorder), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.filter_list, size: 16, color: AppColors.kTextMuted),
                          Text('ALL NODES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                          Icon(Icons.arrow_drop_down, size: 16, color: AppColors.kTextMuted),
                        ],
                      ),
                    )
                  ],
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleArea,
                      const SizedBox(height: 24),
                      searchArea,
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 3, child: titleArea),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: searchArea),
                  ],
                );
              }
            ),
          ),
          
          const Divider(height: 1, color: AppColors.kBorder),

          // Scrollable Table Header & Body
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
              child: DataTable(
                columnSpacing: 48,
                headingRowHeight: 56,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 72,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                dividerThickness: 1,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 9, letterSpacing: 1.5),
                columns: const [
                  DataColumn(label: Text('ENTITY NODE')),
                  DataColumn(label: Text('PROTOCOL REF')),
                  DataColumn(label: Text('VALUE (₹)')),
                ],
                rows: _entries.map((entry) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9), // Light slate
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                entry.initial,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(entry.email, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(entry.ref, style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFF64748B), fontSize: 12))),
                      DataCell(Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// --- Custom Painter for the Line Chart Graphic ---
class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD97706) // Gold / Orange
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Simulating the peaks and valleys from the reference image
    double w = size.width;
    double h = size.height;
    
    // Start slightly indented
    path.moveTo(w * 0.1, h * 0.9);
    path.lineTo(w * 0.25, h * 0.85);
    path.lineTo(w * 0.35, h * 0.1); // Peak 1
    path.lineTo(w * 0.45, h * 0.6); // Valley
    path.lineTo(w * 0.55, h * 0.3); // Peak 2
    path.lineTo(w * 0.65, h * 0.8);
    path.lineTo(w * 0.70, h * 0.9);
    path.lineTo(w * 0.80, h * 0.75); // Small peak 3
    path.lineTo(w * 0.9, h * 0.9);

    // Draw the gradient fill under the line
    final fillPath = Path.from(path);
    fillPath.lineTo(w * 0.9, h);
    fillPath.lineTo(w * 0.1, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFD97706).withOpacity(0.2),
          const Color(0xFFD97706).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}