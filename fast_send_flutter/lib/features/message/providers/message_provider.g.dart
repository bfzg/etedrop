// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MessageList)
final messageListProvider = MessageListProvider._();

final class MessageListProvider
    extends $NotifierProvider<MessageList, List<TransferMessage>> {
  MessageListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageListHash();

  @$internal
  @override
  MessageList create() => MessageList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TransferMessage> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TransferMessage>>(value),
    );
  }
}

String _$messageListHash() => r'3ea42fca9107039b3ea9bf0440cdd25a089e513b';

abstract class _$MessageList extends $Notifier<List<TransferMessage>> {
  List<TransferMessage> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<TransferMessage>, List<TransferMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<TransferMessage>, List<TransferMessage>>,
              List<TransferMessage>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(pendingMessageCount)
final pendingMessageCountProvider = PendingMessageCountProvider._();

final class PendingMessageCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  PendingMessageCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingMessageCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingMessageCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return pendingMessageCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$pendingMessageCountHash() =>
    r'1dd2ee4659ae480ec0816250fc678dfc2fa40848';
