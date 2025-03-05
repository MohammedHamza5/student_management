abstract class SearchState {
  List<dynamic> get results;
}

class SearchInitial extends SearchState {
  @override
  final List<dynamic> results;

  SearchInitial(this.results);
}

class SearchLoaded extends SearchState {
  @override
  final List<dynamic> results;

  SearchLoaded(this.results);
}