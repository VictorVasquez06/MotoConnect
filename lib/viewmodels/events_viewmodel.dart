import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

/// Enum para representar los posibles estados de la carga de eventos.
///
/// Esto permite a la UI reaccionar a diferentes estados de una manera
/// más clara y robusta que usando simples booleanos.
enum EventStatus { initial, loading, success, error }

/// ViewModel para la pantalla de eventos.
///
/// Gestiona el estado de la UI, como el estado de carga y la lista de eventos.
/// Se comunica con [EventService] para obtener los datos y notifica a la
/// vista de cualquier cambio a través de [ChangeNotifier].
class EventsViewModel extends ChangeNotifier {
  final EventService _eventService = EventService();

  List<Event> _events = [];
  List<Event> get events => _events;

  EventStatus _status = EventStatus.initial;
  EventStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Carga la lista de eventos desde el servicio.
  ///
  /// Cambia el estado a `loading`, luego intenta obtener los eventos.
  /// Si tiene éxito, actualiza la lista de eventos y cambia el estado a `success`.
  /// Si falla, guarda el mensaje de error y cambia el estado a `error`.
  Future<void> fetchEvents() async {
    _status = EventStatus.loading;
    notifyListeners();

    try {
      _events = await _eventService.getEvents();
      _status = EventStatus.success;
    } catch (e) {
      _errorMessage = 'No se pudieron cargar los eventos.';
      _status = EventStatus.error;
    }

    notifyListeners();
  }
}