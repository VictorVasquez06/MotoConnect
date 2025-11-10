import 'package:flutter/material.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/event_repository.dart';

/// Enum para representar los posibles estados de la carga de eventos.
///
/// Esto permite a la UI reaccionar a diferentes estados de una manera
/// más clara y robusta que usando simples booleanos.
enum EventStatus { initial, loading, success, error }

/// ViewModel para la pantalla de eventos.
///
/// Gestiona el estado de la UI, como el estado de carga y la lista de eventos.
/// Se comunica con [EventRepository] para obtener los datos y notifica a la
/// vista de cualquier cambio a través de [ChangeNotifier].
class EventsViewModel extends ChangeNotifier {
  // Cambiado de EventService a EventRepository (patrón correcto)
  final EventRepository _eventRepository = EventRepository();

  List<Event> _events = [];
  List<Event> get events => _events;

  EventStatus _status = EventStatus.initial;
  EventStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Carga la lista de eventos desde el repositorio.
  ///
  /// Cambia el estado a `loading`, luego intenta obtener los eventos.
  /// Si tiene éxito, actualiza la lista de eventos y cambia el estado a `success`.
  /// Si falla, guarda el mensaje de error y cambia el estado a `error`.
  Future<void> fetchEvents() async {
    _status = EventStatus.loading;
    notifyListeners();

    try {
      // Usa el Repository en lugar del Service directamente
      _events = await _eventRepository.getEvents();
      _status = EventStatus.success;
    } catch (e) {
      _errorMessage = 'No se pudieron cargar los eventos: ${e.toString()}';
      _status = EventStatus.error;
    }

    notifyListeners();
  }

  /// Recarga los eventos
  Future<void> refreshEvents() async {
    await fetchEvents();
  }
}
