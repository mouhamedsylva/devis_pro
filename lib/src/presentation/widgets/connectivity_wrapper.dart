/// Wrapper pour les actions nécessitant une connexion Internet
///
/// Enveloppe les boutons/actions qui nécessitent Internet et affiche
/// un message d'erreur si l'utilisateur tente de les utiliser hors ligne.

import 'package:flutter/material.dart';

class ConnectivityWrapper extends StatelessWidget {
  const ConnectivityWrapper({
    super.key,
    required this.isOnline,
    required this.child,
    required this.onOfflineTap,
    this.offlineMessage = 'Connexion internet requise pour cette action',
  });

  final bool isOnline;
  final Widget child;
  final VoidCallback onOfflineTap;
  final String offlineMessage;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isOnline,
      child: Opacity(
        opacity: isOnline ? 1.0 : 0.5,
        child: GestureDetector(
          onTap: isOnline
              ? null
              : () {
                  // Afficher le message d'erreur
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              offlineMessage,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFFFF9800),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  onOfflineTap();
                },
          child: child,
        ),
      ),
    );
  }
}
