import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Base Bloc class that provides common functionality for all Blocs in the app
abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(super.initialState);

  /// Flag to track if the bloc has been disposed
  bool _isDisposed = false;

  /// Check if the bloc is disposed
  bool get isDisposed => _isDisposed;

  /// Safely add event only if bloc is not disposed
  void safeAdd(Event event) {
    if (!_isDisposed && !isClosed) {
      add(event);
    }
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    return super.close();
  }
}

/// Base class for all Bloc events
abstract class BaseEvent extends Equatable {
  const BaseEvent();
  
  @override
  List<Object?> get props => [];
}

/// Base class for all Bloc states
abstract class BaseState extends Equatable {
  const BaseState({
    this.isLoading = false,
    this.errorMessage,
  });
  
  final bool isLoading;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
  bool get isSuccess => !isLoading && !hasError;
  
  @override
  List<Object?> get props => [isLoading, errorMessage];
}

/// Common loading state
class LoadingState extends BaseState {
  const LoadingState() : super(isLoading: true);
}

/// Common error state
class ErrorState extends BaseState {
  const ErrorState(String message) : super(errorMessage: message);
  
  @override
  List<Object?> get props => [errorMessage];
}

/// Generic loading event
class LoadingEvent extends BaseEvent {
  const LoadingEvent();
}

/// Generic refresh event
class RefreshEvent extends BaseEvent {
  const RefreshEvent();
}

/// Generic clear error event
class ClearErrorEvent extends BaseEvent {
  const ClearErrorEvent();
}