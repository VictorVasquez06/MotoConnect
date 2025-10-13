import '../models/event_model.dart';

/// Servicio para gestionar los datos de los eventos.
///
/// Abstrae la obtención de datos de eventos. En una implementación real,
/// realizaría llamadas HTTP al microservicio de eventos. Por ahora,
/// devuelve datos de ejemplo para simular la respuesta de la API.
class EventService {

  /// Obtiene una lista de eventos desde el backend.
  ///
  /// Devuelve una lista de objetos [Event] simulados.
  /// En una aplicación real, esto implicaría una llamada de red y podría lanzar
  /// excepciones si la llamada falla.
  Future<List<Event>> getEvents() async {
    // Simula un retardo de red.
    await Future.delayed(const Duration(seconds: 1));

    // Simula una respuesta de la API en formato JSON.
    // Estos datos coinciden con la API definida en la documentación de microservicios.
    final List<Map<String, dynamic>> mockData = [
      {
        "eventId": "evt-abc-123",
        "titulo": "Rodada de Fin de Semana",
        "descripcion": "Una rodada por la montaña para disfrutar del paisaje.",
        "fecha": "2023-11-15T09:00:00Z",
        "puntoEncuentro": "Monumento Principal"
      },
      {
        "eventId": "evt-def-456",
        "titulo": "Café y Motos",
        "descripcion": "Juntada casual para hablar de motos y tomar café.",
        "fecha": "2023-11-20T17:00:00Z",
        "puntoEncuentro": "Cafetería 'El Pistón'"
      }
    ];

    // Mapea la lista de JSON a una lista de objetos Event.
    return mockData.map((json) => Event.fromJson(json)).toList();
  }
}