import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';

/// AI Interview Service
/// 
/// This service handles interview practice sessions with AI.
/// Uses Firebase Cloud Functions as a secure proxy to OpenAI.

class InterviewMessage {
  final String role; // 'user' or 'assistant' or 'system'
  final String content;
  final DateTime timestamp;

  InterviewMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory InterviewMessage.fromJson(Map<String, dynamic> json) {
    return InterviewMessage(
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ResponseAnalysis {
  final double communicationScore; // 0-100
  final double structureScore; // 0-100
  final double examplesScore; // 0-100
  final double roleRelevanceScore; // 0-100
  final String communicationFeedback;
  final String structureFeedback;
  final String examplesFeedback;
  final String roleRelevanceFeedback;

  ResponseAnalysis({
    required this.communicationScore,
    required this.structureScore,
    required this.examplesScore,
    required this.roleRelevanceScore,
    required this.communicationFeedback,
    required this.structureFeedback,
    required this.examplesFeedback,
    required this.roleRelevanceFeedback,
  });

  double get overallScore {
    return (communicationScore + structureScore + examplesScore + roleRelevanceScore) / 4;
  }
}

class InterviewFeedback {
  final double score; // 0-100
  final List<String> strengths;
  final List<String> improvements;
  final String overallFeedback;
  final ResponseAnalysis? detailedAnalysis;
  final List<String> exampleResponses;

  InterviewFeedback({
    required this.score,
    required this.strengths,
    required this.improvements,
    required this.overallFeedback,
    this.detailedAnalysis,
    List<String>? exampleResponses,
  }) : exampleResponses = exampleResponses ?? [];
}

class AIInterviewService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west3');

  /// Get interview question based on field/industry and specific role
  Future<String> getInterviewQuestion({
    String? field,
    String? position,
    String? company,
    int questionNumber = 1,
  }) async {
    try {
      final callable = _functions.httpsCallable('getInterviewQuestion');
      final result = await callable.call({
        'field': field,
        'position': position,
        'company': company,
        'questionNumber': questionNumber,
      });

      return result.data['question'] ?? 'Tell me about yourself.';
      } catch (e) {
      throw Exception('Error getting interview question: $e');
    }
  }

  /// Get AI feedback on user's answer
  Future<InterviewFeedback> getFeedback({
    required String question,
    required String userAnswer,
    String? field,
    String? position,
    String? company,
  }) async {
    try {
      final callable = _functions.httpsCallable('getInterviewFeedback');
      final result = await callable.call({
        'question': question,
        'userAnswer': userAnswer,
        'field': field,
        'position': position,
      });

      return _parseAIFeedback(result.data['feedback']);
      } catch (e) {
      throw Exception('Error getting feedback: $e');
    }
  }

  InterviewFeedback _parseAIFeedback(String aiResponse) {
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(aiResponse);
      if (jsonMatch == null) {
        throw Exception('No JSON found in response');
      }

      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      
      final detailedAnalysis = json['detailedAnalysis'] as Map<String, dynamic>?;
      ResponseAnalysis? analysis;
      
      if (detailedAnalysis != null) {
        final comm = detailedAnalysis['communication'] as Map<String, dynamic>?;
        final struct = detailedAnalysis['structure'] as Map<String, dynamic>?;
        final examples = detailedAnalysis['examples'] as Map<String, dynamic>?;
        final roleRel = detailedAnalysis['roleRelevance'] as Map<String, dynamic>?;

        if (comm != null && struct != null && examples != null && roleRel != null) {
          analysis = ResponseAnalysis(
        communicationScore: (comm['score'] as num).toDouble(),
        structureScore: (struct['score'] as num).toDouble(),
        examplesScore: (examples['score'] as num).toDouble(),
        roleRelevanceScore: (roleRel['score'] as num).toDouble(),
            communicationFeedback: comm['feedback'] as String? ?? '',
            structureFeedback: struct['feedback'] as String? ?? '',
            examplesFeedback: examples['feedback'] as String? ?? '',
            roleRelevanceFeedback: roleRel['feedback'] as String? ?? '',
          );
        }
      }

      return InterviewFeedback(
        score: (json['overallScore'] as num?)?.toDouble() ?? analysis?.overallScore ?? 50,
        strengths: (json['strengths'] as List<dynamic>?)?.cast<String>() ?? [],
        improvements: (json['improvements'] as List<dynamic>?)?.cast<String>() ?? [],
        overallFeedback: json['overallFeedback'] as String? ?? 'Feedback generated successfully.',
        detailedAnalysis: analysis,
        exampleResponses: (json['exampleResponses'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    } catch (e) {
      throw Exception('Failed to parse AI feedback: $e');
    }
  }

  /// Generate follow-up question based on conversation
  Future<String> generateFollowUpQuestion({
    required List<InterviewMessage> conversation,
    String? field,
    String? position,
  }) async {
    try {
      final messages = conversation.map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList();

      final callable = _functions.httpsCallable('chatCompletion');
      final result = await callable.call({
        'messages': [
          {
            'role': 'system',
            'content': 'You are Arya, an expert interview coach. Generate a natural follow-up question based on the conversation.',
          },
          ...messages,
          {
            'role': 'user',
            'content': 'Generate a follow-up question that digs deeper into the previous answer.',
          },
        ],
        'temperature': 0.7,
        'max_tokens': 500,
      });

      return result.data['content'] ?? 'Can you tell me more about that?';
    } catch (e) {
      throw Exception('Error generating follow-up: $e');
    }
  }

  /// Simulate realistic interview - get interviewer response for a stage
  Future<InterviewSimulationResponse> simulateInterview({
    required String stage, // 'intro', 'question', 'followup', 'closing'
    String? position,
    String? company,
    String? field,
    int questionNumber = 1,
    int totalQuestions = 5,
    String? previousAnswer,
    String? previousQuestion,
    String interviewerName = 'Arya',
    String candidateName = 'there',
  }) async {
    try {
      final callable = _functions.httpsCallable('simulateInterview');
      final result = await callable.call({
        'stage': stage,
        'position': position,
        'company': company,
        'field': field,
        'questionNumber': questionNumber,
        'totalQuestions': totalQuestions,
        'previousAnswer': previousAnswer,
        'previousQuestion': previousQuestion,
        'interviewerName': interviewerName,
        'candidateName': candidateName,
      });

      return InterviewSimulationResponse(
        response: result.data['response'] ?? '',
        stage: result.data['stage'] ?? stage,
        questionNumber: result.data['questionNumber'] ?? questionNumber,
        interviewerName: result.data['interviewerName'] ?? interviewerName,
      );
    } catch (e) {
      throw Exception('Error in interview simulation: $e');
    }
  }

  /// Get final interview report
  Future<InterviewReport> getInterviewReport({
    String? position,
    String? company,
    required List<QuestionAnswer> questionsAndAnswers,
    required List<double> overallScores,
    String candidateName = 'Candidate',
  }) async {
    try {
      final callable = _functions.httpsCallable('getInterviewReport');
      final result = await callable.call({
        'position': position,
        'company': company,
        'questionsAndAnswers': questionsAndAnswers.map((qa) => qa.toJson()).toList(),
        'overallScores': overallScores,
        'candidateName': candidateName,
      });

      return InterviewReport(
        report: result.data['report'] ?? '',
        averageScore: (result.data['averageScore'] as num?)?.toDouble() ?? 0,
        verdict: result.data['verdict'] ?? 'Unknown',
      );
    } catch (e) {
      throw Exception('Error getting interview report: $e');
    }
  }
}

// Models for interview simulation
class InterviewSimulationResponse {
  final String response;
  final String stage;
  final int questionNumber;
  final String interviewerName;

  InterviewSimulationResponse({
    required this.response,
    required this.stage,
    required this.questionNumber,
    required this.interviewerName,
  });
}

class QuestionAnswer {
  final String question;
  final String answer;
  final double score;

  QuestionAnswer({
    required this.question,
    required this.answer,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
    'score': score,
  };
}

class InterviewReport {
  final String report;
  final double averageScore;
  final String verdict;

  InterviewReport({
    required this.report,
    required this.averageScore,
    required this.verdict,
  });
}
