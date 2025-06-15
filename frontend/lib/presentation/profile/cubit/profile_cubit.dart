import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/repositories.dart';
import 'package:resellio/core/services/auth_service.dart';
import 'package:resellio/presentation/profile/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserRepository _userRepository;
  final AuthService _authService;

  ProfileCubit(this._userRepository, this._authService)
      : super(ProfileInitial());

  Future<void> loadProfile() async {
    try {
      emit(ProfileLoading());
      final profile = await _userRepository.getUserProfile();
      emit(ProfileLoaded(userProfile: profile));
    } on ApiException catch (e) {
      emit(ProfileInitialError(e.message));
    } catch (e) {
      emit(ProfileInitialError('An unexpected error occurred: $e'));
    }
  }

  void toggleEdit(bool isEditing) {
    if (state is ProfileLoaded) {
      final loadedState = state as ProfileLoaded;
      emit(ProfileLoaded(
          userProfile: loadedState.userProfile, isEditing: isEditing));
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (state is! ProfileLoaded) return;
    final loadedState = state as ProfileLoaded;
    emit(ProfileSaving(userProfile: loadedState.userProfile));

    try {
      final updatedProfile = await _userRepository.updateUserProfile(data);
      _authService.updateDetailedProfile(updatedProfile);
      emit(ProfileLoaded(userProfile: updatedProfile));
    } on ApiException catch (e) {
      emit(ProfileUpdateError(
          userProfile: loadedState.userProfile, message: e.message));
    } catch (e) {
      emit(ProfileUpdateError(
          userProfile: loadedState.userProfile,
          message: 'An unexpected error occurred.'));
    }
  }
}
