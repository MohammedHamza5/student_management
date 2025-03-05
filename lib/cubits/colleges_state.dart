import 'colleges_cubit.dart';

abstract class CollegesState {
  List<College> get colleges;
  
  T when<T>({
    required T Function(List<College> colleges) initial,
    required T Function() loading,
    required T Function(List<College> colleges) loaded,
    required T Function(String message) error,
  }) {
    if (this is CollegesInitial) {
      return initial((this as CollegesInitial).colleges);
    } else if (this is CollegesLoading) {
      return loading();
    } else if (this is CollegesUpdated) {
      return loaded((this as CollegesUpdated).colleges);
    } else if (this is CollegesError) {
      return error((this as CollegesError).message);
    }
    throw Exception('Unknown state type: ${this.runtimeType}');
  }
}

class CollegesInitial extends CollegesState {
  @override
  final List<College> colleges;

  CollegesInitial(this.colleges);
}

class CollegesLoading extends CollegesState {
  @override
  List<College> get colleges => [];
}

class CollegesUpdated extends CollegesState {
  @override
  final List<College> colleges;

  CollegesUpdated(this.colleges);
}

class CollegesError extends CollegesState {
  @override
  List<College> get colleges => [];
  
  final String message;

  CollegesError(this.message);
}