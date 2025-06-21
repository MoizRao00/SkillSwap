// lib/screens/review/reviews_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/review_model.dart';
import '../../models/usermodel.dart';
import '../../services/firestore_service.dart';

class ReviewsListScreen extends StatelessWidget {
  final UserModel user;
  final FirestoreService _fs = FirestoreService();

  ReviewsListScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for ${user.name}'),
      ),
      body: StreamBuilder<List<Review>>(
        stream: _fs.getUserReviews(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reviews = snapshot.data ?? [];

          if (reviews.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No reviews yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return FutureBuilder<UserModel?>(
                future: _fs.getUser(review.reviewerId),
                builder: (context, snapshot) {
                  final reviewer = snapshot.data;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reviewer info
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: reviewer?.profileImageUrl != null
                                    ? NetworkImage(reviewer!.profileImageUrl!)
                                    : null,
                                child: reviewer?.profileImageUrl == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reviewer?.name ?? 'Unknown User',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      _formatDate(review.createdAt),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              // Rating
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  Text(
                                    review.rating.toString(),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Review comment
                          Text(review.comment),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}