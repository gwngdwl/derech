import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/map_screen.dart';
import 'services/gpkg_service.dart';
import 'services/location_service.dart';
import 'services/routing_service.dart';
import 'services/graph_builder.dart';
import 'theme/app_theme.dart';

class DerechApp extends StatelessWidget {
  const DerechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GpkgService>(
          create: (_) => GpkgService(),
          dispose: (_, service) => service.close(),
        ),
        ChangeNotifierProvider<LocationService>(
          create: (_) => LocationService(),
        ),
        ChangeNotifierProvider<RoutingService>(create: (_) => RoutingService()),
      ],
      child: MaterialApp(
        title: 'דרך',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: const Locale('he', 'IL'),
        home: const _AppLoader(),
      ),
    );
  }
}

/// מסך טעינה ראשוני
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader>
    with SingleTickerProviderStateMixin {
  String _status = 'מאתחל...';
  double _progress = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      // שלב 1: פתיחת GPKG
      setState(() {
        _status = 'פותח בסיס נתונים...';
        _progress = 0.1;
      });

      // השג את ה-providers לפני ה-awaits
      final gpkg = context.read<GpkgService>();
      final routing = context.read<RoutingService>();
      final location = context.read<LocationService>();

      // חיפוש קובץ ה-GPKG
      const gpkgPath = r'c:\Users\user\derech\maps\israel-and-palestine.gpkg';
      gpkg.open(gpkgPath);

      // שלב 2: בניית גרף ניתוב
      setState(() {
        _status = 'טוען כבישים...';
        _progress = 0.3;
      });

      await Future.delayed(const Duration(milliseconds: 100));

      final roads = gpkg.getAllRoutableRoads();
      setState(() {
        _status = 'בונה גרף ניתוב (${roads.length} קטעים)...';
        _progress = 0.5;
      });

      await Future.delayed(const Duration(milliseconds: 100));

      // בניית גרף ב-Isolate (כרגע בthread ראשי כי GraphNode לא serializable)
      final graph = GraphBuilder.build(roads, routing.mode);
      routing.setGraph(graph);

      setState(() {
        _status = 'מאתחל מיקום...';
        _progress = 0.8;
      });

      // שלב 3: אתחול מיקום
      await location.initialize();

      if (!mounted) return;

      setState(() {
        _status = 'מוכן!';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const MapScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      setState(() {
        _status = 'שגיאה: $e';
        _progress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mapBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // לוגו
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, _) {
                return Transform.scale(
                  scale: 1.0 + _pulseController.value * 0.05,
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.gradient.createShader(bounds),
                    child: const Icon(
                      Icons.navigation_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // שם
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.gradient.createShader(bounds),
              child: Text(
                'דרך',
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ניווט אופליין',
              style: TextStyle(
                color: Colors.white.withAlpha(128),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),

            // פס התקדמות
            SizedBox(
              width: 260,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white.withAlpha(25),
                      valueColor: const AlwaysStoppedAnimation(
                        AppTheme.routeColor,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _status,
                    style: TextStyle(
                      color: Colors.white.withAlpha(153),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
