abstract class UploadState {}

class UploadInitial extends UploadState {}

class UploadLoading extends UploadState {}

class UploadSuccess extends UploadState {
  final int researches;
  final String gender;

  UploadSuccess(this.researches, this.gender);
}

class ResearchAdded extends UploadState {
  final int researches;
  final String gender;

  ResearchAdded(this.researches, this.gender);
}

class ResearchEdited extends UploadState {
  final int researches;
  final String gender;

  ResearchEdited(this.researches, this.gender);
}

class ResearchDeleted extends UploadState {
  final int researches;
  final String gender;

  ResearchDeleted(this.researches, this.gender);
}

class UploadError extends UploadState {
  final String message;

  UploadError(this.message);
}