import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> userProfile;
  final bool isEditing;

  const ProfileLoaded({required this.userProfile, this.isEditing = false});

  @override
  List<Object?> get props => [userProfile, isEditing];
}

class ProfileSaving extends ProfileState {
  final Map<String, dynamic> userProfile;
  const ProfileSaving({required this.userProfile});
  @override
  List<Object?> get props => [userProfile];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object> get props => [message];
}
