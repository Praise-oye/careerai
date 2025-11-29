const { onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const OpenAI = require("openai");

admin.initializeApp();

// Define OpenAI API key as a secret
const openaiKey = defineSecret("OPENAI_API_KEY");

// Region configuration
const REGION = "europe-west3";

// Initialize OpenAI client
const getOpenAI = (apiKey) => {
  if (!apiKey) {
    throw new Error("OpenAI API key not configured");
  }
  return new OpenAI({ apiKey });
};

// Chat completion endpoint - handles interview questions and feedback
exports.chatCompletion = onCall({ cors: true, secrets: [openaiKey], region: REGION }, async (request) => {
  const data = request.data;

  try {
    const { messages, temperature = 0.7, max_tokens = 2000 } = data;

    if (!messages || !Array.isArray(messages)) {
      throw new Error("Messages array required");
    }

    const openai = getOpenAI(openaiKey.value());

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: messages,
      temperature: temperature,
      max_tokens: max_tokens,
    });

    return {
      content: completion.choices[0].message.content,
      usage: completion.usage,
    };
  } catch (error) {
    console.error("OpenAI API error:", error);
    throw new Error(error.message || "Failed to get AI response");
  }
});

// Interview question generator - STRICT MODE
exports.getInterviewQuestion = onCall({ cors: true, secrets: [openaiKey], region: REGION }, async (request) => {
  const data = request.data;

  try {
    const { field, position, company, questionNumber = 1 } = data;

    const openai = getOpenAI(openaiKey.value());

    const prompt = `Generate a CHALLENGING interview question for a ${position || "job"} position.
${field ? `Industry: ${field}` : ""}
${company ? `Company: ${company}` : ""}
Question number: ${questionNumber}

IMPORTANT: Act as a STRICT, DEMANDING interviewer from a top company. Generate questions that:
- Are difficult and require deep thinking
- Test real competency, not just theoretical knowledge
- Probe for specific examples and measurable results
- Challenge the candidate to demonstrate their expertise
- Cannot be answered with generic, rehearsed responses

Question types based on stage:
- Q1-2: Behavioral questions requiring SPECIFIC examples with metrics
- Q3-4: Technical/situational questions that test problem-solving
- Q5+: Pressure questions, hypotheticals, or "tell me about a failure"

Make it the kind of question that would be asked at Google, McKinsey, or Goldman Sachs.

Generate ONLY the question, nothing else.`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: "You are a strict, no-nonsense senior interviewer at a top-tier company. You ask tough, probing questions that separate exceptional candidates from average ones. You don't accept vague answers.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.8,
      max_tokens: 500,
    });

    return { question: completion.choices[0].message.content.trim() };
  } catch (error) {
    console.error("Error:", error);
    throw new Error(error.message);
  }
});

// Interview feedback generator - STRICT SCORING
exports.getInterviewFeedback = onCall({ cors: true, secrets: [openaiKey], region: REGION }, async (request) => {
  const data = request.data;

  try {
    const { question, userAnswer, field, position } = data;

    const openai = getOpenAI(openaiKey.value());

    const prompt = `You are a STRICT interview evaluator at a top company. Analyze this response with HIGH STANDARDS:

QUESTION: ${question}
CANDIDATE'S ANSWER: ${userAnswer}
ROLE: ${position || "Not specified"}
INDUSTRY: ${field || "Not specified"}

SCORING GUIDELINES (Be STRICT - most candidates should score 40-70):
- 90-100: Exceptional - Would immediately hire. Specific metrics, clear STAR format, compelling story
- 75-89: Strong - Good hire potential. Solid examples but missing some depth
- 60-74: Average - Needs improvement. Generic answers, lacks specifics
- 40-59: Below Average - Significant gaps. Vague, no real examples
- 0-39: Poor - Would not advance. Rambling, off-topic, or no substance

EVALUATE HARSHLY ON:
1. **Specificity** - Did they give EXACT numbers, dates, outcomes? Or vague generalities?
2. **Structure** - Did they use STAR method? Or ramble without clear organization?
3. **Relevance** - Did they actually answer the question asked?
4. **Impact** - Did they show measurable results? Or just describe activities?
5. **Authenticity** - Does it sound like a real experience or a rehearsed script?

CRITICAL FEEDBACK REQUIREMENTS:
- Point out EXACTLY what was weak or missing
- Don't sugarcoat - be direct about deficiencies
- Identify filler words, vague phrases, and missed opportunities
- Note if the answer was too short, too long, or off-topic

Return as JSON:
{
  "overallScore": 0-100,
  "detailedAnalysis": {
    "communication": {"score": 0-100, "feedback": "Be specific about clarity issues, filler words, pacing"},
    "structure": {"score": 0-100, "feedback": "Did they use STAR? Was it organized or rambling?"},
    "examples": {"score": 0-100, "feedback": "Were examples specific with metrics? Or generic?"},
    "roleRelevance": {"score": 0-100, "feedback": "How well did this demonstrate fit for ${position || 'the role'}?"}
  },
  "strengths": ["Be specific - what exactly did they do well?"],
  "improvements": ["Be direct - what MUST they fix? Give actionable items"],
  "overallFeedback": "Honest, direct assessment. What would a hiring manager think?",
  "exampleResponses": ["Provide 2-3 EXCELLENT example answers that would score 85+"]
}`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: "You are a demanding interview coach who has hired hundreds of people at top companies. You have VERY high standards. You give honest, sometimes harsh feedback because you want candidates to actually improve. You never give inflated scores - a 70 is a genuinely good answer. You point out every weakness clearly.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.6,
      max_tokens: 2500,
    });

    return { feedback: completion.choices[0].message.content.trim() };
  } catch (error) {
    console.error("Error:", error);
    throw new Error(error.message);
  }
});

