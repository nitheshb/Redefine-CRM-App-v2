import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:saleapp/Auth/login_screen.dart';
import 'package:saleapp/Screens/Home/home_controller.dart';
import 'package:saleapp/services/fcm_service.dart';
import 'package:saleapp/services/remote_config_service.dart';

import 'Auth/auth_controller.dart';
import 'Screens/SuperHomePage/superhomepage_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );

  // Initialize Remote Config (fetch defaults + first activation)
  await RemoteConfigService.instance.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,  // Only allow portrait mode
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
   Get.put(AuthController());
   Get.put(HomeController());
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('Current user: ${currentUser?.uid}');

    // Initialize FCM token for already-logged-in users
    if (currentUser != null) {
      FcmService.instance.initToken();
      FcmService.instance.listenForTokenRefresh();
    }
    return  GetMaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
        home: currentUser == null ? LoginScreen() : SuperHomePage()

    );
  }
}


