
import 'package:flutter/material.dart';
import '../models/exchange_request.dart';
import '../models/usermodel.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/exchange/exchange_request_list_screen.dart';
import '../screens/exchange/exchange_request_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/user_profile.dart';

import '../screens/review/reviews_list_screen.dart';

class NavigationHelper {
  static void navigateToUserProfile(BuildContext context, UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(user: user),
      ),
    );
  }

  static void navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  static void navigateToExchangeRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExchangeRequestsListScreen(),
      ),
    );
  }

  static void navigateToCreateExchange(
      BuildContext context,
      UserModel otherUser,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateExchangeRequestScreen(
          otherUser: otherUser,
        ),
      ),
    );
  }

  static void navigateToChat(
      BuildContext context,
      ExchangeRequest exchange,
      UserModel otherUser,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          exchange: exchange,
          otherUser: otherUser,
        ),
      ),
    );
  }

  static void navigateToReviews(BuildContext context, UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsListScreen(user: user),
      ),
    );
  }
}