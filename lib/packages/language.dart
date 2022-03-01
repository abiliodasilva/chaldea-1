import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/db.dart';
import '../utils/extension.dart';

class Language {
  final String code;
  final String name;
  final String nameEn;
  final Locale locale;

  const Language(this.code, this.name, this.nameEn, this.locale);

  static const jp = Language('ja', '日本語', 'Japanese', Locale('ja', ''));
  static const chs = Language('zh_Hans', '简体中文', 'Simplified Chinese',
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
  static const cht = Language('zh_Hant', '繁体中文', 'Traditional Chinese',
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'));
  static const en = Language('en', 'English', 'English', Locale('en', ''));
  static const ko = Language('ko', '한국어', 'Korean', Locale('ko', ''));
  static const ar = Language('ar', 'عربى', 'Arabic', Locale('ar', ''));
  static const es = Language('es', 'Española', 'Spanish', Locale('es', ''));

  // static List<Language>? _fallbackLanguages;
  //
  // static List<Language> get fallbackLanguages =>
  //     _fallbackLanguages ?? _defaultFallbackLanguages();
  //
  // static set fallbackLanguages(List<Language> languages) {
  //   assert(languages.length == 5, languages);
  //   _fallbackLanguages = languages;
  // }

  static Language _parseLang(String? code) {
    String locale = Intl.canonicalizedLocale(code);
    if (locale.startsWith('zh') == true) {
      if (locale.contains('Hant')) {
        return cht;
      } else {
        return chs;
      }
    } else if (locale.startsWith('ko') == true) {
      return ko;
    } else if (locale.startsWith('en') == true) {
      return en;
    } else if (locale.startsWith('ja') == true) {
      return jp;
    } else {
      return en;
    }
  }

  static List<Language> get supportLanguages =>
      const [jp, chs, cht, en, ko, es, ar];

  static List<Language> get officialLanguages => const [jp, chs, cht, en, ko];

  static Language? getLanguage(String? code) {
    if (code == null) return null;
    Language? language =
        supportLanguages.firstWhereOrNull((lang) => lang.code == code);
    language ??= supportLanguages
        .firstWhereOrNull((lang) => code.startsWith(lang.locale.languageCode));
    return language;
  }

  static String get currentLocaleCode => Intl.canonicalizedLocale(null);

  /// used for 5 region game data
  static bool get isZH => isCHS || isCHT;

  static bool get isCHS => current == chs;

  static bool get isCHT => current == cht;

  static bool get isJP => current == jp;

  static bool get isEN => current == en;

  static bool get isKO => current == ko;

  static Language get current => _parseLang(db2.settings.language);

  @override
  String toString() {
    return "$runtimeType('$code', '$name')";
  }

  // legacy
  static bool get isEnOrKr => isEN || isKO;
}