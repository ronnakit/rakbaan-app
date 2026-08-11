import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'providers/chat_provider.dart';
import 'providers/job_provider.dart';
import 'providers/text_scale_provider.dart';
import 'repositories/mock_job_repository.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RakBaanApp());
}

class RakBaanApp extends StatelessWidget {
  const RakBaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        // FirestoreJobRepository exists (lib/repositories/firestore_job_repository.dart)
        // but is NOT wired in here yet -- `rakbaan-cnx` has no Firestore
        // database provisioned yet (Cloud Firestore API has never been
        // enabled on that project), so every call it makes would throw.
        // Once that's done and firebase.json/functions are deployed, swap
        // to it like this (no screen needs to change -- see JobRepository):
        //
        //   final auth = FirebaseAuth.instance;
        //   if (auth.currentUser == null) await auth.signInAnonymously();
        //   ...
        //   create: (_) => JobProvider(
        //     repository: FirestoreJobRepository(customerId: auth.currentUser!.uid),
        //   ),
        //
        // (signInAnonymously is a stand-in for real customer auth -- no
        // phone-OTP login flow exists yet, see
        // rakbaan_md/07-technical-requirements.md §1.3.)
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
