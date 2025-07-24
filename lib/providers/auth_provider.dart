import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

// Auth state using sealed classes (modern Dart pattern)
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

// Auth provider using AsyncNotifier (latest Riverpod pattern)
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    // Listen to auth state changes - this will handle all state updates
    SupabaseConfig.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;

      // Handle different auth events
      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          if (session?.user != null) {
            final user = UserModel(
              id: session!.user.id,
              email: session.user.email!,
              displayName: session.user.userMetadata?['display_name'],
              createdAt: DateTime.parse(session.user.createdAt),
            );
            state = AsyncValue.data(user);
          }
          break;
        case AuthChangeEvent.signedOut:
        case AuthChangeEvent.passwordRecovery:
        case AuthChangeEvent.userDeleted:
          state = const AsyncValue.data(null);
          break;
        default:
          // For other events, check session state
          if (session?.user != null) {
            final user = UserModel(
              id: session!.user.id,
              email: session.user.email!,
              displayName: session.user.userMetadata?['display_name'],
              createdAt: DateTime.parse(session.user.createdAt),
            );
            state = AsyncValue.data(user);
          } else {
            state = const AsyncValue.data(null);
          }
          break;
      }
    });

    // Wait for session restoration (important for web)
    await Future.delayed(const Duration(milliseconds: 200));

    // Check current session after waiting for restoration
    final session = SupabaseConfig.auth.currentSession;
    if (session?.user != null) {
      return UserModel(
        id: session!.user.id,
        email: session.user.email!,
        displayName: session.user.userMetadata?['display_name'],
        createdAt: DateTime.parse(session.user.createdAt),
      );
    }

    return null;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();

    // Add timeout protection
    Timer(const Duration(seconds: 30), () {
      if (state.isLoading) {
        state = AsyncValue.error(
          'Sign in timeout. Please try again.',
          StackTrace.current,
        );
      }
    });

    try {
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        state = AsyncValue.error(
          'Sign in failed - no session created',
          StackTrace.current,
        );
        return;
      }
    } on AuthException catch (e, stackTrace) {
      state = AsyncValue.error(e.message, stackTrace);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e.toString(), stackTrace);
    }
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();

    // Add timeout protection
    Timer(const Duration(seconds: 30), () {
      if (state.isLoading) {
        state = AsyncValue.error(
          'Sign up timeout. Please try again.',
          StackTrace.current,
        );
      }
    });

    try {
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        state = AsyncValue.error(
          'Sign up failed - no user created',
          StackTrace.current,
        );
        return;
      }
    } on AuthException catch (e, stackTrace) {
      if (e.message.contains('already_registered') ||
          e.message.contains('User already registered') ||
          e.message.contains('already exists')) {
        state = AsyncValue.error(
          'Account already exists. Try signing in instead.',
          stackTrace,
        );
      } else {
        state = AsyncValue.error(e.message, stackTrace);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e.toString(), stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
      // State managed by listener
    } catch (e, stackTrace) {
      state = AsyncValue.error(e.toString(), stackTrace);
    }
  }
}

// Provider instance
final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  () => AuthNotifier(),
);

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.asData?.value != null;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.asData?.value;
});
