class Usuario {
  final int? id;
  final String username;
  final String password;
  final String rol; // 'admin' o 'vendedor'

  Usuario({
    this.id,
    required this.username,
    required this.password,
    required this.rol,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'rol': rol,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      rol: map['rol'],
    );
  }
}