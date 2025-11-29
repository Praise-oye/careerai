import '../models/resume_model.dart';

/// ATS (Applicant Tracking System) Optimized Resume Builder
/// 
/// This service generates ATS-friendly resumes by:
/// - Using standard section headings
/// - Proper keyword formatting
/// - Clean, parseable structure
/// - Standard date formats
/// - Avoiding complex layouts
class ATSResumeBuilder {
  /// Generate ATS-optimized resume text
  static String generateATSResume(ResumeModel resume, {String template = 'standard'}) {
    final buffer = StringBuffer();
    
    // Header - ATS systems look for name at the top
    _addHeader(buffer, resume);
    
    // Summary/Objective - Important for ATS keyword matching
    if (resume.summary != null && resume.summary!.isNotEmpty) {
      _addSection(buffer, 'PROFESSIONAL SUMMARY');
      buffer.writeln(_cleanText(resume.summary!));
      buffer.writeln();
    }
    
    // Skills - Critical for ATS matching
    if (resume.skills.isNotEmpty) {
      _addSection(buffer, 'SKILLS');
      buffer.writeln(_formatSkills(resume.skills));
      buffer.writeln();
    }
    
    // Experience - Most important for ATS
    if (resume.experience.isNotEmpty) {
      _addSection(buffer, 'PROFESSIONAL EXPERIENCE');
      for (var exp in resume.experience) {
        _addExperience(buffer, exp);
      }
      buffer.writeln();
    }
    
    // Education
    if (resume.education.isNotEmpty) {
      _addSection(buffer, 'EDUCATION');
      for (var edu in resume.education) {
        _addEducation(buffer, edu);
      }
      buffer.writeln();
    }
    
    // Projects (if applicable)
    if (resume.projects.isNotEmpty) {
      _addSection(buffer, 'PROJECTS');
      for (var project in resume.projects) {
        _addProject(buffer, project);
      }
      buffer.writeln();
    }
    
    // Certifications
    if (resume.certifications.isNotEmpty) {
      _addSection(buffer, 'CERTIFICATIONS');
      for (var cert in resume.certifications) {
        _addCertification(buffer, cert);
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }
  
  static void _addHeader(StringBuffer buffer, ResumeModel resume) {
    buffer.writeln(resume.fullName.toUpperCase());
    buffer.writeln();
    
    // Contact information - ATS systems parse this
    final contactInfo = <String>[];
    if (resume.email.isNotEmpty) contactInfo.add(resume.email);
    if (resume.phone.isNotEmpty) contactInfo.add(resume.phone);
    if (resume.address != null && resume.address!.isNotEmpty) {
      contactInfo.add(resume.address!);
    }
    if (resume.linkedIn != null && resume.linkedIn!.isNotEmpty) {
      contactInfo.add('LinkedIn: ${resume.linkedIn}');
    }
    if (resume.website != null && resume.website!.isNotEmpty) {
      contactInfo.add('Website: ${resume.website}');
    }
    
    buffer.writeln(contactInfo.join(' | '));
    buffer.writeln();
  }
  
  static void _addSection(StringBuffer buffer, String title) {
    buffer.writeln(title);
    buffer.writeln('=' * title.length);
  }
  
  static void _addExperience(StringBuffer buffer, Experience exp) {
    // Company and Position - ATS looks for these patterns
    buffer.writeln('${exp.position.toUpperCase()}');
    buffer.writeln('${exp.company}${exp.location != null ? ' | ${exp.location}' : ''}');
    
    // Date range - Standard format for ATS
    final dateRange = exp.isCurrent
        ? '${_formatDate(exp.startDate)} - Present'
        : '${_formatDate(exp.startDate)} - ${_formatDate(exp.endDate ?? '')}';
    buffer.writeln(dateRange);
    buffer.writeln();
    
    // Description and achievements
    if (exp.description != null && exp.description!.isNotEmpty) {
      buffer.writeln(_cleanText(exp.description!));
    }
    
    if (exp.achievements.isNotEmpty) {
      for (var achievement in exp.achievements) {
        buffer.writeln('• ${_cleanText(achievement)}');
      }
    }
    buffer.writeln();
  }
  
  static void _addEducation(StringBuffer buffer, Education edu) {
    // Degree and Field - ATS keyword matching
    buffer.writeln('${edu.degree}${edu.fieldOfStudy.isNotEmpty ? ' in ${edu.fieldOfStudy}' : ''}');
    buffer.writeln(edu.institution);
    
    final dateRange = edu.isCurrent
        ? '${_formatDate(edu.startDate)} - Present'
        : '${_formatDate(edu.startDate)} - ${_formatDate(edu.endDate ?? '')}';
    buffer.writeln(dateRange);
    
    if (edu.gpa != null && edu.gpa!.isNotEmpty) {
      buffer.writeln('GPA: ${edu.gpa}');
    }
    
    if (edu.description != null && edu.description!.isNotEmpty) {
      buffer.writeln(_cleanText(edu.description!));
    }
    buffer.writeln();
  }
  
  static void _addProject(StringBuffer buffer, Project project) {
    buffer.writeln(project.name.toUpperCase());
    
    if (project.startDate != null && project.endDate != null) {
      buffer.writeln('${_formatDate(project.startDate!)} - ${_formatDate(project.endDate!)}');
    }
    
    if (project.description != null && project.description!.isNotEmpty) {
      buffer.writeln(_cleanText(project.description!));
    }
    
    if (project.technologies.isNotEmpty) {
      buffer.writeln('Technologies: ${project.technologies.join(', ')}');
    }
    
    if (project.url != null && project.url!.isNotEmpty) {
      buffer.writeln('URL: ${project.url}');
    }
    buffer.writeln();
  }
  
  static void _addCertification(StringBuffer buffer, Certification cert) {
    buffer.writeln(cert.name.toUpperCase());
    
    if (cert.issuer != null && cert.issuer!.isNotEmpty) {
      buffer.writeln('Issued by: ${cert.issuer}');
    }
    
    if (cert.issueDate != null && cert.issueDate!.isNotEmpty) {
      buffer.writeln('Issued: ${_formatDate(cert.issueDate!)}');
    }
    
    if (cert.expiryDate != null && cert.expiryDate!.isNotEmpty) {
      buffer.writeln('Expires: ${_formatDate(cert.expiryDate!)}');
    }
    
    if (cert.credentialId != null && cert.credentialId!.isNotEmpty) {
      buffer.writeln('Credential ID: ${cert.credentialId}');
    }
    buffer.writeln();
  }
  
  static String _formatSkills(List<String> skills) {
    // ATS systems prefer comma-separated or bulleted lists
    return skills.join(', ');
  }
  
  static String _formatDate(String date) {
    if (date.isEmpty) return '';
    // Try to parse and format date consistently
    // For now, return as-is but could be enhanced
    return date;
  }
  
  static String _cleanText(String text) {
    // Remove extra whitespace and ensure proper formatting
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
  
  /// Generate ATS-friendly keywords from resume
  static List<String> extractKeywords(ResumeModel resume) {
    final keywords = <String>[];
    
    // Add skills as keywords
    keywords.addAll(resume.skills);
    
    // Extract keywords from experience
    for (var exp in resume.experience) {
      keywords.add(exp.position);
      keywords.add(exp.company);
      if (exp.description != null) {
        keywords.addAll(_extractWordsFromText(exp.description!));
      }
      keywords.addAll(exp.achievements.expand((a) => _extractWordsFromText(a)));
    }
    
    // Extract from education
    for (var edu in resume.education) {
      keywords.add(edu.degree);
      keywords.add(edu.fieldOfStudy);
      keywords.add(edu.institution);
    }
    
    // Remove duplicates and normalize
    return keywords
        .map((k) => k.toLowerCase().trim())
        .where((k) => k.length > 2)
        .toSet()
        .toList();
  }
  
  static List<String> _extractWordsFromText(String text) {
    // Simple word extraction - could be enhanced with NLP
    return text
        .split(RegExp(r'[,\s.]+'))
        .where((word) => word.length > 3)
        .toList();
  }
  
  /// Check ATS compatibility score
  static double calculateATSScore(ResumeModel resume) {
    double score = 0.0;
    
    // Basic information (30 points)
    if (resume.firstName.isNotEmpty) score += 5;
    if (resume.lastName.isNotEmpty) score += 5;
    if (resume.email.isNotEmpty) score += 5;
    if (resume.phone.isNotEmpty) score += 5;
    if (resume.summary != null && resume.summary!.isNotEmpty) score += 10;
    
    // Skills (20 points)
    if (resume.skills.length >= 5) score += 20;
    else if (resume.skills.length >= 3) score += 15;
    else if (resume.skills.isNotEmpty) score += 10;
    
    // Experience (30 points)
    if (resume.experience.length >= 3) score += 30;
    else if (resume.experience.length >= 2) score += 20;
    else if (resume.experience.isNotEmpty) score += 10;
    
    // Education (20 points)
    if (resume.education.isNotEmpty) score += 20;
    
    return score;
  }
}

