import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/profile/domain/entities/profile_entity.dart';
import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';
import 'package:hydroflow/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:hydroflow/features/profile/domain/usecases/get_subscription_history_usecase.dart';
import 'package:hydroflow/features/profile/domain/usecases/get_agency_profile_usecase.dart';
import 'package:hydroflow/features/auth/domain/repositories/agency_repository.dart';
import 'package:hydroflow/features/auth/domain/entities/agency.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase _getProfile;
  final GetSubscriptionHistoryUseCase _getSubscriptionHistory;
  final GetAgencyProfileUseCase _getAgencyProfile;
  final AgencyRepository _agencyRepository;
  StreamSubscription? _profileSubscription;
  StreamSubscription? _historySubscription;
  StreamSubscription? _agencySubscription;
  Agency? _currentAgency;

  ProfileBloc({
    required GetProfileUseCase getProfile,
    required GetSubscriptionHistoryUseCase getSubscriptionHistory,
    required GetAgencyProfileUseCase getAgencyProfile,
    required AgencyRepository agencyRepository,
  })  : _getProfile = getProfile,
        _getSubscriptionHistory = getSubscriptionHistory,
        _getAgencyProfile = getAgencyProfile,
        _agencyRepository = agencyRepository,
        super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<LoadAgencyProfile>(_onLoadAgencyProfile);
    on<_InternalUpdate>(_onInternalUpdate);
    on<_InternalError>(_onInternalError);
    on<UpdateAgencySettings>(_onUpdateAgencySettings);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading(isAgencyView: false));
    
    _currentAgency = null;
    await _profileSubscription?.cancel();
    await _historySubscription?.cancel();

    final profileStream = _getProfile(event.uid);
    final historyStream = _getSubscriptionHistory(uid: event.uid);

    ProfileEntity? latestProfile;
    List<SubscriptionRecord>? latestHistory;

    _profileSubscription = profileStream.listen(
      (profile) {
        if (!isClosed) {
          latestProfile = profile;
          add(_InternalUpdate(latestProfile, latestHistory));
        }
      },
      onError: (e) {
        if (!isClosed) {
          add(_InternalError(e.toString()));
        }
      },
    );

    _historySubscription = historyStream.listen(
      (history) {
        if (!isClosed) {
          latestHistory = history;
          add(_InternalUpdate(latestProfile, latestHistory));
        }
      },
      onError: (e) {
        if (!isClosed) {
          add(_InternalError(e.toString()));
        }
      },
    );
  }

  Future<void> _onLoadAgencyProfile(LoadAgencyProfile event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading(isAgencyView: true));

    try {
      // 1. Start Streams
      await _profileSubscription?.cancel();
      await _historySubscription?.cancel();
      await _agencySubscription?.cancel();

      final profileStream = _getProfile(event.uid);
      final historyStream = _getSubscriptionHistory(agencyId: event.agencyId); // Fetch by Agency ID
      final agencyStream = _getAgencyProfile(event.agencyId);

      ProfileEntity? latestProfile;
      List<SubscriptionRecord>? latestHistory;

      // Listen to Agency updates
      _agencySubscription = agencyStream.listen(
        (agency) {
          if (!isClosed) {
             _currentAgency = agency;
             // Trigger update with latest known profile/history
             add(_InternalUpdate(latestProfile, latestHistory));
          }
        },
        onError: (e) {
             if (!isClosed) add(_InternalError(e.toString()));
        }
      );

      // Listen to Profile updates (Salesman data still needed for context)
      _profileSubscription = profileStream.listen(
        (profile) {
          if (!isClosed) {
            latestProfile = profile;
            add(_InternalUpdate(latestProfile, latestHistory));
          }
        },
        onError: (e) {
          if (!isClosed) {
            add(_InternalError(e.toString()));
          }
        },
      );

      // Listen to Subscription History updates
      _historySubscription = historyStream.listen(
        (history) {
          if (!isClosed) {
            latestHistory = history;
            add(_InternalUpdate(latestProfile, latestHistory));
          }
        },
        onError: (e) {
          if (!isClosed) {
            add(_InternalError(e.toString()));
          }
        },
      );
      
    } catch (e) {
      emit(ProfileError(e.toString(), isAgencyView: true));
    }
  }

  // REvising strategy based on the above valid concern:
  // If we are in Agency View, we still need the base ProfileEntity because the State requires it.
  // So `LoadAgencyProfile` should probably also trigger the profile streams OR we should just update `isAgencyView`
  // and fetch agency details as a side effect.
  
  // Implementation Plan said: "Dispatch LoadAgencyProfile if in Agency View".
  // Let's modify LoadAgencyProfile to also take UID, or fetch it? 
  // No, let's stick to the plan but make it robust.
  // We will start the streams in `LoadAgencyProfile` too (requires UID).
  // Wait, `LoadAgencyProfile` in the plan only had `agencyId`.
  // I should probably update `LoadAgencyProfile` to include `uid` as well so we can fetch the profile 
  // which is a required field in `ProfileLoaded`.
  // OR, I can make `ProfileEntity` nullable in `ProfileLoaded`, but that breaks existing UI code.
  
  // Let's MODIFY the plan slightly during execution for correctness:
  // Update LoadAgencyProfile to take (uid, agencyId).
  
  void _onInternalUpdate(_InternalUpdate event, Emitter<ProfileState> emit) {
    if (event.profile != null && event.history != null) {
      final history = event.history!;
      final totalSubscriptions = history.length;
      final totalAmountPaid = history.fold<double>(0, (sum, record) => sum + record.amount);

      final updatedProfile = event.profile!.copyWith(
        totalSubscriptions: totalSubscriptions,
        totalAmountPaid: totalAmountPaid,
      );

      // Preserve existing agency data and view mode if possible, 
      // but _InternalUpdate doesn't know about them.
      // We checks state.
      bool isAgencyView = false;
      
      if (state is ProfileLoaded) {
        isAgencyView = state.isAgencyView;
      } else if (state is ProfileLoading) {
         isAgencyView = state.isAgencyView;
      }

      emit(ProfileLoaded(updatedProfile, history, agency: _currentAgency, isAgencyView: isAgencyView));
    }
  }

  void _onInternalError(_InternalError event, Emitter<ProfileState> emit) {
    emit(ProfileError(event.message, isAgencyView: state.isAgencyView));
  }

  Future<void> _onUpdateAgencySettings(UpdateAgencySettings event, Emitter<ProfileState> emit) async {
    try {
      await _agencyRepository.updateAgencySettings(event.agencyId, event.settings);
      // The stream listener on agency will automatically update the UI when the data changes in Firebase
    } catch (e) {
      emit(ProfileError(e.toString(), isAgencyView: state.isAgencyView));
    }
  }

  @override
  Future<void> close() async {
    // Await each cancellation individually and swallow platform errors
    // (e.g. MissingPluginException on Flutter Web when Firebase RTDB
    //  platform-channel streams are cancelled during widget disposal).
    for (final sub in [
      _profileSubscription,
      _historySubscription,
      _agencySubscription,
    ]) {
      try {
        await sub?.cancel();
      } catch (_) {
        // Intentionally swallow — platform may not support stream cancel on web
      }
    }
    return super.close();
  }
}
