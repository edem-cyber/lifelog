import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../models/journal_entry_model.dart';
import 'auth_provider.dart';

// Journal entries provider
class JournalNotifier extends AsyncNotifier<List<JournalEntryModel>> {
  @override
  Future<List<JournalEntryModel>> build() async {
    // Watch for auth changes and reload entries
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    return _fetchEntries();
  }

  Future<List<JournalEntryModel>> _fetchEntries() async {
    try {
      final response = await SupabaseConfig.client
          .from('journal_entries')
          .select()
          .order('date', ascending: false);

      return (response as List)
          .map((entry) => JournalEntryModel.fromJson(entry))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch journal entries: $e');
    }
  }

  Future<void> addEntry({
    required String title,
    required String body,
    required int mood,
    required DateTime date,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      // Ensure we have a valid session
      final session = SupabaseConfig.client.auth.currentSession;
      if (session?.accessToken == null) {
        throw Exception('No valid authentication session');
      }

      // Check if entry already exists for this date
      final existingEntry =
          await SupabaseConfig.client
              .from('journal_entries')
              .select()
              .eq('user_id', user.id)
              .eq('date', date.toIso8601String().split('T')[0])
              .maybeSingle();

      if (existingEntry != null) {
        throw Exception('You already have an entry for this date');
      }

      // Call edge function to create entry with validation
      final response = await SupabaseConfig.client.functions.invoke(
        'dynamic-endpoint',
        body: {
          'title': title,
          'body': body,
          'mood': mood,
          'date': date.toIso8601String().split('T')[0],
        },
        headers: {
          'Authorization':
              'Bearer ${SupabaseConfig.client.auth.currentSession?.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create entry');
      }

      // Refresh the list
      await refresh();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e.toString(), stackTrace);
      rethrow;
    }
  }

  Future<void> updateEntry({
    required String entryId,
    required String title,
    required String body,
    required int mood,
  }) async {
    try {
      await SupabaseConfig.client
          .from('journal_entries')
          .update({
            'title': title,
            'body': body,
            'mood': mood,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', entryId);

      // Refresh the list
      await refresh();
    } catch (e) {
      throw Exception('Failed to update entry: $e');
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      await SupabaseConfig.client
          .from('journal_entries')
          .delete()
          .eq('id', entryId);

      // Refresh the list
      await refresh();
    } catch (e) {
      throw Exception('Failed to delete entry: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchEntries);
  }
}

// Provider instance
final journalProvider =
    AsyncNotifierProvider<JournalNotifier, List<JournalEntryModel>>(
      () => JournalNotifier(),
    );

// Grouped entries by date
final groupedEntriesProvider = Provider<Map<DateTime, List<JournalEntryModel>>>(
  (ref) {
    final entries = ref.watch(journalProvider).asData?.value ?? [];

    final Map<DateTime, List<JournalEntryModel>> grouped = {};

    for (final entry in entries) {
      final dateKey = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(entry);
    }

    return grouped;
  },
);

// Check if entry exists for specific date
final entryExistsForDateProvider = Provider.family<bool, DateTime>((ref, date) {
  final entries = ref.watch(journalProvider).asData?.value ?? [];
  return entries.any(
    (entry) =>
        entry.date.year == date.year &&
        entry.date.month == date.month &&
        entry.date.day == date.day,
  );
});

// Mood statistics
final moodStatsProvider = Provider<Map<int, int>>((ref) {
  final entries = ref.watch(journalProvider).asData?.value ?? [];
  final stats = <int, int>{};

  for (final entry in entries) {
    stats[entry.mood] = (stats[entry.mood] ?? 0) + 1;
  }

  return stats;
});
