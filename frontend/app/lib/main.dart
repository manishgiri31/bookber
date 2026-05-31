import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bookber_app.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = await buildAppContainer();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BookBerApp(),
    ),
  );
}
