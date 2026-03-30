import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../device/providers/device_provider.dart';
import '../models/share_record.dart';
import '../providers/share_provider.dart';
import '../../../widgets/ui/e_button.dart';
import '../../../widgets/ui/e_dialog.dart';

/// 网盘分享对话框：同一文件若已有未过期分享则直接展示，否则进入创建流程；可取消分享。
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
  bool _checkingExisting = true;
  bool _cancelling = false;

  /// true：打开对话框时该文件已有分享；false：本次会话内刚创建。
  bool _isExistingShare = false;

  static const _expiresOptions = <(String, int?)>[
    ('永不过期', null),
    ('1 小时', 3600000),
    ('24 小时', 86400000),
    ('7 天', 604800000),
    ('30 天', 2592000000),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingShare());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingShare() async {
    await ref.read(shareServiceProvider.notifier).ensureInit();
    if (!mounted) return;
    final existing = ref
        .read(shareServiceProvider)
        .findActiveShareForFile(widget.relativePath, widget.fileName);
    if (!mounted) return;
    setState(() {
      _checkingExisting = false;
      if (existing != null) {
        _result = existing;
        _isExistingShare = true;
      }
    });
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
      setState(() {
        _result = info;
        _isExistingShare = false;
      });
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
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmCancelShare() async {
    if (_result == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消分享'),
        content: const Text('确定取消分享？他人将无法再通过当前链接下载该文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('返回'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('取消分享'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final code = _result!.code;
      await ref.read(shareListProvider.notifier).deleteShare(code);
      if (!mounted) return;
      setState(() {
        _result = null;
        _cancelling = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已取消分享')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('取消分享失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_checkingExisting) {
      return EDialog.alert(
        title: Text('分享「${widget.fileName}」'),
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
        actions: [
          EButton(
            text: '关闭',
            variant: EButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    if (_result != null) {
      return _buildResultDialog(theme, isExistingFlow: _isExistingShare);
    }

    return EDialog.alert(
      title: const Text('创建分享'),
      content: EDialog.scrollableFormBody(
        context,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('文件: ${widget.fileName}', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('设置密码'),
              value: _usePassword,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _usePassword = v),
            ),
            if (_usePassword) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  hintText: '输入密码',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _expiresIn,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _expiresOptions
                  .map((e) => DropdownMenuItem(value: e.$2, child: Text(e.$1)))
                  .toList(),
              onChanged: (v) => setState(() => _expiresIn = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        EButton(
          text: '关闭',
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

  Widget _buildResultDialog(ThemeData theme, {required bool isExistingFlow}) {
    final info = _result!;
    final deviceId = ref.read(deviceIdProvider);
    final shareService = ref.read(shareServiceProvider);
    final shareLink = deviceId != null && deviceId.isNotEmpty
        ? shareService.getShareUrl(info.code, deviceId)
        : null;

    final title = isExistingFlow
        ? Text('分享「${widget.fileName}」')
        : const Text('分享已创建');

    return EDialog.alert(
      title: title,
      content: EDialog.scrollableFormBody(
        context,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isExistingFlow) ...[
              Text(
                '该文件已处于分享状态，可直接复制下方分享码或链接。',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
            ] else
              Text('文件: ${widget.fileName}', style: theme.textTheme.bodyMedium),
            if (!isExistingFlow) const SizedBox(height: 16),
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
            if (info.hasPassword) ...[
              const SizedBox(height: 8),
              Text(
                '已设置访问密码',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
            if (info.expiresAt != null) ...[
              const SizedBox(height: 8),
              Text(
                '过期时间: ${DateTime.fromMillisecondsSinceEpoch(info.expiresAt!).toString().substring(0, 16)}',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (isExistingFlow)
          EButton(
            text: '取消分享',
            variant: EButtonVariant.danger,
            loading: _cancelling,
            onPressed: _cancelling ? null : _confirmCancelShare,
          ),
        EButton(
          text: '完成',
          onPressed: _cancelling ? null : () => Navigator.of(context).pop(info),
        ),
      ],
    );
  }
}
