import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //initialise Firebase for push notification etc
  FirebaseMessagingSetup.instance.initiateOnMain();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    if (Platform.isIOS) {
      ConfigCONST.platform = 'ios';
    } else if (Platform.isAndroid) {
      ConfigCONST.platform = 'android';
    }
    //initialise firebase once
    FirebaseMessagingSetup.instance.initiateInAppInitState(context);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      builder: (ctx, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: ConfigCONST.isDevelopmentMode,
          //wiil be auto replaced
          title: 'NG-APP-TITLE',
          // theme: Provider.of<ThemeProvider>(ctx).currentTheme,
          theme: ThemeProvider.t.getTheme,
          home: const SplashScreen(),
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const SplashScreen(),
            );
          },
          routes: {
            AppAboutScreen.routeName: (ctx) => const AppAboutScreen(),
          },
        );
      },
    );
  }
}
