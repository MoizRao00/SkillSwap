// lib/screens/profile/edit_skills_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/skill_model.dart';

class EditSkillsScreen extends StatefulWidget {
  const EditSkillsScreen({super.key});

  @override
  State<EditSkillsScreen> createState() => _EditSkillsScreenState();
}

class _EditSkillsScreenState extends State<EditSkillsScreen> {
  final _skillController = TextEditingController();
  final FirestoreService _fs = FirestoreService();
  bool _isTeachingSkill = true; // true for teaching, false for learning

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      appBar:
      AppBar(
        title: const Text('Manage Skills'),
      ),
      body:
      Column(
        children: [
          // Toggle between teaching and learning skills
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Skills to Teach'),
                  icon: Icon(Icons.school),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Skills to Learn'),
                  icon: Icon(Icons.psychology),
                ),
              ],
              selected: {_isTeachingSkill},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isTeachingSkill = newSelection.first;
                });
              },
            ),
          ),

          // Add skill input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    decoration: InputDecoration(
                      labelText: _isTeachingSkill
                          ? 'Add teaching skill'
                          : 'Add learning skill',
                      hintText: 'Enter skill name',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final skillName = _skillController.text.trim();
                    if (skillName.isNotEmpty) {
                      if (_isTeachingSkill) {
                        await _fs.addUserSkill(currentUser.uid, skillName);
                      } else {
                        // Add to learning skills
                        await _fs.addLearningSkill(currentUser.uid, skillName);
                      }
                      _skillController.clear();
                    }
                  },
                ),
              ],
            ),
          ),

          // Skills list
          Expanded(
            child: StreamBuilder<List<Skill>>(
              stream: _isTeachingSkill
                  ? _fs.getUserSkillsStream(currentUser.uid)
                  : _fs.getUserLearningSkillsStream(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final skills = snapshot.data ?? [];

                if (skills.isEmpty) {
                  return Center(
                    child: Text(
                      _isTeachingSkill
                          ? 'No teaching skills added yet'
                          : 'No learning skills added yet',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: skills.length,
                  itemBuilder: (context, index) {
                    final skill = skills[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          _isTeachingSkill ? Icons.school : Icons.psychology,
                        ),
                        title: Text(skill.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (_isTeachingSkill) {
                              await _fs.removeUserSkill(
                                currentUser.uid,
                                skill.id,
                                skill.name,
                              );
                            } else {
                              await _fs.removeLearningSkill(
                                currentUser.uid,
                                skill.id,
                                skill.name,
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }
}