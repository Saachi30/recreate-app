class User {
  final String name;
  final String email;
  int greenPoints;
  final String propertyID; // New field
  final List<Achievement> achievements;
  final List<Event> events;
  final bool isProducer;
  final List<String> contractHistory; // New field

  User({
    required this.name,
    required this.email,
    required this.propertyID,
    this.greenPoints = 0,
    this.achievements = const [],
    this.events = const [],
    this.isProducer = false,
    this.contractHistory = const [], // Default empty list
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'propertyId': propertyID,
      'greenPoints': greenPoints,
      'achievements': achievements.map((a) => a.toMap()).toList(),
      'events': events.map((e) => e.toMap()).toList(),
      'isProducer': isProducer,
      'contractHistory': contractHistory
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      propertyID: map['propertyID'] ?? '',
      greenPoints: map['greenPoints'] ?? 0,
      achievements: List<Achievement>.from(
        (map['achievements'] ?? []).map((x) => Achievement.fromMap(x)),
      ),
      events: List<Event>.from(
        (map['events'] ?? []).map((x) => Event.fromMap(x)),
      ),
      isProducer: map['isProducer'] ?? false,
      contractHistory: List<String>.from(map['contractHistory'] ?? []),
    );
  }
}

class Achievement {
  final int id;
  final String title;
  final String description;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id']?.toInt() ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

class Event {
  final int id;
  final String title;
  final String date;

  Event({
    required this.id,
    required this.title,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id']?.toInt() ?? 0,
      title: map['title'] ?? '',
      date: map['date'] ?? '',
    );
  }
}