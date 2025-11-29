import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';

/// AI Mentor Service
/// 
/// Provides personalized career mentorship, skill assessments,
/// and learning recommendations powered by AI via Firebase Cloud Functions.

class SkillAssessment {
  final String skillName;
  final int currentLevel; // 1-10
  final int targetLevel; // 1-10
  final String feedback;
  final List<String> recommendations;

  SkillAssessment({
    required this.skillName,
    required this.currentLevel,
    required this.targetLevel,
    required this.feedback,
    required this.recommendations,
  });

  double get progressPercent => (currentLevel / targetLevel) * 100;
}

class LearningPath {
  final String title;
  final String description;
  final List<LearningModule> modules;
  final String estimatedTime;
  final String difficulty;

  LearningPath({
    required this.title,
    required this.description,
    required this.modules,
    required this.estimatedTime,
    required this.difficulty,
  });
}

class LearningModule {
  final String title;
  final String description;
  final String type; // 'video', 'article', 'exercise', 'project'
  final String duration;
  final String? url;
  final bool isCompleted;

  LearningModule({
    required this.title,
    required this.description,
    required this.type,
    required this.duration,
    this.url,
    this.isCompleted = false,
  });
}

class CareerAdvice {
  final String advice;
  final List<String> actionItems;
  final List<String> resources;
  final String category; // 'skills', 'networking', 'job-search', 'growth'

  CareerAdvice({
    required this.advice,
    required this.actionItems,
    required this.resources,
    required this.category,
  });
}

// AI Learning Resources Models
class LearningResources {
  final String skill;
  final List<VideoResource> videos;
  final List<CourseResource> courses;
  final List<ArticleResource> articles;
  final List<ProjectIdea> projectIdeas;

  LearningResources({
    required this.skill,
    required this.videos,
    required this.courses,
    required this.articles,
    required this.projectIdeas,
  });
}

class VideoResource {
  final String title;
  final String channel;
  final String videoId;
  final String duration;
  final String description;
  final String difficulty;

  VideoResource({
    required this.title,
    required this.channel,
    required this.videoId,
    required this.duration,
    required this.description,
    required this.difficulty,
  });

  String get thumbnailUrl => 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';
}

class CourseResource {
  final String title;
  final String platform;
  final String url;
  final String duration;
  final String description;
  final bool isFree;

  CourseResource({
    required this.title,
    required this.platform,
    required this.url,
    required this.duration,
    required this.description,
    required this.isFree,
  });
}

class ArticleResource {
  final String title;
  final String source;
  final String url;
  final String description;
  final String readTime;

  ArticleResource({
    required this.title,
    required this.source,
    required this.url,
    required this.description,
    required this.readTime,
  });
}

class ProjectIdea {
  final String title;
  final String description;
  final List<String> skills;
  final String difficulty;

  ProjectIdea({
    required this.title,
    required this.description,
    required this.skills,
    required this.difficulty,
  });
}

// ATS CV Models
class ATSCV {
  final String originalSummary;
  final String polishedSummary;
  final String atsSummary;
  String professionalSummary;
  int _selectedMode;
  final CVSkills skills;
  final CVSkills atsSkills;
  final List<CVExperience> experience;
  final List<CVEducation> education;
  final List<String> projects;
  final List<String> certifications;
  final List<String> atsKeywords;
  final List<String> improvementTips;

  ATSCV({
    required this.originalSummary,
    required this.polishedSummary,
    required this.atsSummary,
    required this.professionalSummary,
    int selectedMode = 1,
    required this.skills,
    required this.atsSkills,
    required this.experience,
    required this.education,
    required this.projects,
    required this.certifications,
    required this.atsKeywords,
    required this.improvementTips,
  }) : _selectedMode = selectedMode;

  int get selectedMode => _selectedMode;
  set selectedMode(int value) => _selectedMode = value;

  CVSkills get currentSkills => _selectedMode == 2 ? atsSkills : skills;
}

class CVSkills {
  final List<String> technical;
  final List<String> soft;
  final List<String> tools;

  CVSkills({
    required this.technical,
    required this.soft,
    required this.tools,
  });
}

class CVExperience {
  final String title;
  final String company;
  final String duration;
  final List<String> bullets;

  CVExperience({
    required this.title,
    required this.company,
    required this.duration,
    required this.bullets,
  });
}

class CVEducation {
  final String degree;
  final String institution;
  final String year;
  final List<String> highlights;

  CVEducation({
    required this.degree,
    required this.institution,
    required this.year,
    required this.highlights,
  });
}

class CVProject {
  final String name;
  final String description;
  final String impact;

  CVProject({
    required this.name,
    required this.description,
    required this.impact,
  });
}

