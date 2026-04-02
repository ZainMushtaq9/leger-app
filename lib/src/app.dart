import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controller.dart';
import 'models.dart';
import 'theme.dart';
import 'ui/lock_screen.dart';
import 'ui/customer_portal_viewer_screen.dart';
import 'ui/root_shell.dart';
import 'ui/splash_screen.dart';
import 'ui/welcome_screen.dart';

class HisabRakhoApp extends StatelessWidget {
  const HisabRakhoApp({
    super.key,
    required this.controller,
    this.splashDelay = const Duration(milliseconds: 1200),
    this.adsEnabled = true,
  });

  final HisabRakhoController controller;
  final Duration splashDelay;
  final bool adsEnabled;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: controller.copy.appName,
          locale: controller.appLocale,
          supportedLocales: const <Locale>[Locale('en', 'PK')],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildHisabRakhoTheme(brightness: Brightness.light),
          darkTheme: buildHisabRakhoTheme(brightness: Brightness.dark),
          themeMode: _themeModeFor(controller.settings.themeMode),
          builder: (context, child) {
            return Directionality(
              textDirection: controller.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: LaunchGate(
            controller: controller,
            splashDelay: splashDelay,
            adsEnabled: adsEnabled,
          ),
        );
      },
    );
  }
}

ThemeMode _themeModeFor(AppThemeMode themeMode) {
  switch (themeMode) {
    case AppThemeMode.system:
      return ThemeMode.system;
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
  }
}

class LaunchGate extends StatefulWidget {
  const LaunchGate({
    super.key,
    required this.controller,
    required this.splashDelay,
    required this.adsEnabled,
  });

  final HisabRakhoController controller;
  final Duration splashDelay;
  final bool adsEnabled;

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> with WidgetsBindingObserver {
  bool _showHome = false;
  Timer? _timer;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer(widget.splashDelay, () {
      if (mounted) {
        setState(() {
          _showHome = true;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;
      _backgroundedAt = null;
      if (backgroundedAt != null &&
          widget.controller.shouldAutoLockAfterBackground(backgroundedAt)) {
        unawaited(widget.controller.lockApp());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final portalPayload = widget.controller.portalPayloadFromUri(Uri.base);
        if (!widget.controller.isLoaded || !_showHome) {
          return SplashScreen(
            title: widget.controller.copy.appName,
            subtitle: widget.controller.copy.splashTagline,
          );
        }

        if (portalPayload != null) {
          return CustomerPortalViewerScreen(
            controller: widget.controller,
            payload: portalPayload,
          );
        }

        if (widget.controller.needsOnboarding) {
          return WelcomeScreen(controller: widget.controller);
        }

        if (widget.controller.isLocked) {
          return LockScreen(controller: widget.controller);
        }

        return RootShell(
          controller: widget.controller,
          adsEnabled: widget.adsEnabled,
        );
      },
    );
  }
}
