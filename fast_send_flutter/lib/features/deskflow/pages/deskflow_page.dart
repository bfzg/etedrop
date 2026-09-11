import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../deskflow_service.dart';

class DeskflowPage extends ConsumerStatefulWidget {
  const DeskflowPage({super.key});
  @override
  ConsumerState<DeskflowPage> createState() => _DeskflowPageState();
}

class _DeskflowPageState extends ConsumerState<DeskflowPage> {
  final host = TextEditingController();
  final port = TextEditingController(text: '24800');
  DeskflowMode mode = DeskflowMode.server;
  bool clipboard = true;
  @override
  void dispose() {
    host.dispose();
    port.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(deskflowServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('跨屏协同')),
      body: AnimatedBuilder(
        animation: service,
        builder: (_, __) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              '选择工作模式',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _mode(
                    '使用此计算机的键盘和鼠标\n（将此计算机设为服务器）',
                    DeskflowMode.server,
                    service,
                  ),
                ),
                Expanded(
                  child: _mode(
                    '使用另一台计算机的鼠标和键盘\n（将此计算机设为客户端）',
                    DeskflowMode.client,
                    service,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (mode == DeskflowMode.client)
              TextField(
                controller: host,
                enabled: !service.isRunning,
                decoration: const InputDecoration(
                  labelText: '远程电脑地址',
                  border: OutlineInputBorder(),
                ),
              ),
            if (mode == DeskflowMode.client) const SizedBox(height: 12),
            TextField(
              controller: port,
              enabled: !service.isRunning,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '端口',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              title: const Text('同步剪贴板'),
              value: clipboard,
              onChanged: service.isRunning
                  ? null
                  : (v) => setState(() => clipboard = v),
            ),
            TDButton(
              text: service.isRunning ? '停止跨屏协同' : '启动跨屏协同',
              type: TDButtonType.fill,
              isBlock: true,
              onTap: () async {
                if (service.isRunning) {
                  await service.stop();
                } else {
                  await service.start(
                    DeskflowConfig(
                      mode: mode,
                      remoteHost: host.text,
                      port: int.tryParse(port.text) ?? 24800,
                      clipboard: clipboard,
                    ),
                  );
                }
              },
            ),
            if (service.lastError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  service.lastError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mode(String text, DeskflowMode value, DeskflowService service) =>
      InkWell(
        onTap: service.isRunning ? null : () => setState(() => mode = value),
        child: Row(
          children: [
            Radio<DeskflowMode>(
              value: value,
              groupValue: mode,
              onChanged: service.isRunning
                  ? null
                  : (v) => setState(() => mode = v!),
            ),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
