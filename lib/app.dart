import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/session_store.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/billing_repository.dart';
import 'data/repositories/guest_repository.dart';
import 'state/session_controller.dart';

/// Composition root. One ApiClient is shared by every repository so the auth
/// token and the 401 handler are wired in exactly one place.
class FaceDeliverApp extends StatefulWidget {
  const FaceDeliverApp({super.key});

  @override
  State<FaceDeliverApp> createState() => _FaceDeliverAppState();
}

class _FaceDeliverAppState extends State<FaceDeliverApp> {
  late final ApiClient _api;
  late final SessionController _session;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _api = ApiClient();
    _session = SessionController(_api, AuthRepository(_api), SessionStore());
    _router = buildRouter(_session);

    _session.bootstrap();
  }

  @override
  void dispose() {
    _session.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _session),
        Provider<AuthRepository>(create: (_) => AuthRepository(_api)),
        Provider<GuestRepository>(create: (_) => GuestRepository(_api)),
        Provider<AdminRepository>(create: (_) => AdminRepository(_api)),
        Provider<BillingRepository>(create: (_) => BillingRepository(_api)),
      ],
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        // Respect the reader's font-size preference, but stop runaway scaling
        // from breaking dense stat rows and the photo grid.
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: media.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.3,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
