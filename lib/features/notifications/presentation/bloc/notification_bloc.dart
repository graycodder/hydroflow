import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/notifications/domain/entities/notification_entity.dart';
import 'package:hydroflow/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:hydroflow/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:hydroflow/features/notifications/domain/usecases/mark_all_read_usecase.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String uid;
  const LoadNotifications(this.uid);
  @override
  List<Object?> get props => [uid];
}

class MarkAsRead extends NotificationEvent {
  final String uid;
  final String notificationId;
  const MarkAsRead(this.uid, this.notificationId);
  @override
  List<Object?> get props => [uid, notificationId];
}

class MarkAllAsRead extends NotificationEvent {
  final String uid;
  const MarkAllAsRead(this.uid);
  @override
  List<Object?> get props => [uid];
}

class _NotificationsUpdated extends NotificationEvent {
  final List<NotificationEntity> notifications;
  const _NotificationsUpdated(this.notifications);
  @override
  List<Object?> get props => [notifications];
}

class _NotificationError extends NotificationEvent {
  final String message;
  const _NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}

// States
abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}
class NotificationLoading extends NotificationState {}
class NotificationLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  const NotificationLoaded(this.notifications);
  @override
  List<Object?> get props => [notifications];
}
class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllReadUseCase _markAllRead;
  StreamSubscription? _notificationSubscription;

  NotificationBloc({
    required GetNotificationsUseCase getNotifications,
    required MarkNotificationReadUseCase markRead,
    required MarkAllReadUseCase markAllRead,
  })  : _getNotifications = getNotifications,
        _markRead = markRead,
        _markAllRead = markAllRead,
        super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<_NotificationsUpdated>(_onNotificationsUpdated);
    on<_NotificationError>(_onInternalError);
  }

  Future<void> _onLoadNotifications(LoadNotifications event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    await _notificationSubscription?.cancel();
    _notificationSubscription = _getNotifications(event.uid).listen(
      (notifications) => add(_NotificationsUpdated(notifications)),
      onError: (e) => add(_NotificationError(e.toString())),
    );
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<NotificationState> emit) async {
    try {
      await _markRead(event.uid, event.notificationId);
    } catch (e) {
      // We don't necessarily want to change the whole state to error for a failed marking?
      // Maybe just log it.
    }
  }

  Future<void> _onMarkAllAsRead(MarkAllAsRead event, Emitter<NotificationState> emit) async {
    try {
      await _markAllRead(event.uid);
    } catch (e) {
      // Log error
    }
  }

  void _onNotificationsUpdated(_NotificationsUpdated event, Emitter<NotificationState> emit) {
    emit(NotificationLoaded(event.notifications));
  }

  void _onInternalError(_NotificationError event, Emitter<NotificationState> emit) {
    emit(NotificationError(event.message));
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}
