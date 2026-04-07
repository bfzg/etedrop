import 'dart:convert';
import 'dart:io';

import 'package:etedrop/core/config/styles.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/ui/e_button.dart';
import '../../widgets/ui/e_dialog.dart';
import 'update_manifest.dart';
import 'update_state.dart';
import 'version_utils.dart';

class UpdateService {
  UpdateService._();

  static final instance = UpdateService._();

  Future<File> _downloadToTempFile(Uri url, {required String fileName}) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(url);
      req.headers.set(HttpHeaders.acceptHeader, '*/*');
      final res = await req.close();
      if (res.statusCode >= 400) {
        throw HttpException('HTTP ${res.statusCode}', uri: url);
      }
      final dir = await Directory.systemTemp.createTemp('etedrop_update_');
      final out = File('${dir.path}${Platform.pathSeparator}$fileName');
      final sink = out.openWrite();
      await res.pipe(sink);
      await sink.flush();
      await sink.close();
      return out;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _runWindowsInstallerAndExit(File installer) async {
    // Inno Setup 常用静默升级参数：避免弹窗 + 不重启
    final args = const [
      '/VERYSILENT',
      '/SUPPRESSMSGBOXES',
      '/NORESTART',
      '/CLOSEAPPLICATIONS',
      '/RESTARTAPPLICATIONS',
    ];
    await Process.start(
      installer.path,
      args,
      mode: ProcessStartMode.detached,
      runInShell: true,
    );
    // 让安装器接管升级，主程序退出释放文件锁
    exit(0);
  }

  Future<UpdateManifest?> fetchManifest() async {
    final url = AppConstants.updateManifestUrl.trim();
    if (url.isEmpty) return null;
    final uri = Uri.parse(url);
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close();
      if (res.statusCode >= 400) return null;
      final body = await utf8.decodeStream(res);
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        return UpdateManifest.fromJson(json);
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  String? _downloadUrlForPlatform(UpdateManifest m) {
    if (Platform.isWindows) return m.windowsDownloadUrl ?? m.releasePageUrl;
    if (Platform.isMacOS) return m.macDownloadUrl ?? m.releasePageUrl;
    if (Platform.isAndroid) {
      final store = AppConstants.androidStoreUrl.trim();
      if (store.isNotEmpty) return store;
      return AppConstants.androidUpdateDownloadPageUrl;
    }
    if (Platform.isIOS) return AppConstants.iosStoreUrl;
    return m.releasePageUrl;
  }

  List<String> _releaseNotesForLocale(UpdateManifest m, Locale locale) {
    String norm(String s) => s.trim().toLowerCase();
    final lang = norm(locale.languageCode);
    final tag = norm(locale.toLanguageTag());
    return m.releaseNotes[tag] ??
        m.releaseNotes[lang] ??
        m.releaseNotes['zh'] ??
        m.releaseNotes['en'] ??
        const [];
  }

  Future<bool> checkHasUpdate({
    required String currentVersion,
    required UpdateManifest manifest,
  }) async {
    return VersionUtils.isLess(currentVersion, manifest.latestVersion);
  }

  Future<void> checkSilentlyAndUpdateBadge(WidgetRef ref) async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final current = pkg.version;
      final manifest = await fetchManifest();
      if (manifest == null || manifest.latestVersion.isEmpty) {
        ref
            .read(updateStateProvider.notifier)
            .setResult(manifest: null, hasUpdate: false);
        return;
      }
      final hasUpdate = await checkHasUpdate(
        currentVersion: current,
        manifest: manifest,
      );
      ref
          .read(updateStateProvider.notifier)
          .setResult(manifest: manifest, hasUpdate: hasUpdate);
    } catch (_) {
      ref
          .read(updateStateProvider.notifier)
          .setResult(manifest: null, hasUpdate: false);
    }
  }

  Future<void> checkAndPrompt(BuildContext context, {WidgetRef? ref}) async {
    final l10n = AppLocalizations.of(context)!;
    final pkg = await PackageInfo.fromPlatform();
    final current = pkg.version;

    final manifest = await fetchManifest();
    if (manifest == null || manifest.latestVersion.isEmpty) {
      ref
          ?.read(updateStateProvider.notifier)
          .setResult(manifest: null, hasUpdate: false);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.updateCheckFailed)));
      }
      return;
    }

    final latest = manifest.latestVersion;
    final hasUpdate = VersionUtils.isLess(current, latest);
    ref
        ?.read(updateStateProvider.notifier)
        .setResult(manifest: manifest, hasUpdate: hasUpdate);
    if (!hasUpdate) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.updateAlreadyLatest(current))),
        );
      }
      return;
    }

    final url = _downloadUrlForPlatform(manifest);
    if (!context.mounted) return;

    final notes = _releaseNotesForLocale(
      manifest,
      Localizations.localeOf(context),
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: !manifest.forceUpdate,
      builder: (ctx) {
        final primary = AppStyles.primary;
        return EDialog.alert(
          title: RichText(
            text: TextSpan(
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: primary,
                fontSize: 26,
              ),
              children: [
                TextSpan(
                  text: l10n.updateAvailableTitle,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: Colors.black,
                    fontSize: 26,
                  ),
                ),
                TextSpan(text: ' v$latest'),
              ],
            ),
          ),
          content: SizedBox(
            width: 520,
            child: EDialog.scrollableFormBody(
              ctx,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (notes.isNotEmpty)
                    ...notes.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          line,
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    )
                  else
                    Text(
                      l10n.checkForUpdatesDesc,
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                if (!manifest.forceUpdate) ...[
                  Expanded(
                    child: EButton(
                      text: l10n.later,
                      variant: EButtonVariant.secondary,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: EButton(
                    text: l10n.updateNow,
                    onPressed: (url == null || url.isEmpty)
                        ? null
                        : () async {
                            try {
                              // Windows：优先走“在线升级”（下载 Inno 安装包并执行）
                              if (Platform.isWindows) {
                                final installerUrl = Uri.parse(url);
                                final isExe =
                                    installerUrl.path.toLowerCase().endsWith('.exe');
                                if (isExe) {
                                  final file = await _downloadToTempFile(
                                    installerUrl,
                                    fileName: 'EteDrop-Setup-v$latest.exe',
                                  );
                                  await _runWindowsInstallerAndExit(file);
                                  return;
                                }
                              }

                              // 其他平台：保持现状，打开外部链接
                              final ok = await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                              if (!ok && ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(l10n.openLinkFailed)),
                                );
                              }
                            } catch (_) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(l10n.updateCheckFailed)),
                                );
                              }
                            }
                            ref
                                ?.read(updateStateProvider.notifier)
                                .clearBadge();
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
