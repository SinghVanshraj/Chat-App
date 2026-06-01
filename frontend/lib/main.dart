import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'services/auth_service.dart';
import 'utils/constants.dart';
import 'utils/config.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/direct_messages_screen.dart';

IO.Socket? appSocket;

Future<void> connectGlobalSocket() async {
  final userId = await AuthService.getUserId();
  final token  = await AuthService.getToken();
  if (userId == null || token == null) return;

  appSocket?.dispose();

  appSocket = IO.io(
    Config.apiUrl,
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .disableAutoConnect()
        .build(),
  );

  appSocket!.connect();

  appSocket!.onConnect((_) {
    appSocket!.emit('user_connected', userId);
    debugPrint('Global socket connected');
  });

  appSocket!.onDisconnect((_) => debugPrint('Global socket disconnected'));
  appSocket!.onConnectError((e) => debugPrint('Socket connect error: $e'));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final loggedIn = await AuthService.isLoggedIn();
  if (loggedIn) await connectGlobalSocket();

  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isLoggedIn) return;
    if (state == AppLifecycleState.resumed) {
      if (appSocket?.disconnected ?? true) {
        connectGlobalSocket();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness:              Brightness.dark,
        scaffoldBackgroundColor: AppColor.background,
        colorScheme: const ColorScheme.dark(
          primary:    AppColor.primaryColor,
          surface:    AppColor.surface,
          background: AppColor.background,
        ),
        splashColor:    Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      initialRoute: '/',
      routes: {
        '/':               (_) => const InitializerWidget(),
        '/landing':        (_) => const LandingScreen(),
        '/login':          (_) => const LoginScreen(),
        '/register':       (_) => const RegisterScreen(),
        '/directMessages': (_) => const DirectMessagesScreen(),
      },
    );
  }
}

class InitializerWidget extends StatefulWidget {
  const InitializerWidget({super.key});

  @override
  State<InitializerWidget> createState() => _InitializerWidgetState();
}

class _InitializerWidgetState extends State<InitializerWidget> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      if (appSocket == null || appSocket!.disconnected) {
        await connectGlobalSocket();
      }
      Navigator.pushReplacementNamed(context, '/directMessages');
    } else {
      Navigator.pushReplacementNamed(context, '/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColor.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColor.primaryColor),
      ),
    );
  }
}
