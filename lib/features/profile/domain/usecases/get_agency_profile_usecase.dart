import 'package:hydroflow/features/profile/domain/repositories/profile_repository.dart';
import 'package:hydroflow/features/auth/domain/entities/agency.dart';

class GetAgencyProfileUseCase {
  final ProfileRepository repository;

  GetAgencyProfileUseCase(this.repository);

  Stream<Agency> call(String agencyId) {
    return repository.getAgencyProfile(agencyId);
  }
}
