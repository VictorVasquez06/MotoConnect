import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../core/config/supabase_config.dart';

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

  // Getter para evaluación perezosa (lazy evaluation)
  // Esto previene el error de acceso a Supabase antes de inicialización
  SupabaseClient get _supabase => SupabaseConfig.client;

  List<Event> _events = [];
  List<Event> get events => _events;

  EventStatus _status = EventStatus.initial;
  EventStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Event? _selectedEvent;
  Event? get selectedEvent => _selectedEvent;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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

  /// Carga los detalles de un evento específico
  Future<void> loadEventDetail(String eventId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final respuesta = await _supabase
          .from('eventos')
          .select()
          .eq('id', eventId)
          .single();

      _selectedEvent = Event.fromJson(respuesta);
      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar evento: ${e.toString()}';
      _selectedEvent = null;
      _isLoading = false;
    }

    notifyListeners();
  }

  /// Registra al usuario en un evento
  Future<void> registerForEvent(String eventId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('event_participants').insert({
        'event_id': eventId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Recargar el evento para actualizar la lista de participantes
      await loadEventDetail(eventId);
    } catch (e) {
      _errorMessage = 'Error al registrarse en el evento: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancela la inscripción del usuario en un evento
  Future<void> unregisterFromEvent(String eventId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _supabase
          .from('event_participants')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);

      // Recargar el evento para actualizar la lista de participantes
      await loadEventDetail(eventId);
    } catch (e) {
      _errorMessage = 'Error al cancelar inscripción: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
