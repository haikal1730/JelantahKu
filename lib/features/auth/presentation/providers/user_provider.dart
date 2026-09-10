import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_role.dart';

class UserProfile {
  final String id;
  final String name;
  final String village;
  final UserRole role;

  const UserProfile({
    required this.id,
    required this.name,
    required this.village,
    required this.role,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? village,
    UserRole? role,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      village: village ?? this.village,
      role: role ?? this.role,
    );
  }
}

class UserNotifier extends StateNotifier<UserProfile> {
  UserNotifier()
      : super(const UserProfile(
          id: 'USR-8821',
          name: 'Mukhammad Rangga',
          village: 'Desa Suka Makmur',
          role: UserRole.warga,
        ));

  void setProfile({
    required String id,
    required String name,
    String? village,
    UserRole? role,
  }) {
    state = state.copyWith(
      id: id,
      name: name,
      village: village ?? state.village,
      role: role ?? state.role,
    );
  }

}

final userNotifierProvider =
    StateNotifierProvider<UserNotifier, UserProfile>((ref) {
  return UserNotifier();
});
