import 'package:get/get.dart';
import 'translations/en_us.dart';
import 'translations/ar_sa.dart';
import 'translations/bn_in.dart';
import 'translations/gu_in.dart';
import 'translations/hi_in.dart';
import 'translations/kn_in.dart';
import 'translations/ml_in.dart';
import 'translations/mr_in.dart';
import 'translations/or_in.dart';
import 'translations/ta_in.dart';
import 'translations/te_in.dart';
import 'translations/ur_pk.dart';
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'ar_SA': arSA,
        'bn_in': bnIN,
        'gu_in': guIN,
        'hi_in': hiIN,
        'kn_in': knIN,
        'ml_in': mlIN,
        'mr_in': mrIN,
        'or_in': orIN,
        'ta_in': taIN,
        'te_in': teIN,
        'ur_pk': urPK,
      };
}