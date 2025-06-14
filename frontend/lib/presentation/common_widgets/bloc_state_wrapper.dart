import 'package:flutter/material.dart';

/// A generic wrapper to handle common BLoC states (Loading, Error, Loaded).
/// It simplifies the UI by removing boilerplate if/else chains for state handling.
class BlocStateWrapper<TLoaded> extends StatelessWidget {
  /// The current state from the BLoC builder.
  final Object state;

  /// The callback to execute when the user presses the 'Retry' button on an error.
  final VoidCallback onRetry;

  /// The widget builder for the success (loaded) state.
  /// It receives the strongly-typed loaded state.
  final Widget Function(TLoaded loadedState) builder;

  const BlocStateWrapper({
    super.key,
    required this.state,
    required this.onRetry,
    required this.builder,
  });

  /// A helper to check if a state's runtimeType string contains a specific name.
  /// This is used to generically identify Loading and Initial states without
  /// needing a common base class for them across all features.
  /// Example: `EventBrowseLoading` contains "Loading".
  bool _isState(String typeName) {
    return state.runtimeType.toString().contains(typeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Handle Loading and Initial states
    if (_isState('Loading') || _isState('Initial')) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle Error state
    // This relies on the convention that all 'Error' states have a 'message' property.
    if (_isState('Error')) {
      final String message = (state as dynamic).message;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'An Error Occurred',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Handle Loaded state
    // If the state is of the expected loaded type `TLoaded`, call the builder.
    if (state is TLoaded) {
      return builder(state as TLoaded);
    }

    // Fallback for any other unhandled state.
    return const SizedBox.shrink();
  }
}
