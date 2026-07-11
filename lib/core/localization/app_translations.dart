import 'package:get/get.dart';
import 'package:snginepro/core/localization/translations/bn_in.dart';
import 'package:snginepro/core/localization/translations/gu_in.dart';
import 'package:snginepro/core/localization/translations/hi_in.dart';
import 'package:snginepro/core/localization/translations/kn_in.dart';
import 'package:snginepro/core/localization/translations/ml_in.dart';
import 'package:snginepro/core/localization/translations/mr_in.dart';
import 'package:snginepro/core/localization/translations/or_in.dart';
import 'package:snginepro/core/localization/translations/ta_in.dart';
import 'package:snginepro/core/localization/translations/te_in.dart';
import 'package:snginepro/core/localization/translations/ur_pk.dart';
import 'translations/ar_sa.dart';
import 'translations/en_us.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // English & Arabic
    'en_US': enUS,
    'ar_SA': arSA,

    // Indian languages
    'bn_IN': bnIN,
    'gu_IN': guIN,
    'hi_IN': hiIN,
    'kn_IN': knIN,
    'ml_IN': mlIN,
    'mr_IN': mrIN,
    'or_IN': orIN,
    'ta_IN': taIN,
    'te_IN': teIN,

    // Urdu
    'ur_PK': urPK,
  };
}
