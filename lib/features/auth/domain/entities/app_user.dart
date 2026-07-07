class AppUser {
  final String id;
  final String? email;
  final String? nombre;

  const AppUser({
    required this.id,
    this.email,
    this.nombre,
  });
}