// Interview Simulation - Realistic interview flow
exports.simulateInterview = onCall({ cors: true, secrets: [openaiKey], region: REGION }, async (request) => {
  const data = request.data;

  try {
    const { 
      stage, // 'intro', 'question', 'followup', 'closing'
      position, 
      company,
      field,
      questionNumber = 1,
      totalQuestions = 5,
      previousAnswer,
      previousQuestion,
      interviewerName = 'Arya',
      candidateName = 'Candidate'
    } = data;

    const openai = getOpenAI(openaiKey.value());

    let prompt = '';
    let systemPrompt = `You are ${interviewerName}, an AI Interview Coach and Senior Hiring Manager conducting a REAL job interview for ${position || 'this role'} at ${company || 'a leading company'}. You are professional, thorough, and ask probing questions. You speak naturally and warmly, but maintain high standards. You're known for your tough but fair interview style.`;

    if (stage === 'intro') {
      prompt = `Give a brief professional introduction (3-4 sentences max). Greet warmly, introduce yourself as Arya, mention ${totalQuestions} questions, and ask if ready to begin.`;
    } 
    else if (stage === 'question') {
      const questionType = questionNumber <= 2 ? 'behavioral' :
                          questionNumber <= 4 ? 'situational' : 'challenging';
      
      prompt = `Ask ONE ${questionType} interview question for ${position || 'this role'}. Question #${questionNumber}/${totalQuestions}. Be direct and specific. Output ONLY the question.`;
    }
    else if (stage === 'followup') {
      prompt = `Brief response to: "${previousAnswer}". Either acknowledge and move on, or ask ONE short follow-up. Max 2 sentences.`;
    }
    else if (stage === 'closing') {
      prompt = `End the interview in 2-3 sentences. Thank them, mention next steps, and wish them well.`;
    }

    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: prompt },
      ],
      temperature: 0.7,
      max_tokens: 250,
    });

    return { 
      response: completion.choices[0].message.content.trim(),
      stage: stage,
      questionNumber: questionNumber,
      interviewerName: interviewerName
    };
  } catch (error) {
    console.error("Error:", error);
    throw new Error(error.message);
  }
});

// Generate final interview report
exports.getInterviewReport = onCall({ cors: true, secrets: [openaiKey], region: REGION }, async (request) => {
  const data = request.data;

  try {
    const { 
      position,
      company,
      questionsAndAnswers, // Array of {question, answer, score}
      overallScores,
      candidateName = 'Candidate'
    } = data;

    const openai = getOpenAI(openaiKey.value());

    const qaList = questionsAndAnswers.map((qa, i) => 
      `Q${i+1}: ${qa.question}\nAnswer: ${qa.answer}\nScore: ${qa.score}/100`
    ).join('\n\n');

    const avgScore = overallScores.reduce((a, b) => a + b, 0) / overallScores.length;

    const prompt = `Generate a comprehensive interview report for ${candidateName} who interviewed for ${position || 'this role'} at ${company || 'the company'}.

INTERVIEW SUMMARY:
${qaList}

Average Score: ${avgScore.toFixed(0)}/100

Generate a professional interview report with:
1. **Overall Verdict**: Would you hire? (Strong Hire / Hire / Maybe / No Hire)
2. **Summary**: 2-3 sentence overview of performance
3. **Key Strengths**: Top 3 things they did well
4. **Areas for Development**: Top 3 things to improve
5. **Recommendation**: Specific advice for their next interview
6. **Score Breakdown**: Communication, Technical/Role Fit, Problem Solving, Cultural Fit (each /100)

Be honest and constructive. This should feel like a real post-interview debrief.`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: "You are a senior recruiter writing a post-interview report. Be professional, honest, and constructive.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.6,
      max_tokens: 1500,
    });

    return { 
      report: completion.choices[0].message.content.trim(),
      averageScore: avgScore,
      verdict: avgScore >= 80 ? 'Strong Hire' : avgScore >= 65 ? 'Hire' : avgScore >= 50 ? 'Maybe' : 'No Hire'
    };
  } catch (error) {
    console.error("Error:", error);
    throw new Error(error.message);
  }
});

