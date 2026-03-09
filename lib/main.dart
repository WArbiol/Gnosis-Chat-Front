import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/app.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gnosis_chat/features/chat/data/conversation_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Allow dart-define for CI/scripts, fallback to .env for IDE debugging
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  await Supabase.initialize(
    url: supabaseUrl.isNotEmpty
        ? supabaseUrl
        : dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: supabaseAnonKey.isNotEmpty
        ? supabaseAnonKey
        : dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
    ),
  );

  await Hive.initFlutter();
  await Hive.openBox<String>(ConversationCache.boxName);

  runApp(const ProviderScope(child: GnosisApp()));
}
