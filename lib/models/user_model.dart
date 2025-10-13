/// Representa el modelo de datos de un usuario en la aplicación.
///
/// Este modelo se utiliza para encapsular la información del usuario
/// que se obtiene, por ejemplo, del servicio de autenticación o
/// del servicio de perfiles.
class User {
  final String uid;
  final String email;
  final String? displayName;

  User({required this.uid, required this.email, this.displayName});
}