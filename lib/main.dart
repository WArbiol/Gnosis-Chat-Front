import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnosis_chat/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: initialize Supabase
  // await Supabase.initialize(url: ..., anonKey: ...);

  runApp(const ProviderScope(child: GnosisApp()));
}
