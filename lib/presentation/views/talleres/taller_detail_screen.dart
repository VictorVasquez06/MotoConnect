import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/taller_model.dart';
import '../../viewmodels/talleres/talleres_viewmodel.dart';

class TallerDetailScreen extends StatefulWidget {
  final String tallerId;

  const TallerDetailScreen({super.key, required this.tallerId});

  @override
  State<TallerDetailScreen> createState() => _TallerDetailScreenState();
}

class _TallerDetailScreenState extends State<TallerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TalleresViewModel>().loadTallerDetail(widget.tallerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TalleresViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final taller = viewModel.selectedTaller;
          if (taller == null) {
            return const Center(child: Text('Taller no encontrado'));
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(taller),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTallerInfo(taller),
                      const SizedBox(height: 24),
                      _buildDescription(taller),
                      const SizedBox(height: 24),
                      _buildServices(taller),
                      const SizedBox(height: 24),
                      _buildContactInfo(taller),
                      const SizedBox(height: 24),
                      _buildSchedule(taller),
                      const SizedBox(height: 24),
                      _buildLocation(taller),
                      const SizedBox(height: 24),
                      _buildReviews(taller),
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

  Widget _buildAppBar(TallerModel taller) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          taller.name,
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
            taller.imageUrl != null
                ? Image.network(
                  taller.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultBackground();
                  },
                )
                : _buildDefaultBackground(),
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
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
        child: Icon(Icons.build, size: 80, color: Colors.white54),
      ),
    );
  }

  Widget _buildTallerInfo(TallerModel taller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 32),
                const SizedBox(width: 8),
                Text(
                  taller.rating?.toStringAsFixed(1) ?? '0.0',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${taller.reviewsCount ?? 0} reseñas)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(taller.isOpen),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    taller.isOpen == true ? 'Abierto' : 'Cerrado',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(
                  Icons.motorcycle,
                  taller.specialization ?? 'General',
                ),
                if (taller.yearsExperience != null)
                  _buildInfoChip(
                    Icons.history,
                    '${taller.yearsExperience} años',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDescription(TallerModel taller) {
    if (taller.description == null || taller.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acerca de',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          taller.description!,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildServices(TallerModel taller) {
    if (taller.services == null || taller.services!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servicios',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: taller.services!.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final service = taller.services![index];
              return ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  service.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle:
                    service.description != null
                        ? Text(service.description!)
                        : null,
                trailing:
                    service.price != null
                        ? Text(
                          '\$${service.price!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                        : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(TallerModel taller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contacto',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (taller.phone != null)
              _buildContactItem(
                Icons.phone,
                taller.phone!,
                () => _makePhoneCall(taller.phone!),
              ),
            if (taller.email != null) ...[
              const SizedBox(height: 12),
              _buildContactItem(
                Icons.email,
                taller.email!,
                () => _sendEmail(taller.email!),
              ),
            ],
            if (taller.website != null) ...[
              const SizedBox(height: 12),
              _buildContactItem(
                Icons.language,
                taller.website!,
                () => _openWebsite(taller.website!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Widget _buildSchedule(TallerModel taller) {
    if (taller.schedule == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horario',
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
                _buildScheduleRow(
                  'Lunes - Viernes',
                  taller.schedule!['weekdays'],
                ),
                if (taller.schedule!['saturday'] != null) ...[
                  const Divider(height: 24),
                  _buildScheduleRow('Sábado', taller.schedule!['saturday']),
                ],
                if (taller.schedule!['sunday'] != null) ...[
                  const Divider(height: 24),
                  _buildScheduleRow('Domingo', taller.schedule!['sunday']),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(String day, String? hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        Text(
          hours ?? 'Cerrado',
          style: TextStyle(
            fontSize: 16,
            color: hours != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLocation(TallerModel taller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ubicación',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                // TODO: Abrir en Google Maps
              },
              icon: const Icon(Icons.directions),
              label: const Text('Cómo llegar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Column(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(Icons.map, size: 64, color: Colors.grey[600]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        taller.address ?? 'Dirección no disponible',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviews(TallerModel taller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reseñas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // TODO: Ver todas las reseñas
              },
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                taller.reviewsCount == 0
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('No hay reseñas aún'),
                      ),
                    )
                    : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('Cargando reseñas...'),
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Consumer<TalleresViewModel>(
      builder: (context, viewModel, child) {
        final taller = viewModel.selectedTaller;
        if (taller == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Agendar cita
                      _showAppointmentDialog();
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text(
                      'Agendar cita',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _makePhoneCall(taller.phone ?? ''),
                  icon: const Icon(Icons.phone),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
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

  Color _getStatusColor(bool? isOpen) {
    if (isOpen == null) return Colors.grey;
    return isOpen ? Colors.green : Colors.red;
  }

  void _makePhoneCall(String phone) {
    // TODO: Implementar llamada telefónica
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Llamando a $phone')));
  }

  void _sendEmail(String email) {
    // TODO: Implementar envío de email
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Abriendo correo para $email')));
  }

  void _openWebsite(String website) {
    // TODO: Implementar apertura de navegador
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Abriendo $website')));
  }

  void _showAppointmentDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Agendar cita'),
            content: const Text(
              'Esta función estará disponible próximamente. '
              'Por ahora, puedes llamar directamente al taller.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CERRAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  final taller =
                      context.read<TalleresViewModel>().selectedTaller;
                  if (taller?.phone != null) {
                    _makePhoneCall(taller!.phone!);
                  }
                },
                child: const Text('LLAMAR'),
              ),
            ],
          ),
    );
  }
}
