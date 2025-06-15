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
      emit(ProfileError(e.message));
    } catch (e) {
      emit(ProfileError('An unexpected error occurred: $e'));
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
      emit(ProfileError(e.message));
      // Revert to editing mode on error
      await Future.delayed(const Duration(milliseconds: 100));
      emit(ProfileLoaded(userProfile: loadedState.userProfile, isEditing: true));
    } catch (e) {
      emit(ProfileError('An unexpected error occurred.'));
      // Revert to editing mode on error
      await Future.delayed(const Duration(milliseconds: 100));
      emit(ProfileLoaded(userProfile: loadedState.userProfile, isEditing: true));
    }
  }
}