// Job Search Models
class JobSearchResult {
  final String searchQuery;
  final String location;
  final String totalEstimated;
  final SalaryRange salaryRange;
  final List<JobListing> jobs;
  final List<JobBoard> jobBoards;
  final List<String> tips;

  JobSearchResult({
    required this.searchQuery,
    required this.location,
    required this.totalEstimated,
    required this.salaryRange,
    required this.jobs,
    required this.jobBoards,
    required this.tips,
  });
}

class SalaryRange {
  final String min;
  final String max;
  final String currency;

  SalaryRange({
    required this.min,
    required this.max,
    required this.currency,
  });
}

class JobListing {
  final String title;
  final String company;
  final String location;
  final String type;
  final String salary;
  final String description;
  final List<String> requirements;
  final String applyUrl;
  final String source;
  final String postedDate;

  JobListing({
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.salary,
    required this.description,
    required this.requirements,
    required this.applyUrl,
    required this.source,
    required this.postedDate,
  });
}

class JobBoard {
  final String name;
  final String searchUrl;
  final String description;

  JobBoard({
    required this.name,
    required this.searchUrl,
    required this.description,
  });
}

class AIMentorService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west3');

  /// Assess user's skills based on their background and target role
  Future<List<SkillAssessment>> assessSkills({
    required String currentRole,
    required String targetRole,
    required List<String> currentSkills,
    String? industry,
  }) async {
    try {
      final callable = _functions.httpsCallable('assessSkills');
      final result = await callable.call({
        'currentRole': currentRole,
        'targetRole': targetRole,
        'currentSkills': currentSkills,
        'industry': industry,
      });

      return _parseSkillAssessment(result.data['assessment']);
    } catch (e) {
      throw Exception('Error assessing skills: $e');
    }
  }

  List<SkillAssessment> _parseSkillAssessment(String response) {
    try {
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch == null) throw Exception('No JSON found');
      
      final List<dynamic> json = jsonDecode(jsonMatch.group(0)!);
      return json.map((item) => SkillAssessment(
        skillName: item['skillName'] ?? '',
        currentLevel: (item['currentLevel'] as num?)?.toInt() ?? 1,
        targetLevel: (item['targetLevel'] as num?)?.toInt() ?? 10,
        feedback: item['feedback'] ?? '',
        recommendations: (item['recommendations'] as List<dynamic>?)?.cast<String>() ?? [],
      )).toList();
    } catch (e) {
      throw Exception('Failed to parse skill assessment: $e');
    }
  }

  /// Generate a personalized learning path
  Future<LearningPath> generateLearningPath({
    required String targetRole,
    required List<String> skillsToImprove,
    String? preferredLearningStyle,
    String? timeAvailable,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateLearningPath');
      final result = await callable.call({
        'targetRole': targetRole,
        'skillsToImprove': skillsToImprove,
        'learningStyle': preferredLearningStyle,
        'timeAvailable': timeAvailable,
      });

      return _parseLearningPath(result.data['learningPath']);
    } catch (e) {
      throw Exception('Error generating learning path: $e');
    }
  }

  LearningPath _parseLearningPath(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) throw Exception('No JSON found');
      
      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final modules = (json['modules'] as List<dynamic>?)?.map((m) => LearningModule(
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        type: m['type'] ?? 'article',
        duration: m['duration'] ?? '',
        url: m['url'],
      )).toList() ?? [];

      return LearningPath(
        title: json['title'] ?? 'Learning Path',
        description: json['description'] ?? '',
        modules: modules,
        estimatedTime: json['estimatedTime'] ?? '',
        difficulty: json['difficulty'] ?? 'intermediate',
      );
    } catch (e) {
      throw Exception('Failed to parse learning path: $e');
    }
  }

  /// Get personalized career advice
  Future<CareerAdvice> getCareerAdvice({
    required String question,
    String? currentRole,
    String? targetRole,
    String? context,
  }) async {
    try {
      final callable = _functions.httpsCallable('chatCompletion');
      final result = await callable.call({
        'messages': [
          {
            'role': 'system',
            'content': 'You are Arya, an expert career mentor. Provide helpful, actionable advice.',
          },
          {
            'role': 'user',
            'content': '''As a career mentor, provide advice for this question:

Question: $question
${currentRole != null ? "Current role: $currentRole" : ""}
${targetRole != null ? "Target role: $targetRole" : ""}
${context != null ? "Additional context: $context" : ""}

Return as JSON:
{
  "advice": "Detailed advice paragraph...",
  "actionItems": ["Action 1", "Action 2", "Action 3"],
  "resources": ["Resource 1", "Resource 2"],
  "category": "skills/networking/job-search/growth"
}''',
          },
        ],
        'temperature': 0.7,
        'max_tokens': 1500,
      });

      return _parseCareerAdvice(result.data['content']);
    } catch (e) {
      throw Exception('Error getting career advice: $e');
    }
  }

  CareerAdvice _parseCareerAdvice(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) throw Exception('No JSON found');
      
      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      return CareerAdvice(
        advice: json['advice'] ?? '',
        actionItems: (json['actionItems'] as List<dynamic>?)?.cast<String>() ?? [],
        resources: (json['resources'] as List<dynamic>?)?.cast<String>() ?? [],
        category: json['category'] ?? 'growth',
      );
    } catch (e) {
      throw Exception('Failed to parse career advice: $e');
    }
  }

  /// Chat with AI mentor
  Future<String> chat({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String? userContext,
  }) async {
    try {
      final callable = _functions.httpsCallable('mentorChat');
      final result = await callable.call({
        'message': message,
        'conversationHistory': conversationHistory,
        'userContext': userContext,
      });

      return result.data['response'] ?? 'I apologize, I could not generate a response.';
    } catch (e) {
      throw Exception('Error in chat: $e');
    }
  }

  /// Get AI-curated learning resources for a skill
  Future<LearningResources> getLearningResources({
    required String skill,
    String? targetRole,
    String difficulty = 'beginner',
  }) async {
    try {
      final callable = _functions.httpsCallable('getLearningResources');
      final result = await callable.call({
        'skill': skill,
        'targetRole': targetRole,
        'difficulty': difficulty,
      });

      return _parseLearningResources(result.data['resources']);
    } catch (e) {
      throw Exception('Error getting learning resources: $e');
    }
  }

  LearningResources _parseLearningResources(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) throw Exception('No JSON found');
      
      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      
      final videos = (json['videos'] as List<dynamic>?)?.map((v) => VideoResource(
        title: v['title'] ?? '',
        channel: v['channel'] ?? '',
        videoId: v['videoId'] ?? '',
        duration: v['duration'] ?? '',
        description: v['description'] ?? '',
        difficulty: v['difficulty'] ?? 'beginner',
      )).toList() ?? [];

      final courses = (json['courses'] as List<dynamic>?)?.map((c) => CourseResource(
        title: c['title'] ?? '',
        platform: c['platform'] ?? '',
        url: c['url'] ?? '',
        duration: c['duration'] ?? '',
        description: c['description'] ?? '',
        isFree: c['isFree'] ?? true,
      )).toList() ?? [];

      final articles = (json['articles'] as List<dynamic>?)?.map((a) => ArticleResource(
        title: a['title'] ?? '',
        source: a['source'] ?? '',
        url: a['url'] ?? '',
        description: a['description'] ?? '',
        readTime: a['readTime'] ?? '',
      )).toList() ?? [];

      final projectIdeas = (json['projectIdeas'] as List<dynamic>?)?.map((p) => ProjectIdea(
        title: p['title'] ?? '',
        description: p['description'] ?? '',
        skills: (p['skills'] as List<dynamic>?)?.cast<String>() ?? [],
        difficulty: p['difficulty'] ?? 'beginner',
      )).toList() ?? [];

      return LearningResources(
        skill: json['skill'] ?? '',
        videos: videos,
        courses: courses,
        articles: articles,
        projectIdeas: projectIdeas,
      );
    } catch (e) {
      throw Exception('Failed to parse learning resources: $e');
    }
  }

  /// Generate ATS-optimized CV
  Future<ATSCV> generateATSCV({
    required String targetRole,
    String? currentRole,
    List<String>? skills,
    String? experience,
    String? education,
    String? projects,
    String? achievements,
    Map<String, String>? personalInfo,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateATSCV');
      final result = await callable.call({
        'targetRole': targetRole,
        'currentRole': currentRole,
        'skills': skills,
        'experience': experience,
        'education': education,
        'projects': projects,
        'achievements': achievements,
        'personalInfo': personalInfo,
      });

      // Handle different response formats
      final data = result.data;
      String? cvResponse;
      
      if (data is Map) {
        cvResponse = data['cv']?.toString();
      } else if (data is String) {
        cvResponse = data;
      }
      
      if (cvResponse == null || cvResponse.isEmpty) {
        throw Exception('Empty response from server');
      }

      return _parseATSCV(cvResponse);
    } catch (e) {
      throw Exception('Error generating ATS CV: $e');
    }
  }

  ATSCV _parseATSCV(String response) {
    try {
      // Try to extract JSON from the response
      String jsonString = response;
      
      // If response contains markdown code blocks, extract the JSON
      final codeBlockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(response);
      if (codeBlockMatch != null) {
        jsonString = codeBlockMatch.group(1)!;
      }
      
      // Find the JSON object
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonString);
      if (jsonMatch == null) {
        throw Exception('Could not parse CV response. Please try again.');
      }
      
      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      
      final skillsJson = json['skills'] as Map<String, dynamic>? ?? {};
      final skills = CVSkills(
        technical: _parseStringList(skillsJson['technical']),
        soft: _parseStringList(skillsJson['soft']),
        tools: _parseStringList(skillsJson['tools']),
      );

      final experience = (json['experience'] as List<dynamic>?)?.map((e) {
        final exp = e as Map<String, dynamic>;
        return CVExperience(
          title: exp['title']?.toString() ?? '',
          company: exp['company']?.toString() ?? '',
          duration: exp['duration']?.toString() ?? '',
          bullets: _parseStringList(exp['bullets']),
        );
      }).toList() ?? [];

      final education = (json['education'] as List<dynamic>?)?.map((e) {
        final edu = e as Map<String, dynamic>;
        return CVEducation(
          degree: edu['degree']?.toString() ?? '',
          institution: edu['institution']?.toString() ?? '',
          year: edu['year']?.toString() ?? '',
          highlights: _parseStringList(edu['highlights']),
        );
      }).toList() ?? [];

      // Projects are now just strings
      final projects = _parseStringList(json['projects']);

      // Parse summaries
      final originalSummary = json['originalSummary']?.toString() ?? '';
      final polishedSummary = json['polishedSummary']?.toString() ?? '';
      final atsSummary = json['atsSummary']?.toString() ?? polishedSummary;

      // Parse ATS skills
      final atsSkillsJson = json['atsSkills'] as Map<String, dynamic>? ?? {};
      final atsSkills = CVSkills(
        technical: _parseStringList(atsSkillsJson['technical']),
        soft: _parseStringList(atsSkillsJson['soft']),
        tools: _parseStringList(atsSkillsJson['tools']),
      );

      return ATSCV(
        originalSummary: originalSummary,
        polishedSummary: polishedSummary,
        atsSummary: atsSummary,
        professionalSummary: polishedSummary, // Default to polished
        selectedMode: 1,
        skills: skills,
        atsSkills: atsSkills.technical.isEmpty ? skills : atsSkills,
        experience: experience,
        education: education,
        projects: projects,
        certifications: _parseStringList(json['certifications']),
        atsKeywords: _parseStringList(json['atsKeywords']),
        improvementTips: _parseStringList(json['improvementTips']),
      );
    } catch (e) {
      throw Exception('Failed to parse CV. Please try again.');
    }
  }

  List<String> _parseStringList(dynamic list) {
    if (list == null) return [];
    if (list is! List) return [];
    return list.map((item) => item?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }

  /// Search for real job listings
  Future<JobSearchResult> searchJobs({
    required String targetRole,
    String location = 'South Africa',
    String experience = 'entry',
    List<String>? skills,
  }) async {
    try {
      final callable = _functions.httpsCallable('searchJobs');
      final result = await callable.call({
        'targetRole': targetRole,
        'location': location,
        'experience': experience,
        'skills': skills,
      });

      return _parseJobSearch(result.data['jobs']);
    } catch (e) {
      throw Exception('Error searching jobs: $e');
    }
  }

  JobSearchResult _parseJobSearch(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) throw Exception('No JSON found');
      
      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      
      final salaryJson = json['salaryRange'] as Map<String, dynamic>? ?? {};
      final salaryRange = SalaryRange(
        min: salaryJson['min'] ?? '',
        max: salaryJson['max'] ?? '',
        currency: salaryJson['currency'] ?? 'ZAR',
      );

      final jobs = (json['jobs'] as List<dynamic>?)?.map((j) => JobListing(
        title: j['title'] ?? '',
        company: j['company'] ?? '',
        location: j['location'] ?? '',
        type: j['type'] ?? '',
        salary: j['salary'] ?? '',
        description: j['description'] ?? '',
        requirements: (j['requirements'] as List<dynamic>?)?.cast<String>() ?? [],
        applyUrl: j['applyUrl'] ?? '',
        source: j['source'] ?? '',
        postedDate: j['postedDate'] ?? '',
      )).toList() ?? [];

      final jobBoards = (json['jobBoards'] as List<dynamic>?)?.map((b) => JobBoard(
        name: b['name'] ?? '',
        searchUrl: b['searchUrl'] ?? '',
        description: b['description'] ?? '',
      )).toList() ?? [];

      return JobSearchResult(
        searchQuery: json['searchQuery'] ?? '',
        location: json['location'] ?? '',
        totalEstimated: json['totalEstimated'] ?? '',
        salaryRange: salaryRange,
        jobs: jobs,
        jobBoards: jobBoards,
        tips: (json['tips'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    } catch (e) {
      throw Exception('Failed to parse job search: $e');
    }
  }
}
