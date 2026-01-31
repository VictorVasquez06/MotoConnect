import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/event_participant_model.dart';
import '../../../data/repositories/event_repository.dart';
import 'create_event_screen.dart';
import '../routes/rutas_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _eventRepository = EventRepository();
  Event? _event;
  List<EventParticipantModel> _participants = [];
  bool _isLoading = true;
  bool _isLoadingParticipants = true;
  EstadoAsistencia? _userAttendanceStatus;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
    _loadParticipants();
  }

  Future<void> _loadEventDetails() async {
    try {
      final event = await _eventRepository.getEventById(widget.eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadParticipants() async {
    try {
      final participants =
          await _eventRepository.getEventParticipantsDetailed(widget.eventId);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      EstadoAsistencia? userStatus;

      if (userId != null) {
        final userParticipant = participants.where(
          (p) => p.usuarioId == userId,
        ).firstOrNull;
        userStatus = userParticipant?.estado;
      }

      if (mounted) {
        setState(() {
          _participants = participants;
          _userAttendanceStatus = userStatus;
          _isLoadingParticipants = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingParticipants = false;
        });
      }
    }
  }

  Future<void> _updateAttendanceStatus(EstadoAsistencia newStatus) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (_userAttendanceStatus == null) {
        // Usuario no está registrado, hacer join con el estado
        await _eventRepository.joinEvent(
          widget.eventId,
          userId,
          estado: newStatus,
        );
      } else if (newStatus == _userAttendanceStatus) {
        // Si hace clic en el mismo estado, lo desinscribe
        await _eventRepository.leaveEvent(widget.eventId, userId);
      } else {
        // Actualizar estado existente
        await _eventRepository.updateAttendanceStatus(
          widget.eventId,
          userId,
          newStatus,
        );
      }

      // Recargar participantes
      await _loadParticipants();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _editEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(event: _event),
      ),
    );

    if (result == true) {
      _loadEventDetails();
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: const Text('¿Estás seguro de eliminar este evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _eventRepository.deleteEvent(widget.eventId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evento eliminado')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  bool get _isCreator {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return userId != null && _event?.createdBy == userId;
  }

  /// Abre la pantalla de rutas hacia una ubicación específica
  void _openRouteToLocation(double lat, double lng, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RutasScreen(
          destinoInicial: LatLng(lat, lng),
          nombreDestino: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return const Scaffold(
        body: Center(child: Text('Evento no encontrado')),
      );
    }

    // Obtener el padding del sistema para zonas seguras
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_event!.grupoNombre != null) ...[
                    _buildGrupoChip(),
                    const SizedBox(height: 16),
                  ],
                  _buildEventInfo(),
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildLocationInfo(),
                  const SizedBox(height: 24),
                  _buildAttendanceButtons(),
                  const SizedBox(height: 24),
                  _buildParticipants(),
                  // Agregar espacio extra al final para zonas seguras
                  SizedBox(height: bottomPadding + 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      actions: [
        if (_isCreator) ...[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editEvent,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteEvent,
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _event!.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        background: _event!.fotoUrl != null
            ? Image.network(
                _event!.fotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.event,
                      size: 80,
                      color: Colors.grey,
                    ),
                  );
                },
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.event, size: 80, color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildGrupoChip() {
    return Chip(
      avatar: const Icon(Icons.group, size: 18),
      label: Text(_event!.grupoNombre!),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
    );
  }

  Widget _buildEventInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha',
              DateFormat('dd/MM/yyyy').format(_event!.date),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.access_time,
              'Hora',
              DateFormat('HH:mm').format(_event!.date),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.people,
              'Participantes',
              '${_participants.length} registrados',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          _event!.description.isEmpty
              ? 'Sin descripción disponible'
              : _event!.description,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicaciones',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        // Punto de Encuentro
        _buildLocationCard(
          icon: Icons.flag,
          title: 'Punto de Encuentro',
          location: _event!.puntoEncuentro,
          latitude: _event!.puntoEncuentroLat,
          longitude: _event!.puntoEncuentroLng,
          onVerRuta: _event!.puntoEncuentroLat != null && _event!.puntoEncuentroLng != null
              ? () => _openRouteToLocation(
                    _event!.puntoEncuentroLat!,
                    _event!.puntoEncuentroLng!,
                    _event!.puntoEncuentro,
                  )
              : null,
        ),
        // Destino
        if (_event!.destino != null && _event!.destino!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildLocationCard(
            icon: Icons.location_on,
            title: 'Destino',
            location: _event!.destino!,
            latitude: _event!.destinoLat,
            longitude: _event!.destinoLng,
            onVerRuta: _event!.destinoLat != null && _event!.destinoLng != null
                ? () => _openRouteToLocation(
                      _event!.destinoLat!,
                      _event!.destinoLng!,
                      _event!.destino!,
                    )
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required String title,
    required String location,
    required double? latitude,
    required double? longitude,
    required VoidCallback? onVerRuta,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (latitude != null && longitude != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Botón "Ver Ruta" si hay coordenadas
            if (onVerRuta != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onVerRuta,
                  icon: const Icon(Icons.directions, size: 20),
                  label: const Text('Ver Ruta'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu estado de asistencia',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAttendanceButton(
                EstadoAsistencia.confirmado,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendanceButton(
                EstadoAsistencia.posible,
                Icons.help_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAttendanceButton(
                EstadoAsistencia.noAsiste,
                Icons.cancel,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceButton(EstadoAsistencia estado, IconData icon) {
    final isSelected = _userAttendanceStatus == estado;
    final color = Color(int.parse(estado.colorHex.substring(1), radix: 16) + 0xFF000000);

    return ElevatedButton(
      onPressed: () => _updateAttendanceStatus(estado),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 4 : 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            estado.displayText,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipants() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participantes (${_participants.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingParticipants)
          const Center(child: CircularProgressIndicator())
        else if (_participants.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Sé el primero en unirte',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          ..._buildParticipantsByStatus(),
      ],
    );
  }

  List<Widget> _buildParticipantsByStatus() {
    final confirmados = _participants.where(
      (p) => p.estado == EstadoAsistencia.confirmado,
    ).toList();
    final posibles = _participants.where(
      (p) => p.estado == EstadoAsistencia.posible,
    ).toList();
    final noAsisten = _participants.where(
      (p) => p.estado == EstadoAsistencia.noAsiste,
    ).toList();

    return [
      if (confirmados.isNotEmpty) ...[
        _buildStatusHeader(EstadoAsistencia.confirmado, confirmados.length),
        ...confirmados.map((p) => _buildParticipantTile(p)),
        const SizedBox(height: 16),
      ],
      if (posibles.isNotEmpty) ...[
        _buildStatusHeader(EstadoAsistencia.posible, posibles.length),
        ...posibles.map((p) => _buildParticipantTile(p)),
        const SizedBox(height: 16),
      ],
      if (noAsisten.isNotEmpty) ...[
        _buildStatusHeader(EstadoAsistencia.noAsiste, noAsisten.length),
        ...noAsisten.map((p) => _buildParticipantTile(p)),
      ],
    ];
  }

  Widget _buildStatusHeader(EstadoAsistencia estado, int count) {
    final color = Color(int.parse(estado.colorHex.substring(1), radix: 16) + 0xFF000000);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            '${estado.displayText} ($count)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(EventParticipantModel participant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage: participant.usuario?.fotoPerfil != null
              ? NetworkImage(participant.usuario!.fotoPerfil!)
              : null,
          child: participant.usuario?.fotoPerfil == null
              ? Text(
                  participant.displayName.isNotEmpty
                      ? participant.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          participant.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          participant.grupoDisplay,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Color(int.parse(
                  participant.estado.colorHex.substring(1),
                  radix: 16,
                ) +
                0xFF000000).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            participant.estado.displayText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(int.parse(
                participant.estado.colorHex.substring(1),
                radix: 16,
              ) + 0xFF000000),
            ),
          ),
        ),
      ),
    );
  }
}
