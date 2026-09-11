import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_group.freezed.dart';
part 'contact_group.g.dart';

@freezed
abstract class ContactGroup with _$ContactGroup {
  const factory ContactGroup({
    required String groupId,
    required String name,
    required String ownerId,
    @Default(1) int avatar,
    @Default(<String>[]) List<String> memberIds,
    required int createdAt,
    required int updatedAt,
  }) = _ContactGroup;

  factory ContactGroup.fromJson(Map<String, dynamic> json) =>
      _$ContactGroupFromJson(json);
}
