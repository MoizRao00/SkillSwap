
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/usermodel.dart';

class SkillManagementScreen extends StatefulWidget {
  const SkillManagementScreen({super.key});

  @override
  State<SkillManagementScreen> createState() => _SkillManagementScreenState();
}

class _SkillManagementScreenState extends State<SkillManagementScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();
  late TabController _tabController;
  UserModel? _currentUser;
  bool _isLoading = false;

  final _teachSkillController = TextEditingController();
  final _learnSkillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _fs.getUser(user.uid);
        setState(() => _currentUser = userData);
      }
    } catch (e) {
      print('❌ Error loading user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSkill(bool isTeachingSkill) async {
    final skillName = isTeachingSkill
        ? _teachSkillController.text.trim()
        : _learnSkillController.text.trim();

    if (skillName.isEmpty || _currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      List<String> updatedSkills;
      if (isTeachingSkill) {
        updatedSkills = [..._currentUser!.skillsToTeach, skillName];
        final updatedUser = _currentUser!.copyWith(skillsToTeach: updatedSkills);
        await _fs.saveUser(updatedUser);
        _teachSkillController.clear();
      } else {
        updatedSkills = [..._currentUser!.skillsToLearn, skillName];
        final updatedUser = _currentUser!.copyWith(skillsToLearn: updatedSkills);
        await _fs.saveUser(updatedUser);
        _learnSkillController.clear();
      }

      await _loadCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${isTeachingSkill ? "teaching" : "learning"} skill: $skillName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding skill: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeSkill(String skill, bool isTeachingSkill) async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      List<String> updatedSkills;
      if (isTeachingSkill) {
        updatedSkills = _currentUser!.skillsToTeach.where((s) => s != skill).toList();
        final updatedUser = _currentUser!.copyWith(skillsToTeach: updatedSkills);
        await _fs.saveUser(updatedUser);
      } else {
        updatedSkills = _currentUser!.skillsToLearn.where((s) => s != skill).toList();
        final updatedUser = _currentUser!.copyWith(skillsToLearn: updatedSkills);
        await _fs.saveUser(updatedUser);
      }

      await _loadCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed ${isTeachingSkill ? "teaching" : "learning"} skill: $skill')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing skill: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _teachSkillController.dispose();
    _learnSkillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Skills'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Skills to Teach'),
            Tab(text: 'Skills to Learn'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // Teaching Skills Tab
          _buildSkillList(
            true,
            _teachSkillController,
            _currentUser?.skillsToTeach ?? [],
          ),
          // Learning Skills Tab
          _buildSkillList(
            false,
            _learnSkillController,
            _currentUser?.skillsToLearn ?? [],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillList(
      bool isTeachingSkill,
      TextEditingController controller,
      List<String> skills,
      ) {
    return Column(
      children: [
        // Add Skill Input
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Add ${isTeachingSkill ? "teaching" : "learning"} skill',
                    hintText: 'Enter skill name',
                  ),
                  onSubmitted: (_) => _addSkill(isTeachingSkill),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addSkill(isTeachingSkill),
              ),
            ],
          ),
        ),

        // Skills List
        Expanded(
          child: skills.isEmpty
              ? Center(
            child: Text(
              'No ${isTeachingSkill ? "teaching" : "learning"} skills added yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: skills.length,
            itemBuilder: (context, index) {
              final skill = skills[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    isTeachingSkill ? Icons.school : Icons.psychology,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(skill),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeSkill(skill, isTeachingSkill),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}