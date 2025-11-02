class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'], name: json['name']);
  }
}

class Recommendation {
  final int id;
  final String name;
  final int degree;
  final int mutualFriends;

  Recommendation({
    required this.id,
    required this.name,
    required this.degree,
    required this.mutualFriends,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'],
      name: json['name'],
      degree: json['degree'],
      mutualFriends: json['mutual_friends'],
    );
  }

  String get degreeDescription {
    switch (degree) {
      case 1:
        return 'Direct Friend';
      case 2:
        return 'Friend of Friend';
      case 3:
        return "Friend's Friend's Friend";
      default:
        return '$degree degrees away';
    }
  }
}
