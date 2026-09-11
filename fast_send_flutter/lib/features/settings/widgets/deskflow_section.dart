import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../deskflow/services/deskflow_service.dart';
import 'settings_card.dart';
import 'settings_section_header.dart';

class DeskflowSection extends ConsumerStatefulWidget {
  const DeskflowSection({super.key});

  @override
  ConsumerState<DeskflowSection> createState() => _DeskflowSectionState();
}

class _DeskflowSectionState extends ConsumerState<DeskflowSection> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '24800');
  DeskflowMode _mode = DeskflowMode.client;
  bool _clipboard = true;

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _toggle(DeskflowService service) async {
    if (service.isRunning) {
      await service.stop();
      return;
    }
    final port = int.tryParse(_port.text.trim()) ?? 24800;
    await service.start(
      DeskflowConfig(
        mode: _mode,
        remoteHost: _host.text.trim(),
        port: port,
        clipboard: _clipboard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(deskflowServiceProvider);
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(title: '跨屏协同'),
          SettingsCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  DropdownButtonFormField<DeskflowMode>(
                    initialValue: _mode,
                    decoration: const InputDecoration(labelText: '工作模式'),
                    items: const [
                      DropdownMenuItem(
                        value: DeskflowMode.client,
                        child: Text('连接到其他电脑'),
                      ),
                      DropdownMenuItem(
                        value: DeskflowMode.server,
                        child: Text('本机作为主控电脑'),
                      ),
                    ],
                    onChanged: service.isRunning
                        ? null
                        : (value) => setState(() => _mode = value!),
                  ),
                  if (_mode == DeskflowMode.client) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _host,
                      enabled: !service.isRunning,
                      decoration: const InputDecoration(
                        labelText: '远程电脑地址',
                        hintText: '例如 192.168.1.10',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _port,
                    enabled: !service.isRunning,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '端口'),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('同步剪贴板'),
                    value: _clipboard,
                    onChanged: service.isRunning
                        ? null
                        : (value) => setState(() => _clipboard = value),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _toggle(service),
                      icon: Icon(
                        service.isRunning ? Icons.stop : Icons.play_arrow,
                      ),
                      label: Text(service.isRunning ? '停止跨屏协同' : '启动跨屏协同'),
                    ),
                  ),
                  if (service.lastError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      service.lastError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
