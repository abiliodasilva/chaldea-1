import 'package:chaldea/generated/intl/messages_all.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

import '../generated/l10n.dart';
import '../models/db.dart';
import '../packages/language.dart';
import '../packages/method_channel/method_channel_chaldea.dart';
import '../packages/network.dart';
import '../packages/platform/platform.dart';
import '../utils/catcher/catcher_util.dart';
import '../utils/constants.dart';
import '../widgets/after_layout.dart';
import 'app.dart';
import 'routes/parser.dart';

class ChaldeaNext extends StatefulWidget {
  ChaldeaNext({Key? key}) : super(key: key);

  @override
  _ChaldeaNextState createState() => _ChaldeaNextState();
}

class _ChaldeaNextState extends State<ChaldeaNext> with AfterLayoutMixin {
  final routeInformationParser = AppRouteInformationParser();
  final backButtonDispatcher = RootBackButtonDispatcher();

  @override
  void reassemble() {
    super.reassemble();
    reloadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = _getThemeData(dark: false);
    final darkTheme = _getThemeData(dark: true);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: db2.settings.isResolvedDarkMode
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: darkTheme.scaffoldBackgroundColor)
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: lightTheme.scaffoldBackgroundColor),
      child: Screenshot(
        controller: db2.runtimeData.screenshotController,
        child: MaterialApp.router(
          title: kAppName,
          routeInformationParser: routeInformationParser,
          routerDelegate: rootRouter,
          backButtonDispatcher: backButtonDispatcher,
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: db2.settings.themeMode,
          scrollBehavior: DraggableScrollBehavior(),
          locale: Language.getLanguage(db2.settings.language)?.locale,
          localizationsDelegates: const [
            S.delegate,
            ...GlobalMaterialLocalizations.delegates
          ],
          supportedLocales: S.delegate.supportedLocales,
          builder: (context, widget) {
            ErrorWidget.builder = CatcherUtil.errorWidgetBuilder;
            return FlutterEasyLoading(child: widget);
          },
        ),
      ),
    );
  }

  ThemeData _getThemeData({required bool dark}) {
    var themeData = dark
        ? ThemeData(brightness: Brightness.dark)
        : ThemeData(brightness: Brightness.light);
    return themeData.copyWith(
      appBarTheme: themeData.appBarTheme.copyWith(
        titleSpacing: 0,
      ),
    );
  }

  void onAppUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    debugPrint('initiate $runtimeType');
    super.initState();
    db2.notifyAppUpdate = onAppUpdate;
    if (db2.settings.language != null) {
      Intl.defaultLocale = Language.current.code;
    }

    SystemChannels.lifecycle.setMessageHandler((msg) async {
      debugPrint('SystemChannels> $msg');
      if (msg == AppLifecycleState.resumed.toString()) {
        // Actions when app is resumed
        network.check();
      } else if (msg == AppLifecycleState.inactive.toString()) {
        db2.saveAll();
        debugPrint('save userdata before being inactive');
      }
      return null;
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    if (PlatformU.isWindows || PlatformU.isMacOS) {
      MethodChannelChaldeaNext.setAlwaysOnTop();
    }
    if (PlatformU.isWindows) {
      MethodChannelChaldeaNext.setWindowPos();
    }
  }
}

class DraggableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
