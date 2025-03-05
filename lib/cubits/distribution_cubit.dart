import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'distribution_state.dart';
import 'upload_cubit.dart';

class DistributionCubit extends Cubit<DistributionState> {
  final UploadCubit uploadCubit;

  DistributionCubit({required this.uploadCubit})
      : super(DistributionInitial({"male": [], "female": []})) {
    _loadDistribution();
  }

  final Box _box = Hive.box('app_data');

  void _loadDistribution() {
    final rawDistribution = _box.get(
      'distribution',
      defaultValue: {"male": [], "female": []},
    );

    final Map<String, List<Map<String, String>>> typedDistribution = {};

    if (rawDistribution is Map) {
      rawDistribution.forEach((key, value) {
        if (key is String) {
          if (value is List) {
            final List<Map<String, String>> validList = [];
            for (var item in value) {
              if (item is Map) {
                final validMap = <String, String>{};
                item.forEach((k, v) {
                  if (k is String && v is String) {
                    validMap[k] = v;
                  }
                });
                if (validMap.isNotEmpty) {
                  validList.add(validMap);
                }
              }
            }
            typedDistribution[key] = validList;
          } else {
            typedDistribution[key] = [];
          }
        }
      });
    }

    typedDistribution.putIfAbsent("male", () => []);
    typedDistribution.putIfAbsent("female", () => []);

    emit(DistributionSuccess(typedDistribution));
  }

  void distributeResearches(int totalStudents, int totalResearches, String gender) {
    final researches = gender == "الذكور" ? uploadCubit.researchesMale : uploadCubit.researchesFemale;
    if (researches.isEmpty || totalStudents <= 0) {
      emit(DistributionFailure("لا توجد أبحاث كافية أو عدد طلاب غير صالح"));
      return;
    }


    final distribution = <Map<String, String>>[];
    final shuffledResearches = researches.toList()..shuffle();

    // توليد أرقام مسلسلة لجميع الطلاب
    final serialNumbers = List.generate(totalStudents, (index) => (index + 1).toString())..shuffle();

    // الحد الأدنى للطلاب لكل بحث
    const minStudentsPerResearch = 2;

    // حساب عدد الأبحاث التي يمكن استخدامها مع الحد الأدنى
    final maxPossibleResearches = totalStudents ~/ minStudentsPerResearch;
    final usableResearches = shuffledResearches.length > maxPossibleResearches
        ? maxPossibleResearches
        : shuffledResearches.length;

    // عدد الطلاب لكل بحث (مع ضمان الحد الأدنى)
    final studentsPerResearch = (totalStudents / usableResearches).ceil();

    // توزيع جميع الطلاب على الأبحاث مع ضمان الحد الأدنى
    for (int i = 0; i < totalStudents; i++) {
      final researchIndex = (i ~/ studentsPerResearch) % usableResearches;
      distribution.add({
        "serial": serialNumbers[i],
        "research": shuffledResearches[researchIndex].title,
      });
    }

    final rawDistribution = _box.get('distribution', defaultValue: {"male": [], "female": []});
    final Map<String, List<Map<String, String>>> currentDistributions = {};

    if (rawDistribution is Map) {
      rawDistribution.forEach((key, value) {
        if (key is String) {
          if (value is List) {
            final List<Map<String, String>> validList = [];
            for (var item in value) {
              if (item is Map) {
                final validMap = <String, String>{};
                item.forEach((k, v) {
                  if (k is String && v is String) {
                    validMap[k] = v;
                  }
                });
                if (validMap.isNotEmpty) {
                  validList.add(validMap);
                }
              }
            }
            currentDistributions[key] = validList;
          } else {
            currentDistributions[key] = [];
          }
        }
      });
    }

    currentDistributions[gender == "الذكور" ? "male" : "female"] = distribution;
    currentDistributions.putIfAbsent("male", () => []);
    currentDistributions.putIfAbsent("female", () => []);

    _box.put('distribution', currentDistributions);
    emit(DistributionSuccess(currentDistributions));
  }

  List<Map<String, String>> filterDistribution(String gender, String query) {
    final rawDistribution = _box.get('distribution', defaultValue: {"male": [], "female": []});
    if (rawDistribution is Map) {
      final distribution = rawDistribution[gender == "الذكور" ? "male" : "female"] as List? ?? [];
      return distribution
          .where((item) {
        if (item is Map<String, dynamic>) {
          final serial = item["serial"]?.toString().toLowerCase() ?? "";
          final research = item["research"]?.toString().toLowerCase() ?? "";
          return serial.contains(query.toLowerCase()) || research.contains(query.toLowerCase());
        }
        return false;
      })
          .map((item) => Map<String, String>.from(item))
          .toList();
    }
    return [];
  }

  void resetDistribution(String gender) {
    final rawDistribution = _box.get('distribution', defaultValue: {"male": [], "female": []});
    final Map<String, List<Map<String, String>>> currentDistributions = {
      "male": [],
      "female": [],
    };

    if (rawDistribution is Map) {
      rawDistribution.forEach((key, value) {
        if (key is String && value is List) {
          final List<Map<String, String>> validList = [];
          for (var item in value) {
            if (item is Map) {
              final validMap = <String, String>{};
              item.forEach((k, v) {
                if (k is String && v is String) {
                  validMap[k] = v;
                }
              });
              if (validMap.isNotEmpty) {
                validList.add(validMap);
              }
            }
          }
          currentDistributions[key] = validList;
        }
      });
    }

    currentDistributions[gender == "الذكور" ? "male" : "female"] = [];
    _box.put('distribution', currentDistributions);
    emit(DistributionSuccess(currentDistributions));
  }
}