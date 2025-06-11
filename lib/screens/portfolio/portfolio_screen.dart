import 'package:flutter/material.dart';
import '../../models/potfolio_item.dart';
import '../../services/firestore_service.dart';

class PortfolioScreen extends StatelessWidget {
  final String userId;
  final FirestoreService _fs = FirestoreService();

  PortfolioScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPortfolioDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<PortfolioItem>>(
        stream: _fs.getUserPortfolio(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.work_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No portfolio items yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showAddPortfolioDialog(context),
                    child: const Text('Add Portfolio Item'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _PortfolioItemCard(item: item);
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddPortfolioDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final tagsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Portfolio Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final tags = tagsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              await _fs.addPortfolioItem(
                userId,
                title: titleController.text,
                description: descController.text,
                tags: tags,
              );

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _PortfolioItemCard extends StatelessWidget {
  final PortfolioItem item;

  const _PortfolioItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(item.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: item.tags
                  .map((tag) => Chip(
                label: Text(tag),
                backgroundColor:
                Theme.of(context).primaryColor.withOpacity(0.1),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}