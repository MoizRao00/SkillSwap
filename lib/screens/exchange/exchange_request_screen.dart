
import 'package:flutter/material.dart';
import '../../models/usermodel.dart';
import '../../models/exchange_request.dart';
import '../../services/firestore_service.dart';

class ExchangeRequestScreen extends StatefulWidget {
  final UserModel otherUser;
  final List<String> matchingTeachSkills;
  final List<String> matchingLearnSkills;

  const ExchangeRequestScreen({
    super.key,
    required this.otherUser,
    required this.matchingTeachSkills,
    required this.matchingLearnSkills,
  });

  @override
  State<ExchangeRequestScreen> createState() => _ExchangeRequestScreenState();
}

class _ExchangeRequestScreenState extends State<ExchangeRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final FirestoreService _fs = FirestoreService();

  String? _selectedTeachSkill;
  String? _selectedLearnSkill;
  DateTime? _scheduledDate;
  String? _location;
  bool _isLoading = false;

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _sendRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeachSkill == null || _selectedLearnSkill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both skills')),
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
        location: _location,
        scheduledDate: _scheduledDate,
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Exchange Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Card
              Card(
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
                  subtitle: Text(widget.otherUser.location ?? 'No location'),
                ),
              ),
              const SizedBox(height: 24),

              // Skill Selection
              Text(
                'Select skills to exchange:',
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
                items: widget.matchingLearnSkills
                    .map((skill) => DropdownMenuItem(
                  value: skill,
                  child: Text(skill),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedTeachSkill = value);
                },
              ),
              const SizedBox(height: 16),

              // What you'll learn
              DropdownButtonFormField<String>(
                value: _selectedLearnSkill,
                decoration: const InputDecoration(
                  labelText: 'Skill you\'ll learn',
                  border: OutlineInputBorder(),
                ),
                items: widget.matchingTeachSkills
                    .map((skill) => DropdownMenuItem(
                  value: skill,
                  child: Text(skill),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedLearnSkill = value);
                },
              ),
              const SizedBox(height: 24),

              // Message
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
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
              const SizedBox(height: 16),

              // Location
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Preferred Location (optional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _location = value,
              ),
              const SizedBox(height: 16),

              // Date/Time Selection
              ListTile(
                title: const Text('Preferred Date/Time (optional)'),
                subtitle: Text(
                  _scheduledDate?.toString() ?? 'Not selected',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendRequest,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Send Exchange Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}