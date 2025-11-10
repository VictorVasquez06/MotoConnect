/// Representa el modelo de datos para un evento.
///
/// Encapsula toda la información relacionada con un evento,
/// como su título, descripción, fecha y lugar.
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
  });

  /// Factory constructor para crear una instancia de Event desde un mapa (JSON).
  /// Esto es útil cuando se decodifican datos de una API.
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['eventId'],
      title: json['titulo'],
      description: json['descripcion'],
      date: DateTime.parse(json['fecha']),
      location: json['puntoEncuentro'],
    );
  }
}