import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/events/events_viewmodel.dart';
import '../../../data/models/event_model.dart';

/// La Vista (View) para la pantalla de eventos.
///
/// Utiliza `ChangeNotifierProvider` para crear e inyectar el `EventsViewModel`.
/// El ViewModel se inicializa llamando a `fetchEvents()` inmediatamente después
/// de su creación.
class EventosScreen extends StatelessWidget {
  const EventosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Se crea el ViewModel y se llama al método para cargar los eventos.
      create: (context) => EventsViewModel()..fetchEvents(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Próximos Eventos'),
          actions: [
            // Botón de refrescar
            Consumer<EventsViewModel>(
              builder: (context, viewModel, _) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed:
                      viewModel.status == EventStatus.loading
                          ? null
                          : () => viewModel.refreshEvents(),
                );
              },
            ),
          ],
        ),
        // El cuerpo de la vista consume el estado del ViewModel.
        body: Consumer<EventsViewModel>(
          builder: (context, viewModel, child) {
            // Se muestra una UI diferente según el estado de carga.
            switch (viewModel.status) {
              case EventStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case EventStatus.error:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        viewModel.errorMessage ?? 'Error desconocido',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => viewModel.refreshEvents(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              case EventStatus.success:
                return _EventList(events: viewModel.events);
              default:
                return const SizedBox.shrink();
            }
          },
        ),
        // Botón flotante para crear evento (opcional)
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Navegar a pantalla de crear evento
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función de crear evento próximamente'),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/// Widget para mostrar la lista de eventos.
///
/// Recibe la lista de eventos y la renderiza.
class _EventList extends StatelessWidget {
  final List<Event> events;

  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay eventos próximos',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<EventsViewModel>().refreshEvents();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _EventCard(event: event);
        },
      ),
    );
  }
}

/// Widget de tarjeta para mostrar un evento
class _EventCard extends StatelessWidget {
  final Event event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalle del evento
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Evento: ${event.title}')));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título del evento
              Text(
                event.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Fecha y hora
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(event.date),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Ubicación
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Descripción
              if (event.description.isNotEmpty)
                Text(
                  event.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
