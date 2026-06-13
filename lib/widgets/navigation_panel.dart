import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_result.dart';
import '../theme/app_theme.dart';

/// פאנל ניווט תחתון
class NavigationPanel extends StatelessWidget {
  final RouteResult? route;
  final LatLng? origin;
  final LatLng? destination;
  final RoutingMode mode;
  final bool isCalculating;
  final ValueChanged<RoutingMode> onModeChanged;
  final VoidCallback onClear;
  final VoidCallback onSelectOrigin;
  final VoidCallback onSelectDestination;

  const NavigationPanel({
    super.key,
    this.route,
    this.origin,
    this.destination,
    required this.mode,
    required this.isCalculating,
    required this.onModeChanged,
    required this.onClear,
    required this.onSelectOrigin,
    required this.onSelectDestination,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.58;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight.clamp(260.0, 460.0).toDouble(),
      ),
      child: Container(
        decoration: AppTheme.glassDecorationTop,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ידית גרירה
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(64),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      route == null ? 'תכנון מסלול' : 'מסלול מוכן',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onClear,
                      tooltip: 'נקה מסלול',
                      icon: const Icon(Icons.close, size: 20),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white70,
                        backgroundColor: Colors.white.withAlpha(13),
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // בחירת מצב ניתוב
                _buildModeSelector(context),
                const SizedBox(height: 16),

                // נקודות מוצא ויעד
                _buildWaypoints(context),

                // תוצאת מסלול
                if (route != null) ...[
                  const SizedBox(height: 16),
                  _buildRouteInfo(context),
                ],

                // אינדיקטור חישוב
                if (isCalculating) ...[
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('מחשב מסלול...'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: RoutingMode.values.map((m) {
          final isSelected = m == mode;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: isSelected
                    ? AppTheme.routeColor.withAlpha(51)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => onModeChanged(m),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.routeColor
                            : Colors.white.withAlpha(38),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(m.icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          m.hebrew,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.routeColor
                                : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWaypoints(BuildContext context) {
    return Column(
      children: [
        _WaypointRow(
          icon: Icons.trip_origin,
          color: AppTheme.routeColor,
          label: origin != null
              ? '${origin!.latitude.toStringAsFixed(4)}, ${origin!.longitude.toStringAsFixed(4)}'
              : 'בחר נקודת מוצא',
          isEmpty: origin == null,
          onTap: onSelectOrigin,
        ),
        Container(
          margin: const EdgeInsets.only(right: 19),
          alignment: Alignment.centerRight,
          child: Container(
            width: 2,
            height: 16,
            color: Colors.white.withAlpha(51),
          ),
        ),
        _WaypointRow(
          icon: Icons.location_on,
          color: Colors.red,
          label: destination != null
              ? '${destination!.latitude.toStringAsFixed(4)}, ${destination!.longitude.toStringAsFixed(4)}'
              : 'בחר יעד',
          isEmpty: destination == null,
          onTap: onSelectDestination,
        ),
      ],
    );
  }

  Widget _buildRouteInfo(BuildContext context) {
    final r = route!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.routeColor.withAlpha(38),
            AppTheme.routeColor.withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.routeColor.withAlpha(51),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoChip(
                icon: Icons.straighten,
                label: r.formattedDistance,
                sublabel: 'מרחק',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withAlpha(38),
              ),
              _InfoChip(
                icon: Icons.access_time,
                label: r.formattedDuration,
                sublabel: 'זמן משוער',
              ),
            ],
          ),

          // הוראות ניווט (הראשונות)
          if (r.instructions.length > 1) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'הוראות ניווט',
                    style: TextStyle(
                      color: Colors.white.withAlpha(179),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...r.instructions
                      .take(5)
                      .map((inst) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text(inst.type.icon,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    inst.text,
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                  if (r.instructions.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '...ועוד ${r.instructions.length - 5} הוראות',
                        style: TextStyle(
                          color: Colors.white.withAlpha(128),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaypointRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isEmpty;
  final VoidCallback onTap;

  const _WaypointRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.isEmpty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withAlpha(31),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isEmpty ? Colors.white54 : Colors.white,
                  fontSize: 14,
                  fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
            if (!isEmpty)
              Icon(Icons.edit, color: Colors.white.withAlpha(77), size: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.routeColor, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withAlpha(128),
          ),
        ),
      ],
    );
  }
}
