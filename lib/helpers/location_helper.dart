import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_settings/app_settings.dart';

Future<bool> ensureLocationEnabled(BuildContext context) async {
  LocationPermission permission = await Geolocator.checkPermission();

  // Si NO tiene permisos, pide permisos primero
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      if (!context.mounted) return false;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permiso requerido'),
          content: const Text('Debes permitir acceso a la ubicación.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppSettings.openAppSettings(); // Abre permisos de la app
              },
              child: const Text('Otorgar permisos'),
            ),
          ],
        ),
      );
      return false;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    if (!context.mounted) return false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso denegado permanentemente'),
        content: const Text(
            'Activa la ubicación en la configuración del teléfono para poder usar la app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppSettings.openAppSettings(); // Lleva a permisos de app
            },
            child: const Text('Abrir configuración'),
          ),
        ],
      ),
    );
    return false;
  }

  // Si SÍ tiene permisos, ahora verifica si el GPS está activo
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!context.mounted) return false;
  if (!serviceEnabled) {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubicación desactivada'),
        content: const Text('Por favor activa el GPS para continuar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return false;
  }

  return true;
}
