// lib/screens/search/search_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Make sure this is imported for GeoPoint
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../models/usermodel.dart';
import '../../services/firestore_service.dart';
import '../../services/skill_api_service.dart';
import '../../utils/navigation_helper.dart';
import '../../widgets/animation/fade_animation.dart';
import '../../widgets/animation/slide_animation.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  final FirestoreService _fs = FirestoreService();

  final _searchController = TextEditingController();
  final SkillApiService _skillApiService = SkillApiService();

  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  String _selectedFilter = 'skills';
  String _selectedSkillType = 'teaching';
  double _minRating = 0.0;
  bool _onlyAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Header
          FadeAnimation(
            child: _buildSearchHeader(),
          ),

          // Results or Empty State
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : _searchResults.isEmpty
                ? _buildEmptyState()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ⭐️ Conditionally show TypeAheadField for skills or TextField for location
            _selectedFilter == 'skills'
                ? TypeAheadField<String>(
              // 📄 Use your existing controller to sync text
              controller: _searchController,
              suggestionsCallback: (pattern) async {
                // 🚀 Get suggestions from the GitHub API
                return await _skillApiService.searchSkills(pattern);
              },
              // 🎨 Use the styled UI from our previous conversation
              itemBuilder: (context, suggestion) {
                return Card(
                  elevation: 2, // Use a slightly lower elevation for suggestions
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
                    title: Text(suggestion),
                  ),
                );
              },
              onSelected: (suggestion) {
                // ⭐ When a suggestion is selected, perform the search
                setState(() {
                  // Update the text field with the selected suggestion
                  _searchController.text = suggestion;
                  // Now, perform the Firestore search with the selected skill
                  _performSearch(suggestion);
                });
              },
              // 📄 The TextField UI for the TypeAheadField
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller, // Use the controller provided by the builder
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search skills...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.clear();
                              _performSearch(''); // Clear results when clearing text
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _showFilterDialog,
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (text) {
                    // The onChanged here only triggers suggestions, not a search.
                    // The search is triggered onSelected.
                  },
                );
              },
            )
                : TextField(
              // 📄 Regular TextField for location search
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFilterDialog,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _performSearch, // This still performs a search on every change
            ),
            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                // ... your FilterChip widgets ...
                children: [
                  _buildFilterChip(
                    label: 'Skills',
                    isSelected: _selectedFilter == 'skills',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = 'skills';
                          _searchController.clear();
                          _searchResults = [];
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Location',
                    isSelected: _selectedFilter == 'location',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = 'location';
                          _searchController.clear();
                          _searchResults = [];
                        });
                      }
                    },
                  ),
                  if (_selectedFilter == 'skills') ...[
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Teaching',
                      isSelected: _selectedSkillType == 'teaching',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedSkillType = 'teaching';
                            // Re-run the search if there is text in the controller
                            if (_searchController.text.isNotEmpty) {
                              _performSearch(_searchController.text);
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Learning',
                      isSelected: _selectedSkillType == 'learning',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedSkillType = 'learning';
                            if (_searchController.text.isNotEmpty) {
                              _performSearch(_searchController.text);
                            }
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  })
  {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildEmptyState() {
    return FadeAnimation(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedFilter == 'skills' ? Icons.psychology : Icons.location_on,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Start searching...'
                  : 'No users found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return SlideAnimation(
          direction: SlideDirection.fromRight,
          delay: Duration(milliseconds: index * 100),
          child: _UserSearchCard(user: user),
        );
      },
    );
  }

  Future<void> _showFilterDialog() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _minRating = 0.0;
                        _onlyAvailable = true;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Minimum Rating
              Text(
                'Minimum Rating',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                value: _minRating,
                max: 5,
                divisions: 5,
                label: _minRating.toString(),
                onChanged: (value) {
                  setState(() => _minRating = value);
                },
              ),

              // Only Available Users
              SwitchListTile(
                title: const Text('Only Available Users'),
                subtitle: const Text('Show users ready to exchange skills'),
                value: _onlyAvailable,
                onChanged: (value) {
                  setState(() => _onlyAvailable = value);
                },
              ),

              const SizedBox(height: 16),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _performSearch(_searchController.text);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // NOTE: If searching by 'location', your searchUsers method will need
      // to handle the query as a location string, possibly by performing
      // a reverse geocoding or by comparing it with pre-stored location names.
      // If your backend search is purely GeoPoint/geohash based, then
      // 'location' search here implies searching by approximate string.
      _searchResults = await _fs.searchUsers(
        query: query,
        searchSkills: _selectedFilter == 'skills',
        skillType: _selectedSkillType,
        minRating: _minRating,
        onlyAvailable: _onlyAvailable,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _UserSearchCard extends StatelessWidget {
  final UserModel user;

  const _UserSearchCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => NavigationHelper.navigateToUserProfile(context, user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (user.location != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${user.locationName!}', // Directly use locationName from UserModel
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            user.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Text(
                        '${user.totalExchanges} exchanges',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.skillsToTeach
                    .take(3)
                    .map((skill) => Chip(
                  label: Text(
                    skill,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor:
                  Theme.of(context).primaryColor.withOpacity(0.1),
                ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}