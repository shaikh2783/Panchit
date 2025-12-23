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
import 'translations/de_de.dart';
import 'translations/el_gr.dart';
import 'translations/en_us.dart';
import 'translations/es_es.dart';
import 'translations/fr_fr.dart';
import 'translations/it_it.dart';
import 'translations/nl_nl.dart';
import 'translations/pt_br.dart';
import 'translations/pt_pt.dart';
import 'translations/ro_ro.dart';
import 'translations/ru_ru.dart';
import 'translations/tr_tr.dart';

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

    // European languages
    'fr_FR': frFR,
    'es_ES': esES,
    'pt_PT': ptPT,
    'pt_BR': ptBR,
    'de_DE': deDE,
    'tr_TR': trTR,
    'nl_NL': nlNL,
    'it_IT': itIT,
    'ru_RU': ruRU,
    'ro_RO': roRO,
    'el_GR': elGR,
  };
}
