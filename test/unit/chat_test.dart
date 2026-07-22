import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gnosis_chat/features/chat/data/conversation_cache.dart';
import 'package:gnosis_chat/features/chat/data/conversation_remote_source.dart';
import 'package:gnosis_chat/features/chat/domain/conversation_entity.dart';
import 'package:gnosis_chat/features/chat/domain/message_entity.dart';
import 'package:gnosis_chat/features/chat/presentation/chat_provider.dart';
import 'package:gnosis_chat/features/chat/presentation/conversation_provider.dart';

class FakeConversationCache implements ConversationCache {
  final Map<String, String> _data = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #init) {
      return Future<void>.value();
    }
    if (invocation.memberName == #hasData) {
      return _data.isNotEmpty;
    }
    if (invocation.memberName == #loadConversations) {
      final items = _data.values.map((jsonStr) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return ConversationEntity.fromJson(map);
      }).toList();
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    }
    if (invocation.memberName == #saveConversations) {
      final conversations = invocation.positionalArguments[0] as List<ConversationEntity>;
      _data.clear();
      for (var c in conversations) {
        _data[c.id] = jsonEncode(c.toJson());
      }
      return Future<void>.value();
    }
    if (invocation.memberName == #saveSingle) {
      final conversation = invocation.positionalArguments[0] as ConversationEntity;
      _data[conversation.id] = jsonEncode(conversation.toJson());
      return Future<void>.value();
    }
    if (invocation.memberName == #deleteSingle) {
      final id = invocation.positionalArguments[0] as String;
      _data.remove(id);
      return Future<void>.value();
    }
    if (invocation.memberName == #clear) {
      _data.clear();
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeConversationRemoteSource implements ConversationRemoteSource {
  final List<ConversationEntity> conversations = [];
  bool shouldFailSendMessage = false;
  Map<String, dynamic>? lastSendMessageUiFilters;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #listConversations) {
      return Future.value(conversations);
    }
    if (invocation.memberName == #createConversation) {
      final title = invocation.positionalArguments[0] as String;
      final newConv = ConversationEntity(
        id: 'new-id-${conversations.length}',
        title: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      conversations.add(newConv);
      return Future.value(newConv);
    }
    if (invocation.memberName == #getConversation) {
      final id = invocation.positionalArguments[0] as String;
      return Future.value(conversations.firstWhere((c) => c.id == id));
    }
    if (invocation.memberName == #deleteConversation) {
      final id = invocation.positionalArguments[0] as String;
      conversations.removeWhere((c) => c.id == id);
      return Future<void>.value();
    }
    if (invocation.memberName == #updateConversation) {
      final id = invocation.positionalArguments[0] as String;
      final title = invocation.positionalArguments[1] as String;
      final index = conversations.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updated = conversations[index].copyWith(title: title, updatedAt: DateTime.now());
        conversations[index] = updated;
        return Future.value(updated);
      }
      throw Exception('Not found');
    }
    if (invocation.memberName == #sendMessage) {
      if (shouldFailSendMessage) {
        return Future<MessageEntity>.error(Exception('API quota or connection error'));
      }
      final uiFilters = invocation.namedArguments[#uiFilters] as Map<String, dynamic>?;
      lastSendMessageUiFilters = uiFilters;

      return Future.value(MessageEntity(
        id: 'msg-ai-123',
        content: 'Resposta do Gnosis',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ));
    }
    if (invocation.memberName == #getPdfCatalog) {
      return Future.value([
        {'book_name': 'O Matrimônio Perfeito', 'author': 'V.M. Samael Aun Weor', 'chamber': 1},
        {'book_name': 'A Grande Rebelião', 'author': 'V.M. Samael Aun Weor', 'chamber': 1},
        {'book_name': 'Ciência Gnostic', 'author': 'V.M. Lakhsmi Daimon', 'chamber': 2},
      ]);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('ActiveFilters Tests', () {
    test('Default values should be empty and include chambers [1, 2]', () {
      const filters = ActiveFilters();
      expect(filters.books, isEmpty);
      expect(filters.authors, isEmpty);
      expect(filters.chamberLevels, equals([1, 2]));
      expect(filters.isEmpty, isTrue);
    });

    test('isEmpty returns false if books, authors or chamber levels are modified', () {
      final filtersWithBook = const ActiveFilters().copyWith(books: ['Livro A']);
      expect(filtersWithBook.isEmpty, isFalse);

      final filtersWithChamber = const ActiveFilters().copyWith(chamberLevels: [1]);
      expect(filtersWithChamber.isEmpty, isFalse);
    });

    test('toJson serializes only non-empty parameters', () {
      const filters = ActiveFilters(
        books: ['Livro A'],
        authors: ['Autor B'],
        chamberLevels: [2],
      );
      final json = filters.toJson();
      expect(json['books'], equals(['Livro A']));
      expect(json['authors'], equals(['Autor B']));
      expect(json['chamber_levels'], equals([2]));
    });

    test('toJson excludes empty books/authors fields', () {
      const filters = ActiveFilters(books: [], authors: [], chamberLevels: [1, 2]);
      final json = filters.toJson();
      expect(json.containsKey('books'), isFalse);
      expect(json.containsKey('authors'), isFalse);
      expect(json['chamber_levels'], equals([1, 2]));
    });
  });

  group('ChatNotifier and ConversationNotifier Tests', () {
    late FakeConversationRemoteSource mockRemote;
    late FakeConversationCache mockCache;
    late ProviderContainer container;

    setUp(() {
      mockRemote = FakeConversationRemoteSource();
      mockCache = FakeConversationCache();
      container = ProviderContainer(
        overrides: [
          conversationRemoteSourceProvider.overrideWithValue(mockRemote),
          conversationCacheProvider.overrideWithValue(mockCache),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('ask executes optimistic updates and reverts state on remote error', () async {
      // Mock initial conversation
      final initialConv = ConversationEntity(
        id: 'conv-123',
        title: 'Nova conversa',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRemote.conversations.add(initialConv);
      await mockCache.saveSingle(initialConv);

      // Force select conversation
      await container.read(conversationProvider.notifier).selectConversation('conv-123');
      expect(container.read(conversationProvider).activeId, equals('conv-123'));

      // Set state notifier and verify empty state
      final chatNotifier = container.read(chatProvider.notifier);
      expect(container.read(chatProvider).value, isEmpty);

      // Mock error on sendMessage
      mockRemote.shouldFailSendMessage = true;

      // Expect ask to fail with the thrown exception
      try {
        await chatNotifier.ask('Como meditar?');
        fail('Should have failed');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      // Check state rolled back to empty
      expect(container.read(chatProvider).value, isEmpty);
    });

    test('ask passes active filters to API request', () async {
      // Set active filters
      container.read(activeFiltersProvider.notifier).state = const ActiveFilters(
        books: ['O Matrimônio Perfeito'],
        authors: ['V.M. Samael Aun Weor'],
        chamberLevels: [1],
      );

      // Setup initial conversation
      final initialConv = ConversationEntity(
        id: 'conv-123',
        title: 'Nova conversa',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRemote.conversations.add(initialConv);
      await container.read(conversationProvider.notifier).selectConversation('conv-123');

      // Send query successfully
      mockRemote.shouldFailSendMessage = false;
      await container.read(chatProvider.notifier).ask('O que é o ego?');

      // Verify filters parsed to sendMessage
      expect(mockRemote.lastSendMessageUiFilters, isNotNull);
      expect(mockRemote.lastSendMessageUiFilters!['books'], equals(['O Matrimônio Perfeito']));
      expect(mockRemote.lastSendMessageUiFilters!['authors'], equals(['V.M. Samael Aun Weor']));
      expect(mockRemote.lastSendMessageUiFilters!['chamber_levels'], equals([1]));

      // Verify messages list has user query + assistant response
      final messages = container.read(chatProvider).value!;
      expect(messages.length, equals(2));
      expect(messages[0].content, equals('O que é o ego?'));
      expect(messages[0].role, equals(MessageRole.user));
      expect(messages[1].content, equals('Resposta do Gnosis'));
      expect(messages[1].role, equals(MessageRole.assistant));
    });

    test('ConversationNotifier syncMessages updates active conversation preview and triggers self-healing title updater', () async {
      // Setup initial conversation in list
      final initialConv = ConversationEntity(
        id: 'conv-123',
        title: 'Nova conversa',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRemote.conversations.add(initialConv);

      final notifier = container.read(conversationProvider.notifier);
      await notifier.loadConversations();

      // Set active
      await notifier.selectConversation('conv-123');
      expect(container.read(conversationProvider).activeId, equals('conv-123'));

      // Sync user message to active conversation
      final userMessage = MessageEntity(
        id: 'msg-user-1',
        content: 'Primeira pergunta longa sobre psicologia gnóstica.',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      
      notifier.syncMessages([userMessage]);

      // Verify that the title updated from "Nova conversa" to the message snippet,
      // and last message preview was synced.
      final active = container.read(conversationProvider).active!;
      expect(active.title, equals('Primeira pergunta longa sobre psicologia…'));
      expect(active.lastMessagePreview, equals('Primeira pergunta longa sobre psicologia gnóstica.'));
      expect(active.messageCount, equals(1));

      // Wait briefly for the self-healing async callback to finish updating the remote repository
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(mockRemote.conversations.first.title, equals('Primeira pergunta longa sobre psicologia…'));
    });

    test('ask in draft conversation (activeId == null) maintains optimistic user message during creation', () async {
      expect(container.read(conversationProvider).activeId, isNull);
      expect(container.read(chatProvider).value, isEmpty);

      mockRemote.shouldFailSendMessage = false;
      await container.read(chatProvider.notifier).ask('Pergunta em nova conversa');

      expect(container.read(conversationProvider).activeId, isNotNull);
      final messages = container.read(chatProvider).value!;
      expect(messages.length, equals(2));
      expect(messages[0].content, equals('Pergunta em nova conversa'));
      expect(messages[0].role, equals(MessageRole.user));
      expect(messages[1].content, equals('Resposta do Gnosis'));
    });

    test('loadMessages ignores duplicate message lists with identical content to prevent re-renders', () {
      final msg1 = MessageEntity(
        id: 'msg-1',
        content: 'Conteúdo A',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      final msg2 = MessageEntity(
        id: 'msg-2',
        content: 'Conteúdo B',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      final listA = [msg1, msg2];
      final listB = [
        MessageEntity(
          id: 'msg-1',
          content: 'Conteúdo A',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ),
        MessageEntity(
          id: 'msg-2',
          content: 'Conteúdo B',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        ),
      ];

      final chatNotifier = container.read(chatProvider.notifier);
      chatNotifier.loadMessages(listA);

      final stateRef1 = container.read(chatProvider);

      // Calling loadMessages with identical listB should NOT alter state instance
      chatNotifier.loadMessages(listB);

      final stateRef2 = container.read(chatProvider);
      expect(identical(stateRef1, stateRef2), isTrue);
    });

    test('selectConversation sets loading state when conversation has no pre-cached messages', () async {
      final conv = ConversationEntity(
        id: 'conv-uncached',
        title: 'Conversa Sem Cache',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRemote.conversations.add(conv);

      final convNotifier = container.read(conversationProvider.notifier);
      await convNotifier.loadConversations();

      // Trigger selection
      final selectFuture = convNotifier.selectConversation('conv-uncached');

      // Before remote fetch resolves, chatProvider should be in loading state
      expect(container.read(chatProvider).isLoading, isTrue);

      await selectFuture;
      expect(container.read(conversationProvider).activeId, equals('conv-uncached'));
      expect(container.read(chatProvider).hasValue, isTrue);
    });

    test('selectConversation loads existing cached messages instantly before fetching remote update', () async {
      final cachedMessage = MessageEntity(
        id: 'msg-cached-1',
        content: 'Pergunta salva no cache',
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      final convWithCache = ConversationEntity(
        id: 'conv-cached',
        title: 'Conversa Com Cache',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [cachedMessage],
        messageCount: 1,
        lastMessagePreview: 'Pergunta salva no cache',
      );
      mockRemote.conversations.add(convWithCache);

      final convNotifier = container.read(conversationProvider.notifier);
      await convNotifier.loadConversations();

      // Trigger selection
      await convNotifier.selectConversation('conv-cached');

      expect(container.read(conversationProvider).activeId, equals('conv-cached'));
      final messages = container.read(chatProvider).value!;
      expect(messages.length, equals(1));
      expect(messages.first.content, equals('Pergunta salva no cache'));
    });
  });
}
