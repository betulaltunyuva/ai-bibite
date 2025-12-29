import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_helper.dart';

class AuthService {
  final supabase = Supabase.instance.client;
  final _helper = SupabaseHelper();

  /// Sign up with email and password
  /// Creates user in Supabase auth and profile in profiles table
  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String name,
    required String surname,
  }) async {
    try {
      // Check if user already exists
      try {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        // If login succeeds, user already exists
        await supabase.auth.signOut();
        return {
          'success': false,
          'error': 'User already registered',
        };
      } catch (e) {
        // User doesn't exist, continue with signup
      }

      // Create user in Supabase auth
      final response = await _helper.executeWithRetry(
        operation: () => supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'name': name,
            'surname': surname,
          },
        ),
        silent: false, // Show errors for debugging
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Kullanıcı oluşturulamadı');
      }

      // Note: Supabase automatically sends email confirmation when "Confirm email" is enabled
      // If email doesn't arrive, check Supabase Dashboard -> Authentication -> Settings
      // Make sure "Confirm email" toggle is ON

      // Check if profile already exists
      final existingProfile = await _helper.executeQuerySilent(
        () => supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle(),
      );

      if (existingProfile == null) {
        // Create profile in profiles table
        try {
              await _helper.executeWithRetry(
                operation: () => supabase.from('profiles').insert({
                  'id': user.id,
                  'name': name,
                  'surname': surname,
                  'email': email,
                  // Note: is_info_completed column doesn't exist in the database
                }),
                silent: false, // Show errors for debugging
              );
        } catch (profileError) {
          // Log the error but don't fail completely
          // User can complete profile later
          print('Profile creation error: $profileError');
          // Don't throw, let user proceed - profile can be created in KVKK screen
        }
      }

      return {
        'success': true,
        'user': user,
      };
    } catch (e) {
      String errorMessage = e.toString();
      
      // Check for specific error types
      if (errorMessage.contains('User already registered') ||
          errorMessage.contains('already registered') ||
          errorMessage.contains('duplicate key')) {
        errorMessage = 'User already registered';
      } else if (errorMessage.contains('Password')) {
        errorMessage = 'Password too weak';
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  /// Login with email and password
  /// Returns user profile if successful
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with password
      await _helper.executeWithRetry(
        operation: () => supabase.auth.signInWithPassword(
          email: email,
          password: password,
        ),
        silent: true,
      );

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Giriş başarısız');
      }

      // Get user profile
      final profile = await _helper.executeQuerySilent(
        () => supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle(),
      );

      return {
        'success': true,
        'user': user,
        'profile': profile,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final profile = await _helper.executeQuerySilent(
        () => supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle(),
      );

      return profile;
    } catch (e) {
      return null;
    }
  }

  /// Verify OTP code sent to email
  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      // Verify the OTP token
      final response = await _helper.executeWithRetry(
        operation: () => supabase.auth.verifyOTP(
          type: OtpType.email,
          email: email,
          token: token,
        ),
        silent: false,
      );

      final user = response.user;
      if (user == null) {
        return {
          'success': false,
          'error': 'Kod doğrulanamadı',
        };
      }

      return {
        'success': true,
        'user': user,
      };
    } catch (e) {
      String errorMessage = e.toString();
      
      if (errorMessage.contains('Invalid') || errorMessage.contains('invalid')) {
        errorMessage = 'Geçersiz kod. Lütfen tekrar deneyin.';
      } else if (errorMessage.contains('expired') || errorMessage.contains('Expired')) {
        errorMessage = 'Kodun süresi dolmuş. Lütfen yeni kod isteyin.';
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  /// Resend OTP code to email
  Future<Map<String, dynamic>> resendOTP({
    required String email,
  }) async {
    try {
      await _helper.executeWithRetry(
        operation: () => supabase.auth.resend(
          type: OtpType.email,
          email: email,
        ),
        silent: false,
      );

      return {
        'success': true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Reset password - send recovery OTP to email
  /// Uses resetPasswordForEmail which sends an email with recovery token/OTP
  /// IMPORTANT: In Supabase Dashboard -> Authentication -> Email Templates -> "Reset Password",
  /// make sure the template includes {{ .Token }} to display the OTP code instead of a link.
  Future<Map<String, dynamic>> resetPasswordForEmail({
    required String email,
  }) async {
    try {
      // Send password reset email with OTP code
      // The email template must include {{ .Token }} to show the OTP code
      await _helper.executeWithRetry(
        operation: () => supabase.auth.resetPasswordForEmail(
          email,
          redirectTo: null, // We handle OTP verification in-app, not via redirect
        ),
        silent: false,
      );

      return {
        'success': true,
      };
    } catch (e) {
      String errorMessage = e.toString();
      
      if (errorMessage.contains('not found') || errorMessage.contains('does not exist')) {
        errorMessage = 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      } else if (errorMessage.contains('rate limit') || errorMessage.contains('too many')) {
        errorMessage = 'Çok fazla istek gönderildi. Lütfen birkaç dakika sonra tekrar deneyin.';
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  /// Verify OTP for password reset
  Future<Map<String, dynamic>> verifyPasswordResetOTP({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _helper.executeWithRetry(
        operation: () => supabase.auth.verifyOTP(
          type: OtpType.recovery,
          email: email,
          token: token,
        ),
        silent: false,
      );

      final user = response.user;
      if (user == null) {
        return {
          'success': false,
          'error': 'Kod doğrulanamadı',
        };
      }

      return {
        'success': true,
        'user': user,
      };
    } catch (e) {
      String errorMessage = e.toString();
      
      if (errorMessage.contains('Invalid') || errorMessage.contains('invalid')) {
        errorMessage = 'Geçersiz kod. Lütfen tekrar deneyin.';
      } else if (errorMessage.contains('expired') || errorMessage.contains('Expired')) {
        errorMessage = 'Kodun süresi dolmuş. Lütfen yeni kod isteyin.';
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  /// Update password after OTP verification
  Future<Map<String, dynamic>> updatePassword({
    required String newPassword,
  }) async {
    try {
      await _helper.executeWithRetry(
        operation: () => supabase.auth.updateUser(
          UserAttributes(password: newPassword),
        ),
        silent: false,
      );

      return {
        'success': true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}

