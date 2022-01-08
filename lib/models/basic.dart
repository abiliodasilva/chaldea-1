import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/extension.dart';

bool _runChaldeaNext = false;

bool get runChaldeaNext => kDebugMode && _runChaldeaNext;

set runChaldeaNext(bool v) => _runChaldeaNext = kDebugMode && v;

class Language {
  final String code;
  final String name;
  final String nameEn;
  final Locale locale;

  const Language(this.code, this.name, this.nameEn, this.locale);

  static const jp = Language('ja', '日本語', 'Japanese', Locale('ja', ''));
  static const chs =
  Language('zh-CN', '简体中文', 'Simplified Chinese', Locale('zh', 'CN'));
  static const cht =
  Language('zh-TW', '繁体中文', 'Traditional Chinese', Locale('zh', 'TW'));
  static const en = Language('en', 'English', 'English', Locale('en', ''));
  static const kr = Language('ko', '한국어', 'Korean', Locale('ko', ''));
  static const ar = Language('ar', 'عربى', 'Arabic', Locale('ar', ''));
  static const es = Language('es', 'Española', 'Spanish', Locale('es', ''));

  static List<Language>? _fallbackLanguages;

  static List<Language> get fallbackLanguages =>
      _fallbackLanguages ??= _defaultFallbackLanguages(Intl.getCurrentLocale());

  static set fallbackLanguages(List<Language> languages) {
    assert(languages.length == 5, languages);
    _fallbackLanguages = languages;
  }

  static List<Language> _defaultFallbackLanguages(String? locale) {
    locale = locale?.replaceAll('_', '-');
    if (['zh-TW', 'zh-HK', 'zh-MO'].contains(locale)) {
      return [cht, chs, jp, en, kr];
    } else if (locale?.startsWith('zh') == true) {
      return [chs, jp, en, cht, kr];
    } else if (locale?.startsWith('ko') == true) {
      return [kr, en, jp, chs, cht];
    } else if (locale?.startsWith('en') == true) {
      return [en, jp, chs, cht, kr];
    } else if (locale?.startsWith('jp') == true) {
      return [jp, chs, cht, en, kr];
    } else {
      return [en, jp, chs, cht, kr];
    }
  }

  static List<Language> get supportLanguages =>
      const [jp, chs, cht, en, kr, ar, es];

  static List<Language> get officialLanguages => const [jp, chs, cht, en, kr];

  static Language? getLanguage(String? code) {
    if (code == null) return null;
    Language? language =
    supportLanguages.firstWhereOrNull((lang) => lang.code == code);
    language ??= supportLanguages
        .firstWhereOrNull((lang) => code.startsWith(lang.locale.languageCode));
    return language;
  }

  static String get currentLocaleCode =>
      Intl.getCurrentLocale().replaceAll('_', '-');

  /// used for 5 region game data
  static bool get isZH => [chs, cht].contains(fallbackLanguages.first);

  static bool get isCHS => current == chs;

  static bool get isCHT => current == cht;

  static bool get isJP => current == jp;

  static bool get isEN => current == en;

  static bool get isKR => current == kr;

  static Language get current => fallbackLanguages.first;

  @override
  String toString() {
    return "$runtimeType('$code', '$name')";
  }
}