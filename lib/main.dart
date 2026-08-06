import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'providers/chat_provider.dart';
import 'providers/job_provider.dart';
import 'providers/text_scale_provider.dart';
import 'repositories/mock_job_repository.dart';
import 'router/app_router.dart';

void main() {
  runApp(const RakBaanApp());
}

class RakBaanApp extends StatelessWidget {
  const RakBaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        // Swap MockJobRepository for a Firebase-backed one here once the
        // backend lands -- no screen needs to change (see JobRepository).
        ChangeNotifierProvider(
          create: (_) => JobProvider(repository: MockJobRepository()),
        ),
        ChangeNotifierProvider(create: (_) => TextScaleProvider()),
      ],
      child: Builder(
        builder: (context) {
          final textScale = context.watch<TextScaleProvider>().scale;
          return MaterialApp.router(
            title: 'รักบ้าน@CNX',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: appRouter,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            ),
          );
        },
      ),
    );
  }
}
