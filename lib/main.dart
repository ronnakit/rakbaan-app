import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'providers/chat_provider.dart';
import 'providers/job_provider.dart';
import 'providers/text_scale_provider.dart';
import 'repositories/firestore_job_repository.dart';
import 'repositories/job_repository.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Anonymous auth is a stand-in for real customer auth -- no phone-OTP
  // login flow exists yet (rakbaan_md/07-technical-requirements.md §1.3).
  // It's enough to satisfy firestore.rules' `request.auth != null` checks
  // and gives a stable uid to key `jobs.customerId` off of.
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }
  final customerId = auth.currentUser!.uid;

  runApp(RakBaanApp(customerId: customerId));
}

class RakBaanApp extends StatelessWidget {
  const RakBaanApp({super.key, required this.customerId, this.jobRepository});

  final String customerId;

  /// Test-only override -- widget tests pump this app with no Firebase app
  /// initialized, so they must not let this class construct a
  /// [FirestoreJobRepository] itself (see test/widget_test.dart).
  final JobRepository? jobRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(
          create: (_) => JobProvider(
            repository: jobRepository ?? FirestoreJobRepository(customerId: customerId),
          ),
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
