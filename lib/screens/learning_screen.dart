// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ai_mentor_service.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AIMentorService _mentorService = AIMentorService();
  
  // Skill Assessment State
  List<SkillAssessment>? _skillAssessments;
  bool _isAssessing = false;
  
  // Learning Path State
  LearningPath? _learningPath;
  bool _isGeneratingPath = false;
  
  // Mentor Chat State
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isChatting = false;
  
  // User Input Controllers
  final TextEditingController _currentRoleController = TextEditingController();
  final TextEditingController _targetRoleController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  // AI Learning Resources State
  final TextEditingController _skillSearchController = TextEditingController();
  LearningResources? _aiLearningResources;
  bool _isSearchingResources = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _currentRoleController.dispose();
    _targetRoleController.dispose();
    _skillsController.dispose();
    _skillSearchController.dispose();
    super.dispose();
  }

  // Search for AI-curated learning resources
  Future<void> _searchLearningResources() async {
    if (_skillSearchController.text.trim().isEmpty) {
      _showError('Please enter a skill to search');
      return;
    }

    setState(() => _isSearchingResources = true);

    try {
      final resources = await _mentorService.getLearningResources(
        skill: _skillSearchController.text.trim(),
        targetRole: _targetRoleController.text.isNotEmpty ? _targetRoleController.text : null,
      );

      setState(() {
        _aiLearningResources = resources;
        _isSearchingResources = false;
      });
    } catch (e) {
      setState(() => _isSearchingResources = false);
      _showError(e.toString());
    }
  }

  Future<void> _launchVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildResourceHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count found',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildAIVideoCard(VideoResource video) {
    return GestureDetector(
      onTap: () => _launchVideo(video.youtubeUrl),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  Image.network(
                    video.thumbnailUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 110,
                      color: Colors.grey[300],
                      child: const Icon(Icons.play_circle_fill, size: 40, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.duration,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.channel,
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAICourseCard(CourseResource course) {
    return GestureDetector(
      onTap: () => _launchVideo(course.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${course.platform} • ${course.duration}',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (course.isFree)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'FREE',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAIArticleCard(ArticleResource article) {
    return GestureDetector(
      onTap: () => _launchVideo(article.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.article, color: Colors.purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${article.source} • ${article.readTime} read',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAIProjectCard(ProjectIdea project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  project.title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(project.difficulty).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  project.difficulty,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _getDifficultyColor(project.difficulty),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project.description,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: project.skills.map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(skill, style: GoogleFonts.inter(fontSize: 11)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _assessSkills() async {
    if (_currentRoleController.text.isEmpty || _targetRoleController.text.isEmpty) {
      _showError('Please enter both your current and target role');
      return;
    }

    setState(() => _isAssessing = true);

    try {
      final skills = _skillsController.text.isEmpty 
          ? <String>[] 
          : _skillsController.text.split(',').map((s) => s.trim()).toList();
      
      final assessments = await _mentorService.assessSkills(
        currentRole: _currentRoleController.text,
        targetRole: _targetRoleController.text,
        currentSkills: skills,
      );

      setState(() {
        _skillAssessments = assessments;
        _isAssessing = false;
      });
    } catch (e) {
      setState(() => _isAssessing = false);
      _showError(e.toString());
    }
  }

  Future<void> _generateLearningPath() async {
    if (_targetRoleController.text.isEmpty) {
      _showError('Please enter your target role first');
      return;
    }

    setState(() => _isGeneratingPath = true);

    try {
      final skillsToImprove = _skillAssessments
          ?.where((s) => s.currentLevel < s.targetLevel)
          .map((s) => s.skillName)
          .toList() ?? [];

      final path = await _mentorService.generateLearningPath(
        targetRole: _targetRoleController.text,
        skillsToImprove: skillsToImprove.isEmpty 
            ? ['general skills for ${_targetRoleController.text}'] 
            : skillsToImprove,
      );

      setState(() {
        _learningPath = path;
        _isGeneratingPath = false;
      });
      
      // Switch to learning path tab
      _tabController.animateTo(1);
    } catch (e) {
      setState(() => _isGeneratingPath = false);
      _showError(e.toString());
    }
  }

  Future<void> _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final message = _chatController.text.trim();
    _chatController.clear();

    setState(() {
      _chatHistory.add({'role': 'user', 'content': message});
      _isChatting = true;
    });

    try {
      final response = await _mentorService.chat(
        message: message,
        conversationHistory: _chatHistory.length > 1 
            ? _chatHistory.sublist(0, _chatHistory.length - 1) 
            : null,
        userContext: _targetRoleController.text.isNotEmpty 
            ? 'Target role: ${_targetRoleController.text}' 
            : null,
      );

      setState(() {
        _chatHistory.add({'role': 'assistant', 'content': response});
        _isChatting = false;
      });
    } catch (e) {
      setState(() {
        _chatHistory.add({
          'role': 'assistant',
          'content': 'Sorry, I encountered an error. Please try again.',
        });
        _isChatting = false;
      });
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Skill Building',
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
            Tab(icon: Icon(Icons.assessment), text: 'Skills'),
            Tab(icon: Icon(Icons.school), text: 'Learn'),
            Tab(icon: Icon(Icons.chat), text: 'Mentor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSkillsTab(),
          _buildLearningTab(),
          _buildMentorTab(),
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
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
                const Icon(Icons.trending_up, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skill Gap Analysis',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Identify skills needed for your dream role',
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
          const SizedBox(height: 24),

          // Input Fields
          Text(
            'Your Current Role',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _currentRoleController,
            decoration: InputDecoration(
              hintText: 'e.g., Junior Developer, Student, Sales Associate',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Your Target Role',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _targetRoleController,
            decoration: InputDecoration(
              hintText: 'e.g., Senior Software Engineer, Data Scientist',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Your Current Skills (comma-separated)',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _skillsController,
            decoration: InputDecoration(
              hintText: 'e.g., Python, Excel, Communication',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Assess Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAssessing ? null : _assessSkills,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAssessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Analyze My Skills',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Results
          if (_skillAssessments != null) ...[
            Text(
              'Skill Assessment Results',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._skillAssessments!.map((skill) => _buildSkillCard(skill)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPath ? null : _generateLearningPath,
                icon: const Icon(Icons.school),
                label: Text(
                  _isGeneratingPath ? 'Generating...' : 'Generate Learning Path',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillCard(SkillAssessment skill) {
    final progress = skill.currentLevel / skill.targetLevel;
    final color = progress >= 0.8 
        ? Colors.green 
        : progress >= 0.5 
            ? Colors.orange 
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  skill.skillName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${skill.currentLevel}/${skill.targetLevel}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            skill.feedback,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          if (skill.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Recommendations:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B46C1),
              ),
            ),
            const SizedBox(height: 4),
            ...skill.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF6B46C1))),
                  Expanded(
                    child: Text(
                      rec,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildLearningTab() {
    // AI-powered learning - search for any skill
    if (_learningPath == null) {
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
                    const Color(0xFF10B981),
                    const Color(0xFF10B981).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Learning Assistant',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Search any skill to get AI-curated resources',
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
            const SizedBox(height: 24),

            // Search Input
            Text(
              'What do you want to learn?',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _skillSearchController,
              decoration: InputDecoration(
                hintText: 'e.g., Python, Excel, Data Science, Communication',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearchingResources 
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _searchLearningResources,
                      ),
              ),
              onSubmitted: (_) => _searchLearningResources(),
            ),
            const SizedBox(height: 24),

            // AI-Generated Resources
            if (_aiLearningResources != null) ...[
              // Videos Section
              if (_aiLearningResources!.videos.isNotEmpty) ...[
                _buildResourceHeader('📺 Videos', _aiLearningResources!.videos.length),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _aiLearningResources!.videos.length,
                    itemBuilder: (context, index) => _buildAIVideoCard(_aiLearningResources!.videos[index]),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Courses Section
              if (_aiLearningResources!.courses.isNotEmpty) ...[
                _buildResourceHeader('🎓 Free Courses', _aiLearningResources!.courses.length),
                const SizedBox(height: 12),
                ..._aiLearningResources!.courses.map((course) => _buildAICourseCard(course)),
                const SizedBox(height: 24),
              ],

              // Articles Section
              if (_aiLearningResources!.articles.isNotEmpty) ...[
                _buildResourceHeader('📖 Articles', _aiLearningResources!.articles.length),
                const SizedBox(height: 12),
                ..._aiLearningResources!.articles.map((article) => _buildAIArticleCard(article)),
                const SizedBox(height: 24),
              ],

              // Projects Section
              if (_aiLearningResources!.projectIdeas.isNotEmpty) ...[
                _buildResourceHeader('🛠️ Project Ideas', _aiLearningResources!.projectIdeas.length),
                const SizedBox(height: 12),
                ..._aiLearningResources!.projectIdeas.map((project) => _buildAIProjectCard(project)),
              ],
            ] else ...[
              // Empty state - prompt to search
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.search, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Search for any skill',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our AI will find the best videos, courses, articles, and project ideas for you',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],

            // CTA to generate learning path
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6B46C1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6B46C1).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.route, size: 40, color: Color(0xFF6B46C1)),
                  const SizedBox(height: 8),
                  Text(
                    'Want a personalized learning path?',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6B46C1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete a skill assessment to get a custom AI roadmap',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _tabController.animateTo(0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B46C1),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Start Skill Assessment'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Path Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981),
                  const Color(0xFF10B981).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.route, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _learningPath!.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _learningPath!.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildPathChip(Icons.timer, _learningPath!.estimatedTime),
                    const SizedBox(width: 12),
                    _buildPathChip(Icons.signal_cellular_alt, _learningPath!.difficulty),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Learning Modules',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Modules
          ...List.generate(_learningPath!.modules.length, (index) {
            final module = _learningPath!.modules[index];
            return _buildModuleCard(module, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildPathChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Track expanded modules with their resources
  final Map<int, LearningResources?> _moduleResources = {};
  final Set<int> _loadingModules = {};

  Future<void> _loadModuleResources(int index, String moduleName) async {
    if (_loadingModules.contains(index)) return;
    
    setState(() => _loadingModules.add(index));

    try {
      final resources = await _mentorService.getLearningResources(
        skill: moduleName,
        targetRole: _targetRoleController.text.isNotEmpty ? _targetRoleController.text : null,
      );

      setState(() {
        _moduleResources[index] = resources;
        _loadingModules.remove(index);
      });
    } catch (e) {
      setState(() => _loadingModules.remove(index));
      _showError(e.toString());
    }
  }

  Widget _buildModuleCard(LearningModule module, int index) {
    IconData typeIcon;
    Color typeColor;
    
    switch (module.type) {
      case 'video':
        typeIcon = Icons.play_circle;
        typeColor = Colors.red;
        break;
      case 'article':
        typeIcon = Icons.article;
        typeColor = Colors.blue;
        break;
      case 'exercise':
        typeIcon = Icons.fitness_center;
        typeColor = Colors.orange;
        break;
      case 'project':
        typeIcon = Icons.code;
        typeColor = Colors.purple;
        break;
      default:
        typeIcon = Icons.book;
        typeColor = Colors.grey;
    }

    final hasResources = _moduleResources.containsKey(index) && _moduleResources[index] != null;
    final isLoading = _loadingModules.contains(index);
    final resources = _moduleResources[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: hasResources ? Colors.green : const Color(0xFF6B46C1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: hasResources 
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '$index',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (index < _learningPath!.modules.length)
                Container(
                  width: 2,
                  height: hasResources ? 200 : 80,
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Module content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: hasResources ? Colors.green[300]! : Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(typeIcon, size: 20, color: typeColor),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          module.type.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        module.duration,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    module.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Find Resources Button or Resources List
                  if (!hasResources && !isLoading)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _loadModuleResources(index, module.title),
                        icon: const Icon(Icons.search, size: 18),
                        label: Text(
                          'Find Learning Resources',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  // Show resources when loaded
                  if (hasResources && resources != null) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    // Videos
                    if (resources.videos.isNotEmpty) ...[
                      Text(
                        '📺 Videos',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ...resources.videos.take(3).map((video) => _buildMiniVideoCard(video)),
                      const SizedBox(height: 12),
                    ],

                    // Courses
                    if (resources.courses.isNotEmpty) ...[
                      Text(
                        '🎓 Courses',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ...resources.courses.take(2).map((course) => _buildMiniCourseCard(course)),
                      const SizedBox(height: 12),
                    ],

                    // Articles
                    if (resources.articles.isNotEmpty) ...[
                      Text(
                        '📖 Articles',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      ...resources.articles.take(2).map((article) => _buildMiniArticleCard(article)),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniVideoCard(VideoResource video) {
    return GestureDetector(
      onTap: () => _launchVideo(video.youtubeUrl),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                video.thumbnailUrl,
                width: 60,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 40,
                  color: Colors.grey[300],
                  child: const Icon(Icons.play_circle, size: 24, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${video.channel} • ${video.duration}',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_arrow, color: Colors.red[600], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCourseCard(CourseResource course) {
    return GestureDetector(
      onTap: () => _launchVideo(course.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.school, color: Colors.blue[600], size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${course.platform} • ${course.duration}',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (course.isFree)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'FREE',
                  style: GoogleFonts.inter(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniArticleCard(ArticleResource article) {
    return GestureDetector(
      onTap: () => _launchVideo(article.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.article, color: Colors.purple[600], size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${article.source} • ${article.readTime} read',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, color: Colors.purple[600], size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorTab() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6B46C1).withOpacity(0.1),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6B46C1),
                child: const Icon(Icons.psychology, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat with Thrive',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your AI Career Mentor',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Chat Messages
        Expanded(
          child: _chatHistory.isEmpty
              ? _buildEmptyChat()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatHistory.length + (_isChatting ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _chatHistory.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _buildChatBubble(_chatHistory[index]);
                  },
                ),
        ),

        // Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Ask about career advice, skills, job search...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6B46C1),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _isChatting ? null : _sendChatMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChat() {
    final suggestions = [
      'How can I transition into tech?',
      'What skills do I need for data science?',
      'How do I negotiate a salary?',
      'Tips for networking effectively',
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Hi! I\'m Thrive, your AI career mentor.',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about career development, skills, or job searching.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Text(
            'Try asking:',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: suggestions.map((s) => ActionChip(
              label: Text(s, style: GoogleFonts.inter(fontSize: 12)),
              onPressed: () {
                _chatController.text = s;
                _sendChatMessage();
              },
              backgroundColor: const Color(0xFF6B46C1).withOpacity(0.1),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6B46C1),
              child: const Icon(Icons.psychology, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF6B46C1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message['content'] ?? '',
                style: GoogleFonts.inter(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