// Skill assessment endpoint
exports.assessSkills = onCall({ cors: true, secrets: [openaiKey], region: REGION }, async (request) => {
  const data = request.data;

  try {
    const { currentRole, targetRole, currentSkills, industry } = data;

    const openai = getOpenAI(openaiKey.value());

    const prompt = `As a strict career advisor, provide a REALISTIC skill gap assessment for:

Current Role: "${currentRole}"
Target Role: "${targetRole}"
Industry: ${industry || "Not specified"}
Current Skills: ${currentSkills?.join(", ") || "Not specified"}

Be HONEST and DIRECT:
- Don't inflate their current levels to make them feel good
- Identify the REAL gaps that could prevent them from getting hired
- Give brutally honest feedback about what they're missing
- Provide specific, actionable steps (not generic advice)

Return as JSON array:
[
  {
    "skillName": "Specific skill name",
    "currentLevel": 1-10 (be realistic, most people are 3-6),
    "targetLevel": 1-10 (what top companies expect),
    "feedback": "Honest assessment of their gap and why it matters",
    "recommendations": ["Specific action 1", "Specific action 2", "Specific action 3"]
  }
]

Include 5-7 CRITICAL skills. Focus on what will actually get them hired or rejected.`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: "You are a tough but fair career advisor. You give realistic assessments, not feel-good feedback. You've seen too many people fail because no one told them the truth about their gaps.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.7,
      max_tokens: 2000,
    });

    return { assessment: completion.choices[0].message.content.trim() };
  } catch (error) {
    console.error("Error:", error);
    throw new Error(error.message);
  }
});

// Learning path generator
exports.generateLearningPath = onCall({ cors: true, secrets: [openaiKey], region: REGION }, async (request) => {
  const data = request.data;

  try {
    const { targetRole, skillsToImprove, learningStyle, timeAvailable } = data;

    const openai = getOpenAI(openaiKey.value());

    const prompt = `Create an INTENSIVE learning path for someone serious about becoming a "${targetRole}".

Skills to develop: ${skillsToImprove?.join(", ") || "general skills"}
${learningStyle ? `Learning style: ${learningStyle}` : ""}
${timeAvailable ? `Time available: ${timeAvailable}` : ""}

This should be a RIGOROUS program that will actually prepare them, not a gentle introduction.

Return as JSON:
{
  "title": "Intensive Path to ${targetRole}",
  "description": "What they'll achieve and the commitment required",
  "estimatedTime": "X weeks/months (be realistic)",
  "difficulty": "beginner/intermediate/advanced",
  "modules": [
    {
      "title": "Module name",
      "description": "What they'll learn and why it matters",
      "type": "video/article/exercise/project",
      "duration": "X hours",
      "deliverable": "What they should produce to prove mastery"
    }
  ]
}

Include 8-12 challenging modules with real deliverables.`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: "You create intensive, no-fluff learning paths. Every module has a clear purpose and deliverable. You don't waste people's time with theory - you focus on what actually gets results.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.7,
      max_tokens: 2500,
    });

    return { learningPath: completion.choices[0].message.content.trim() };
  } catch (error) {
    console.error("Error:", error);
    throw new Error(error.message);
  }
});

