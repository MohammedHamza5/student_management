abstract class DistributionState {}

class DistributionInitial extends DistributionState {
  final Map<String, List<Map<String, String>>> distribution;

  DistributionInitial(this.distribution);
}

class DistributionLoading extends DistributionState {}

class DistributionSuccess extends DistributionState {
  final Map<String, List<Map<String, String>>> distribution;

  DistributionSuccess(this.distribution);
}

class DistributionFailure extends DistributionState {
  final String error;

  DistributionFailure(this.error);
}