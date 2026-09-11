import 'package:flutter/material.dart';

// Note: Import your Member class here based on where you defined it, or extract it to a shared model file.
import 'package:frontend/features/shared/members_screen.dart' show Member;
import 'app_theme.dart';

class StylishForm extends StatefulWidget {
  final Member? member;

  const StylishForm({super.key, this.member});

  @override
  State<StylishForm> createState() => _StylishFormState();
}

class _StylishFormState extends State<StylishForm> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // Initialize with data if in Edit Mode
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _phoneController = TextEditingController(text: widget.member?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.member != null;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: (screenHeight - 160) > (screenHeight * 0.5)
          ? (screenHeight - 160)
          : (screenHeight * 0.75),

      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ... (The rest of your code inside the Column remains exactly the same)
          // Drag Handle & Header
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Member' : 'Create Member',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back,
                      size: 16, color: Colors.black54),
                  label: const Text('Back to Members',
                      style: TextStyle(color: Colors.black54)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.person_outline, 'Basic Information',
                      Colors.blue.shade100, Colors.blue.shade700),
                  const SizedBox(height: 24),

                  // Profile Photo
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade100,
                          child: const Icon(Icons.camera_alt_outlined,
                              size: 30, color: Colors.grey),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 16),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField('Full Name', controller: _nameController),
                  const SizedBox(height: 16),
                  _buildTextField('Phone Number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField('Alternate Phone',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField('Email Address',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField('Door No / Street'),
                  const SizedBox(height: 16),
                  _buildTextField('Landmark / Area'),
                  const SizedBox(height: 16),
                  _buildTextField('City/Town'),
                  const SizedBox(height: 16),
                  _buildTextField('State', initialValue: 'Tamil Nadu'),
                  const SizedBox(height: 16),
                  _buildTextField('Pincode',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildDropdown(
                      'Assigned Branch',
                      ['Main Office', "Teacher's Colony Branch"],
                      widget.member?.branch),
                  const SizedBox(height: 16),
                  _buildDropdown('Status', ['Active', 'Inactive'],
                      widget.member?.status ?? 'Active'),
                  const SizedBox(height: 16),
                  _buildDropdown(
                      'Join Chit Group', ['Group A', 'Group B'], null),

                  const SizedBox(height: 32),
                  _buildSectionHeader(
                      Icons.verified_user_outlined,
                      'KYC & Banking Details',
                      Colors.green.shade100,
                      Colors.green.shade700),
                  const SizedBox(height: 24),

                  _buildDropdown('ID Proof Type (Aadhaar / PAN)',
                      ['Aadhaar', 'PAN'], null),
                  const SizedBox(height: 16),
                  _buildTextField('ID Number'),
                  const SizedBox(height: 16),

                  // File Attachment Simulator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('KYC DOC ATTACHMENT',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.black87,
                              elevation: 0,
                            ),
                            child: const Text('Choose File'),
                          ),
                          const SizedBox(width: 12),
                          const Text('no file selected',
                              style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Bank Name'),
                  const SizedBox(height: 16),
                  _buildTextField('Account Number',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildTextField('IFSC Code'),

                  const SizedBox(height: 32),
                  _buildSectionHeader(
                      Icons.group_outlined,
                      'Nominee Information',
                      Colors.orange.shade100,
                      Colors.orange.shade700),
                  const SizedBox(height: 24),

                  _buildTextField('Nominee Full Name'),
                  const SizedBox(height: 16),
                  _buildTextField('Relationship'),
                  const SizedBox(height: 16),
                  _buildTextField('Nominee Phone Number',
                      keyboardType: TextInputType.phone),

                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement save logic here
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Save Changes' : 'Create Member',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      IconData icon, String title, Color bgColor, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label, {
    TextEditingController? controller,
    TextInputType? keyboardType,
    String? initialValue,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value) {
    return DropdownButtonFormField<String>(
      value: (value != null && items.contains(value)) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (val) {},
    );
  }
}

class StylishTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;

  const StylishTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: AppColors.kPrimary),
        filled: true,
        fillColor: AppColors.kBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kPrimary, width: 1.5),
        ),
      ),
    );
  }
}
