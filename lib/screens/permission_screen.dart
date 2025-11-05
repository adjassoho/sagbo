import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_localizations.dart';

/// Écran de demande de permissions
class PermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionScreen({
    super.key,
    required this.onPermissionsGranted,
  });

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isCheckingPermissions = false;
  Map<Permission, PermissionStatus> _permissionStatuses = {};

  final List<Permission> _requiredPermissions = [
    Permission.microphone,
    Permission.contacts,
    Permission.phone,
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      // Vérifier le statut de chaque permission
      for (final permission in _requiredPermissions) {
        final status = await permission.status;
        _permissionStatuses[permission] = status;
      }

      // Si toutes les permissions sont accordées, passer à l'écran principal
      if (_permissionStatuses.values.every((status) => status.isGranted)) {
        widget.onPermissionsGranted();
        return;
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des permissions: $e');
    }

    setState(() {
      _isCheckingPermissions = false;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      // Demander toutes les permissions en une fois
      final statuses = await _requiredPermissions.request();
      
      setState(() {
        _permissionStatuses = statuses;
      });

      // Vérifier si toutes les permissions sont accordées
      if (statuses.values.every((status) => status.isGranted)) {
        widget.onPermissionsGranted();
        return;
      }

      // Vérifier s'il y a des permissions définitivement refusées
      final permanentlyDenied = statuses.entries
          .where((entry) => entry.value.isPermanentlyDenied)
          .map((entry) => entry.key)
          .toList();

      if (permanentlyDenied.isNotEmpty) {
        _showSettingsDialog();
      }
    } catch (e) {
      debugPrint('Erreur lors de la demande de permissions: $e');
    }

    setState(() {
      _isCheckingPermissions = false;
    });
  }

  void _showSettingsDialog() {
    final localizations = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(localizations?.translate('permissions_required') ?? 'Permissions requises'),
        content: Text(
          localizations?.translate('permissions_denied_message') ?? 
          'Certaines permissions ont été définitivement refusées. '
          'Veuillez les autoriser manuellement dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations?.translate('cancel') ?? 'Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text(localizations?.translate('open_settings') ?? 'Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  String _getPermissionName(Permission permission) {
    final localizations = AppLocalizations.of(context);
    switch (permission) {
      case Permission.microphone:
        return localizations?.translate('microphone') ?? 'Microphone';
      case Permission.contacts:
        return localizations?.translate('contacts') ?? 'Contacts';
      case Permission.phone:
        return localizations?.translate('phone') ?? 'Téléphone';
      default:
        return permission.toString();
    }
  }

  String _getPermissionDescription(Permission permission) {
    final localizations = AppLocalizations.of(context);
    switch (permission) {
      case Permission.microphone:
        return localizations?.translate('microphone_description') ?? 'Nécessaire pour la reconnaissance vocale';
      case Permission.contacts:
        return localizations?.translate('contacts_description') ?? 'Nécessaire pour appeler vos contacts';
      case Permission.phone:
        return localizations?.translate('phone_description') ?? 'Nécessaire pour passer des appels';
      default:
        return localizations?.translate('permission_required_general') ?? 'Permission requise pour le fonctionnement de l\'application';
    }
  }

  IconData _getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return Icons.mic;
      case Permission.contacts:
        return Icons.contacts;
      case Permission.phone:
        return Icons.phone;
      default:
        return Icons.security;
    }
  }

  Color _getStatusColor(PermissionStatus? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.orange;
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(PermissionStatus? status) {
    final localizations = AppLocalizations.of(context);
    if (status == null) return localizations?.translate('checking') ?? 'Vérification...';
    switch (status) {
      case PermissionStatus.granted:
        return localizations?.translate('granted') ?? 'Accordée';
      case PermissionStatus.denied:
        return localizations?.translate('denied') ?? 'Refusée';
      case PermissionStatus.permanentlyDenied:
        return localizations?.translate('permanently_denied') ?? 'Définitivement refusée';
      default:
        return localizations?.translate('unknown') ?? 'Inconnue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple[900],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo_sagbo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Titre
              Text(
                AppLocalizations.of(context)?.translate('permissions_required') ?? 'Permissions requises',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                AppLocalizations.of(context)?.translate('permissions_description') ?? 
                'Sagbo a besoin de ces permissions pour fonctionner correctement :',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Liste des permissions
              ...(_requiredPermissions.map((permission) {
                final status = _permissionStatuses[permission];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getPermissionIcon(permission),
                        color: _getStatusColor(status),
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPermissionName(permission),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _getPermissionDescription(permission),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()),

              const SizedBox(height: 32),

              // Bouton d'action
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCheckingPermissions ? null : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCheckingPermissions
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)?.translate('checking') ?? 'Vérification...',
                            ),
                          ],
                        )
                      : Text(
                          AppLocalizations.of(context)?.translate('allow_permissions') ?? 'Autoriser les permissions',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
