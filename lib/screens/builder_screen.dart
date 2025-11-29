// ignore_for_file: deprecated_member_use, strict_top_level_inference

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/resume_provider.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  String _selectedTemplate = 'standard';
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ResumeProvider>(
          builder: (context, provider, _) {
            final resume = provider.resume;
            final atsScore = provider.atsScore;
            final isComplete = provider.isComplete;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ATS Score Indicator
                  if (isComplete)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getScoreColor(atsScore).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getScoreColor(atsScore),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: _getScoreColor(atsScore),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ATS Compatibility Score',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${atsScore.toStringAsFixed(0)}% - ${_getScoreMessage(atsScore)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Complete your profile to generate an ATS-optimized resume',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Templates Section
                  Text(
                    'ATS-Optimized Templates',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTemplateCard(
                          'Standard',
                          'Best for most ATS systems',
                          _selectedTemplate == 'standard',
                          () => setState(() => _selectedTemplate = 'standard'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTemplateCard(
                          'Detailed',
                          'More sections, more keywords',
                          _selectedTemplate == 'detailed',
                          () => setState(() => _selectedTemplate = 'detailed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Resume Preview Section
                  if (isComplete) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Resume Preview',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showPreview = !_showPreview;
                            });
                          },
                          icon: Icon(
                            _showPreview ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                          ),
                          label: Text(
                            _showPreview ? 'Hide' : 'Show Preview',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_showPreview)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SelectableText(
                          provider.generateATSResume(template: _selectedTemplate),
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      )
                    else
                      _buildResumeSummary(resume),
                    const SizedBox(height: 24),
                  ],

                  // Generate Resume Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              isComplete ? Icons.check_circle : Icons.info_outline,
                              color: isComplete
                                  ? const Color(0xFF10B981)
                                  : Colors.grey[600],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isComplete
                                    ? 'Your resume is ready! Generate an ATS-optimized PDF.'
                                    : 'Complete your profile to generate your resume.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isComplete
                                ? () {
                                    _generateResume(context, provider);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Generate ATS Resume PDF',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.rocket_launch,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6B46C1).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6B46C1)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF6B46C1),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeSummary(resume) {
    final sections = <String>[];
    if (resume.summary != null && resume.summary!.isNotEmpty) {
      sections.add('SUMMARY');
    }
    if (resume.skills.isNotEmpty) sections.add('SKILLS');
    if (resume.experience.isNotEmpty) sections.add('EXPERIENCE');
    if (resume.education.isNotEmpty) sections.add('EDUCATION');
    if (resume.projects.isNotEmpty) sections.add('PROJECTS');
    if (resume.certifications.isNotEmpty) sections.add('CERTIFICATIONS');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resume.fullName.isNotEmpty ? resume.fullName.toUpperCase() : 'YOUR NAME',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...sections.map((section) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 2,
                      width: double.infinity,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 4),
                    ...List.generate(2, (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            height: 8,
                            width: double.infinity,
                            color: Colors.grey[200],
                          ),
                        )),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _generateResume(BuildContext context, ResumeProvider provider) {
    final atsResume = provider.generateATSResume(template: _selectedTemplate);
    
    // In a real app, you would use a PDF generation library here
    // For now, we'll show the resume text and a message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ATS-Optimized Resume Generated'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your ATS-optimized resume is ready!'),
              const SizedBox(height: 16),
              const Text(
                'Resume Preview:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  atsResume,
                  style: GoogleFonts.robotoMono(fontSize: 10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: In production, this would generate a PDF file optimized for ATS systems.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ATS Resume generated! Score: ${provider.atsScore.toStringAsFixed(0)}%',
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage(double score) {
    if (score >= 80) return 'Excellent ATS compatibility';
    if (score >= 60) return 'Good ATS compatibility';
    return 'Needs improvement';
  }
}
