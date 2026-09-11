import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/shared/widgets/stat_card.dart'; // Your provided StatCard widget

// --- Mock Data Model ---
class WalletCustomer {
  final String name;
  final String email;
  final String balance;
  final String status;

  WalletCustomer({
    required this.name,
    required this.email,
    required this.balance,
    required this.status,
  });
}

class WalletListScreen extends StatefulWidget {
  const WalletListScreen({super.key});

  @override
  State<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends State<WalletListScreen> {
  // Mock data matching the design
  final List<WalletCustomer> _customers = [
    WalletCustomer(name: 'ANAND K', email: 'anandkannan72@gmail.com', balance: '₹ 1,00,000', status: 'ACTIVE'),
    WalletCustomer(name: 'NANDHA KUMAR.M', email: 'n2348979@gmail.com', balance: '₹ 54,000', status: 'ACTIVE'),
    WalletCustomer(name: 'KANAGARAJ K', email: 'kanagarajk.31@gmail.com', balance: '₹ 12,500', status: 'ACTIVE'),
    WalletCustomer(name: 'AKILA.M', email: 'akilakannan31@gmail.com', balance: '₹ 25,000', status: 'ACTIVE'),
    WalletCustomer(name: 'TIRUPARANKUNDRAM MURUGAN', email: 'tiruparankundram123@gmail.com', balance: '₹ 1,50,000', status: 'ACTIVE'),
    WalletCustomer(name: 'KUMARAN THANGAVELU', email: 'kumaran1980@gmail.com', balance: '₹ 75,000', status: 'ACTIVE'),
    WalletCustomer(name: 'SATHYA T', email: 'sathya.tech@gmail.com', balance: '₹ 10,000', status: 'ACTIVE'),
    WalletCustomer(name: 'PRAKASH.A', email: 'prakashaugust1@gmail.com', balance: '₹ 2,00,000', status: 'ACTIVE'),
    WalletCustomer(name: 'HARIHARAN.M', email: 'hariharan.m@gmail.com', balance: '₹ 33,400', status: 'ACTIVE'),
    WalletCustomer(name: 'SOMASUNDARAM S', email: 'somasundaram@gmail.com', balance: '₹ 45,000', status: 'ACTIVE'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light crisp background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A), // Dark blue brand icon
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WALLET LIST', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), letterSpacing: 1)),
            Text('WALLET BALANCE CONTROL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.kBorder, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Titles
                  const Text('INVESTOR WALLETS', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  Text('MANAGEMENT PORTAL FOR CAPITAL FLOWS AND NETWORK YIELDS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.kBorder),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'SEARCH IDENTITY OR PROTOCOL...',
                        hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
                        prefixIcon: Icon(Icons.search, color: AppColors.kTextMuted, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Dropdown Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('LIFETIME YIELDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                      Icon(Icons.arrow_drop_down, color: const Color(0xFF1E3A8A).withOpacity(0.5)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2x2 Stats Grid using provided StatCard widget
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9, // Optimizes layout on mobile
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      StatCard(
                        label: 'TOTAL MANAGED CAPITAL',
                        value: '₹3,65,434.08',
                        icon: Icons.monetization_on_outlined,
                        color: Color(0xFFD97706), // Gold/Amber
                        backgroundColor: Colors.white,
                      ),
                      StatCard(
                        label: 'TOTAL YIELD DISTRIBUTED',
                        value: '₹3,65,434.59',
                        icon: Icons.trending_up,
                        color: Color(0xFF3B82F6), // Blue
                        backgroundColor: Colors.white,
                      ),
                      StatCard(
                        label: 'ACTIVE INSTITUTIONAL NODES',
                        value: '9',
                        icon: Icons.business,
                        color: Color(0xFF6366F1), // Indigo
                        backgroundColor: Colors.white,
                      ),
                      StatCard(
                        label: 'TOTAL NETWORK ALLOCATIONS',
                        value: '110',
                        icon: Icons.hub_outlined,
                        color: Color(0xFF8B5CF6), // Purple
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // White Container for Customer List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                border: Border.all(color: AppColors.kBorder),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  
                  // Customer List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _customers.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 32),
                    itemBuilder: (context, index) => _buildCustomerRow(_customers[index]),
                  ),
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerRow(WalletCustomer customer) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar Box
        Container(
          width: 48, 
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A), 
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            customer.name.substring(0, 1).toUpperCase(), 
            style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(width: 16),
        
        // Identity & Details (Expanded to prevent overflow)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and Star Icon
              Row(
                children: [
                  Flexible(
                    child: Text(
                      customer.name, 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.star, size: 12, color: Color(0xFFFBBF24)),
                ],
              ),
              const SizedBox(height: 4),
              // Email
              Text(
                customer.email, 
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Badges
              Row(
                children: [
                  // Balance Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB), 
                      borderRadius: BorderRadius.circular(12), 
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      customer.balance, 
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFFD97706)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), 
                      borderRadius: BorderRadius.circular(12), 
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      customer.status, 
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF3B82F6)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Optional Trailing Icon (like a chevron for navigation)
        const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
      ],
    );
  }
}