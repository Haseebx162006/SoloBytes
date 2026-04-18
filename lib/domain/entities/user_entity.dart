class UserEntity {
  const UserEntity({
    required this.uid,
    required this.email,
    required this.isAnonymous,
  });

  final String uid;
  final String? email;
  final bool isAnonymous;
}
