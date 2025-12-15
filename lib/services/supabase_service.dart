import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  Future<void> createUserProfileIfNotExists() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final existing = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('profiles').insert({
        'id': user.id,
        'name': '',
        'surname': '',
        'email': user.email,
      });
    }
  }

  /// Kullanıcıya ait tüm sohbet mesajlarını Supabase'den çek
  /// created_at'e göre sıralı olarak döner
  Future<List<Map<String, dynamic>>> getChatMessages() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('chat_messages')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Sohbet mesajını Supabase'e kaydet
  /// role: "user" veya "assistant"
  Future<bool> saveChatMessage(String message, String role) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await supabase.from('chat_messages').insert({
        'user_id': user.id,
        'message': message,
        'role': role, // "user" veya "assistant"
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Kullanıcıya ait tüm sohbet mesajlarını Supabase'den sil
  Future<bool> deleteAllMessages() async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await supabase
          .from('chat_messages')
          .delete()
          .eq('user_id', user.id);
      return true;
    } catch (e) {
      return false;
    }
  }
}

