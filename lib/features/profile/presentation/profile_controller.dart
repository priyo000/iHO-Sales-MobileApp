import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileController extends Notifier<ProfileControllerState> {
  @override
  ProfileControllerState build() {
    return const ProfileControllerState();
  }

  Future<void> logout() async {
    // call auth logout
  }
}

class ProfileControllerState {
  final ProfileUser? user;
  const ProfileControllerState({this.user});
  ProfileControllerState copyWith({ProfileUser? user}) =>
      ProfileControllerState(user: user ?? this.user);
}

class ProfileUser {
  final String? nama;
  final String? email;
  final String? role;
  const ProfileUser({this.nama, this.email, this.role});
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileControllerState>(
      ProfileController.new,
    );
