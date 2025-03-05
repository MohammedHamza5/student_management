abstract class StatsState {
  final int male;
  final int female;
  final int researchesMale;
  final int researchesFemale;

  StatsState({
    required this.male,
    required this.female,
    required this.researchesMale,
    required this.researchesFemale,
  });
}

class StatsInitial extends StatsState {
  StatsInitial()
      : super(male: 0, female: 0, researchesMale: 0, researchesFemale: 0);
}

class StatsUpdated extends StatsState {
  StatsUpdated(int male, int female, int researchesMale, int researchesFemale)
      : super(male: male, female: female, researchesMale: researchesMale, researchesFemale: researchesFemale);
}