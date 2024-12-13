

import 'dart:async';
import 'dart:io';

// import 'package:applovin_max/applovin_max.dart';
import 'package:audio_service/audio_service.dart';
import 'package:blackhole/Helpers/config.dart';
import 'package:blackhole/Helpers/handle_native.dart';
import 'package:blackhole/Helpers/route_handler.dart';
import 'package:blackhole/Screens/About/about.dart';
import 'package:blackhole/Screens/Home/home.dart';
import 'package:blackhole/Screens/Home/splash_view.dart';
import 'package:blackhole/Screens/Library/downloads.dart';
import 'package:blackhole/Screens/Library/nowplaying.dart';
import 'package:blackhole/Screens/Library/playlists.dart';
import 'package:blackhole/Screens/Library/recent.dart';
import 'package:blackhole/Screens/Login/auth.dart';
import 'package:blackhole/Screens/Login/pref.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Screens/Settings/setting.dart';
// import 'package:blackhole/Screens/login_view.dart';
// import 'package:blackhole/Screens/register_view.dart';
import 'package:blackhole/Screens/signin_screen.dart';
import 'package:blackhole/Screens/signup_screen.dart';
import 'package:blackhole/Services/audio_service.dart';
import 'package:blackhole/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
// import 'package:startapp_sdk/startapp.dart';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AppLovinMAX.initialize(
  //   ' NbsDssfMrCd1s_mv7RvFVafiTCL0A_tQzTRRTkTkboxnQBArrHc034SovMsZuvEu_vI_KTTDZaK6TMatvDLlnR',
  // );
  // MobileAds.instance.initialize();
  Paint.enableDithering = true;
  FlutterDownloader.initialize(
      debug: false // optional: set false to disable printing logs to console
      );
  await Firebase.initializeApp();
  // FirebaseFirestore.initializeApp();
  GetIt locator = GetIt.instance;
  locator.registerSingleton<SupabaseClient>(
    SupabaseClient(
      'https://axilwxdcqocnvxqsrbsi.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF4aWx3eGRjcW9jbnZ4cXNyYnNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NTU3OTE1NDksImV4cCI6MTk3MTM2NzU0OX0.BZJ4YGyp6mWAgVqvgnglRJYAYNgNFe9xRFHKgbUi9FA',
    ),
  );
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await Hive.initFlutter('BlackHole');
  } else {
    await Hive.initFlutter();
  }

  await openHiveBox('settings');
  await openHiveBox('downloads');
  await openHiveBox('Favorite Songs');
  await openHiveBox('cache', limit: true);
  // if (Platform.isAndroid) {
  //   OneSignal.shared.setAppId("9a828e84-8516-4c5d-a73a-915536278fb1");
  //   setOptimalDisplayMode();
  // }
  await startService();
  runApp(MyApp());
}

Future<void> setOptimalDisplayMode() async {
  final List<DisplayMode> supported = await FlutterDisplayMode.supported;
  final DisplayMode active = await FlutterDisplayMode.active;

  final List<DisplayMode> sameResolution = supported
      .where(
        (DisplayMode m) => m.width == active.width && m.height == active.height,
      )
      .toList()
    ..sort(
      (DisplayMode a, DisplayMode b) => b.refreshRate.compareTo(a.refreshRate),
    );

  final DisplayMode mostOptimalMode =
      sameResolution.isNotEmpty ? sameResolution.first : active;

  await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
}

Future<void> startService() async {
  final AudioPlayerHandler audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandlerImpl(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.shadow.blackhole.channel.audio',
      androidNotificationChannelName: 'BlackHole',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'drawable/ic_stat_music_note',
      androidShowNotificationBadge: true,
      // androidStopForegroundOnPause: Hive.box('settings')
      //     .get('stopServiceOnPause', defaultValue: true) as bool,
      notificationColor: Colors.grey[900],
    ),
  );
  GetIt.I.registerSingleton<AudioPlayerHandler>(audioHandler);
  GetIt.I.registerSingleton<MyTheme>(MyTheme());
}

