// ignore_for_file: deprecated_member_use, unused_field, unused_element

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/ai_mentor_service.dart';

// Data models for CV entries
class ExperienceEntry {
  String jobTitle;
  String company;
  String location;
  int startYear;
  int? endYear; // null = Present
  String description;
  List<String> achievements;

  ExperienceEntry({
    this.jobTitle = '',
    this.company = '',
    this.location = '',
    this.startYear = 2020,
    this.endYear,
    this.description = '',
    List<String>? achievements,
  }) : achievements = achievements ?? [];
}

class EducationEntry {
  String degree;
  String fieldOfStudy;
  String institution;
  int startYear;
  int endYear;
  String? gpa;
  List<String> achievements;

  EducationEntry({
    this.degree = '',
    this.fieldOfStudy = '',
    this.institution = '',
    this.startYear = 2016,
    this.endYear = 2020,
    this.gpa,
    List<String>? achievements,
  }) : achievements = achievements ?? [];
}

class CertificateEntry {
  String name;
  int year;

  CertificateEntry({
    this.name = '',
    this.year = 2023,
  });
}

class ProjectEntry {
  String name;

  ProjectEntry({
    this.name = '',
  });
}

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AIMentorService _mentorService = AIMentorService();
  
  // Search State
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(text: 'South Africa');
  final String _selectedExperience = 'entry';
  
  // Results State
  JobSearchResult? _jobResults;
  // ignore: prefer_final_fields
  bool _isSearching = false;
  
  // CV Builder State - Personal Info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _linkedInController = TextEditingController();
  final TextEditingController _portfolioController = TextEditingController();
  final TextEditingController _githubController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _targetRoleController = TextEditingController();
  
  // Structured CV Data
  final List<ExperienceEntry> _experiences = [];
  final List<EducationEntry> _educations = [];
  final List<CertificateEntry> _certificates = [];
  final List<ProjectEntry> _projects = [];
  final List<String> _skills = [];
  final List<String> _languages = [];
  
  // CV Builder UI State
  int _currentStep = 0;
  ATSCV? _generatedCV;
  bool _isGeneratingCV = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize with one empty entry each
    _experiences.add(ExperienceEntry());
    _educations.add(EducationEntry());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _roleController.dispose();
    _locationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _linkedInController.dispose();
    _portfolioController.dispose();
    _githubController.dispose();
    _summaryController.dispose();
    _targetRoleController.dispose();
    super.dispose();
  }


  Future<void> _generateCV() async {
    if (_targetRoleController.text.trim().isEmpty) {
      _showError('Please enter a target role');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }

    setState(() => _isGeneratingCV = true);

    try {
      // Build experience string from structured data
      final experienceStr = _experiences
          .where((e) => e.jobTitle.isNotEmpty && e.company.isNotEmpty)
          .map((e) => '${e.jobTitle} at ${e.company} (${e.startYear} - ${e.endYear ?? "Present"}): ${e.description}. Achievements: ${e.achievements.join(", ")}')
          .join('\n');

      // Build education string from structured data
      final educationStr = _educations
          .where((e) => e.degree.isNotEmpty && e.institution.isNotEmpty)
          .map((e) => '${e.degree} in ${e.fieldOfStudy} from ${e.institution} (${e.startYear} - ${e.endYear})${e.gpa != null ? ", GPA: ${e.gpa}" : ""}')
          .join('\n');

      // Build certificates string
      final certificatesStr = _certificates
          .where((c) => c.name.isNotEmpty)
          .map((c) => '${c.name} (${c.year})')
          .join(', ');

      // Build projects string
      final projectsStr = _projects
          .where((p) => p.name.isNotEmpty)
          .map((p) => p.name)
          .join(', ');

      final cv = await _mentorService.generateATSCV(
        targetRole: _targetRoleController.text.trim(),
        currentRole: _experiences.isNotEmpty && _experiences.first.jobTitle.isNotEmpty 
            ? _experiences.first.jobTitle 
            : null,
        skills: _skills.isNotEmpty ? _skills : null,
        experience: experienceStr.isNotEmpty ? experienceStr : null,
        education: educationStr.isNotEmpty ? educationStr : null,
        projects: projectsStr.isNotEmpty ? projectsStr : null,
        achievements: certificatesStr.isNotEmpty ? certificatesStr : null,
        personalInfo: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'linkedin': _linkedInController.text.trim(),
          'portfolio': _portfolioController.text.trim(),
          'github': _githubController.text.trim(),
          'summary': _summaryController.text.trim(),
          'languages': _languages.join(', '),
        },
      );

      setState(() {
        _generatedCV = cv;
        _isGeneratingCV = false;
        _currentStep = 0;
      });
    } catch (e) {
      setState(() => _isGeneratingCV = false);
      _showError(e.toString());
    }
  }

  void _addSkill(String skill) {
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() => _skills.add(skill));
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  void _addLanguage(String language) {
    if (language.isNotEmpty && !_languages.contains(language)) {
      setState(() => _languages.add(language));
    }
  }

  void _removeLanguage(String language) {
    setState(() => _languages.remove(language));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Jobs & CV',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6B46C1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6B46C1),
          tabs: const [
           
            Tab(icon: Icon(Icons.description), text: 'Build CV'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
         
          _buildCVTab(),
        ],
      ),
    );
  }



  Widget _buildCVTab() {
    if (_generatedCV != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildCVPreview(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6B46C1),
                  const Color(0xFF6B46C1).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Professional CV Builder',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Build an ATS-optimized CV step by step',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Progress Indicator
          _buildProgressIndicator(),
          const SizedBox(height: 24),

          // Step Content
          if (_currentStep == 0) _buildPersonalInfoStep(),
          if (_currentStep == 1) _buildExperienceStep(),
          if (_currentStep == 2) _buildEducationStep(),
          if (_currentStep == 3) _buildSkillsStep(),
          if (_currentStep == 4) _buildCertificatesStep(),
          if (_currentStep == 5) _buildProjectsStep(),
          if (_currentStep == 6) _buildReviewStep(),

          const SizedBox(height: 24),

          // Navigation Buttons
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _currentStep--),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _currentStep < 6 
                      ? () => setState(() => _currentStep++)
                      : (_isGeneratingCV ? null : _generateCV),
                  icon: _currentStep < 6 
                      ? const Icon(Icons.arrow_forward)
                      : (_isGeneratingCV 
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.auto_awesome)),
                  label: Text(
                    _currentStep < 6 
                        ? 'Continue' 
                        : (_isGeneratingCV ? 'Generating...' : 'Generate ATS CV'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Personal', 'Experience', 'Education', 'Skills', 'Certificates', 'Projects', 'Review'];
    return Column(
      children: [
        Row(
          children: List.generate(steps.length, (index) {
            final isActive = index <= _currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < steps.length - 1 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF6B46C1) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '${_currentStep + 1}/${steps.length}: ${steps[_currentStep]}',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('👤 Personal Information', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildTextField('Full Name *', _nameController, 'Enter your full name'),
        _buildTextField('Email *', _emailController, 'Enter your email address'),
        Row(
          children: [
            Expanded(child: _buildTextField('Phone', _phoneController, '+27 XXX XXX XXXX')),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Location', _addressController, 'City, Country')),
          ],
        ),
        _buildTextField('Target Role *', _targetRoleController, 'Software Engineer'),
        _buildTextField('Professional Summary', _summaryController, 'Brief overview of your career goals and key strengths...', maxLines: 3),
        const SizedBox(height: 16),
        Text('🔗 Online Profiles (Optional)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildTextField('LinkedIn URL', _linkedInController, 'https://linkedin.com/in/yourprofile'),
        Row(
          children: [
            Expanded(child: _buildTextField('GitHub', _githubController, 'https://github.com/username')),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Portfolio', _portfolioController, 'https://yourportfolio.com')),
          ],
        ),
      ],
    );
  }

  Widget _buildExperienceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('💼 Work Experience', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() => _experiences.add(ExperienceEntry())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Add your work history, starting with the most recent', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 16),
        ...List.generate(_experiences.length, (index) => _buildExperienceCard(index)),
      ],
    );
  }

  Widget _buildExperienceCard(int index) {
    final exp = _experiences[index];
    final currentYear = DateTime.now().year;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Experience ${index + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              if (_experiences.length > 1)
                IconButton(
                  onPressed: () => setState(() => _experiences.removeAt(index)),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: exp.jobTitle,
            decoration: _inputDecoration('Job Title *', 'e.g. Software Developer'),
            onChanged: (v) => exp.jobTitle = v,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: exp.company,
                  decoration: _inputDecoration('Company *', 'Company Name'),
                  onChanged: (v) => exp.company = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: exp.location,
                  decoration: _inputDecoration('Location', 'City, Country'),
                  onChanged: (v) => exp.location = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: exp.startYear,
                  decoration: _inputDecoration('Start Year', ''),
                  items: List.generate(30, (i) => currentYear - i)
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) => setState(() => exp.startYear = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: exp.endYear,
                  decoration: _inputDecoration('End Year', ''),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Present')),
                    ...List.generate(30, (i) => currentYear - i)
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y'))),
                  ],
                  onChanged: (v) => setState(() => exp.endYear = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: exp.description,
            decoration: _inputDecoration('Job Description', 'What did you do in this role?'),
            maxLines: 3,
            onChanged: (v) => exp.description = v,
          ),
          const SizedBox(height: 12),
          Text('Key Achievements (one per line)', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: exp.achievements.join('\n'),
            decoration: _inputDecoration('Achievements', 'Increased sales by 20%\nLed team of 5 developers'),
            maxLines: 3,
            onChanged: (v) => exp.achievements = v.split('\n').where((s) => s.isNotEmpty).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🎓 Education', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() => _educations.add(EducationEntry())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_educations.length, (index) => _buildEducationCard(index)),
      ],
    );
  }

  Widget _buildEducationCard(int index) {
    final edu = _educations[index];
    final currentYear = DateTime.now().year;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Education ${index + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              if (_educations.length > 1)
                IconButton(
                  onPressed: () => setState(() => _educations.removeAt(index)),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: edu.degree.isNotEmpty ? edu.degree : null,
            decoration: _inputDecoration('Degree Type *', ''),
            hint: const Text('Select degree'),
            items: [
              'High School Diploma',
              'Certificate',
              'Diploma',
              'Associate Degree',
              'Bachelor\'s Degree',
              'Honours Degree',
              'Master\'s Degree',
              'Doctoral Degree (PhD)',
              'Professional Degree',
              'Other',
            ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => edu.degree = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: edu.fieldOfStudy,
            decoration: _inputDecoration('Field of Study *', 'e.g. Computer Science'),
            onChanged: (v) => edu.fieldOfStudy = v,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: edu.institution,
            decoration: _inputDecoration('Institution *', 'University/College Name'),
            onChanged: (v) => edu.institution = v,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: edu.startYear,
                  decoration: _inputDecoration('Start Year', ''),
                  items: List.generate(40, (i) => currentYear - i)
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) => setState(() => edu.startYear = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: edu.endYear,
                  decoration: _inputDecoration('End Year', ''),
                  items: List.generate(40, (i) => currentYear - i + 5)
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) => setState(() => edu.endYear = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: edu.gpa,
                  decoration: _inputDecoration('GPA/Grade (Optional)', 'e.g. 3.8/4.0'),
                  onChanged: (v) => edu.gpa = v.isNotEmpty ? v : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsStep() {
    final skillController = TextEditingController();
    final languageController = TextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🛠️ Skills', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Add relevant technical and soft skills', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: skillController,
                decoration: _inputDecoration('Add a skill', 'e.g. Python, Project Management'),
                onSubmitted: (v) {
                  _addSkill(v.trim());
                  skillController.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                _addSkill(skillController.text.trim());
                skillController.clear();
              },
              icon: const Icon(Icons.add_circle, color: Color(0xFF6B46C1)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _skills.map((skill) => Chip(
            label: Text(skill),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => _removeSkill(skill),
            backgroundColor: const Color(0xFF6B46C1).withOpacity(0.1),
          )).toList(),
        ),
        if (_skills.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add your technical and soft skills relevant to your target role',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Text('🌍 Languages', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: languageController,
                decoration: _inputDecoration('Add a language', 'e.g. English (Fluent)'),
                onSubmitted: (v) {
                  _addLanguage(v.trim());
                  languageController.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                _addLanguage(languageController.text.trim());
                languageController.clear();
              },
              icon: const Icon(Icons.add_circle, color: Color(0xFF6B46C1)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _languages.map((lang) => Chip(
            label: Text(lang),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => _removeLanguage(lang),
            backgroundColor: Colors.blue.withOpacity(0.1),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCertificatesStep() {
    final currentYear = DateTime.now().year;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('📜 Certifications', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() => _certificates.add(CertificateEntry())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Professional certifications and licenses (optional)', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 16),
        if (_certificates.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.workspace_premium, color: Colors.grey[400], size: 40),
                const SizedBox(height: 8),
                Text('No certifications added', style: GoogleFonts.inter(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('Click "Add" to add certifications', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          )
        else
          ...List.generate(_certificates.length, (index) {
            final cert = _certificates[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: cert.name,
                      decoration: _inputDecoration('Certificate Name', 'e.g. AWS Certified'),
                      onChanged: (v) => cert.name = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<int>(
                      value: cert.year,
                      decoration: _inputDecoration('Year', ''),
                      items: List.generate(20, (i) => currentYear - i)
                          .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                          .toList(),
                      onChanged: (v) => setState(() => cert.year = v!),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _certificates.removeAt(index)),
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildProjectsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🚀 Projects', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() => _projects.add(ProjectEntry())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Showcase your best projects (optional)', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 16),
        if (_projects.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.folder_special, color: Colors.grey[400], size: 40),
                const SizedBox(height: 8),
                Text('No projects added', style: GoogleFonts.inter(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('Click "Add" to showcase your work', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          )
        else
          ...List.generate(_projects.length, (index) {
            final proj = _projects[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: proj.name,
                      decoration: _inputDecoration('Project Name', 'e.g. E-commerce App'),
                      onChanged: (v) => proj.name = v,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _projects.removeAt(index)),
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('✨ Review & Generate', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Review your information before generating', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 24),
        _buildReviewSection('👤 Personal Info', [
          'Name: ${_nameController.text.isNotEmpty ? _nameController.text : "Not provided"}',
          'Email: ${_emailController.text.isNotEmpty ? _emailController.text : "Not provided"}',
          'Target Role: ${_targetRoleController.text.isNotEmpty ? _targetRoleController.text : "Not provided"}',
        ]),
        _buildReviewSection('💼 Experience', [
          '${_experiences.where((e) => e.jobTitle.isNotEmpty).length} position(s) added',
          if (_experiences.isNotEmpty && _experiences.first.jobTitle.isNotEmpty)
            'Latest: ${_experiences.first.jobTitle} at ${_experiences.first.company}',
        ]),
        _buildReviewSection('🎓 Education', [
          '${_educations.where((e) => e.degree.isNotEmpty).length} qualification(s) added',
          if (_educations.isNotEmpty && _educations.first.degree.isNotEmpty)
            'Latest: ${_educations.first.degree} in ${_educations.first.fieldOfStudy}',
        ]),
        _buildReviewSection('🛠️ Skills & Languages', [
          '${_skills.length} skills added',
          '${_languages.length} languages added',
        ]),
        _buildReviewSection('📜 Certifications', [
          '${_certificates.length} certification(s) added',
          if (_certificates.isNotEmpty)
            _certificates.where((c) => c.name.isNotEmpty).map((c) => '• ${c.name} (${c.year})').join('\n'),
        ]),
        _buildReviewSection('🚀 Projects', [
          '${_projects.length} project(s) added',
          if (_projects.isNotEmpty)
            _projects.where((p) => p.name.isNotEmpty).map((p) => '• ${p.name}').join('\n'),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.green[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI will optimize your CV for ATS systems and highlight your strengths for "${_targetRoleController.text}" roles.',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.green[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(item, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
          )),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<pw.Document> _generatePDF() async {
    final cv = _generatedCV!;
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _nameController.text.toUpperCase(),
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _targetRoleController.text,
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  [
                    if (_emailController.text.isNotEmpty) _emailController.text,
                    if (_phoneController.text.isNotEmpty) _phoneController.text,
                    if (_addressController.text.isNotEmpty) _addressController.text,
                  ].join('  |  '),
                  style: const pw.TextStyle(fontSize: 10),
                ),
                if (_linkedInController.text.isNotEmpty || _githubController.text.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      [
                        if (_linkedInController.text.isNotEmpty) 'LinkedIn: ${_linkedInController.text}',
                        if (_githubController.text.isNotEmpty) 'GitHub: ${_githubController.text}',
                      ].join('  |  '),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Professional Summary
          _pdfSection('PROFESSIONAL SUMMARY', cv.professionalSummary),

          // Skills
          if (cv.currentSkills.technical.isNotEmpty || cv.currentSkills.soft.isNotEmpty || cv.currentSkills.tools.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('SKILLS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Text(
              [...cv.currentSkills.technical, ...cv.currentSkills.soft, ...cv.currentSkills.tools].join('  |  '),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],

          // Experience
          if (cv.experience.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('EXPERIENCE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            ...cv.experience.map((exp) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(exp.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(exp.duration, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Text(exp.company, style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 4),
                  ...exp.bullets.map((b) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('- ', style: const pw.TextStyle(fontSize: 10)),
                        pw.Expanded(child: pw.Text(b, style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                  )),
                ],
              ),
            )),
          ],

          // Education
          if (cv.education.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('EDUCATION', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            ...cv.education.map((edu) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(edu.degree, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(edu.institution, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Text(edu.year, style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            )),
          ],

          // Projects
          if (cv.projects.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('PROJECTS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Text(
              cv.projects.join('  |  '),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],

          // Certifications
          if (cv.certifications.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('CERTIFICATIONS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Text(
              cv.certifications.join('  |  '),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _pdfSection(String title, String content) {
    if (content.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Text(content, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.4)),
      ],
    );
  }

  Future<void> _downloadPDF() async {
    try {
      final pdf = await _generatePDF();
      final bytes = await pdf.save();
      
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${_nameController.text.isNotEmpty ? _nameController.text.replaceAll(' ', '_') : 'CV'}_Resume.pdf',
      );
    } catch (e) {
      _showError('Error generating PDF: $e');
    }
  }

  Future<void> _printPDF() async {
    try {
      final pdf = await _generatePDF();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      _showError('Error printing PDF: $e');
    }
  }

  Widget _buildCVPreview() {
    final cv = _generatedCV!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success Banner with Download Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CV Generated Successfully!',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                        Text(
                          'Download your ATS-optimized CV as PDF',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.green[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _downloadPDF,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _printPDF,
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _generatedCV = null;
                    _currentStep = 0;
                  }),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit & Regenerate'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        Text('📄 CV Preview', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Professional Summary - Choose from options
        _buildSummarySelector(cv),
        const SizedBox(height: 16),

        // Skills
        _buildCVSection('Skills', null, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cv.selectedMode.clamp(0, 2) == 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '✨ Enhanced with ATS keywords',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.purple[700]),
                  ),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...cv.currentSkills.technical.map((s) => _buildSkillChip(s, Colors.blue)),
                ...cv.currentSkills.soft.map((s) => _buildSkillChip(s, Colors.green)),
                ...cv.currentSkills.tools.map((s) => _buildSkillChip(s, Colors.orange)),
              ],
            ),
          ],
        )),

        // Experience
        if (cv.experience.isNotEmpty)
          _buildCVSection('Experience', null, child: Column(
            children: cv.experience.map((exp) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exp.title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${exp.company} • ${exp.duration}',
                    style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ...exp.bullets.map((b) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(b, style: GoogleFonts.inter(fontSize: 13))),
                      ],
                    ),
                  )),
                ],
              ),
            )).toList(),
          )),

        // Education
        if (cv.education.isNotEmpty)
          _buildCVSection('Education', null, child: Column(
            children: cv.education.map((edu) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(edu.degree, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  Text(
                    '${edu.institution} • ${edu.year}',
                    style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            )).toList(),
          )),

        // Projects
        if (cv.projects.isNotEmpty)
          _buildCVSection('Projects', null, child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cv.projects.map((project) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Text(
                project,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.purple[700]),
              ),
            )).toList(),
          )),

        // Certifications
        if (cv.certifications.isNotEmpty)
          _buildCVSection('Certifications', null, child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cv.certifications.map((cert) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Text(
                cert,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.amber[800]),
              ),
            )).toList(),
          )),

        // ATS Keywords
        _buildCVSection('ATS Keywords', null, child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: cv.atsKeywords.map((k) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Text(
              k,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.green[700]),
            ),
          )).toList(),
        )),

        // Improvement Tips
        _buildCVSection('💡 Tips to Improve', null, child: Column(
          children: cv.improvementTips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right, color: Colors.amber[700], size: 20),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(tip, style: GoogleFonts.inter(fontSize: 13)),
                ),
              ],
            ),
          )).toList(),
        )),
      ],
    );
  }

  Widget _buildCVSection(String title, String? content, {Widget? child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6B46C1),
            ),
          ),
          const SizedBox(height: 8),
          if (content != null)
            Text(content, style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        skill,
        style: GoogleFonts.inter(fontSize: 12, color: color.withOpacity(0.8)),
      ),
    );
  }

  Widget _buildSummarySelector(ATSCV cv) {
    final modes = [
      {'label': 'Original', 'icon': Icons.person, 'color': Colors.blue},
      {'label': 'Polished', 'icon': Icons.auto_fix_high, 'color': Colors.green},
      {'label': 'ATS Pro', 'icon': Icons.rocket_launch, 'color': Colors.purple},
    ];
    
    // Ensure selectedMode is within bounds
    final safeMode = cv.selectedMode.clamp(0, 2);
    final currentMode = modes[safeMode];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose CV Version',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6B46C1),
          ),
        ),
        const SizedBox(height: 12),
        
        // 3-way toggle
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: List.generate(3, (index) {
              final isSelected = safeMode == index;
              final mode = modes[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    cv.selectedMode = index;
                    cv.professionalSummary = index == 0 
                        ? cv.originalSummary 
                        : (index == 1 ? cv.polishedSummary : cv.atsSummary);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? (mode['color'] as Color) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          mode['icon'] as IconData,
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[500],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mode['label'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        
        // Mode description
        if (safeMode == 2)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.stars, size: 16, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ATS Pro adds industry keywords & skills to help you stand out!',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.purple[700]),
                  ),
                ),
              ],
            ),
          ),
        
        // Show selected summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    currentMode['icon'] as IconData,
                    size: 16,
                    color: currentMode['color'] as Color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    safeMode == 0 ? 'Your Original' 
                        : (safeMode == 1 ? 'AI Polished' : 'ATS Optimized'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: currentMode['color'] as Color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                cv.professionalSummary.isNotEmpty 
                    ? cv.professionalSummary 
                    : 'No summary provided',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

