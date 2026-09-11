import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/confirm_dialog.dart';
import 'package:frontend/shared/widgets/app_toast.dart';

// --- Data Model ---
class HolidayEntry {
  final String id;
  final String date;
  final String day;
  final String name;
  final String type;

  HolidayEntry({
    required this.id,
    required this.date,
    required this.day,
    required this.name,
    required this.type,
  });
}

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  // Form & Settings State
  bool _skipWeekends = true;
  String _selectedType = 'GOVERNMENT';
  final TextEditingController _dateController = TextEditingController(text: '02/09/2026');
  final TextEditingController _nameController = TextEditingController();

  final List<String> _holidayTypes = ['GOVERNMENT', 'COMPANY', 'OPTIONAL'];

  // Mock Data
  final List<HolidayEntry> _holidays = [
    HolidayEntry(
      id: '1',
      date: '15 Aug\n2026',
      day: 'Saturday',
      name: 'Independence\nDay',
      type: 'GOVERNMENT',
    ),
  ];

  @override
  void dispose() {
    _dateController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // --- Action Handlers ---

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
      ToastService.show(title: 'Success', message: 'Monthly yield processed successfully.', type: ToastType.success);
    }
  }

  void _handleAddHoliday() {
    if (_dateController.text.isEmpty || _nameController.text.isEmpty) {
      ToastService.show(title: 'Validation Error', message: 'Please provide both a date and a holiday name.', type: ToastType.error);
      return;
    }

    setState(() {
      _holidays.add(HolidayEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: _dateController.text.replaceAll('/', ' '), // Simplistic format for demo
        day: 'Selected Day',
        name: _nameController.text,
        type: _selectedType,
      ));
      _nameController.clear();
    });

    ToastService.show(title: 'Holiday Added', message: 'The holiday has been added to the calendar.', type: ToastType.success);
  }

  Future<void> _handleRemoveHoliday(HolidayEntry holiday) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'REMOVE HOLIDAY',
      message: 'Are you sure you want to remove "${holiday.name.replaceAll('\n', ' ')}" from the calendar?',
      confirmLabel: 'REMOVE',
      cancelLabel: 'CANCEL',
      confirmButtonColor: AppColors.kDanger,
    );

    if (confirmed == true) {
      setState(() {
        _holidays.removeWhere((h) => h.id == holiday.id);
      });
      ToastService.show(title: 'Holiday Removed', message: 'The holiday has been successfully removed.', type: ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
              const SizedBox(height: 24),

              // --- 2. Process Monthly Yield Button ---
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _handleProcessYield,
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('PROCESS MONTHLY YIELD', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 12, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 4,
                    shadowColor: const Color(0xFF1E3A8A).withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. Holiday Calendar Header Card ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.kBorder),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A), // Navy Blue
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('HOLIDAY CALENDAR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                              const SizedBox(height: 4),
                              Text('NON-WORKING DAYS — CASHBACK DOES NOT ACCRUE ON THESE DATES · ${_holidays.length} HOLIDAYS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Critical Note Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB), // Light amber tint
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'NOTE: THE CASHBACK PLAN IS CURRENTLY MONTHLY (10% × 10 MONTHS = 100%), PAID ONCE PER CALENDAR MONTH — SO WEEKENDS & HOLIDAYS DO NOT AFFECT CASHBACK. THIS CALENDAR IS RETAINED FOR REFERENCE AND FOR ANY OPERATIONAL (PAYOUT / WORKING-DAY) USE.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFFD97706).withOpacity(0.9), // Amber text
                                height: 1.6,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- 4. Skip Weekends Toggle Card ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.kBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SKIP WEEKENDS (SAT & SUN)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A))),
                          const SizedBox(height: 4),
                          Text('WHEN ON, NO CASHBACK ACCRUES ON SATURDAYS OR SUNDAYS.', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF94A3B8).withOpacity(0.8), letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _skipWeekends,
                      onChanged: (val) {
                        setState(() => _skipWeekends = val);
                        ToastService.show(title: 'Settings Updated', message: 'Weekend skipping is now ${val ? 'enabled' : 'disabled'}.', type: ToastType.info);
                      },
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFFD97706), // Gold/Amber track
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- 5. Add Holiday Form Card ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.kBorder),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ADD A HOLIDAY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), letterSpacing: 1.5)),
                    const SizedBox(height: 24),

                    _buildInputField(label: 'DATE', controller: _dateController, hintText: 'DD/MM/YYYY'),
                    const SizedBox(height: 16),
                    _buildInputField(label: 'HOLIDAY NAME', controller: _nameController, hintText: 'e.g. Diwali / Republic Day', isLightHint: true),
                    const SizedBox(height: 16),
                    _buildDropdownField('TYPE', _selectedType, _holidayTypes, (val) => setState(() => _selectedType = val!)),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: _handleAddHoliday,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('ADD HOLIDAY', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 11, letterSpacing: 1.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A), // Navy Blue
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- 6. Configured Holidays Data Table ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: const Text('CONFIGURED HOLIDAYS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), letterSpacing: 1.5)),
                    ),
                    const Divider(height: 1, color: AppColors.kBorder),

                    // Scrollable Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
                        child: DataTable(
                          columnSpacing: 32,
                          headingRowHeight: 56,
                          dataRowMinHeight: 80,
                          dataRowMaxHeight: 80,
                          dividerThickness: 1,
                          headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 10, letterSpacing: 1.5),
                          columns: const [
                            DataColumn(label: Text('DATE')),
                            DataColumn(label: Text('DAY')),
                            DataColumn(label: Text('NAME')),
                            DataColumn(label: Text('TYPE')),
                            DataColumn(label: Text('ACTION')),
                          ],
                          rows: _holidays.map((holiday) {
                            return DataRow(
                              cells: [
                                DataCell(Text(holiday.date, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13, height: 1.4))),
                                DataCell(Text(holiday.day, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), fontSize: 12))),
                                DataCell(Text(holiday.name, style: const TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A), fontSize: 13, height: 1.4))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFDBFE))),
                                    child: Text(holiday.type, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 8, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
                                  ),
                                ),
                                DataCell(
                                  OutlinedButton.icon(
                                    onPressed: () => _handleRemoveHoliday(holiday),
                                    icon: const Icon(Icons.delete_outline, size: 14),
                                    label: const Text('REMOVE', style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 9)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFEF4444), // Red
                                      backgroundColor: const Color(0xFFFEF2F2), // Light Red Bg
                                      side: const BorderSide(color: Color(0xFFFECACA)), // Light Red Border
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    if (_holidays.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'NO HOLIDAYS CONFIGURED',
                            style: TextStyle(fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: AppColors.kTextMuted, letterSpacing: 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets for Form Inputs ---

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool isLightHint = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isLightHint ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8), 
              fontWeight: FontWeight.w900, 
              fontStyle: FontStyle.italic, 
              fontSize: 13
            ),
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8), letterSpacing: 1)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          icon: const Icon(Icons.unfold_more, color: Color(0xFF1E3A8A), size: 18),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
          decoration: InputDecoration(
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
        ),
      ],
    );
  }
}