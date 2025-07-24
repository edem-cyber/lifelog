import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

class AnimatedSplashScreen extends ConsumerStatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  ConsumerState<AnimatedSplashScreen> createState() =>
      _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends ConsumerState<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _startSplashSequence();
  }

  void _startSplashSequence() async {
    // Start animations
    _backgroundController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    // Wait for animations to complete and check app state
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      _navigateBasedOnState();
    }
  }

  void _navigateBasedOnState() {
    final hasOnboarded = ref.read(hasCompletedOnboardingProvider);
    final isAuthenticated = ref.read(isAuthenticatedProvider);

    if (!hasOnboarded) {
      context.go('/onboarding');
    } else if (!isAuthenticated) {
      context.go('/auth');
    } else {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.secondary,
              AppColors.tertiary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated Logo Section
              _buildAnimatedLogo(),

              const SizedBox(height: 32),

              // Animated Text
              _buildAnimatedText(),

              const Spacer(flex: 2),

              // Loading indicator
              _buildLoadingIndicator(),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoController.value,
          child: Transform.rotate(
            angle: _logoController.value * 0.5,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(Icons.book, size: 40, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Opacity(
          opacity: _textController.value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - _textController.value)),
            child: Column(
              children: [
                Text(
                  'LifeLog',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 48,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'by OppX',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Daily Journal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w300,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Opacity(
          opacity: _backgroundController.value * 0.8,
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.8),
              ),
              strokeWidth: 3,
            ),
          ),
        );
      },
    );
  }
}

// Alternative Lottie Animation Splash Screen
class LottieSplashScreen extends ConsumerStatefulWidget {
  const LottieSplashScreen({super.key});

  @override
  ConsumerState<LottieSplashScreen> createState() => _LottieSplashScreenState();
}

class _LottieSplashScreenState extends ConsumerState<LottieSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      final hasOnboarded = ref.read(hasCompletedOnboardingProvider);
      final isAuthenticated = ref.read(isAuthenticatedProvider);

      if (!hasOnboarded) {
        context.go('/onboarding');
      } else if (!isAuthenticated) {
        context.go('/auth');
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie.asset(
              //   'assets/lottie/lifelog_animation.json',
              //   width: 200,
              //   height: 200,
              //   fit: BoxFit.cover,
              // ),
              Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.book,
                      size: 80,
                      color: Colors.white,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    duration: 2000.ms,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(0.8, 0.8),
                    duration: 2000.ms,
                  ),

              const SizedBox(height: 32),

              Text(
                    'LifeLog',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 1000.ms)
                  .slideY(begin: 0.3, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class RiveSplashScreen extends ConsumerStatefulWidget {
  const RiveSplashScreen({super.key});

  @override
  ConsumerState<RiveSplashScreen> createState() => _RiveSplashScreenState();
}

class _RiveSplashScreenState extends ConsumerState<RiveSplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SizedBox(
              //   width: 300,
              //   height: 300,
              //   child: RiveAnimation.asset('assets/rive/lifelog_logo.riv'),
              // ),
              Text(
                'Add your Rive animation here',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
