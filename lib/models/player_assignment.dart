import 'package:jinro_flutter/models/role.dart';

class PlayerAssignment {
  final String name;
  final Role role;
  final String password;

  PlayerAssignment({
    required this.name,
    required this.role,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'password': password,
        'role': role.toJson(),
      };

  // Factory for when we load from the DB with the role joined
  factory PlayerAssignment.fromSupabase(Map<String, dynamic> json) {
    return PlayerAssignment(
      name: json['player_name'],
      password: json['password'],
      role: Role.fromJson(json['roles']), // 'roles' is the joined table data
    );
  }
}
