import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resellio/core/network/api_exception.dart';

/// A reusable helper function to standardize data loading logic in Cubits.
///
/// It handles emitting loading, success, and error states, reducing boilerplate code.
/// - `emit`: The `emit` function from the Cubit.
/// - `loader`: The async function that fetches the data (e.g., a repository call).
/// - `loadingBuilder`: A function that returns the loading state.
/// - `successBuilder`: A function that takes the loaded data and returns the success state.
/// - `errorBuilder`: A function that takes an error message and returns the error state.
Future<void> loadData<T, S>({
  required Emitter<S> emit,
  required Future<T> Function() loader,
  required S Function() loadingBuilder,
  required S Function(T data) successBuilder,
  required S Function(String message) errorBuilder,
}) async {
  emit(loadingBuilder());
  try {
    final data = await loader();
    emit(successBuilder(data));
  } on ApiException catch (e) {
    emit(errorBuilder(e.message));
  } catch (e) {
    emit(errorBuilder('An unexpected error occurred: $e'));
  }
}