// Career mentor chat
exports.mentorChat = onCall({ cors: true, secrets: [openaiKey], region: REGION }, async (request) => {
  const data = request.data;

  try {
    const { message, conversationHistory, userContext } = data;

    const openai = getOpenAI(openaiKey.value());

    const messages = [
      {
        role: "system",
        content: `You are Arya, a direct and honest career mentor. You care about people's success, which means you:

- Give HONEST feedback, even when it's uncomfortable
- Don't sugarcoat reality about job markets or competition
- Push people to be specific and take action
- Challenge vague goals or unrealistic timelines
- Share hard truths that others won't tell them

You're supportive but not soft. You want them to succeed, so you tell them what they NEED to hear, not what they want to hear.

${userContext ? `Context: ${userContext}` : ""}`,
      },
    ];

    if (conversationHistory && Array.isArray(conversationHistory)) {
      messages.push(...conversationHistory);
    }
    messages.push({ role: "user", content: message });

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: messages,
      temperature: 0.7,
      max_tokens: 1000,
    });

    return { response: completion.choices[0].message.content.trim() };
  } catch (error) {
    console.error("Error:", error);
    throw new Error(error.message);
  }
});

// Get learning resources for a skill
exports.getLearningResources = onCall({ cors: true, secrets: [openaiKey], region: REGION }, async (request) => {
  const data = request.data;

  try {
    const { skill, targetRole, difficulty = "beginner" } = data;

    const openai = getOpenAI(openaiKey.value());

    const prompt = `Find the BEST free learning resources for "${skill}"${targetRole ? ` for someone becoming a ${targetRole}` : ""}.
Difficulty: ${difficulty}

Provide REAL, EXISTING resources with actual URLs and YouTube video IDs:

Return as JSON:
{
  "skill": "${skill}",
  "videos": [
    {
      "title": "Video title",
      "channel": "Channel name (freeCodeCamp, Traversy Media, CS50, etc.)",
      "videoId": "actual_11_char_youtube_id",
      "duration": "X:XX:XX",
      "description": "Why this video is valuable",
      "difficulty": "beginner/intermediate/advanced"
    }
  ],
  "courses": [
    {
      "title": "Course name",
      "platform": "Coursera/edX/Khan Academy/freeCodeCamp",
      "url": "https://actual-url.com",
      "duration": "X hours/weeks",
      "description": "What you'll learn",
      "isFree": true
    }
  ],
  "articles": [
    {
      "title": "Article title",
      "source": "MDN/Official Docs/Dev.to",
      "url": "https://actual-url.com",
      "description": "Why read this",
      "readTime": "X min"
    }
  ],
  "projectIdeas": [
    {
      "title": "Project name",
      "description": "Build this to practice",
      "skills": ["skill1", "skill2"],
      "difficulty": "beginner/intermediate/advanced"
    }
  ]
}

Include 5-7 videos, 3-4 courses, 3-4 articles, 2-3 projects. Use REAL resources only.`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: "You are an expert curator of educational content. You know real YouTube video IDs, actual course URLs, and legitimate learning resources. Only recommend resources that actually exist.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.5,
      max_tokens: 3000,
    });

    return { resources: completion.choices[0].message.content.trim() };
  } catch (error) {
    console.error("Error:", error);
    throw new Error(error.message);
  }
});

