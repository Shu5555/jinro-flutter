import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jinro_flutter/services/data_service.dart';
import 'package:jinro_flutter/services/role_assignment_service.dart';

final roleAssignmentServiceProvider = Provider<RoleAssignmentService>((ref) {
  // Assuming RoleService has no dependencies. If it does, it should also be a provider.
  return RoleAssignmentService(RoleService());
});
