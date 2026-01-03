class UserProfile {
  final String name;
  final int age;
  final String location;
  final String bio;
  final String mood;
  final String moodIcon;
  final String imageUrl;
  final List<String> interests;
  final List<String> lookingFor;

  const UserProfile({
    required this.name,
    required this.age,
    required this.location,
    required this.bio,
    required this.mood,
    required this.moodIcon,
    required this.imageUrl,
    this.interests = const [],
    this.lookingFor = const [],
  });
}

class Experience {
  final String id;
  final String title;
  final DateTime dateTime;
  final String location;
  final String description;
  final String mood;
  final String imageUrl;
  final List<String> tags;
  final double? price; 

  const Experience({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.description,
    required this.mood,
    required this.imageUrl,
    this.tags = const [],
    this.price,
  });

  String get dateFormatted {
    // Example: Sat, Jan 4 • 9:00 AM
    final weekday = _weekdayShort(dateTime.weekday);
    final month = _monthShort(dateTime.month);
    final day = dateTime.day;
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $month $day • $hour:$minute $ampm';
  }

  String _weekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }

  String _monthShort(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[(month - 1) % 12];
  }
}

class Mood {
  final String name;
  final String icon;
  final bool isSelected;

  const Mood({
    required this.name,
    required this.icon,
    this.isSelected = false,
  });
}

// Sample data for the prototype
final sampleProfiles = [
  const UserProfile(
    name: 'Sofia',
    age: 28,
    location: 'Brooklyn, NY',
    bio: 'Looking for people who appreciate quiet mornings, good design, and conversations that matter.',
    mood: 'Calm',
    moodIcon: 'coffee',
    imageUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=500&fit=crop',
  ),
  const UserProfile(
    name: 'Marcus',
    age: 31,
    location: 'Manhattan, NY',
    bio: 'Architect by day, jazz enthusiast by night. I believe the best conversations happen over good food and even better questions.',
    mood: 'Reflective',
    moodIcon: 'building',
    imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h-500&fit=crop',
    interests: ['Architecture', 'Jazz', 'Photography', 'Cooking', 'Philosophy'],
    lookingFor: ['Friends', 'Community'],
  ),
];

final sampleExperiences = [
  Experience(
    id: '1',
    title: 'Morning Coffee & Conversation',
    dateTime: DateTime(2025, 1, 4, 9, 0), // Jan 4, 9:00 AM
    location: 'Bluestone Lane, SoHo',
    description: 'Start your weekend with meaningful conversations over specialty coffee in a relaxed atmosphere.',
    mood: 'Calm',
    imageUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&h=300&fit=crop',
    tags: ['Coffee', 'Conversation', 'Weekend'],
  ),
  Experience(
    id: '2',
    title: 'Gallery Opening: New Perspectives',
    dateTime: DateTime(2025, 1, 6, 18, 30), // Jan 6, 6:30 PM
    location: 'Modern Art Gallery, Chelsea',
    description: 'Explore emerging artists and engage in thoughtful discussions about contemporary art.',
    mood: 'Curious',
    imageUrl: 'https://images.unsplash.com/photo-1563089145-599997674d42?w=600&h=300&fit=crop',
    tags: ['Art', 'Gallery', 'Networking'],
  ),
  Experience(
    id: '3',
    title: 'Jazz Night & Philosophy',
    dateTime: DateTime(2025, 1, 8, 20, 0), // Jan 8, 8:00 PM
    location: 'The Blue Note, Greenwich Village',
    description: 'An evening of live jazz music followed by intimate philosophical discussions in small groups.',
    mood: 'Reflective',
    imageUrl: 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=600&h=300&fit=crop',
    tags: ['Jazz', 'Music', 'Philosophy', 'Discussion'],
  ),
];

final sampleMoods = [
  const Mood(name: 'Energetic', icon: 'bolt'),
  const Mood(name: 'Reflective', icon: 'brain'),
  const Mood(name: 'Adventurous', icon: 'compass'),
  const Mood(name: 'Calm', icon: 'waves'),
  const Mood(name: 'Curious', icon: 'eye'),
  const Mood(name: 'Creative', icon: 'paint-brush'),
];