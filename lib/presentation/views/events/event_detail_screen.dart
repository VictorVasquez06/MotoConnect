import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/event_model.dart';
import '../../viewmodels/events/events_viewmodel.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsViewModel>().loadEventDetail(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<EventsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = viewModel.selectedEvent;
          if (event == null) {
            return const Center(child: Text('Evento no encontrado'));
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(event),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventInfo(event),
                      const SizedBox(height: 24),
                      _buildDescription(event),
                      const SizedBox(height: 24),
                      _buildLocationInfo(event),
                      const SizedBox(height: 24),
                      _buildParticipants(event),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: _buildBottomActions(),
    );
  }

  Widget _buildAppBar(EventModel event) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          event.title,
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
        background:
            event.imageUrl != null
                ? Image.network(
                  event.imageUrl!,
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
                        Theme.of(context).primaryColor.withValues(alpha: 0.7),
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

  Widget _buildEventInfo(EventModel event) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha',
              _formatDate(event.date),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.access_time,
              'Hora',
              event.time ?? 'Por confirmar',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.people,
              'Participantes',
              '${event.participantsCount ?? 0} inscritos',
            ),
            if (event.maxParticipants != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                Icons.group_add,
                'Capacidad',
                '${event.participantsCount ?? 0}/${event.maxParticipants}',
              ),
            ],
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

  Widget _buildDescription(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          event.description ?? 'Sin descripción disponible',
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(EventModel event) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ubicación',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Abrir mapa
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('Ver mapa'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.location ?? 'Ubicación por confirmar',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipants(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participantes',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (event.participantsCount == 0)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Sé el primero en unirte'),
                    ),
                  )
                else
                  // TODO: Mostrar lista de participantes
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Cargando participantes...'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Consumer<EventsViewModel>(
      builder: (context, viewModel, child) {
        final event = viewModel.selectedEvent;
        if (event == null) return const SizedBox.shrink();

        final isRegistered = event.isUserRegistered ?? false;
        final isFull =
            event.maxParticipants != null &&
            (event.participantsCount ?? 0) >= event.maxParticipants!;

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (isFull && !isRegistered)
                            ? null
                            : () {
                              if (isRegistered) {
                                viewModel.unregisterFromEvent(event.id);
                              } else {
                                viewModel.registerForEvent(event.id);
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isRegistered
                          ? 'Cancelar inscripción'
                          : isFull
                          ? 'Evento lleno'
                          : 'Unirse al evento',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    // TODO: Compartir evento
                  },
                  icon: const Icon(Icons.share),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}
