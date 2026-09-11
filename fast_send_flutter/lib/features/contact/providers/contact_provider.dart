import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../services/local_storage_service.dart';
import '../../../services/notification_service.dart';
import '../../device/providers/device_provider.dart';
import '../../lan/models/lan_device.dart';
import '../../lan/providers/lan_provider.dart';
import '../models/chat_message.dart';
import '../models/contact.dart';
import '../models/contact_group.dart';
import '../models/contact_state.dart';
import '../services/lan_chat_file_bus.dart';
import '../services/incoming_lan_chat_bus.dart';
import '../services/lan_chat_service.dart';

const _contactsKey = 'contacts_v1';
const _groupsKey = 'contact_groups_v1';
const _chatMessagesKey = 'chat_messages_v1';

final contactBookProvider = NotifierProvider<ContactBook, ContactBookState>(
  ContactBook.new,
);

final peerChatMessageProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.watch(deviceManagerProvider).peerMessageStream;
});

class ContactBook extends Notifier<ContactBookState> {
  @override
  ContactBookState build() {
    var loaded = ContactBookState(
      contacts: _readList(_contactsKey, Contact.fromJson),
      groups: _readList(_groupsKey, ContactGroup.fromJson),
      messages: _readList(_chatMessagesKey, ChatMessage.fromJson),
    );
    state = loaded;
    loaded = _withLanDevices(loaded, ref.read(lanManagerProvider));
    state = loaded;
    ref.listen<List<LanDevice>>(lanManagerProvider, (_, devices) {
      syncLanDevices(devices);
    });
    ref.listen<AsyncValue<LanChatPayload>>(incomingLanChatProvider, (_, next) {
      next.whenData((message) {
        receiveLanMessage(message);
      });
    });
    ref.listen<AsyncValue<LanChatFileEvent>>(lanChatFileEventProvider, (
      _,
      next,
    ) {
      next.whenData((event) {
        _handleLanChatFileEvent(event);
      });
    });
    ref.listen<AsyncValue<Map<String, dynamic>>>(peerChatMessageProvider, (
      _,
      next,
    ) {
      next.whenData((message) {
        try {
          receiveLanMessage(LanChatPayload.fromJson(message));
        } catch (_) {}
      });
    });
    return loaded;
  }

  ContactBookState _withLanDevices(
    ContactBookState current,
    List<LanDevice> devices,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final next = [...current.contacts];
    for (final device in devices) {
      final index = next.indexWhere((c) => c.userId == device.deviceId);
      final existing = index >= 0 ? next[index] : null;
      final contact =
          (existing ??
                  Contact(
                    userId: device.deviceId,
                    displayName: device.deviceName,
                    avatar: device.avatar,
                    addedAt: now,
                  ))
              .copyWith(
                displayName: device.deviceName,
                avatar: device.avatar,
                transport: ContactTransport.lan,
                ip: device.ip,
                port: device.port,
                os: device.os,
                isOnline: device.isOnline,
                autoDiscovered: true,
                lastSeenAt: device.lastSeen,
              );
      if (index >= 0) {
        next[index] = contact;
      } else {
        next.add(contact);
      }
    }
    return current.copyWith(contacts: next);
  }

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      final raw = LocalStorageService.instance.get<String>(key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _persist() {
    LocalStorageService.instance.set<String>(
      _contactsKey,
      jsonEncode(state.contacts.map((e) => e.toJson()).toList()),
    );
    LocalStorageService.instance.set<String>(
      _groupsKey,
      jsonEncode(state.groups.map((e) => e.toJson()).toList()),
    );
    LocalStorageService.instance.set<String>(
      _chatMessagesKey,
      jsonEncode(state.messages.take(500).map((e) => e.toJson()).toList()),
    );
  }

  void syncLanDevices(List<LanDevice> devices) {
    state = _withLanDevices(state, devices);
    _persist();
  }

  void addByUserId(String userId) {
    final id = userId.trim();
    if (id.isEmpty || state.contacts.any((c) => c.userId == id)) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      contacts: [
        ...state.contacts,
        Contact(
          userId: id,
          displayName: id,
          transport: ContactTransport.webrtc,
          autoDiscovered: false,
          addedAt: now,
        ),
      ],
    );
    _persist();
  }

