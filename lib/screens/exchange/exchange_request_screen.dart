// lib/screens/exchange/create_exchange_request_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/usermodel.dart';
import '../../services/firestore_service.dart';
import '../../widgets/animation/fade_animation.dart';
import '../../widgets/animation/slide_animation.dart';

class CreateExchangeRequestScreen extends StatefulWidget {
  final UserModel otherUser;

  const CreateExchangeRequestScreen({
    super.key,
    required this.otherUser,
  });

  @override
  State<CreateExchangeRequestScreen> createState() =>
      _CreateExchangeRequestScreenState();
}

class _CreateExchangeRequestScreenState
    extends State<CreateExchangeRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _locationController = TextEditingController();
  final FirestoreService _fs = FirestoreService();

  String? _selectedTeachSkill;
  String? _selectedLearnSkill;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userData = await _fs.getUser(currentUser.uid);
      if (mounted && userData != null) {
        setState(() {
          if (userData.skillsToTeach.isNotEmpty) {
            _selectedTeachSkill = userData.skillsToTeach.first;
          }
          if (widget.otherUser.skillsToTeach.isNotEmpty) {
            _selectedLearnSkill = widget.otherUser.skillsToTeach.first;
          }
        });
      }
    }
  }

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeachSkill == null || _selectedLearnSkill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select skills to exchange')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _fs.createExchangeRequest(
        receiverId: widget.otherUser.uid,
        senderSkill: _selectedTeachSkill!,
        receiverSkill: _selectedLearnSkill!,
        message: _messageController.text.trim(),
        location: _locationController.text.trim(),
        scheduledDate: _selectedDate,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exchange request sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(
        title: const Text('Create Exchange Request'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Card
              FadeAnimation(
                child: _buildUserInfoCard(),
              ),
              const SizedBox(height: 24),

              // Skills Selection
              SlideAnimation(
                direction: SlideDirection.fromLeft,
                child: _buildSkillsSelection(),
              ),
              const SizedBox(height: 24),

              // Message
              SlideAnimation(
                direction: SlideDirection.fromRight,
                child: _buildMessageInput(),
              ),
              const SizedBox(height: 24),

              // Location and Date
              SlideAnimation(
                direction: SlideDirection.fromLeft,
                child: _buildLocationAndDate(),
              ),
              const SizedBox(height: 32),

              // Submit Button
              FadeAnimation(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sendRequest,
                    child: const Text('Send Exchange Request'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: widget.otherUser.profilePicUrl != null
              ? NetworkImage(widget.otherUser.profilePicUrl!)
              : null,
          child: widget.otherUser.profilePicUrl == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(widget.otherUser.name),
        subtitle: widget.otherUser.location != null
            ? Row(
          children: [
            const Icon(Icons.location_on, size: 16),
            Text(widget.otherUser.location!),
          ],
        )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            Text(widget.otherUser.rating.toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select skills to exchange',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        // What you'll teach
        DropdownButtonFormField<String>(
          value: _selectedTeachSkill,
          decoration: const InputDecoration(
            labelText: 'Skill you\'ll teach',
            border: OutlineInputBorder(),
          ),
          items: widget.otherUser.skillsToLearn
              .map((skill) => DropdownMenuItem(
            value: skill,
            child: Text(skill),
          ))
              .toList(),
          onChanged: (value) => setState(() => _selectedTeachSkill = value),
        ),
        const SizedBox(height: 16),
        // What you'll learn
        DropdownButtonFormField<String>(
          value: _selectedLearnSkill,
          decoration: const InputDecoration(
            labelText: 'Skill you\'ll learn',
            border: OutlineInputBorder(),
          ),
          items: widget.otherUser.skillsToTeach
              .map((skill) => DropdownMenuItem(
            value: skill,
            child: Text(skill),
          ))
              .toList(),
          onChanged: (value) => setState(() => _selectedLearnSkill = value),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          decoration: const InputDecoration(
            hintText: 'Write a message to introduce yourself...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a message';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationAndDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        // Location
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Preferred Location (optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 16),
        // Date
        ListTile(
          title: const Text('Preferred Date (optional)'),
          subtitle: Text(
            _selectedDate != null
                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                : 'Not selected',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: _selectDate,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}