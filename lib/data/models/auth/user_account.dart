class UserAccount {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String initials;
  final bool hasPin;

  const UserAccount({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.initials,
    required this.hasPin,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as int,
      username: json['username'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      hasPin: json['hasPin'] as bool? ?? false,
    );
  }
}
