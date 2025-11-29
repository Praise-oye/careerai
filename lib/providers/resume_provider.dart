import 'package:flutter/foundation.dart';
import '../models/resume_model.dart';
import '../services/ats_resume_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ResumeProvider with ChangeNotifier {
  ResumeModel _resume = ResumeModel();
  static const String _storageKey = 'resume_data';

  ResumeModel get resume => _resume;

  bool get isComplete => _resume.isComplete;

  double get atsScore => ATSResumeBuilder.calculateATSScore(_resume);

  ResumeProvider() {
    _loadResume();
  }

  // Personal Information
  void updatePersonalInfo({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    String? linkedIn,
    String? website,
    String? summary,
  }) {
    _resume.firstName = firstName ?? _resume.firstName;
    _resume.lastName = lastName ?? _resume.lastName;
    _resume.email = email ?? _resume.email;
    _resume.phone = phone ?? _resume.phone;
    if (address != null) _resume.address = address;
    if (linkedIn != null) _resume.linkedIn = linkedIn;
    if (website != null) _resume.website = website;
    if (summary != null) _resume.summary = summary;
    _saveResume();
    notifyListeners();
  }

  // Education
  void addEducation(Education education) {
    _resume.education.add(education);
    _saveResume();
    notifyListeners();
  }

  void updateEducation(int index, Education education) {
    if (index >= 0 && index < _resume.education.length) {
      _resume.education[index] = education;
      _saveResume();
      notifyListeners();
    }
  }

  void removeEducation(int index) {
    if (index >= 0 && index < _resume.education.length) {
      _resume.education.removeAt(index);
      _saveResume();
      notifyListeners();
    }
  }

  // Experience
  void addExperience(Experience experience) {
    _resume.experience.add(experience);
    _saveResume();
    notifyListeners();
  }

  void updateExperience(int index, Experience experience) {
    if (index >= 0 && index < _resume.experience.length) {
      _resume.experience[index] = experience;
      _saveResume();
      notifyListeners();
    }
  }

  void removeExperience(int index) {
    if (index >= 0 && index < _resume.experience.length) {
      _resume.experience.removeAt(index);
      _saveResume();
      notifyListeners();
    }
  }

  // Skills
  void addSkill(String skill) {
    if (skill.isNotEmpty && !_resume.skills.contains(skill)) {
      _resume.skills.add(skill);
      _saveResume();
      notifyListeners();
    }
  }

  void removeSkill(String skill) {
    _resume.skills.remove(skill);
    _saveResume();
    notifyListeners();
  }

  void updateSkills(List<String> skills) {
    _resume.skills = skills;
    _saveResume();
    notifyListeners();
  }

  // Projects
  void addProject(Project project) {
    _resume.projects.add(project);
    _saveResume();
    notifyListeners();
  }

  void removeProject(int index) {
    if (index >= 0 && index < _resume.projects.length) {
      _resume.projects.removeAt(index);
      _saveResume();
      notifyListeners();
    }
  }

  // Certifications
  void addCertification(Certification certification) {
    _resume.certifications.add(certification);
    _saveResume();
    notifyListeners();
  }

  void removeCertification(int index) {
    if (index >= 0 && index < _resume.certifications.length) {
      _resume.certifications.removeAt(index);
      _saveResume();
      notifyListeners();
    }
  }

  // Generate ATS Resume
  String generateATSResume({String template = 'standard'}) {
    return ATSResumeBuilder.generateATSResume(_resume, template: template);
  }

  List<String> getKeywords() {
    return ATSResumeBuilder.extractKeywords(_resume);
  }

  // Persistence
  Future<void> _saveResume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_resume.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving resume: $e');
    }
  }

  Future<void> _loadResume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _resume = ResumeModel.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading resume: $e');
    }
  }

  void clearResume() {
    _resume = ResumeModel();
    _saveResume();
    notifyListeners();
  }
}

