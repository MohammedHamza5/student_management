import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'colleges_state.dart';
import 'stats_cubit.dart';
import 'stats_state.dart';

class CollegesCubit extends Cubit<CollegesState> {
  final StatsCubit statsCubit;

  CollegesCubit({required this.statsCubit}) : super(CollegesInitial([])) {
    _loadColleges();
  }

  final Box _box = Hive.box('app_data');
  bool _isLoaded = false;

  void _loadColleges() {
    if (_isLoaded && state.colleges.isNotEmpty) {
      emit(CollegesUpdated(state.colleges));
      return;
    }

    final collegesData = _box.get('colleges', defaultValue: []);
    final colleges = (collegesData as List<dynamic>).map((item) {
      final mapItem = Map<String, dynamic>.from(item as Map);
      return College.fromJson(mapItem);
    }).toList();

    _updateStats(colleges);
    emit(CollegesUpdated(colleges));
    _isLoaded = true;
  }

  void addCollege(String name, int students, String gender) {
    final colleges = state is CollegesInitial ? (state as CollegesInitial).colleges : (state as CollegesUpdated).colleges;
    final newCollege = College(name: name, students: students.clamp(0, double.infinity).toInt(), gender: gender);
    final updatedColleges = List<College>.from(colleges)..add(newCollege);
    _box.put('colleges', updatedColleges.map((c) => c.toJson()).toList());
    _updateStats(updatedColleges);
    emit(CollegesUpdated(updatedColleges));
    _isLoaded = true;
  }

  void editCollege(int index, String name, int students) {
    final colleges = state is CollegesInitial ? (state as CollegesInitial).colleges : (state as CollegesUpdated).colleges;
    final updatedColleges = List<College>.from(colleges);
    updatedColleges[index] = College(
      name: name,
      students: students.clamp(0, double.infinity).toInt(),
      gender: updatedColleges[index].gender,
    );
    _box.put('colleges', updatedColleges.map((c) => c.toJson()).toList());
    _updateStats(updatedColleges);
    emit(CollegesUpdated(updatedColleges));
    _isLoaded = true;
  }

  void deleteCollege(int index) {
    final colleges = state is CollegesInitial ? (state as CollegesInitial).colleges : (state as CollegesUpdated).colleges;
    final updatedColleges = List<College>.from(colleges)..removeAt(index);
    _box.put('colleges', updatedColleges.map((c) => c.toJson()).toList());
    _updateStats(updatedColleges);
    emit(CollegesUpdated(updatedColleges));
    _isLoaded = true;
  }

  void clearAllColleges() {
    _box.delete('colleges');
    _updateStats([]);
    emit(CollegesInitial([]));
  }

  void clearCollegesByGender(String gender) {
    final colleges = state is CollegesInitial ? (state as CollegesInitial).colleges : (state as CollegesUpdated).colleges;
    final updatedColleges = List<College>.from(colleges).where((c) => c.gender != gender).toList();
    _box.put('colleges', updatedColleges.map((c) => c.toJson()).toList());
    _updateStats(updatedColleges);
    emit(CollegesUpdated(updatedColleges));
  }

  void _updateStats(List<College> colleges) {
    // حساب إجمالي الطلاب من الكليات الحالية
    final maleStudentsFromColleges = colleges.where((c) => c.gender == "ذكور").fold(0, (sum, c) => sum + c.students);
    final femaleStudentsFromColleges = colleges.where((c) => c.gender == "إناث").fold(0, (sum, c) => sum + c.students);

    // الحصول على القيم الحالية من StatsCubit
    final currentState = statsCubit.state;
    final currentMale = currentState is StatsInitial ? currentState.male : (currentState as StatsUpdated).male;
    final currentFemale = currentState is StatsInitial ? currentState.female : (currentState as StatsUpdated).female;

    // الجمع التراكمي مع القيم الحالية
    final newMale = (currentMale + maleStudentsFromColleges).clamp(0, double.infinity).toInt();
    final newFemale = (currentFemale + femaleStudentsFromColleges).clamp(0, double.infinity).toInt();

    statsCubit.setStats(male: newMale, female: newFemale);
  }
}

class College {
  final String name;
  final int students;
  final String gender;

  College({required this.name, required this.students, required this.gender});

  Map<String, dynamic> toJson() => {'name': name, 'students': students, 'gender': gender};
  factory College.fromJson(Map<String, dynamic> json) => College(
    name: json['name'] as String,
    students: json['students'] as int,
    gender: json['gender'] as String,
  );
}