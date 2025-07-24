import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final String? additionalDetail;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    this.additionalDetail,
  });
}

class OnboardingData {
  static List<OnboardingItem> get items => [
    OnboardingItem(
      title: "Welcome to LifeLog",
      description:
          "Your personal journal for daily reflections, mood tracking, and capturing life's moments.",
      icon: PhosphorIcons.book(),
      gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      additionalDetail: "Start your journaling journey today",
    ),
    OnboardingItem(
      title: "Track Your Mood",
      description:
          "Rate your daily mood from 1-5 and discover patterns in your emotional well-being over time.",
      icon: PhosphorIcons.smiley(),
      gradientColors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      additionalDetail: "Understand your emotional patterns",
    ),
    OnboardingItem(
      title: "One Entry Per Day",
      description:
          "Focus on quality over quantity. Create one meaningful journal entry each day with your thoughts and feelings.",
      icon: PhosphorIcons.calendar(),
      gradientColors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
      additionalDetail: "Quality journaling made simple",
    ),
    OnboardingItem(
      title: "Secure & Private",
      description:
          "Your thoughts are safe with bank-level security. Only you can access your personal journal entries.",
      icon: PhosphorIcons.shield(),
      gradientColors: [Color(0xFFF59E0B), Color(0xFF10B981)],
      additionalDetail: "Your privacy is our priority",
    ),
    OnboardingItem(
      title: "Start Your Journey",
      description:
          "Ready to begin? Sign up now and write your first journal entry. Your future self will thank you.",
      icon: PhosphorIcons.rocketLaunch(),
      gradientColors: [Color(0xFF10B981), Color(0xFF06B6D4)],
      additionalDetail: "Let's create something beautiful together",
    ),
  ];
}
