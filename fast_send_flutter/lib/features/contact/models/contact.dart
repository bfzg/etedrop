import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact.freezed.dart';
part 'contact.g.dart';

enum ContactTransport { lan, webrtc }

@freezed
abstract class Contact with _$Contact {
  const factory Contact({
    required String userId,
    required String displayName,
    @Default(1) int avatar,
    @Default(ContactTransport.lan) ContactTransport transport,
    String? ip,
    int? port,
    String? os,
    @Default(false) bool isOnline,
    @Default(true) bool autoDiscovered,
    required int addedAt,
    @Default(0) int lastSeenAt,
  }) = _Contact;

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);
}
