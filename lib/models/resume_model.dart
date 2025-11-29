class ResumeModel {
  // Personal Information
  String firstName;
  String lastName;
  String email;
  String phone;
  String? address;
  String? linkedIn;
  String? website;
  String? summary;

  // Education
  List<Education> education;

  // Experience
  List<Experience> experience;

  // Skills
  List<String> skills;

  // Projects (optional)
  List<Project> projects;

  // Certifications (optional)
  List<Certification> certifications;

  ResumeModel({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.address,
    this.linkedIn,
    this.website,
    this.summary,
    List<Education>? education,
    List<Experience>? experience,
    List<String>? skills,
    List<Project>? projects,
    List<Certification>? certifications,
  })  : education = education ?? [],
        experience = experience ?? [],
        skills = skills ?? [],
        projects = projects ?? [],
        certifications = certifications ?? [];

  String get fullName => '$firstName $lastName'.trim();

  bool get isComplete {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        email.isNotEmpty &&
        phone.isNotEmpty &&
        (education.isNotEmpty || experience.isNotEmpty);
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'linkedIn': linkedIn,
      'website': website,
      'summary': summary,
      'education': education.map((e) => e.toJson()).toList(),
      'experience': experience.map((e) => e.toJson()).toList(),
      'skills': skills,
      'projects': projects.map((p) => p.toJson()).toList(),
      'certifications': certifications.map((c) => c.toJson()).toList(),
    };
  }

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    return ResumeModel(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'],
      linkedIn: json['linkedIn'],
      website: json['website'],
      summary: json['summary'],
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => Education.fromJson(e))
              .toList() ??
          [],
      experience: (json['experience'] as List<dynamic>?)
              ?.map((e) => Experience.fromJson(e))
              .toList() ??
          [],
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      projects: (json['projects'] as List<dynamic>?)
              ?.map((p) => Project.fromJson(p))
              .toList() ??
          [],
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((c) => Certification.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class Education {
  String institution;
  String degree;
  String fieldOfStudy;
  String startDate;
  String? endDate;
  bool isCurrent;
  String? gpa;
  String? description;

  Education({
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.gpa,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'institution': institution,
      'degree': degree,
      'fieldOfStudy': fieldOfStudy,
      'startDate': startDate,
      'endDate': endDate,
      'isCurrent': isCurrent,
      'gpa': gpa,
      'description': description,
    };
  }

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      institution: json['institution'] ?? '',
      degree: json['degree'] ?? '',
      fieldOfStudy: json['fieldOfStudy'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      isCurrent: json['isCurrent'] ?? false,
      gpa: json['gpa'],
      description: json['description'],
    );
  }
}

class Experience {
  String company;
  String position;
  String startDate;
  String? endDate;
  bool isCurrent;
  String? location;
  String? description;
  List<String> achievements;

  Experience({
    required this.company,
    required this.position,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.location,
    this.description,
    List<String>? achievements,
  }) : achievements = achievements ?? [];

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'position': position,
      'startDate': startDate,
      'endDate': endDate,
      'isCurrent': isCurrent,
      'location': location,
      'description': description,
      'achievements': achievements,
    };
  }

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      company: json['company'] ?? '',
      position: json['position'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      isCurrent: json['isCurrent'] ?? false,
      location: json['location'],
      description: json['description'],
      achievements: (json['achievements'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
    );
  }
}

class Project {
  String name;
  String? description;
  String? startDate;
  String? endDate;
  String? url;
  List<String> technologies;

  Project({
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.url,
    List<String>? technologies,
  }) : technologies = technologies ?? [];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'url': url,
      'technologies': technologies,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'] ?? '',
      description: json['description'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      url: json['url'],
      technologies: (json['technologies'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
    );
  }
}

class Certification {
  String name;
  String? issuer;
  String? issueDate;
  String? expiryDate;
  String? credentialId;
  String? credentialUrl;

  Certification({
    required this.name,
    this.issuer,
    this.issueDate,
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'issuer': issuer,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'credentialId': credentialId,
      'credentialUrl': credentialUrl,
    };
  }

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      name: json['name'] ?? '',
      issuer: json['issuer'],
      issueDate: json['issueDate'],
      expiryDate: json['expiryDate'],
      credentialId: json['credentialId'],
      credentialUrl: json['credentialUrl'],
    );
  }
}

