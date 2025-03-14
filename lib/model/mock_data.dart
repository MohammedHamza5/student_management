import 'package:hive/hive.dart';

part 'mock_data.g.dart'; // سيتم توليد هذا الملف باستخدام build_runner


          // flutter pub run build_runner build --delete-conflicting-outputs

@HiveType(typeId: 0)
class MockResearch {
  @HiveField(0)
  final String title;

  MockResearch(this.title);

  Map<String, dynamic> toJson() => {'title': title};
  factory MockResearch.fromJson(Map<String, dynamic> json) => MockResearch(json['title']);
}

// قائمة وهمية للاختبار الأولي (سيتم استبدالها بالبيانات المستخرجة)
final List<MockResearch> mockResearches = [
  MockResearch("بحث عن الفيزياء"),
  MockResearch("بحث عن الكيمياء"),
  MockResearch("بحث عن الأحياء"),
];