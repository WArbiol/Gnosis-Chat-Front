import 'package:gnosis_chat/features/chat/domain/message_entity.dart';

abstract class ChatRepository {
  Future<({String answer, List<CitationEntity> citations, String route})> ask(
    String query,
  );
}
