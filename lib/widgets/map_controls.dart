import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// כפתורי שליטה במפה
class MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final VoidCallback onClearRoute;

  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.onClearRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlButton(
            icon: Icons.add,
            onPressed: onZoomIn,
            tooltip: 'הגדל',
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          const _Divider(),
          _ControlButton(
            icon: Icons.remove,
            onPressed: onZoomOut,
            tooltip: 'הקטן',
          ),
          const _Divider(),
          _ControlButton(
            icon: Icons.my_location,
            onPressed: onMyLocation,
            tooltip: 'המיקום שלי',
            isPrimary: true,
          ),
          const _Divider(),
          _ControlButton(
            icon: Icons.close,
            onPressed: onClearRoute,
            tooltip: 'נקה מסלול',
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final BorderRadius? borderRadius;
  final bool isPrimary;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.borderRadius,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              icon,
              color: isPrimary
                  ? AppTheme.routeColor
                  : Colors.white.withAlpha(200),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: 32,
      color: Colors.white.withAlpha(25),
    );
  }
}
