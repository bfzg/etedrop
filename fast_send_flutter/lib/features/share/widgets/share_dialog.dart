import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../device/providers/device_provider.dart';
import '../models/share_record.dart';
import '../providers/share_provider.dart';
import '../../../widgets/ui/e_button.dart';

/// 创建分享对话框
/// 对应 Electron: src/components/cloud/share-dialog.tsx
class ShareDialog extends ConsumerStatefulWidget {
  final String relativePath;
  final String fileName;
  final int fileSize;

  const ShareDialog({
    super.key,
    required this.relativePath,
    required this.fileName,
    required this.fileSize,
  });

  static Future<ShareInfo?> show(
    BuildContext context, {
    required String relativePath,
    required String fileName,
    required int fileSize,
  }) {
    return showDialog<ShareInfo>(
      context: context,
      builder: (_) => ShareDialog(
        relativePath: relativePath,
        fileName: fileName,
        fileSize: fileSize,
      ),
    );
  }

  @override
  ConsumerState<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends ConsumerState<ShareDialog> {
  final _passwordController = TextEditingController();
  bool _usePassword = false;
  int? _expiresIn;
  bool _loading = false;
  ShareInfo? _result;
  String? _error;

  static const _expiresOptions = <(String, int?)>[
    ('永不过期', null),
    ('1 小时', 3600000),
    ('24 小时', 86400000),
    ('7 天', 604800000),
    ('30 天', 2592000000),
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createShare() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final info = await ref
          .read(shareListProvider.notifier)
          .createShare(
            widget.relativePath,
            fileName: widget.fileName,
            fileSize: widget.fileSize,
            password: _usePassword ? _passwordController.text : null,
            expiresIn: _expiresIn,
          );
      setState(() => _result = info);
      // 有设备 ID 时自动复制分享链接
      final deviceId = ref.read(deviceIdProvider);
      if (deviceId != null && deviceId.isNotEmpty && mounted) {
        final shareService = ref.read(shareServiceProvider);
        final link = shareService.getShareUrl(info.code, deviceId);
        await Clipboard.setData(ClipboardData(text: link));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已复制分享链接'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _error = '创建分享失败: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dialogWidth = _dialogWidth(context);

    if (_result != null) {
      final deviceId = ref.read(deviceIdProvider);
      final shareService = ref.read(shareServiceProvider);
      final shareLink = deviceId != null && deviceId.isNotEmpty
          ? shareService.getShareUrl(_result!.code, deviceId)
          : null;

      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: const Text('分享已创建'),
        content: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '文件: ${widget.fileName}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text('分享码', style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _result!.code,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: '复制分享码',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _result!.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已复制分享码'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('分享链接', style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                if (shareLink != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            shareLink,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: '复制分享链接',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: shareLink));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('已复制分享链接'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    '请先连接设备（连接服务端）后，在「我的分享」中可查看分享链接。',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                if (_result!.hasPassword) ...[
                  const SizedBox(height: 8),
                  Text(
                    '已设置访问密码',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (_result!.expiresAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '过期时间: ${DateTime.fromMillisecondsSinceEpoch(_result!.expiresAt!).toString().substring(0, 16)}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          EButton(
            text: '完成',
            onPressed: () => Navigator.of(context).pop(_result),
          ),
        ],
      );
    }

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: const Text('创建分享'),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('文件: ${widget.fileName}', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              // 密码选项
              SwitchListTile(
                title: const Text('设置密码'),
                value: _usePassword,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _usePassword = v),
              ),
              if (_usePassword)
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    hintText: '输入密码',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              const SizedBox(height: 16),
              // 过期时间
              Text('过期时间', style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _expiresIn,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _expiresOptions
                    .map(
                      (e) => DropdownMenuItem(value: e.$2, child: Text(e.$1)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _expiresIn = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actions: [
        EButton(
          text: '取消',
          variant: EButtonVariant.secondary,
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
        ),
        EButton(
          text: '创建分享',
          loading: _loading,
          onPressed: _loading ? null : _createShare,
        ),
      ],
    );
  }

  double? _dialogWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // 手机：让 dialog 自适应（不强行设置固定宽度）
    if (w < 340) return null;
    // 桌面/平板：更宽一点
    return 340;
  }
}
