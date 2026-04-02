import 'dart:async';

import 'package:flutter/material.dart';
import 'package:eddy/core/config/constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n_utils.dart';
import 'core/config/styles.dart';
import 'core/router/router_provider.dart';
import 'core/update/update_service.dart';
import 'core/update/update_state.dart';
import 'features/device/providers/device_auto_connect.dart';
import 'features/settings/providers/locale_provider.dart';
import 'features/lan/providers/lan_provider.dart';
import 'services/desktop_service.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _didCheckUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTray();
      _checkUpdateOnStartup();
    });
  }

  void _syncTray() {
    if (!DesktopService.instance.isDesktop) return;
    unawaited(
      DesktopService.instance.updateTrayMenu(loadAppLocalizationsSync()),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.read(deviceAutoConnectProvider);
    ref.read(lanManagerProvider);

    ref.listen<Locale?>(localeProvider, (previous, next) => _syncTray());

    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppStyles.lightTheme(),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  Future<void> _checkUpdateOnStartup() async {
    if (_didCheckUpdate) return;
    _didCheckUpdate = true;

    // 1) Silent check to update badge state.
    await UpdateService.instance.checkSilentlyAndUpdateBadge(ref);
    if (!mounted) return;

    // 2) If update available, prompt immediately with default UI.
    final hasUpdate = ref.read(updateStateProvider).hasUpdate;
    if (!hasUpdate) return;

    await UpdateService.instance.checkAndPrompt(context, ref: ref);
  }
}
