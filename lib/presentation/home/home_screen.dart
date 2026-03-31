import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:playingkorean/core/presentation/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pointGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Playing Korean!',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '동음이의어 카드 게임',
              style: TextStyle(
                fontSize: 24,
                color: AppTheme.text.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => context.go('/quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.background,
                foregroundColor: AppTheme.pointGreen,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: const Text(
                '게임 시작!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