Future<void> openHiveBox(String boxName, {bool limit = false}) async {
  final box = await Hive.openBox(boxName).onError((error, stackTrace) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String dirPath = dir.path;
    File dbFile = File('$dirPath/$boxName.hive');
    File lockFile = File('$dirPath/$boxName.lock');
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      dbFile = File('$dirPath/BlackHole/$boxName.hive');
      lockFile = File('$dirPath/BlackHole/$boxName.lock');
    }
    await dbFile.delete();
    await lockFile.delete();
    await Hive.openBox(boxName);
    throw 'Failed to open $boxName Box\nError: $error';
  });
  // clear box if it grows large
  if (limit && box.length > 500) {
    box.clear();
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  // StartAppSdk startAppSdk = StartAppSdk();
  static OnAudioQuery audioQuery = OnAudioQuery();
  Future<void> requestPermission() async {
    if (!await audioQuery.permissionsStatus()) {
      await audioQuery.permissionsRequest();
      if (await audioQuery.permissionsStatus()) {
        await Permission.requestInstallPackages.request();
      }
    }
  }

  Locale _locale = const Locale('en', '');
  late StreamSubscription _intentDataStreamSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final String lang =
        Hive.box('settings').get('lang', defaultValue: 'English') as String;
    final Map<String, String> codes = {
      'Chinese': 'zh',
      'Czech': 'cs',
      'Dutch': 'nl',
      'English': 'en',
      'French': 'fr',
      'German': 'de',
      'Hebrew': 'he',
      'Hindi': 'hi',
      'Hungarian': 'hu',
      'Indonesian': 'id',
      'Italian': 'it',
      'Polish': 'pl',
      'Portuguese': 'pt',
      'Russian': 'ru',
      'Spanish': 'es',
      'Tamil': 'ta',
      'Turkish': 'tr',
      'Ukrainian': 'uk',
      'Urdu': 'ur',
    };
    _locale = Locale(codes[lang]!);

    AppTheme.currentTheme.addListener(() {
      setState(() {});
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getTextStream().listen(
      (String value) {
        handleSharedText(value, navigatorKey);
      },
      onError: (err) {
        // print("ERROR in getTextStream: $err");
      },
    );

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then(
      (String? value) {
        if (value != null) handleSharedText(value, navigatorKey);
      },
    );
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

//   Widget initialFuntion() {
//     void checkLogin() async {
//     final sharedPreferences = await SharedPreferences.getInstance();
//     final session = sharedPreferences.getString('user');

//     if (session == null) {
//       Navigator.pushReplacementNamed(context, '/login');
//     } else {
//       final response =
//           await GetIt.instance<SupabaseClient>().auth.recoverSession(session);

//       sharedPreferences.setString('user', response.data!.persistSessionString);

//       Navigator.pushReplacementNamed(context, '/home');
//     }
//   }
// throw Exception(Error);
//     // return Hive.box('settings').get('userId') != null
//     //     ? HomePage()
//     //     : AuthScreen();
//   }

  @override
  Widget build(BuildContext context) {
    requestPermission();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppTheme.themeMode == ThemeMode.dark
            ? Colors.black38
            : Colors.white,
        statusBarIconBrightness: AppTheme.themeMode == ThemeMode.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarIconBrightness: AppTheme.themeMode == ThemeMode.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return MaterialApp(
      title: 'BlackHole',
      restorationScopeId: 'blackhole',
      debugShowCheckedModeBanner: false,
      themeMode: AppTheme.themeMode,
      theme: AppTheme.lightTheme(
        context: context,
      ),
      darkTheme: AppTheme.darkTheme(
        context: context,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', ''), // Chinese
        Locale('cs', ''), // Czech
        Locale('nl', ''), // Dutch
        Locale('en', ''), // English, no country code
        Locale('fr', ''), // French
        Locale('de', ''), // German
        Locale('he', ''), // Hebrew
        Locale('hi', ''), // Hindi
        Locale('hu', ''), // Hungarian
        Locale('id', ''), // Indonesian
        Locale('it', ''), // Italian
        Locale('pl', ''), // Polish
        Locale('pt', ''), // Portuguese
        Locale('ru', ''), // Russian
        Locale('es', ''), // Spanish
        Locale('ta', ''), // Tamil
        Locale('tr', ''), // Turkish
        Locale('uk', ''), // Ukrainian
        Locale('ur', ''), // Urdu
      ],
      routes: {
        '/': (context) => const SplashView(),
        '/home': (context) => HomePage(),
        '/auth': (context) => AuthScreen(),
        '/login': (context) => const SignInScreen(),
        '/register': (context) => const SignUpScreen(),
        '/pref': (context) => const PrefScreen(),
        '/setting': (context) => const SettingPage(),
        '/about': (context) => AboutScreen(),
        '/playlists': (context) => PlaylistScreen(),
        '/nowplaying': (context) => NowPlaying(),
        '/recent': (context) => RecentlyPlayed(),
        '/downloads': (context) => const Downloads(),
      },
      navigatorKey: navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        return HandleRoute.handleRoute(settings.name);
      },
    );
  }
}
