import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../lan/models/lan_device.dart';
import '../../lan/providers/lan_provider.dart';
import '../models/transfer_message.dart';

/// 与「发给 …」占位符相同的收件人描述串，用于 [AppLocalizations.messageOutgoingHeaderLine]。
String? outgoingRecipientNamesOnly(
  WidgetRef ref,
  TransferMessage m,
  AppLocalizations l10n,
) {
  if (!m.isOutgoing || m.targetDeviceIdsJson == null) return null;
  try {
    final ids = (jsonDecode(m.targetDeviceIdsJson!) as List)
        .map((e) => e as String)
        .toList();
    final devices = ref.watch(lanManagerProvider);
    final names = <String>[];
    for (final id in ids) {
      LanDevice? found;
      for (final d in devices) {
        if (d.deviceId == id) {
          found = d;
          break;
        }
      }
      if (found != null) names.add(found.deviceName);
    }
    if (names.isEmpty) {
      return l10n.recipientNDevices(ids.length);
    }
    if (names.length == 1) {
      return names[0];
    }
    if (names.length == 2) {
      return l10n.recipientTwo(names[0], names[1]);
    }
    return l10n.recipientMany(names[0], names[1], ids.length);
  } catch (_) {
    return null;
  }
}
