import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'stats_state.dart';

class StatsCubit extends Cubit<StatsState> {
  StatsCubit() : super(StatsInitial()) {
    _loadStats();
  }

  final Box _box = Hive.box('app_data');

  void _loadStats() {
    final male = _box.get('male_students', defaultValue: 0);
    final female = _box.get('female_students', defaultValue: 0);
    final researchesMale = _box.get('researches_male', defaultValue: 0);
    final researchesFemale = _box.get('researches_female', defaultValue: 0);
    emit(StatsUpdated(male, female, researchesMale, researchesFemale));
  }

  void updateStats({int male = 0, int female = 0, int researchesMale = 0, int researchesFemale = 0}) {
    final currentState = state;
    final currentMale = currentState is StatsInitial ? currentState.male : (currentState as StatsUpdated).male;
    final currentFemale = currentState is StatsInitial ? currentState.female : (currentState as StatsUpdated).female;
    final currentResearchesMale = currentState is StatsInitial ? currentState.researchesMale : (currentState as StatsUpdated).researchesMale;
    final currentResearchesFemale = currentState is StatsInitial ? currentState.researchesFemale : (currentState as StatsUpdated).researchesFemale;

    // منع الأعداد السالبة
    final newMale = (currentMale + male).clamp(0, double.infinity).toInt();
    final newFemale = (currentFemale + female).clamp(0, double.infinity).toInt();
    final newResearchesMale = (currentResearchesMale + researchesMale).clamp(0, double.infinity).toInt();
    final newResearchesFemale = (currentResearchesFemale + researchesFemale).clamp(0, double.infinity).toInt();

    _box.put('male_students', newMale);
    _box.put('female_students', newFemale);
    _box.put('researches_male', newResearchesMale);
    _box.put('researches_female', newResearchesFemale);

    emit(StatsUpdated(newMale, newFemale, newResearchesMale, newResearchesFemale));
  }

  void setStats({int? male, int? female, int? researchesMale, int? researchesFemale}) {
    final currentState = state;
    final currentMale = currentState is StatsInitial ? currentState.male : (currentState as StatsUpdated).male;
    final currentFemale = currentState is StatsInitial ? currentState.female : (currentState as StatsUpdated).female;
    final currentResearchesMale = currentState is StatsInitial ? currentState.researchesMale : (currentState as StatsUpdated).researchesMale;
    final currentResearchesFemale = currentState is StatsInitial ? currentState.researchesFemale : (currentState as StatsUpdated).researchesFemale;

    // منع الأعداد السالبة
    final newMale = (male ?? currentMale).clamp(0, double.infinity).toInt();
    final newFemale = (female ?? currentFemale).clamp(0, double.infinity).toInt();
    final newResearchesMale = (researchesMale ?? currentResearchesMale).clamp(0, double.infinity).toInt();
    final newResearchesFemale = (researchesFemale ?? currentResearchesFemale).clamp(0, double.infinity).toInt();

    _box.put('male_students', newMale);
    _box.put('female_students', newFemale);
    _box.put('researches_male', newResearchesMale);
    _box.put('researches_female', newResearchesFemale);

    emit(StatsUpdated(newMale, newFemale, newResearchesMale, newResearchesFemale));
  }

  void resetStats() {
    _box.put('male_students', 0);
    _box.put('female_students', 0);
    _box.put('researches_male', 0);
    _box.put('researches_female', 0);
    emit(StatsInitial());
  }

  // دالة جديدة لحذف جميع البيانات من Hive
  void clearAllData() {
    _box.clear(); // حذف جميع المفاتيح في Box 'app_data'
    emit(StatsInitial());
  }
}