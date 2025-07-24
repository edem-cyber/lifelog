import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/journal_provider.dart';
import '../../models/journal_entry_model.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../theme/app_theme.dart';

// Search providers
final searchQueryProvider = StateProvider<String>((ref) => '');
final searchResultsProvider = Provider<List<JournalEntryModel>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final entries = ref.watch(journalProvider).asData?.value ?? [];

  if (query.isEmpty) return entries;

  return entries.where((entry) {
    return entry.title.toLowerCase().contains(query) ||
        entry.body.toLowerCase().contains(query) ||
        entry.moodDescription.toLowerCase().contains(query) ||
        DateFormat(
          'MMMM d, y',
        ).format(entry.date).toLowerCase().contains(query);
  }).toList();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Export Journal Data'),
            content: const Text(
              'Choose how you\'d like to export your journal entries:',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _exportAsText(context, ref);
                },
                child: const Text('Export as Text'),
              ),
            ],
          ),
    );
  }

  void _exportAsText(BuildContext context, WidgetRef ref) {
    final entries = ref.read(journalProvider).asData?.value ?? [];
    if (entries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No entries to export')));
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('LifeLog Journal Export');
    buffer.writeln(
      'Generated on: ${DateFormat('MMMM d, y \'at\' h:mm a').format(DateTime.now())}',
    );
    buffer.writeln('Total entries: ${entries.length}');
    buffer.writeln('\n${'=' * 50}\n');

    for (final entry in entries) {
      buffer.writeln('Date: ${DateFormat('MMMM d, y').format(entry.date)}');
      buffer.writeln('Mood: ${entry.moodEmoji} ${entry.moodDescription}');
      buffer.writeln('Title: ${entry.title}');
      buffer.writeln('');
      buffer.writeln(entry.body);
      buffer.writeln('\n${'-' * 30}\n');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export ready! ${entries.length} entries processed'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(journalProvider);
    final groupedEntries = ref.watch(groupedEntriesProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search entries...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                )
                : const Text('Journal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (_isSearching) ...[
            if (query.isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
                icon: const Icon(Icons.clear),
                tooltip: 'Clear Search',
              ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = false;
                });
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
              icon: const Icon(Icons.close),
              tooltip: 'Close Search',
            ),
          ] else ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
              icon: const Icon(Icons.search),
              tooltip: 'Search Entries',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    ref.read(journalProvider.notifier).refresh();
                    break;
                  case 'export':
                    _showExportDialog(context, ref);
                    break;
                  case 'logout':
                    ref.read(authProvider.notifier).signOut();
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Refresh'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download),
                          SizedBox(width: 8),
                          Text('Export Data'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ],
      ),
      body: entriesAsync.when(
        loading: () => const LoadingOverlay(isLoading: true, child: SizedBox()),
        error:
            (error, stack) => _ErrorView(
              error: error.toString(),
              onRetry: () => ref.read(journalProvider.notifier).refresh(),
            ),
        data: (entries) {
          if (entries.isEmpty) {
            return _EmptyStateView(
              onCreateFirst: () => context.push('/create-entry'),
            );
          }

          if (_isSearching) {
            return _SearchResultsView(results: searchResults, query: query);
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(journalProvider.notifier).refresh(),
            child: _JournalListView(groupedEntries: groupedEntries),
          );
        },
      ),
      floatingActionButton:
          _isSearching
              ? null
              : FloatingActionButton.extended(
                onPressed: () async {
                  final today = DateTime.now();
                  final hasEntryToday = ref.read(
                    entryExistsForDateProvider(today),
                  );

                  if (hasEntryToday) {
                    _showAlreadyExistsDialog(context);
                  } else {
                    context.push('/create-entry');
                  }
                },
                label: const Text('New Entry'),
                icon: const Icon(Icons.add),
              ),
    );
  }

  void _showAlreadyExistsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Entry Already Exists'),
            content: const Text(
              'You already have a journal entry for today. You can only create one entry per day.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

class _JournalListView extends StatelessWidget {
  final Map<DateTime, List<JournalEntryModel>> groupedEntries;

  const _JournalListView({required this.groupedEntries});

  @override
  Widget build(BuildContext context) {
    final sortedDates =
        groupedEntries.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // Most recent first

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final entries = groupedEntries[date]!;

        return _DateGroup(
          date: date,
          entries: entries,
        ).animate().fadeIn(delay: (index * 100).ms).slideX();
      },
    );
  }
}

class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<JournalEntryModel> entries;

  const _DateGroup({required this.date, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _formatDate(date),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),

        // Entries for this date
        ...entries.map((entry) => _EntryCard(entry: entry)),

        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today';
    } else if (entryDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }
}

class _EntryCard extends StatelessWidget {
  final JournalEntryModel entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/journal/${entry.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with mood and time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.moodEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.moodDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getMoodColor(entry.mood),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('h:mm a').format(entry.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                entry.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Body preview
              Text(
                entry.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 1:
        return Colors.red.shade600;
      case 2:
        return Colors.orange.shade600;
      case 3:
        return Colors.amber.shade600;
      case 4:
        return Colors.lightGreen.shade600;
      case 5:
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}

class _EmptyStateView extends StatelessWidget {
  final VoidCallback onCreateFirst;

  const _EmptyStateView({required this.onCreateFirst});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),

            const SizedBox(height: 24),

            Text(
              'Start Your Journal',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              'Capture your thoughts, feelings, and memories. Every day is a new story waiting to be written.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: onCreateFirst,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Entry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),

            const SizedBox(height: 16),

            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  final List<JournalEntryModel> results;
  final String query;

  const _SearchResultsView({required this.results, required this.query});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty && query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try searching with different keywords',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search your journal entries',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Find entries by title, content, mood, or date',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final entry = results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                entry.moodEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: _highlightText(entry.title, query),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _highlightText(
                  entry.body.length > 100
                      ? '${entry.body.substring(0, 100)}...'
                      : entry.body,
                  query,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM d, y').format(entry.date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
            isThreeLine: true,
            onTap: () {
              context.push('/journal/${entry.id}');
            },
          ),
        );
      },
    );
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(text);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text);
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: TextStyle(
              backgroundColor: AppColors.primary.withOpacity(0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}
