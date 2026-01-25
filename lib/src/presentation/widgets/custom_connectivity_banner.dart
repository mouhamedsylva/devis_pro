import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/connectivity_service.dart';

class CustomConnectivityBanner extends StatefulWidget {
  final Widget child;

  const CustomConnectivityBanner({
    super.key,
    required this.child,
  });

  @override
  State<CustomConnectivityBanner> createState() => _CustomConnectivityBannerState();
}

class _CustomConnectivityBannerState extends State<CustomConnectivityBanner> with SingleTickerProviderStateMixin {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isOnline = true;
  bool _showOnline = false; // Pour montrer "Connexion rétablie" temporairement
  Timer? _hideTimer;

  // Animation
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Initial check
    _connectivityService.checkConnection().then((isConnected) {
      if (mounted) {
        setState(() => _isOnline = isConnected);
        if (!isConnected) {
          _controller.value = 1.0; // Show immediately if offline
        }
      }
    });

    // Listen to changes
    _connectivityService.connectionStatus.listen((isConnected) {
      if (mounted && isConnected != _isOnline) {
        setState(() => _isOnline = isConnected);

        if (!isConnected) {
          // Offline -> Show Banner (Blue)
          _hideTimer?.cancel();
          _showOnline = false;
          _controller.forward();
        } else {
          // Online -> Show "Connexion rétablie" (Green) then hide
          setState(() => _showOnline = true);
          _controller.forward(); // Ensure visible
          
          _hideTimer?.cancel();
          _hideTimer = Timer(const Duration(seconds: 3), () {
            if (mounted && _isOnline) {
              _controller.reverse().then((_) {
                 if (mounted) setState(() => _showOnline = false);
              });
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Content pushed down if banner is visible? 
        // Or overlay? The plugin overlaid, but let's push content down or overlay based on preference.
        // User liked the plugin behavior which usually overlays or pushes.
        // Let's use Column to push content down so it doesn't hide app bar content.
        Column(
          children: [
            SizeTransition(
              sizeFactor: _controller,
              axisAlignment: -1,
              child: Container(
                height: 32,
                width: double.infinity,
                color: _isOnline && _showOnline ? Colors.green : Colors.blue,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isOnline ? Icons.wifi : Icons.wifi_off,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isOnline ? 'Connexion rétablie' : 'Mode hors ligne',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: widget.child),
          ],
        ),
      ],
    );
  }
}
