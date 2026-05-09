import 'package:flutter/material.dart';

import '../presentation/exam_screen/exam_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/results_screen/results_screen.dart';
import '../presentation/analytics_screen/analytics_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String homeScreen = '/home-screen';
  static const String examScreen = '/exam-screen';
  static const String resultsScreen = '/results-screen';
  static const String analyticsScreen = '/analytics-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const HomeScreen(),
    homeScreen: (context) => const HomeScreen(),
    examScreen: (context) => const ExamScreen(),
    resultsScreen: (context) => const ResultsScreen(),
    analyticsScreen: (context) => const AnalyticsScreen(),
  };
}
