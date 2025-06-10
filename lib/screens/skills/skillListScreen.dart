import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SkillListScreen extends StatefulWidget {
  const SkillListScreen({Key? key}) : super(key: key);

  @override
  State<SkillListScreen> createState() => _SkillListScreenState();
}

class _SkillListScreenState extends State<SkillListScreen> {
  List<String> skills = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchSkills();
  }

  Future<void> fetchSkills() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        error = "User not logged in";
        isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('skills')
          .get();

      final skillList = snapshot.docs.map((doc) {
        return doc.data()['skillName'] as String? ?? "Unnamed Skill";
      }).toList();

      setState(() {
        skills = skillList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    if (skills.isEmpty) {
      return const Center(child: Text('No skills added yet.'));
    }

    return ListView.builder(
      itemCount: skills.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.star),
          title: Text(skills[index]),
        );
      },
    );
  }
}
