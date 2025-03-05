class Research {
  final String title;
  final String gender;

  Research({
    required this.title,
    required this.gender,
  });

  Research copyWith({
    String? title,
    String? gender,
  }) {
    return Research(
      title: title ?? this.title,
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'gender': gender,
  };

  factory Research.fromJson(Map<String, dynamic> json) => Research(
    title: json['title'] as String,
    gender: json['gender'] as String,
  );
}
