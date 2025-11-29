/// API Keys Configuration
/// 
/// API keys are now securely stored on the server (Firebase Cloud Functions).
/// This file is kept for backwards compatibility but keys are no longer needed here.
/// 
/// To set up your API key on the server:
/// 1. cd functions
/// 2. npm install
/// 3. firebase functions:config:set openai.key="sk-your-key-here"
/// 4. firebase deploy --only functions

class ApiKeys {
  // Keys are now on the server - no longer needed in frontend
  static String? get openAI => null;
  static String? get gemini => null;
  
  // Always return true since the server handles the API key
  static bool get hasApiKey => true;
}
