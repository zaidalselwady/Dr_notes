class User {
  final int userId; // User ID
  final String userName; // User name
  final String password; // User password (preferably hashed)
  final int userType; // User type (e.g., admin = 1, user = 2)
  final String permissions; // User permissions as a comma-separated string
  final bool rememberMe;

  User({
    required this.userId,
    required this.userName,
    required this.password,
    required this.userType,
    required this.permissions,
    required this.rememberMe,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['User_Id'],
      userName: json['User_Name'],
      password: json['Password'],
      userType: json['User_Type'],
      permissions: json['Permissions'] ?? "",
      rememberMe: json['Remember_Me'] ?? false,
    );
  }

  // Convert the User object to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'User_Id': userId,
      'User_Name': userName,
      'Password': password,
      'User_Type': userType,
      'Permissions': permissions,
      'Remember_Me': rememberMe,
    };
  }

  // Create a User object from a map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['User_Id'] as int,
      userName: map['User_Name'] as String,
      password: map['Password'] as String,
      userType: map['User_Type'] as int,
      permissions: map['Permissions'] as String,
      rememberMe: map['Remember_Me'] as bool,
    );
  }

 
}
