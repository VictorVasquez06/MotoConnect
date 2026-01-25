/// Utilidad de Colores para Marcadores de Mapa
///
/// Define el pool de colores disponibles y conversiones
library;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class MapColors {
  /// Pool de 10 colores distintos para marcadores
  static const List<double> hues = [
    0.0,    // 0: Rojo
    30.0,   // 1: Naranja
    60.0,   // 2: Amarillo
    120.0,  // 3: Verde
    180.0,  // 4: Cian
    210.0,  // 5: Azul claro
    240.0,  // 6: Azul
    270.0,  // 7: Violeta
    300.0,  // 8: Magenta
    330.0,  // 9: Rosa
  ];

  /// Nombres de colores en español
  static const List<String> nombres = [
    'Rojo',
    'Naranja',
    'Amarillo',
    'Verde',
    'Cian',
    'Azul Claro',
    'Azul',
    'Violeta',
    'Magenta',
    'Rosa',
  ];

  /// Colores para UI (Flutter Colors)
  static const List<Color> coloresUI = [
    Colors.red,        // 0
    Colors.orange,     // 1
    Colors.yellow,     // 2
    Colors.green,      // 3
    Colors.cyan,       // 4
    Colors.lightBlue,  // 5
    Colors.blue,       // 6
    Colors.purple,     // 7
    Colors.pink,       // 8
    Color(0xFFFF1493), // 9: DeepPink (rosa fuerte)
  ];

  /// Obtener BitmapDescriptor por índice
  static BitmapDescriptor getMarkerIcon(int colorIndex) {
    final index = colorIndex.clamp(0, 9); // Asegurar rango válido
    return BitmapDescriptor.defaultMarkerWithHue(hues[index]);
  }

  /// Obtener nombre del color por índice
  static String getNombreColor(int colorIndex) {
    final index = colorIndex.clamp(0, 9);
    return nombres[index];
  }

  /// Obtener Color de UI por índice
  static Color getColorUI(int colorIndex) {
    final index = colorIndex.clamp(0, 9);
    return coloresUI[index];
  }

  /// Generar color aleatorio (0-9)
  static int generarColorAleatorio() {
    return DateTime.now().millisecondsSinceEpoch % 10;
  }

  /// Color especial para usuario pausado (gris)
  static BitmapDescriptor get markerPausado {
    // Gris no está en el pool de colores, es especial
    return BitmapDescriptor.defaultMarkerWithHue(0.0); // Usar rojo con alpha
    // Nota: BitmapDescriptor no soporta alpha, usar custom marker si se necesita
  }

  /// Validar índice de color
  static bool esIndiceValido(int index) {
    return index >= 0 && index < 10;
  }
}
