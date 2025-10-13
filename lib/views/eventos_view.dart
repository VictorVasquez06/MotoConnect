import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/events_viewmodel.dart';
import '../models/event_model.dart';

/// La Vista (View) para la pantalla de eventos.
///
/// Utiliza `ChangeNotifierProvider` para crear e inyectar el `EventsViewModel`.
/// El ViewModel se inicializa llamando a `fetchEvents()` inmediatamente después
/// de su creación.
class EventosScreen extends StatelessWidget {
  const EventosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Se crea el ViewModel y se llama al método para cargar los eventos.
      create: (context) => EventsViewModel()..fetchEvents(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Próximos Eventos'),
        ),
        // El cuerpo de la vista consume el estado del ViewModel.
        body: Consumer<EventsViewModel>(
          builder: (context, viewModel, child) {
            // Se muestra una UI diferente según el estado de carga.
            switch (viewModel.status) {
              case EventStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case EventStatus.error:
                return Center(child: Text(viewModel.errorMessage ?? 'Error desconocido'));
              case EventStatus.success:
                return _EventList(events: viewModel.events);
              default:
                return const SizedBox.shrink();
            }
          },
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

  const _EventList({required this.events, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text('No hay eventos próximos.'));
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        // Cada evento se muestra en una tarjeta con un diseño limpio.
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(event.title, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text('${event.location}\n${event.date.toLocal()}'),
            isThreeLine: true,
            onTap: () {
              // Lógica para ver detalles del evento (futura implementación)
            },
          ),
        );
      },
    );
  }
}