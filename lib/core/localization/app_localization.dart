import 'package:get/get.dart';
import 'app_translations.dart';

class AppLocalization extends Translations {
  @override
  Map<String, Map<String, String>> get keys => AppTranslations().keys;
}