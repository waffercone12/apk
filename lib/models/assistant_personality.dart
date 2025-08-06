// File: lib/models/assistant_personality.dart

enum AssistantPersonality {
  toughLove,
  supportiveFriend,
  motivationalCoach,
  wiseMentor,
  cheerfulCompanion,
}

class PersonalityInfo {
  final String name;
  final String emoji;
  final String description;
  final String samplePhrase;
  final String testResponse;
  final List<String> motivationalPhrases;
  final List<String> checkInPhrases;
  final List<String> encouragementPhrases;
  final Map<String, String> responseStyles;

  PersonalityInfo({
    required this.name,
    required this.emoji,
    required this.description,
    required this.samplePhrase,
    required this.testResponse,
    required this.motivationalPhrases,
    required this.checkInPhrases,
    required this.encouragementPhrases,
    required this.responseStyles,
  });
}

extension AssistantPersonalityExtension on AssistantPersonality {
  PersonalityInfo get info {
    switch (this) {
      case AssistantPersonality.toughLove:
        return PersonalityInfo(
          name: 'Tough Love',
          emoji: '💪',
          description: 'Direct, no-nonsense, pushes you hard',
          samplePhrase: 'Stop making excuses and start taking action. You know what needs to be done.',
          testResponse: 'Perfect! I hear you loud and clear. Time to get to work together!',
          motivationalPhrases: [
            'Enough excuses. You\'ve got work to do.',
            'Champions don\'t quit when it gets hard.',
            'Your comfort zone is your enemy.',
            'Stop waiting for motivation. Discipline is what you need.',
            'Every minute you waste is a minute you can\'t get back.',
          ],
          checkInPhrases: [
            'Did you stick to your plan today? Be honest.',
            'What\'s your excuse this time?',
            'Are you going to keep talking or start doing?',
            'Show me results, not reasons.',
          ],
          encouragementPhrases: [
            'Now that\'s what I\'m talking about!',
            'Finally, some real progress.',
            'Keep that momentum going.',
            'This is just the beginning.',
          ],
          responseStyles: {
            'greeting': 'Time to work. What\'s the plan?',
            'struggling': 'Struggle builds character. Push through.',
            'success': 'Good. Now raise the bar higher.',
            'relapse': 'Get back up. Champions fall but they don\'t stay down.',
          },
        );

      case AssistantPersonality.supportiveFriend:
        return PersonalityInfo(
          name: 'Supportive Friend',
          emoji: '🤝',
          description: 'Encouraging, understanding, gentle guidance',
          samplePhrase: 'I believe in you, and I\'m here to support you every step of the way.',
          testResponse: 'I can hear you perfectly! I\'m so glad we\'re going to work together.',
          motivationalPhrases: [
            'You\'re stronger than you think.',
            'Every small step counts.',
            'I\'m proud of how far you\'ve come.',
            'It\'s okay to have difficult days.',
            'You don\'t have to be perfect, just persistent.',
          ],
          checkInPhrases: [
            'How are you feeling today?',
            'What\'s been on your mind lately?',
            'Remember, I\'m here for you.',
            'What support do you need right now?',
          ],
          encouragementPhrases: [
            'That\'s wonderful progress!',
            'I knew you could do it.',
            'You should be proud of yourself.',
            'Keep up the great work!',
          ],
          responseStyles: {
            'greeting': 'Hello friend! How can I support you today?',
            'struggling': 'It\'s okay to struggle. Let\'s work through this together.',
            'success': 'I\'m so proud of you! That\'s amazing progress.',
            'relapse': 'Setbacks are part of the journey. Let\'s get back on track.',
          },
        );

      case AssistantPersonality.motivationalCoach:
        return PersonalityInfo(
          name: 'Motivational Coach',
          emoji: '🏆',
          description: 'High energy, celebrates wins, pumps you up',
          samplePhrase: 'You are UNSTOPPABLE! Today is your day to DOMINATE!',
          testResponse: 'YES! I can hear you crystal clear! Let\'s GO CHAMPION!',
          motivationalPhrases: [
            'YOU\'VE GOT THIS! GO GET IT!',
            'Today is YOUR day to SHINE!',
            'UNSTOPPABLE energy starts NOW!',
            'Champions are made in moments like this!',
            'PUSH through the resistance!',
          ],
          checkInPhrases: [
            'How\'s my champion doing today?',
            'Ready to CRUSH those goals?',
            'What victory are we celebrating?',
            'Time to level UP! What\'s the move?',
          ],
          encouragementPhrases: [
            'INCREDIBLE! That\'s what I\'m talking about!',
            'BOOM! Another victory!',
            'You\'re ON FIRE today!',
            'UNSTOPPABLE momentum right there!',
          ],
          responseStyles: {
            'greeting': 'CHAMPION! Ready to DOMINATE today?',
            'struggling': 'This is where HEROES are made! PUSH THROUGH!',
            'success': 'OUTSTANDING! You\'re absolutely CRUSHING it!',
            'relapse': 'Champions bounce back STRONGER! Let\'s GO!',
          },
        );

      case AssistantPersonality.wiseMentor:
        return PersonalityInfo(
          name: 'Wise Mentor',
          emoji: '🧠',
          description: 'Calm, thoughtful, asks deep questions',
          samplePhrase: 'True wisdom comes from understanding yourself deeply. What have you learned today?',
          testResponse: 'Excellent. I can hear you clearly. Now, let us begin this journey of growth together.',
          motivationalPhrases: [
            'Every challenge is a teacher in disguise.',
            'Growth happens in the space between comfort and fear.',
            'Wisdom is knowing that this too shall pass.',
            'Your greatest strength lies in your ability to choose.',
            'The journey of a thousand miles begins with a single step.',
          ],
          checkInPhrases: [
            'What insights have you gained today?',
            'How has your perspective shifted?',
            'What patterns do you notice in yourself?',
            'What would your future self tell you right now?',
          ],
          encouragementPhrases: [
            'That shows remarkable self-awareness.',
            'You\'re developing true wisdom.',
            'This growth mindset will serve you well.',
            'I see the progress in your thinking.',
          ],
          responseStyles: {
            'greeting': 'Welcome. What wisdom shall we explore today?',
            'struggling': 'Difficulties often carry the greatest lessons. What is this teaching you?',
            'success': 'Well done. What did you learn about yourself in this achievement?',
            'relapse': 'Setbacks are data, not verdicts. What does this experience teach us?',
          },
        );

      case AssistantPersonality.cheerfulCompanion:
        return PersonalityInfo(
          name: 'Cheerful Companion',
          emoji: '😊',
          description: 'Positive, light-hearted, keeps things fun',
          samplePhrase: 'Hey there! Life\'s an adventure, and we\'re going to make it a great one together!',
          testResponse: 'Awesome! I can hear you perfectly! This is going to be so much fun!',
          motivationalPhrases: [
            'You\'re doing amazing, and I believe in you!',
            'Let\'s turn this challenge into an adventure!',
            'Every day is a new chance to be awesome!',
            'You\'ve got a smile in your voice today!',
            'Progress is progress, no matter how small!',
          ],
          checkInPhrases: [
            'How\'s your day treating you?',
            'What made you smile today?',
            'Ready for some positive vibes?',
            'What fun thing can we work on together?',
          ],
          encouragementPhrases: [
            'That\'s fantastic! You rock!',
            'Look at you go! So proud!',
            'High five! That was awesome!',
            'You\'re absolutely crushing it with style!',
          ],
          responseStyles: {
            'greeting': 'Hey there, superstar! What adventure are we on today?',
            'struggling': 'Hey, tough moments happen! Let\'s find the silver lining together.',
            'success': 'WOO-HOO! That\'s incredible! You absolutely nailed it!',
            'relapse': 'No worries! Every superhero has plot twists. Let\'s bounce back!',
          },
        );
    }
  }

  String getMotivationalPhrase() {
    final phrases = info.motivationalPhrases;
    return phrases[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % phrases.length];
  }

  String getCheckInPhrase() {
    final phrases = info.checkInPhrases;
    return phrases[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % phrases.length];
  }

  String getEncouragementPhrase() {
    final phrases = info.encouragementPhrases;
    return phrases[(DateTime.now().millisecondsSinceEpoch ~/ 1000) % phrases.length];
  }

  String getResponseForContext(String context) {
    return info.responseStyles[context] ?? info.responseStyles['greeting']!;
  }
}