import 'package:equatable/equatable.dart';
import 'package:resellio/core/models/models.dart';

class ProfileSaved extends ProfileLoaded {
  const ProfileSaved({required super.userProfile}) : super(isEditing: false);
}

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile userProfile;
  final bool isEditing;

  const ProfileLoaded({required this.userProfile, this.isEditing = false});

  @override
  List<Object?> get props => [userProfile, isEditing];
}

class ProfileSaving extends ProfileLoaded {
  const ProfileSaving({required super.userProfile}) : super(isEditing: true);
}

class ProfileInitialError extends ProfileState {
  final String message;
  const ProfileInitialError(this.message);
  @override
  List<Object> get props => [message];
}

class ProfileUpdateError extends ProfileLoaded {
  final String message;
  const ProfileUpdateError({required super.userProfile, required this.message})
      : super(isEditing: true);

  @override
  List<Object?> get props => [super.props, message];
}
