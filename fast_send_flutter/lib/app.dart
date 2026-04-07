import 'dart:async';

import 'package:flutter/material.dart';
import 'package:etedrop/core/config/constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n_utils.dart';
import 'core/config/styles.dart';
import 'core/router/router_provider.dart';
import 'core/update/update_service.dart';
import 'core/update/update_state.dart';
import 'features/device/providers/device_auto_connect.dart';
import 'features/device/providers/device_provider.dart';
import 'features/settings/providers/locale_provider.dart';
import 'features/settings/providers/server_line_provider.dart';
import 'features/settings/providers/webrtc_keepalive_prefs_provider.dart';
import 'features/lan/providers/lan_provider.dart';
import 'services/desktop_service.dart';
import 'services/webrtc_background_keepalive.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  bool _didCheckUpdate = false;
  bool _didRestoreWebrtcKeepalive = false;

  @override
  void initState() {
    super.initState();
    if (WebRtcBackgroundKeepalive.isSupportedMobile) {
      WidgetsBinding.instance.addObserver(this);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTray();
      _checkUpdateOnStartup();
      unawaited(_restoreWebrtcKeepaliveIfNeeded());
    });
  }

  @override
  void dispose() {
    if (WebRtcBackgroundKeepalive.isSupportedMobile) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    if (!WebRtcBackgroundKeepalive.isSupportedMobile) return;
    if (!ref.read(webrtcKeepalivePreferenceProvider)) return;
    unawaited(WebRtcBackgroundKeepalive.refreshAudioSessionIfActive());
  }

  Future<void> _restoreWebrtcKeepaliveIfNeeded() async {
    if (!WebRtcBackgroundKeepalive.isSupportedMobile) return;
    if (_didRestoreWebrtcKeepalive) return;
    _didRestoreWebrtcKeepalive = true;
    if (!ref.read(webrtcKeepalivePreferenceProvider)) return;
    final l10n = loadAppLocalizationsSync();
    await WebRtcBackgroundKeepalive.activate(
      notificationTitle: l10n.webrtcBackgroundFgNotificationTitle,
      notificationText: l10n.webrtcBackgroundFgNotificationBody,
    );
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

    ref.listen(serverEndpointsProvider, (previous, next) {
      ref.read(deviceManagerProvider).applyEndpoints(next);
    });

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

    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) {
      // ignore: use_build_context_synchronously
      await UpdateService.instance.checkAndPrompt(ctx, ref: ref);
      return;
    }

    // In rare cases (very first frame), navigator context may not be ready.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctx2 = rootNavigatorKey.currentContext;
      if (ctx2 == null) return;
      // ignore: use_build_context_synchronously
      await UpdateService.instance.checkAndPrompt(ctx2, ref: ref);
    });
  }
}
