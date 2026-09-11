import 'contact.dart';
import 'contact_group.dart';
import 'chat_message.dart';

class ContactBookState {
  final List<Contact> contacts;
  final List<ContactGroup> groups;
  final List<ChatMessage> messages;

  const ContactBookState({
    this.contacts = const [],
    this.groups = const [],
    this.messages = const [],
  });

  ContactBookState copyWith({
    List<Contact>? contacts,
    List<ContactGroup>? groups,
    List<ChatMessage>? messages,
  }) {
    return ContactBookState(
      contacts: contacts ?? this.contacts,
      groups: groups ?? this.groups,
      messages: messages ?? this.messages,
    );
  }
}
