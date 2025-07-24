import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/journal_provider.dart';
import '../../models/journal_entry_model.dart';
import '../../theme/app_theme.dart';
import '../journal/journal_detail_screen.dart';

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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Entries'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search by title, content, mood, or date...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    query.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Search Results
          Expanded(
            child:
                searchResults.isEmpty
                    ? _buildEmptyState(query)
                    : _buildSearchResults(searchResults, query),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String query) {
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
    } else {
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
  }

  Widget _buildSearchResults(List<JournalEntryModel> results, String query) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => JournalDetailScreen(entryId: entry.id),
                ),
              );
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
        style: DefaultTextStyle.of(context).style,
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
