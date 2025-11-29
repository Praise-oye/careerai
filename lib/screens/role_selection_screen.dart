import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'interview_practice_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  String? _selectedField;

  final List<String> _commonFields = [
    'Technology',
    'Healthcare',
    'Education',
    'Business & Finance',
    'Marketing & Sales',
    'Engineering',
    'Design',
    'Human Resources',
    'Operations',
    'Customer Service',
    'Legal',
    'Real Estate',
    'Hospitality',
    'Manufacturing',
    'Other',
  ];

  @override
  void dispose() {
    _roleController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _startInterview() {
    if (_roleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the role you\'re interviewing for'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterviewPracticeScreen(
          field: _selectedField,
          position: _roleController.text.trim(),
          company: _companyController.text.trim().isEmpty
              ? null
              : _companyController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Select Interview Role',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF6B46C1).withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color: Color(0xFF6B46C1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, I\'m Arya',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Let\'s personalize your interview practice',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6B46C1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF6B46C1),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I\'ll tailor the interview questions specifically for the role you\'re applying for, making your practice more relevant and effective.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Role Input
            Text(
              'Job Title / Role *',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _roleController,
              decoration: InputDecoration(
                hintText: 'e.g., Software Engineer, Marketing Manager, Nurse...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6B46C1),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.work_outline),
              ),
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 24),

            // Company Input (Optional)
            Text(
              'Company Name (Optional)',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _companyController,
              decoration: InputDecoration(
                hintText: 'e.g., Google, ABC Corp, Local Hospital...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6B46C1),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.business_outlined),
              ),
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 24),

            // Industry/Field Selection
            Text(
              'Industry / Field (Optional)',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonFields.map((field) {
                final isSelected = _selectedField == field;
                return FilterChip(
                  selected: isSelected,
                  label: Text(field),
                  onSelected: (selected) {
                    setState(() {
                      _selectedField = selected ? field : null;
                    });
                  },
                  selectedColor: const Color(0xFF6B46C1).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF6B46C1),
                  labelStyle: GoogleFonts.inter(
                    color: isSelected
                        ? const Color(0xFF6B46C1)
                        : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startInterview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Interview Practice',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