  void removeContact(String userId) {
    final next = state.contacts.where((c) => c.userId != userId).toList();
    if (next.length == state.contacts.length) return;
    state = state.copyWith(contacts: next);
    _persist();
  }

  void createGroup(String name, List<String> memberIds) {
    final clean = name.trim();
    if (clean.isEmpty || memberIds.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final ownerId = ref.read(deviceIdProvider) ?? '';
    state = state.copyWith(
      groups: [
        ...state.groups,
        ContactGroup(
          groupId: const Uuid().v4(),
          name: clean,
          ownerId: ownerId,
          memberIds: {...memberIds, ownerId}.toList(),
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    _persist();
  }

  Future<void> receiveLanMessage(LanChatPayload payload) async {
    debugPrint(
      '[chat][recv] message=${payload.messageId} '
      'from=${payload.senderId} conversation=${payload.conversationId}',
    );
    if (state.messages.any((m) => m.messageId == payload.messageId)) return;
    final existing = state.contacts.where((c) => c.userId == payload.senderId);
    if (existing.isEmpty) {
      addByUserId(payload.senderId);
    }
    final conversationId = payload.conversationId.startsWith('dm:')
        ? 'dm:${payload.senderId}'
        : payload.conversationId;
    var groups = state.groups;
    if (conversationId.startsWith('group:')) {
      final groupId = conversationId.substring(6);
      if (!groups.any((g) => g.groupId == groupId)) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final me = ref.read(deviceIdProvider) ?? '';
        groups = [
          ...groups,
          ContactGroup(
            groupId: groupId,
            name: payload.conversationTitle?.trim().isNotEmpty == true
                ? payload.conversationTitle!.trim()
                : '群组',
            ownerId: payload.senderId,
            memberIds: {...payload.memberIds, payload.senderId, me}.toList(),
            createdAt: now,
            updatedAt: now,
          ),
        ];
      }
    }
    state = state.copyWith(
      groups: groups,
      messages: [
        ...state.messages,
        payload
            .toChatMessage(normalizedConversationId: conversationId)
            .copyWith(isRead: false),
      ],
    );
    _persist();
    await NotificationService.instance.showIncomingChat(
      senderName: payload.senderName,
      text: payload.text,
    );
  }

  Future<void> sendText(String conversationId, String text) async {
    final body = text.trim();
    if (body.isEmpty) return;
    final me = ref.read(deviceManagerProvider).config;
    if (me == null) return;
    final message = ChatMessage(
      messageId: const Uuid().v4(),
      conversationId: conversationId,
      senderId: me.deviceId,
      senderName: me.deviceName,
      senderAvatar: me.avatar,
      text: body,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isOutgoing: true,
      isRead: true,
      status: ChatMessageStatus.sending,
    );
    state = state.copyWith(messages: [...state.messages, message]);
    _persist();

    final targetIds = _targetIds(conversationId, me.deviceId);
    final groupInfo = _groupInfo(conversationId);
    final service = LanChatService();
    var delivered = false;
    for (final id in targetIds) {
      final matches = state.contacts.where((c) => c.userId == id);
      final contact = matches.isEmpty ? null : matches.first;
      final payload = LanChatPayload(
        messageId: message.messageId,
        conversationId: conversationId,
        senderId: me.deviceId,
        senderName: me.deviceName,
        senderAvatar: me.avatar,
        text: body,
        timestamp: message.timestamp,
        conversationTitle: groupInfo?.name,
        memberIds: groupInfo?.memberIds ?? const [],
      );
      debugPrint(
        '[chat][send] message=${message.messageId} to=$id '
        'transport=${contact?.transport} ip=${contact?.ip}:${contact?.port} '
        'online=${contact?.isOnline}',
      );
      final ip = contact?.ip;
      final port = contact?.port;
      final ok = ip != null && port != null
          ? await service.send(ip: ip, port: port, payload: payload)
          : contact?.transport == ContactTransport.webrtc
          ? await _sendWebRtc(id, payload)
          : false;
      delivered = delivered || ok;
    }
    if (targetIds.isEmpty) {
      debugPrint(
        '[chat][send] message=${message.messageId} failed: no targets',
      );
    }
    state = state.copyWith(
      messages: [
        for (final item in state.messages)
          if (item.messageId == message.messageId)
            item.copyWith(
              status: delivered
                  ? ChatMessageStatus.delivered
                  : ChatMessageStatus.failed,
            )
          else
            item,
      ],
    );
    debugPrint(
      '[chat][send] message=${message.messageId} delivered=$delivered',
    );
    _persist();
  }

  Future<void> sendFiles(
    String conversationId, {
    required List<String> paths,
    String? caption,
  }) async {
    final cleanPaths = paths.where((path) => path.trim().isNotEmpty).toList();
    final cleanCaption = caption?.trim();
    if (cleanPaths.isEmpty && (cleanCaption == null || cleanCaption.isEmpty)) {
      return;
    }
    if (cleanCaption != null && cleanCaption.isNotEmpty) {
      await sendText(conversationId, cleanCaption);
    }
    if (cleanPaths.isEmpty) return;

    final me = ref.read(deviceManagerProvider).config;
    if (me == null) return;

    final targetIds = _targetIds(conversationId, me.deviceId);
    final targets = state.contacts
        .where(
          (contact) =>
              targetIds.contains(contact.userId) &&
              contact.transport == ContactTransport.lan &&
              contact.ip != null &&
              contact.port != null &&
              contact.isOnline,
        )
        .map((contact) => contact.userId)
        .toList();
    if (targets.isEmpty) {
      throw Exception('当前会话没有可用的局域网联系人');
    }

    final groupInfo = _groupInfo(conversationId);
    final lan = ref.read(lanManagerProvider.notifier);
    for (final path in cleanPaths) {
      final file = File(path);
      if (!await file.exists()) continue;
      final message = ChatMessage(
        messageId: const Uuid().v4(),
        conversationId: conversationId,
        senderId: me.deviceId,
        senderName: me.deviceName,
        senderAvatar: me.avatar,
        text: '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isOutgoing: true,
        isRead: true,
        status: ChatMessageStatus.sending,
        kind: ChatMessageKind.file,
        fileName: p.basename(path),
        fileSize: await file.length(),
        localPath: path,
      );
      state = state.copyWith(messages: [...state.messages, message]);
      _persist();
      try {
        final shareId = await lan.startChatFileShare(
          absoluteFilePath: path,
          targetDeviceIds: targets,
          conversationId: conversationId,
          chatMessageId: message.messageId,
          conversationTitle: groupInfo?.name,
          memberIds: groupInfo?.memberIds ?? const [],
        );
        state = state.copyWith(
          messages: [
            for (final item in state.messages)
              if (item.messageId == message.messageId)
                item.copyWith(shareId: shareId)
              else
                item,
          ],
        );
        _persist();
      } catch (_) {
        state = state.copyWith(
          messages: [
            for (final item in state.messages)
              if (item.messageId == message.messageId)
                item.copyWith(status: ChatMessageStatus.failed)
              else
                item,
          ],
        );
        _persist();
      }
    }
  }

  void _handleLanChatFileEvent(LanChatFileEvent event) {
    switch (event.type) {
      case LanChatFileEventType.incomingOffer:
        _receiveLanFileOffer(event);
        break;
      case LanChatFileEventType.saved:
        _updateFileMessage(event.messageId, (message) {
          return message.copyWith(
            localPath: event.localPath ?? message.localPath,
            status: ChatMessageStatus.delivered,
          );
        });
        break;
      case LanChatFileEventType.outgoingDelivered:
        _updateFileMessage(
          event.messageId,
          (message) => message.copyWith(status: ChatMessageStatus.delivered),
        );
        break;
      case LanChatFileEventType.failed:
        _updateFileMessage(
          event.messageId,
          (message) => message.copyWith(status: ChatMessageStatus.failed),
        );
        break;
    }
  }

  void _receiveLanFileOffer(LanChatFileEvent event) {
    if (state.messages.any((m) => m.messageId == event.messageId)) return;
    final conversationId = event.conversationId.startsWith('dm:')
        ? 'dm:${event.senderId}'
        : event.conversationId;
    if (!state.contacts.any((c) => c.userId == event.senderId)) {
      addByUserId(event.senderId);
    }
    var groups = state.groups;
    if (conversationId.startsWith('group:')) {
      final groupId = conversationId.substring(6);
      if (!groups.any((g) => g.groupId == groupId)) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final me = ref.read(deviceIdProvider) ?? '';
        groups = [
          ...groups,
          ContactGroup(
            groupId: groupId,
            name: event.conversationTitle?.trim().isNotEmpty == true
                ? event.conversationTitle!.trim()
                : '群组',
            ownerId: event.senderId,
            memberIds: {...event.memberIds, event.senderId, me}.toList(),
            createdAt: now,
            updatedAt: now,
          ),
        ];
      }
    }
    state = state.copyWith(
      groups: groups,
      messages: [
        ...state.messages,
        ChatMessage(
          messageId: event.messageId,
          conversationId: conversationId,
          senderId: event.senderId,
          senderName: event.senderName,
          senderAvatar: event.senderAvatar,
          text: '',
          timestamp: event.timestamp,
          isOutgoing: false,
          isRead: false,
          status: ChatMessageStatus.sending,
          kind: ChatMessageKind.file,
          fileName: event.fileName,
          fileSize: event.fileSize,
          localPath: event.localPath,
          shareId: event.shareId,
        ),
      ],
    );
    _persist();
    NotificationService.instance.showIncomingChat(
      senderName: event.senderName,
      text: '[文件] ${event.fileName}',
    );
  }

  void _updateFileMessage(
    String messageId,
    ChatMessage Function(ChatMessage message) update,
  ) {
    var changed = false;
    state = state.copyWith(
      messages: [
        for (final item in state.messages)
          if (item.messageId == messageId)
            (() {
              changed = true;
              return update(item);
            })()
          else
            item,
      ],
    );
    if (changed) _persist();
  }

  List<String> _targetIds(String conversationId, String selfId) {
    if (conversationId.startsWith('dm:')) {
      return [conversationId.substring(3)];
    }
    if (conversationId.startsWith('group:')) {
      final id = conversationId.substring(6);
      final matches = state.groups.where((g) => g.groupId == id);
      final group = matches.isEmpty ? null : matches.first;
      return group?.memberIds.where((id) => id != selfId).toList() ?? [];
    }
    return [];
  }

  ContactGroup? _groupInfo(String conversationId) {
    if (!conversationId.startsWith('group:')) return null;
    final id = conversationId.substring(6);
    final matches = state.groups.where((g) => g.groupId == id);
    return matches.isEmpty ? null : matches.first;
  }

  Future<bool> _sendWebRtc(String peerId, LanChatPayload payload) async {
    try {
      await ref
          .read(deviceManagerProvider)
          .sendPeerData(peerId, payload.toJson());
      debugPrint('[chat][send][webrtc] peer=$peerId delivered=true');
      return true;
    } catch (e) {
      debugPrint('[chat][send][webrtc] peer=$peerId failed=$e');
      return false;
    }
  }

  void markConversationRead(String conversationId) {
    var changed = false;
    final messages = [
      for (final message in state.messages)
        if (message.conversationId == conversationId &&
            !message.isOutgoing &&
            !message.isRead)
          (() {
            changed = true;
            return message.copyWith(isRead: true);
          })()
        else
          message,
    ];
    if (!changed) return;
    state = state.copyWith(messages: messages);
    _persist();
  }

  Future<void> deleteMessage(String messageId) async {
    final matches = state.messages.where((m) => m.messageId == messageId);
    final message = matches.isEmpty ? null : matches.first;
    if (message != null &&
        !message.isOutgoing &&
        message.kind == ChatMessageKind.file &&
        message.localPath != null &&
        message.localPath!.isNotEmpty) {
      try {
        final file = File(message.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('[chat][file][delete] failed=$e');
      }
    }
    final next = state.messages
        .where((message) => message.messageId != messageId)
        .toList();
    if (next.length == state.messages.length) return;
    state = state.copyWith(messages: next);
    _persist();
  }
}

final unreadChatCountProvider = Provider<int>((ref) {
  final messages = ref.watch(contactBookProvider).messages;
  return messages.where((m) => !m.isOutgoing && !m.isRead).length;
});
