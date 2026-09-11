import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'lan_chat_service.dart';

final _incomingLanChatController = StreamController<LanChatPayload>.broadcast();

void publishIncomingLanChat(LanChatPayload payload) {
  _incomingLanChatController.add(payload);
}

final incomingLanChatProvider = StreamProvider<LanChatPayload>((ref) {
  return _incomingLanChatController.stream;
});
