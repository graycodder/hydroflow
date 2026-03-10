import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watermemo/features/auth/domain/repositories/agency_repository.dart';
import 'package:watermemo/features/auth/domain/entities/agency.dart';
import 'package:watermemo/features/auth/domain/entities/salesman.dart';
import 'package:watermemo/features/auth/presentation/bloc/agency_event.dart';
import 'package:watermemo/features/auth/presentation/bloc/agency_state.dart';

class AgencyBloc extends Bloc<AgencyEvent, AgencyState> {
  final AgencyRepository _agencyRepository;

  AgencyBloc({required AgencyRepository agencyRepository})
      : _agencyRepository = agencyRepository,
        super(AgencyInitial()) {
    on<LoadAgencySalesmen>(_onLoadAgencySalesmen);
    on<ResetDevice>(_onResetDevice);
    on<AddSalesman>(_onAddSalesman);
    on<UpdateSalesman>(_onUpdateSalesman);
    on<ResetAgency>((event, emit) => emit(AgencyInitial()));
  }

  Future<void> _onLoadAgencySalesmen(
    LoadAgencySalesmen event,
    Emitter<AgencyState> emit,
  ) async {
    emit(AgencyLoading());
    try {
      final results = await Future.wait([
        _agencyRepository.getSalesmenByAgency(event.agencyId),
        _agencyRepository.getAgencyDetails(event.agencyId),
      ]);
      
      final salesmen = results[0] as List<Salesman>;
      final agency = results[1] as Agency?;
      
      emit(AgencySalesmenLoaded(salesmen: salesmen, agency: agency));
    } catch (e) {
      emit(AgencyFailure('Failed to load salesmen: $e'));
    }
  }

  Future<void> _onResetDevice(
    ResetDevice event,
    Emitter<AgencyState> emit,
  ) async {
    emit(AgencyLoading());
    try {
      await _agencyRepository.resetDeviceBinding(event.salesmanId);
      final salesmen = await _agencyRepository.getSalesmenByAgency(event.agencyId);
      emit(AgencySalesmenLoaded(salesmen: salesmen));
    } catch (e) {
      emit(AgencyFailure('Failed to reset device: $e'));
    }
  }

  Future<void> _onAddSalesman(
    AddSalesman event,
    Emitter<AgencyState> emit,
  ) async {
    emit(AgencyLoading());
    try {
      await _agencyRepository.addSalesman(event.salesman);
      final salesmen = await _agencyRepository.getSalesmenByAgency(event.salesman.agencyId);
      // Retrieve current agency details if possible, or keep existing if state was loaded
      Agency? agency;
      if (state is AgencySalesmenLoaded) {
        agency = (state as AgencySalesmenLoaded).agency;
      } else {
        agency = await _agencyRepository.getAgencyDetails(event.salesman.agencyId);
      }
      
      emit(AgencySalesmenLoaded(salesmen: salesmen, agency: agency, message: 'Salesman added successfully'));
    } catch (e) {
      emit(AgencyFailure('Failed to add salesman: $e'));
      try {
         final salesmen = await _agencyRepository.getSalesmenByAgency(event.salesman.agencyId);
         // Restore list if failed
          Agency? agency;
          if (state is AgencySalesmenLoaded) {
            agency = (state as AgencySalesmenLoaded).agency;
          }
         emit(AgencySalesmenLoaded(salesmen: salesmen, agency: agency));
      } catch (_) {}
    }
  }

  Future<void> _onUpdateSalesman(
    UpdateSalesman event,
    Emitter<AgencyState> emit,
  ) async {
    emit(AgencyLoading());
    try {
      await _agencyRepository.updateSalesman(event.salesman);
      final salesmen = await _agencyRepository.getSalesmenByAgency(event.salesman.agencyId);
      
      Agency? agency;
      if (state is AgencySalesmenLoaded) {
        agency = (state as AgencySalesmenLoaded).agency;
      } else {
        agency = await _agencyRepository.getAgencyDetails(event.salesman.agencyId);
      }

      emit(AgencySalesmenLoaded(salesmen: salesmen, agency: agency, message: 'Salesman updated successfully'));
    } catch (e) {
      emit(AgencyFailure('Failed to update salesman: $e'));
      try {
         final salesmen = await _agencyRepository.getSalesmenByAgency(event.salesman.agencyId);
          Agency? agency;
          if (state is AgencySalesmenLoaded) {
            agency = (state as AgencySalesmenLoaded).agency;
          }
         emit(AgencySalesmenLoaded(salesmen: salesmen, agency: agency));
      } catch (_) {}
    }
  }
}
