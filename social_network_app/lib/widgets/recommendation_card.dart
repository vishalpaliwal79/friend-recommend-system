import 'package:flutter/material.dart';
import '../models/user_model.dart';

class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;

  const RecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Enhanced Avatar with connectivity indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getDegreeColor(recommendation.degree),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.12),
                        blurRadius: 2,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getUserInitials(recommendation.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Connectivity indicator badge
                if (recommendation.mutualFriends == 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.12),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.public,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                // Popular user indicator
                if (recommendation.mutualFriends >= 3)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.12),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.people,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Enhanced User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recommendation.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF37474F), // blueGrey[900]
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Degree badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDegreeColor(
                            recommendation.degree,
                          ).withAlpha(25), // 10% opacity
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getDegreeColor(
                              recommendation.degree,
                            ).withAlpha(76), // 30% opacity
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Degree ${recommendation.degree}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getDegreeColor(recommendation.degree),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Connection description
                  Text(
                    _getConnectionDescription(recommendation),
                    style: TextStyle(
                      color: _getDescriptionColor(recommendation),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Mutual friends or connection info
                  if (recommendation.mutualFriends > 0)
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recommendation.mutualFriends} mutual friend${recommendation.mutualFriends != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                  if (recommendation.mutualFriends == 0)
                    Row(
                      children: [
                        Icon(Icons.public, size: 14, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Distant connection in network',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),

                  // Connection strength indicator
                  const SizedBox(height: 8),
                  _buildConnectionStrengthBar(recommendation),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Enhanced Add Friend Button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD), // blue[50]
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(51), // 20% opacity
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  _showFriendRequestDialog(context, recommendation.name);
                },
                icon: Icon(
                  Icons.person_add_alt_1,
                  color: Colors.blue[700],
                  size: 24,
                ),
                tooltip: 'Send friend request to ${recommendation.name}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUserInitials(String name) {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}';
    }
    return name.length >= 2 ? name.substring(0, 2) : name;
  }

  String _getConnectionDescription(Recommendation recommendation) {
    switch (recommendation.degree) {
      case 1:
        return 'Direct friend';
      case 2:
        if (recommendation.mutualFriends >= 3) {
          return 'Close friend of ${recommendation.mutualFriends} friends';
        } else if (recommendation.mutualFriends == 1) {
          return 'Friend of 1 mutual friend';
        } else {
          return 'Friend of friends';
        }
      case 3:
        if (recommendation.mutualFriends > 0) {
          return '${recommendation.mutualFriends} shared connections';
        } else {
          return 'Extended network connection';
        }
      default:
        return '${recommendation.degree} degrees away';
    }
  }

  Color _getDescriptionColor(Recommendation recommendation) {
    switch (recommendation.degree) {
      case 1:
        return const Color(0xFF2E7D32); // green[800]
      case 2:
        return const Color(0xFFEF6C00); // orange[800]
      case 3:
        return const Color(0xFFC62828); // red[800]
      default:
        return const Color(0xFF424242); // grey[800]
    }
  }

  Widget _buildConnectionStrengthBar(Recommendation recommendation) {
    double strength = 0.0;

    // Calculate connection strength based on degree and mutual friends
    if (recommendation.degree == 2) {
      strength = 0.3 + (recommendation.mutualFriends * 0.15);
    } else if (recommendation.degree == 3) {
      strength = 0.1 + (recommendation.mutualFriends * 0.1);
    } else {
      strength = 1.0; // Direct friends
    }

    strength = strength.clamp(0.1, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connection strength',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              Expanded(
                flex: (strength * 100).round(),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getStrengthColor(strength),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                flex: 100 - (strength * 100).round(),
                child: const SizedBox(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStrengthColor(double strength) {
    if (strength >= 0.7) return const Color(0xFF4CAF50); // green
    if (strength >= 0.4) return const Color(0xFFFF9800); // orange
    return const Color(0xFFF44336); // red
  }

  Color _getDegreeColor(int degree) {
    switch (degree) {
      case 1:
        return const Color(0xFF4CAF50); // green
      case 2:
        return const Color(0xFFFF9800); // orange
      case 3:
        return const Color(0xFFF44336); // red
      default:
        return const Color(0xFF9E9E9E); // grey
    }
  }

  void _showFriendRequestDialog(BuildContext context, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Colors.blue),
              SizedBox(width: 8),
              Text('Send Friend Request'),
            ],
          ),
          content: Text(
            'Send a friend request to $userName?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Friend request sent to $userName! 🎉',
                      style: const TextStyle(fontSize: 14),
                    ),
                    backgroundColor: const Color(0xFF4CAF50), // green
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3), // blue
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Request'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}
