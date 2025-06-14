import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/network/api_exception.dart';
import 'package:resellio/core/repositories/user_repository.dart';
import 'package:resellio/presentation/profile/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserRepository _userRepository;

  ProfileCubit(this._userRepository) : super(ProfileInitial());

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
      await _userRepository.updateUserProfile(data);
      await loadProfile(); // Refresh after successful save
    } on ApiException {
      emit(ProfileLoaded(userProfile: loadedState.userProfile)); // Revert
      rethrow; // re-throw for listener
    } catch (e) {
      emit(ProfileLoaded(userProfile: loadedState.userProfile)); // Revert
      throw Exception('An unexpected error occurred.');
    }
  }
}
