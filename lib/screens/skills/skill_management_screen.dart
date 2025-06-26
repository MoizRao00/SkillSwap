// lib/screens/skills/skill_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../services/skill_api_service.dart';

class SkillManagementScreen extends StatefulWidget {
  final List<String> initialSkillsToTeach;
  final List<String> initialSkillsToLearn;

  const SkillManagementScreen({
    super.key,
    required this.initialSkillsToTeach,
    required this.initialSkillsToLearn,
  });

  @override
  State<SkillManagementScreen> createState() => _SkillManagementScreenState();
}

class _SkillManagementScreenState extends State<SkillManagementScreen> {
  late List<String> _skillsToTeach;
  late List<String> _skillsToLearn;

  final TextEditingController _teachController = TextEditingController();
  final TextEditingController _learnController = TextEditingController();

  final SkillApiService _skillApiService = SkillApiService();

  @override
  void initState() {
    super.initState();
    _skillsToTeach = List.from(widget.initialSkillsToTeach);
    _skillsToLearn = List.from(widget.initialSkillsToLearn);
  }

  @override
  void dispose() {
    _teachController.dispose();
    _learnController.dispose();
    super.dispose();
  }


  void _addSkill(List<String> skillList, String skill) {
    final trimmedSkill = skill.trim();
    if (trimmedSkill.isNotEmpty && !skillList.contains(trimmedSkill)) {
      setState(() {
        skillList.add(trimmedSkill);
      });

    } else if (trimmedSkill.isNotEmpty) {
      // Optional: Show a message if skill already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$trimmedSkill already exists!'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _removeSkill(List<String> skillList, String skill) {
    setState(() {
      skillList.remove(skill);
    });
  }

  // Helper widget for skill input section
  Widget _buildSkillInputSection(
      String title,
      TextEditingController controller,
      List<String> skillList,
      Function(String) onAddSkill,
      Function(String) onRemoveSkill,
      ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TypeAheadField<String>(
              // 1. Use the 'builder' to create the TextField
              // The `controller` and `focusNode` are provided by the builder
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller, // Use the provided controller
                  focusNode: focusNode, // Use the provided focusNode
                  decoration: InputDecoration( // Define the decoration here
                    hintText: 'Search for a skill...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        onAddSkill(controller.text);
                        controller.clear();
                      },
                    ),
                  ),
                );
              },
              // 2. This callback fetches the suggestions from your API
              suggestionsCallback: (pattern) async {
                return await _skillApiService.searchSkills(pattern);
              },
              // 3. This builds each suggestion item in the dropdown
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              // 4. Use 'onSelected' for the latest package version
              onSelected: (suggestion) {
                onAddSkill(suggestion);
                controller.clear();
              },
              // 5. Use 'loadingBuilder' for the loading indicator
              loadingBuilder: (context) => const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              // 6. ⭐️ Corrected: Use 'emptyBuilder' instead of 'noItemsFoundBuilder'
              emptyBuilder: (context) => const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No skills found. Try a different search term.'),
              ),
            ),
            const SizedBox(height: 15),
            skillList.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'No skills added yet. Add some above!',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
              ),
            )
                : Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: skillList.map((skill) => Chip(
                label: Text(skill),
                onDeleted: () => onRemoveSkill(skill),
                deleteIcon: const Icon(Icons.close, size: 18),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                labelStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500),
                side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Skills'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios), // iOS style back arrow
          onPressed: () {
            // Return the updated skill lists when popping
            Navigator.pop(context, {
              'skillsToTeach': _skillsToTeach,
              'skillsToLearn': _skillsToLearn,
            });
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skills to Teach Section
            _buildSkillInputSection(
              'Skills I can Teach',
              _teachController, // 👈 separate controller
              _skillsToTeach,
                  (skill) => _addSkill(_skillsToTeach, skill),
                  (skill) => _removeSkill(_skillsToTeach, skill),
            ),
            const SizedBox(height: 10), // Spacing between sections

            // Skills to Learn Section
            _buildSkillInputSection(
              'Skills I want to Learn',
              _learnController, // 👈 separate controller
              _skillsToLearn,
                  (skill) => _addSkill(_skillsToLearn, skill),
                  (skill) => _removeSkill(_skillsToLearn, skill),
            ),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Explicitly pop with data
                  Navigator.pop(context, {
                    'skillsToTeach': _skillsToTeach,
                    'skillsToLearn': _skillsToLearn,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary, // Use a contrasting color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Done Managing Skills',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}