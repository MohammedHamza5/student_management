import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'search_state.dart';
import 'distribution_cubit.dart';

class SearchCubit extends Cubit<SearchState> {
  final DistributionCubit distributionCubit;

  SearchCubit({required this.distributionCubit}) : super(SearchInitial([])) {
    _loadSearchResults();
  }

  final Box _box = Hive.box('app_data');

  void _loadSearchResults() {
    final distributionData = _box.get('distribution', defaultValue: {"male": [], "female": []});
    final Map<String, List<Map<String, String>>> convertedDistribution = {};
    distributionData.forEach((key, value) {
      convertedDistribution[key] = (value as List<dynamic>).map((item) => Map<String, String>.from(item as Map)).toList();
    });
    final allResults = [
      ...convertedDistribution["male"] ?? [],
      ...convertedDistribution["female"] ?? [],
    ];
    emit(SearchLoaded(allResults));
  }

  void search(String query) {
    final distributionData = _box.get('distribution', defaultValue: {"male": [], "female": []});
    final Map<String, List<Map<String, String>>> convertedDistribution = {};
    distributionData.forEach((key, value) {
      convertedDistribution[key] = (value as List<dynamic>).map((item) => Map<String, String>.from(item as Map)).toList();
    });
    final allResults = [
      ...convertedDistribution["male"] ?? [],
      ...convertedDistribution["female"] ?? [],
    ];
    final filteredResults = allResults.where((item) {
      final research = item["research"]?.toLowerCase() ?? "";
      final serial = item["serial"]?.toLowerCase() ?? "";
      return research.contains(query.toLowerCase()) || serial.contains(query.toLowerCase());
    }).toList();
    emit(SearchLoaded(filteredResults));
  }
}