// Generate ATS-optimized CV
exports.generateATSCV = onCall({ cors: true, secrets: [openaiKey], region: REGION }, async (request) => {
  const data = request.data;

  try {
    const { 
      targetRole, 
      currentRole,
      skills,
      experience,
      education,
      projects,
      achievements,
      personalInfo 
    } = data;

    const openai = getOpenAI(openaiKey.value());

    const prompt = `Generate an ATS-OPTIMIZED CV using the EXACT information provided below. DO NOT invent or change any facts - only enhance the wording to be more professional and ATS-friendly.

=== CANDIDATE INFORMATION ===
Full Name: ${personalInfo?.name || "Not provided"}
Email: ${personalInfo?.email || "Not provided"}
Phone: ${personalInfo?.phone || "Not provided"}
Address: ${personalInfo?.address || "South Africa"}
LinkedIn: ${personalInfo?.linkedin || ""}
GitHub: ${personalInfo?.github || ""}
Portfolio: ${personalInfo?.portfolio || ""}

Target Position: ${targetRole}
Professional Summary provided: ${personalInfo?.summary || "Not provided"}

=== SKILLS ===
${skills?.join(", ") || "Not provided"}

Languages: ${personalInfo?.languages || "Not provided"}

=== WORK EXPERIENCE ===
${experience || "No experience provided"}

=== EDUCATION ===
${education || "No education provided"}

=== CERTIFICATIONS ===
${achievements || "No certifications provided"}

=== PROJECTS ===
${projects || "No projects provided"}

=== INSTRUCTIONS ===
Create THREE versions of the professional summary:
1. originalSummary: Return their exact summary as-is
2. polishedSummary: Refine their summary to sound more professional (keep same meaning)
3. atsSummary: Create a powerful ATS-optimized summary with industry keywords, metrics, and standout phrases for ${targetRole}

For SKILLS:
- polishedSkills: Use ONLY skills from input, organized into categories
- atsSkills: Add relevant industry-standard skills for ${targetRole} that would help them stand out

For EXPERIENCE: Create polished bullet points using the information given

Return ONLY valid JSON in this exact format:
{
  "originalSummary": "${personalInfo?.summary || ''}",
  "polishedSummary": "Professional version of their summary keeping same meaning",
  "atsSummary": "Powerful ATS-optimized summary with keywords, metrics language, and standout phrases for ${targetRole}. Make it compelling and include industry buzzwords.",
  "professionalSummary": "",
  "skills": {
    "technical": ["ONLY skills from input that are technical"],
    "soft": ["ONLY skills from input that are soft skills"],
    "tools": ["ONLY skills from input that are tools"]
  },
  "atsSkills": {
    "technical": ["Original technical skills PLUS additional relevant skills for ${targetRole}"],
    "soft": ["Original soft skills PLUS leadership, communication skills valued for ${targetRole}"],
    "tools": ["Original tools PLUS industry-standard tools for ${targetRole}"]
  },
  "experience": [
    {
      "title": "EXACT job title from input",
      "company": "EXACT company name from input", 
      "duration": "EXACT dates from input",
      "bullets": ["Polished version of their experience description"]
    }
  ],
  "education": [
    {
      "degree": "EXACT degree from input",
      "institution": "EXACT institution from input",
      "year": "EXACT year from input",
      "highlights": []
    }
  ],
  "projects": ["EXACT project names from input"],
  "certifications": ["EXACT certifications from input"],
  "atsKeywords": ["powerful keywords for ${targetRole} that ATS systems scan for"],
  "improvementTips": ["Specific tips to improve this CV"]
}`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: "You are an expert ATS CV writer. Your job is to take the user's EXACT information and format it into an ATS-optimized CV. NEVER invent information - only use what is provided. Enhance wording to be professional but keep all facts accurate.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.3,
      max_tokens: 3500,
    });

    return { cv: completion.choices[0].message.content.trim() };
  } catch (error) {
    console.error("Error:", error);
    throw new Error(error.message);
  }
});

// Search for real job listings
exports.searchJobs = onCall({ cors: true, secrets: [openaiKey], region: REGION }, async (request) => {
  const data = request.data;

  try {
    const { targetRole, location = "South Africa", experience = "entry", skills } = data;

    const openai = getOpenAI(openaiKey.value());

    const prompt = `Find REAL job opportunities for "${targetRole}" in ${location}.

Experience level: ${experience}
${skills ? `Key skills: ${skills.join(", ")}` : ""}

Provide actual job listings that exist on major job boards. Include:
1. Real company names hiring for this role in ${location}
2. Actual job board URLs where they can apply
3. Salary ranges typical for ${location}
4. Key requirements

Return as JSON:
{
  "searchQuery": "${targetRole}",
  "location": "${location}",
  "totalEstimated": "Approximate number of openings",
  "salaryRange": {
    "min": "R XX,XXX",
    "max": "R XX,XXX",
    "currency": "ZAR"
  },
  "jobs": [
    {
      "title": "Exact job title",
      "company": "Real company name",
      "location": "City, Country",
      "type": "Full-time/Part-time/Contract/Remote",
      "salary": "R XX,XXX - R XX,XXX per month (if available)",
      "description": "Brief job description",
      "requirements": ["Req 1", "Req 2", "Req 3"],
      "applyUrl": "https://actual-job-board-link.com",
      "source": "LinkedIn/Indeed/Careers24/PNet/Glassdoor",
      "postedDate": "Recent/This week/This month"
    }
  ],
  "jobBoards": [
    {
      "name": "Job Board Name",
      "searchUrl": "https://jobboard.com/search?q=${encodeURIComponent(targetRole)}&location=${encodeURIComponent(location)}",
      "description": "Best for X type of jobs"
    }
  ],
  "tips": ["Tip for applying to ${targetRole} roles", "What companies look for"]
}

Include 8-10 realistic job opportunities from real South African companies and job boards.
Use actual job board search URLs that will show relevant results.`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: "You are a job market expert for South Africa. You know real companies, actual salary ranges, and legitimate job boards. Provide realistic, actionable job search results with real URLs to job boards.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.6,
      max_tokens: 3500,
    });

    return { jobs: completion.choices[0].message.content.trim() };
  } catch (error) {
    console.error("Error:", error);
    throw new Error(error.message);
  }
});
