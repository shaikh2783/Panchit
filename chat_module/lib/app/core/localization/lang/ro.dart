import '../app_translations.dart';
import 'base.dart';

final Map<String, String> ro = <String, String>{
  ...buildBaseTranslations(),
  AppTranslations.appName: 'Messenger',
  AppTranslations.loginHeadline: 'Bine ai revenit la conversațiile tale',
  AppTranslations.loginSubtitle:
      'Conectați-vă pentru a vă continua conversațiile, pentru a gestiona conturile conectate și pentru a rămâne aproape de oamenii dvs.',
  AppTranslations.loginIdentifierLabel: 'E-mail sau nume de utilizator',
  AppTranslations.loginIdentifierHint:
      'Introduceți adresa dvs. de e-mail sau numele de utilizator',
  AppTranslations.passwordLabel: 'Parolă',
  AppTranslations.passwordHint: 'Introduceți parola',
  AppTranslations.rememberMe: 'ține minte',
  AppTranslations.forgotPassword: 'Ai uitat parola?',
  AppTranslations.signIn: 'Conectați-vă',
  AppTranslations.createAccount: 'Creați cont',
  AppTranslations.alreadyHaveAccount: 'Aveți deja un cont?',
  AppTranslations.dontHaveAccount: 'Nu ai un cont?',
  AppTranslations.registerTitle: 'Înregistrează-te',
  AppTranslations.registerSubtitle:
      'Completați detaliile contului pentru a crea un nou cont Messenger.',
  AppTranslations.signUpHeadline: 'Creează-ți contul Messenger',
  AppTranslations.signUpSubtitle:
      'Alăturați-vă conversației cu un cont nou și continuați automat cu următorul pas de configurare necesar.',
  AppTranslations.signUpToggleTitle: 'Nou aici?',
  AppTranslations.signInToggleTitle: 'Aveți deja un cont?',
  AppTranslations.signUpUsernameLabel: 'Nume de utilizator',
  AppTranslations.signUpUsernameHint: 'Alegeți un nume de utilizator',
  AppTranslations.signUpEmailLabel: 'Adresă de e-mail',
  AppTranslations.signUpEmailHint: 'Introdu adresa ta de e-mail',
  AppTranslations.signUpFirstNameLabel: 'Prenume',
  AppTranslations.signUpFirstNameHint: 'Introduceți prenumele dvs',
  AppTranslations.signUpLastNameLabel: 'Nume de familie',
  AppTranslations.signUpLastNameHint: 'Introduceți numele dvs. de familie',
  AppTranslations.signUpGenderLabel: 'Gen',
  AppTranslations.signUpGenderMale: 'Bărbat',
  AppTranslations.signUpGenderFemale: 'Femeie',
  AppTranslations.signUpConfirmPasswordLabel: 'Confirmați parola',
  AppTranslations.signUpConfirmPasswordHint: 'Reintroduceți parola',
  AppTranslations.signUpUsernameRequired:
      'Numele de utilizator este obligatoriu',
  AppTranslations.signUpUsernameTooShort:
      'Numele de utilizator trebuie să aibă cel puțin 3 caractere',
  AppTranslations.signUpEmailRequired: 'Este necesară adresa de e-mail',
  AppTranslations.signUpEmailInvalid: 'Introduceți o adresă de e-mail validă',
  AppTranslations.signUpPasswordTooShort:
      'Parola trebuie să aibă cel puțin 6 caractere',
  AppTranslations.signUpConfirmPasswordRequired:
      'Este necesară confirmarea parolei',
  AppTranslations.signUpPasswordsDoNotMatch: 'Parolele nu se potrivesc',
  AppTranslations.signUpFirstNameRequired: 'Prenumele este obligatoriu',
  AppTranslations.signUpLastNameRequired: 'Numele de familie este obligatoriu',
  AppTranslations.signUpFailed: 'Nu se poate crea contul în acest moment',
  AppTranslations.signUpNote:
      'După înregistrare, Messenger vă va ghida automat prin activare sau orice pas de configurare necesar.',
  AppTranslations.signUpAgreementPrefix: 'Sunt de acord cu',
  AppTranslations.signUpAgreementAnd: 'şi',
  AppTranslations.signUpAgreementSuffix: 'înainte de a-mi crea contul.',
  AppTranslations.signUpTermsOfUse: 'Termeni de utilizare',
  AppTranslations.signUpPrivacyPolicy: 'Politica de confidențialitate',
  AppTranslations.signUpTermsRequiredTitle: 'Este necesară aprobarea',
  AppTranslations.signUpTermsRequiredMessage:
      'Mai întâi trebuie să fiți de acord cu Termenii de utilizare și Politica de confidențialitate.',
  AppTranslations.webViewPageTitle: 'Detalii',
  AppTranslations.secureAccessNote:
      'Conectare protejată cu verificarea sesiunii în funcție de dispozitiv.',
  AppTranslations.loginFooter:
      'Creat pentru mesagerie rapidă, cu un flux de conectare concentrat și sigur.',
  AppTranslations.loginWithTimeline: 'Continuați cu contul Timeline',
  AppTranslations.loginWithTimelineSubtitle:
      'Utilizați contul care este deja conectat în Timeline.',
  AppTranslations.identifierRequired:
      'Este necesar un e-mail sau un nume de utilizator',
  AppTranslations.passwordRequired: 'Parola este necesară',
  AppTranslations.loading: 'Se încarcă...',
  AppTranslations.homeHeadline: 'Mesaje',
  AppTranslations.homeSubtitle: 'Rămâi aproape de oamenii la care îți pasă.',
  AppTranslations.homeWelcomeBack: 'Bine ai revenit, @name',
  AppTranslations.homeSearchHint: 'Căutați conversații',
  AppTranslations.homeSearchEmptyTitle: 'Nicio conversație care se potrivește',
  AppTranslations.homeSearchEmptyBody:
      'Încercați alt nume sau cuvânt cheie pentru a găsi o conversație.',
  AppTranslations.addStory: 'Adăugați o poveste',
  AppTranslations.shareStory: 'Distribuiți povestea',
  AppTranslations.storyAddText: 'Adăugați text',
  AppTranslations.storyTextHint: 'Scrie ceva...',
  AppTranslations.storyMediaHint:
      'Adăugați o fotografie sau un videoclip pentru a vă împărtăși povestea.',
  AppTranslations.camera: 'Camera foto',
  AppTranslations.gallery: 'Galerie',
  AppTranslations.done: 'Gata',
  AppTranslations.replyToStory: 'Răspunde la poveste',
  AppTranslations.storyReplySent: 'Răspunsul la poveste a fost trimis.',
  AppTranslations.storyReactionSent: 'Reacția la poveste trimisă.',
  AppTranslations.storyPublished: 'Povestea publicată.',
  AppTranslations.storyViews: 'Vizualizări',
  AppTranslations.storyViewers: 'Vizionatori de povești',
  AppTranslations.storyReactions: 'Reacții la poveste',
  AppTranslations.noStoryViewers: 'Încă nu există spectatori.',
  AppTranslations.noStoryReactions: 'Nicio reacție încă.',
  AppTranslations.unableToLoadStoryViewers:
      'Nu se pot încărca spectatorii de povești în acest moment.',
  AppTranslations.unableToLoadStoryReactions:
      'Nu se pot încărca reacțiile la poveste în acest moment.',
  AppTranslations.unableToReplyToStory:
      'Nu se poate trimite răspunsul la poveste chiar acum.',
  AppTranslations.unableToReactToStory:
      'Nu se poate trimite reacția la poveste chiar acum.',
  AppTranslations.unableToPublishStory: 'Nu se poate publica povestea acum.',
  AppTranslations.storiesLoadFailed: 'Nu s-au încărcat poveștile',
  AppTranslations.storyFeatureSoon:
      'Urmează vizualizarea poveștii și publicarea.',
  AppTranslations.homeStoriesTitle: 'Activ acum',
  AppTranslations.homeChatsTitle: 'Chat-uri recente',
  AppTranslations.homeTabAll: 'Toate',
  AppTranslations.homeTabUnread: 'Necitit',
  AppTranslations.homeTabGroups: 'Grupuri',
  AppTranslations.homeOnlineNow: 'online acum',
  AppTranslations.homeTypePlaceholder: 'Tastați un mesaj',
  AppTranslations.homeStatusActive: 'Activ acum',
  AppTranslations.homeStatusTyping: 'Tastând...',
  AppTranslations.homeStatusSent: 'Trimis',
  AppTranslations.homeStatusDelivered: 'Livrat',
  AppTranslations.homeStatusVoice: 'Mesaj vocal',
  AppTranslations.homeStatusMuted: 'Notificările sunt dezactivate',
  AppTranslations.homeChatsUnavailableTitle: 'Chaturile live nu sunt încă gata',
  AppTranslations.homeChatsUnavailableBody:
      'Punctul final de chat Messenger încă returnează un răspuns de la schelă de la server.',
  AppTranslations.homeChatsEmptyTitle: 'Mesaje primite este gata',
  AppTranslations.homeChatsEmptyBody:
      'Începeți prima conversație pentru a vedea mesajele, răspunsurile și momentele partajate aici.',
  AppTranslations.homeChatsEmptyAction: 'Începeți un chat',
  AppTranslations.retry: 'Reîncercați',
  AppTranslations.settingsTitle: 'Setări',
  AppTranslations.settingsLanguage: 'Limba',
  AppTranslations.settingsArabic: 'arabă',
  AppTranslations.settingsEnglish: 'engleză',
  AppTranslations.settingsFrench: 'francez',
  AppTranslations.settingsSpanish: 'spaniolă',
  AppTranslations.settingsPortuguese: 'portugheză',
  AppTranslations.settingsGerman: 'germană',
  AppTranslations.settingsTurkish: 'turcesc',
  AppTranslations.settingsDutch: 'olandeză',
  AppTranslations.settingsItalian: 'italiană',
  AppTranslations.settingsRussian: 'rusă',
  AppTranslations.settingsRomanian: 'română',
  AppTranslations.settingsPortugueseBrazil: 'portugheză (Brazilia)',
  AppTranslations.settingsGreek: 'greacă',
  AppTranslations.settingsUkrainian: 'ucrainean',
  AppTranslations.settingsTheme: 'Temă',
  AppTranslations.settingsDarkMode: 'Modul întunecat',
  AppTranslations.settingsLightMode: 'Modul de lumină',
  AppTranslations.settingsLanguageSheetDescription:
      'Alegeți limba aplicației dintr-o listă curată.',
  AppTranslations.settingsHeroDescription:
      'Gestionați limba, aspectul și accesul la cont dintr-un singur loc.',
  AppTranslations.settingsPreferencesEyebrow: 'PREFERINȚE',
  AppTranslations.settingsPreferencesTitle: 'Experiența aplicației',
  AppTranslations.settingsAccountEyebrow: 'CONT',
  AppTranslations.settingsAccountTitle: 'Sesiune și securitate',
  AppTranslations.settingsBlockedUsers: 'Utilizatori blocați',
  AppTranslations.settingsBlockedUsersSubtitle:
      'Revizuiește persoanele blocate și elimină restricțiile când este nevoie.',
  AppTranslations.blockedUsersTitle: 'Utilizatori blocați',
  AppTranslations.blockedUsersEmpty:
      'Nu au fost găsiți utilizatori blocați pentru acest cont în acest moment.',
  AppTranslations.blockedUsersUnblock: 'Deblochează',
  AppTranslations.blockedUsersUnblockTitle: 'Deblochează utilizatorul',
  AppTranslations.blockedUsersUnblockMessage:
      'Vrei să elimini acest utilizator din lista ta de blocați?',
  AppTranslations.blockedUsersUserUnblocked: 'Utilizator deblocat cu succes',
  AppTranslations.settingsDeleteAccount: 'Șterge contul',
  AppTranslations.settingsDeleteAccountSubtitle:
      'Elimină permanent acest cont și șterge accesul la Messenger.',
  AppTranslations.settingsDeleteAccountTitle: 'Șterge contul',
  AppTranslations.settingsDeleteAccountMessage:
      'Această acțiune este permanentă. Sigur vrei să îți ștergi contul?',
  AppTranslations.settingsDeleteAccountConfirm: 'Șterge contul',
  AppTranslations.settingsDeleteAccountSuccess:
      'Contul tău a fost șters cu succes',
  AppTranslations.settingsLogoutSubtitle:
      'Deconectați-vă de la sesiunea curentă pe acest dispozitiv',
  AppTranslations.settingsLogout: 'Deconectați-vă',
  AppTranslations.settingsLogoutTitle: 'Deconectați-vă',
  AppTranslations.settingsLogoutMessage:
      'Sigur doriți să vă deconectați de la Messenger pe acest dispozitiv?',
  AppTranslations.settingsLogoutTimelineBridgeMessage:
      'Veți fi deconectat numai de la Messenger. Sesiunea de cronologie va rămâne conectată pe acest dispozitiv.',
  AppTranslations.settingsLogoutCancel: 'Anulează',
  AppTranslations.settingsLogoutConfirm: 'Deconectați-vă',
  AppTranslations.settingsLegalEyebrow: 'LEGAL',
  AppTranslations.settingsLegalTitle: 'Confidențialitate și termeni',
  AppTranslations.settingsPrivacyPolicy: 'Politica de confidențialitate',
  AppTranslations.settingsPrivacyPolicySubtitle:
      'Vezi cum Ukraina.co-Chat colectează, folosește și protejează datele contului.',
  AppTranslations.settingsTermsOfUse: 'Termeni de utilizare',
  AppTranslations.settingsTermsOfUseSubtitle:
      'Citește regulile, responsabilitățile și termenii de utilizare pentru Ukraina.co-Chat.',
  AppTranslations.navChats: 'Chaturi',
  AppTranslations.navCalls: 'Apeluri',
  AppTranslations.navProfile: 'Profil',
  AppTranslations.navSettings: 'Setări',
  AppTranslations.composeTitle: 'Conversație nouă',
  AppTranslations.composeSearchHint: 'Caută prieteni',
  AppTranslations.composeSelectContact: 'Selectează mai întâi un prieten',
  AppTranslations.composeOpenConversation: 'Deschide conversația',
  AppTranslations.composeContactsUnavailable:
      'Contactele vor apărea aici de îndată ce punctul final este gata.',
  AppTranslations.composeNoContacts:
      'Nu există persoane de contact disponibile momentan.',
  AppTranslations.composeRecipientId: 'ID utilizator al destinatarului',
  AppTranslations.composeRecipientHint: 'Introduceți ID-ul utilizatorului',
  AppTranslations.composeMessage: 'Primul mesaj',
  AppTranslations.composeMessageHint: 'Scrie-ți mesajul',
  AppTranslations.composeSend: 'Trimite',
  AppTranslations.composeRecipientRequired:
      'ID-ul de utilizator al destinatarului este necesar',
  AppTranslations.composeMessageRequired: 'Mesajul este obligatoriu',
  AppTranslations.callsPlaceholder:
      'Fila Apeluri este pregătită pentru următorul pas API.',
  AppTranslations.callsEmptyTitle: 'Nu există apeluri încă',
  AppTranslations.callsEmptyBody:
      'Apelurile dvs. vocale și video recente vor apărea aici.',
  AppTranslations.callsIncoming: 'Sosire',
  AppTranslations.callsOutgoing: 'Ieșire',
  AppTranslations.callsMissed: 'ratat',
  AppTranslations.callsDeclined: 'A refuzat',
  AppTranslations.callsAnswered: 'Răspuns',
  AppTranslations.callsOpenChat: 'Deschide chatul',
  AppTranslations.profilePlaceholder:
      'Fila Profil este rezervată pentru detalii de cont și identitate.',
  AppTranslations.profileCurrentAccount: 'Contul curent',
  AppTranslations.profileConnectedAccounts: 'Conturi conectate',
  AppTranslations.profileAddAccount: 'Adăugați cont',
  AppTranslations.profileSwitchAccount: 'Comutator',
  AppTranslations.profileRemoveAccount: 'Eliminați',
  AppTranslations.profileRevokeAccount: 'Revocați',
  AppTranslations.profileAccountUsername: 'Nume de utilizator',
  AppTranslations.profileAccountEmail: 'E-mail',
  AppTranslations.profileAccountStatus: 'Starea contului',
  AppTranslations.profileAccountCurrent: 'Curent',
  AppTranslations.profileAccountMaster: 'Maestre',
  AppTranslations.profileNoConnectedAccounts:
      'Nu au fost găsite încă conturi conectate.',
  AppTranslations.profileAddAccountTitle: 'Adăugați un cont conectat',
  AppTranslations.profileAddAccountIdentifier: 'E-mail sau nume de utilizator',
  AppTranslations.profileAddAccountIdentifierHint:
      'Introduceți adresa de e-mail a contului conectat sau numele de utilizator',
  AppTranslations.profileAddAccountPassword: 'Parola contului',
  AppTranslations.profileAddAccountConfirm: 'Conectați contul',
  AppTranslations.profileAddAccountSuccess:
      'Contul conectat a fost adăugat cu succes',
  AppTranslations.profileSwitchAccountSuccess:
      'Contul a fost schimbat cu succes',
  AppTranslations.profileRemoveAccountTitle: 'Eliminați contul conectat',
  AppTranslations.profileRemoveAccountMessage:
      'Sigur doriți să eliminați acest cont conectat?',
  AppTranslations.profileRemoveAccountSuccess:
      'Contul conectat a fost eliminat cu succes',
  AppTranslations.profileRevokeAccountTitle: 'Revocați conexiunea la cont',
  AppTranslations.profileRevokeAccountMessage:
      'Sigur doriți să revocați conexiunea principală conectată actuală?',
  AppTranslations.profileRevokeAccountSuccess:
      'Conexiunea la cont a fost revocată cu succes',
  AppTranslations.profileManageSettings: 'Deschideți setările',
  AppTranslations.profileTimelineBridgeActive:
      'Sesiunea bridge cronologie este activă pe acest dispozitiv.',
  AppTranslations.profileLinkedAccountsDisabled:
      'Comutarea contului conectat este dezactivată pentru acest cont.',
  AppTranslations.profileAccountAdded: 'Cont conectat',
  AppTranslations.profileAccountEmptyField:
      'E-mail/nume de utilizator și parola sunt necesare',
  AppTranslations.chatOnlineNow: 'Online acum',
  AppTranslations.chatSeen: 'Văzut',
  AppTranslations.chatInputHint: 'Tastați un mesaj',
  AppTranslations.chatInfoTitle: 'Informații de chat',
  AppTranslations.chatInfoSharedMedia: 'Media partajată',
  AppTranslations.chatInfoSettings: 'Setări de chat',
  AppTranslations.chatInfoAll: 'Toate',
  AppTranslations.chatInfoImages: 'Imagini',
  AppTranslations.chatInfoVideos: 'Videoclipuri',
  AppTranslations.chatInfoAudio: 'Audio',
  AppTranslations.chatInfoFiles: 'Fișiere',
  AppTranslations.chatInfoLinks: 'Legături',
  AppTranslations.chatInfoNoSharedMedia:
      'Nu a fost găsit niciun conținut partajat pentru această conversație.',
  AppTranslations.chatInfoOpen: 'Deschide',
  AppTranslations.chatSettingBackground: 'Fundal pentru chat',
  AppTranslations.chatSettingMute: 'Dezactivați notificările',
  AppTranslations.chatSettingPin: 'Fixați chatul',
  AppTranslations.chatSettingBlock: 'Blocați utilizatorul',
  AppTranslations.chatSettingReport: 'Raportează utilizatorul',
  AppTranslations.chatSettingReportSubtitle:
      'Trimite un raport de siguranță despre acest cont.',
  AppTranslations.chatSettingDelete: 'Șterge conversația',
  AppTranslations.chatSettingApiPending:
      'Această setare așteaptă punctul final API dedicat.',
  AppTranslations.chatReportTitle: 'Raportează utilizatorul',
  AppTranslations.chatReportDescription:
      'Alege motivul acestui raport. Ukraina.co-Chat îl va trimite echipei de moderare pentru verificare.',
  AppTranslations.chatReportCategoryLabel: 'Categoria raportului',
  AppTranslations.chatReportCategoryHint: 'Selectează un motiv',
  AppTranslations.chatReportReasonLabel: 'Detalii suplimentare',
  AppTranslations.chatReportReasonHint:
      'Adaugă mai mult context pentru a ajuta la verificarea raportului.',
  AppTranslations.chatReportSubmit: 'Trimite raportul',
  AppTranslations.chatReportSuccess: 'Raport trimis',
  AppTranslations.chatReportEmptyCategories:
      'Nu sunt disponibile categorii de raportare în acest moment.',
  AppTranslations.chatReportCategoryRequired:
      'Te rugăm să selectezi o categorie de raportare înainte de a continua.',
  AppTranslations.chatReportLoadFailed:
      'Categoriile de raportare nu pot fi încărcate acum.',
  AppTranslations.chatDeleteTitle: 'Șterge conversația',
  AppTranslations.chatDeleteMessage:
      'Sigur vrei să ștergi această conversație?',
  AppTranslations.chatDeleteConfirm: 'Ștergeți',
  AppTranslations.chatDeleted: 'Conversația a fost ștearsă cu succes',
  AppTranslations.chatMessageDelete: 'Ștergeți mesajul',
  AppTranslations.chatMessageEdit: 'Editați mesajul',
  AppTranslations.chatMessageReply: 'Răspunde',
  AppTranslations.chatMessageForward: 'Înainte',
  AppTranslations.chatMessageCopy: 'Copiere',
  AppTranslations.chatStickerTitle: 'Autocolante',
  AppTranslations.chatStickerSubtitle:
      'Alegeți un pachet de autocolante și trimiteți un autocolant instantaneu.',
  AppTranslations.chatStickerEmpty:
      'Nu există autocolante disponibile în acest pachet.',
  AppTranslations.chatMessageDeleteTitle: 'Ștergeți mesajul',
  AppTranslations.chatMessageDeleteMessage:
      'Sigur doriți să ștergeți acest mesaj?',
  AppTranslations.chatMessageDeleted: 'Mesajul a fost șters cu succes',
  AppTranslations.chatMessageEditPending:
      'Editarea mesajelor necesită un punct final API dedicat.',
  AppTranslations.callVoice: 'Apel vocal',
  AppTranslations.callVideo: 'Apel video',
  AppTranslations.callConnecting: 'Se conectează...',
  AppTranslations.callWaiting: 'Așteptând să se alăture cealaltă persoană',
  AppTranslations.callMicOff: 'Microfonul oprit',
  AppTranslations.callMicOn: 'Microfonul pornit',
  AppTranslations.callSpeakerOn: 'Difuzor pornit',
  AppTranslations.callSpeakerOff: 'Difuzor oprit',
  AppTranslations.callCameraFlip: 'Comutați camera',
  AppTranslations.callEnd: 'Încheiați apelul',
  AppTranslations.callPermissionDenied:
      'Permisiunea pentru cameră sau microfon a fost refuzată.',
  AppTranslations.callAgoraDisabled:
      'Apelarea Agora este dezactivată în settings.dart.',
  AppTranslations.callAgoraMissingAppId:
      'Codul aplicației Agora lipsește în settings.dart.',
  AppTranslations.callRemoteJoined: 'Conectat',
  AppTranslations.callRinging: 'Sună...',
  AppTranslations.callNoAnswer: 'Niciun răspuns de la cealaltă persoană.',
  AppTranslations.callDeclined: 'Apelul a fost refuzat.',
  AppTranslations.callIncoming: 'Apel primit',
  AppTranslations.callAccept: 'Acceptați',
  AppTranslations.callDeclineAction: 'Declin',
  AppTranslations.callRecipientBusy: 'Cealaltă persoană este ocupată acum.',
  AppTranslations.callRecipientOffline: 'Cealaltă persoană este offline.',
  AppTranslations.callCallerBusy: 'Aveți deja un apel activ.',
  AppTranslations.callDirectOnly:
      'Apelurile sunt disponibile doar în conversațiile directe chiar acum.',
  AppTranslations.callMissingConnection:
      'Serverul nu a returnat date complete de conectare a apelurilor.',
  AppTranslations.authFlowHeadline:
      'Este necesar un pas suplimentar de autentificare',
  AppTranslations.authFlowDescription:
      'Serverul a acceptat autentificarea dvs., dar următorul pas necesar este: @step',
  AppTranslations.accountBannedTitle: 'Acest cont a fost interzis',
  AppTranslations.accountBannedBody:
      'Contul dvs. Messenger este în prezent restricționat și nu poate utiliza aplicația în acest moment.',
  AppTranslations.accountBannedSupport:
      'Vă rugăm să contactați asistența sau administratorul site-ului dacă credeți că acest lucru s-a întâmplat din greșeală.',
  AppTranslations.accountBannedContactSupport: 'Contactați asistența',
  AppTranslations.authActivationTitle: 'Este necesară activarea',
  AppTranslations.authActivationDescription:
      'Introdu codul de verificare trimis în contul tău pentru a continua.',
  AppTranslations.authApprovalTitle: 'Este necesară aprobarea',
  AppTranslations.authApprovalDescription:
      'Contul dvs. așteaptă aprobarea înainte ca Messenger să poată continua.',
  AppTranslations.authGettingStartedTitle: 'Este necesară începerea',
  AppTranslations.authGettingStartedDescription:
      'Contul dvs. are nevoie de încă un pas de configurare înainte ca Messenger să se poată deschide complet.',
  AppTranslations.authTwoFactorTitle: 'Verificare în doi factori',
  AppTranslations.authTwoFactorDescription:
      'Introdu codul de verificare din metoda configurată cu doi factori.',
  AppTranslations.verificationCode: 'Cod de verificare',
  AppTranslations.verificationCodeHint:
      'Introdu codul exact așa cum l-ai primit',
  AppTranslations.verificationCodeRequired: 'Codul de verificare este necesar',
  AppTranslations.resendCode: 'Retrimiteți codul',
  AppTranslations.verifyAndContinue: 'Verificați și continuați',
  AppTranslations.activationCodeSent: 'A fost trimis un nou cod de activare.',
  AppTranslations.authUnableToLoadState:
      'Nu se poate încărca starea de autentificare în acest moment.',
  AppTranslations.authUnableToVerifyCode: 'Nu se poate verifica codul acum.',
  AppTranslations.authUnableToResendCode: 'Nu se poate retrimite codul acum.',
  AppTranslations.backToLogin: 'Înapoi la autentificare',
  AppTranslations.loginFailed: 'Nu se poate conecta acum',
  AppTranslations.commonConversation: 'Conversație',
  AppTranslations.commonChat: 'Chat',
  AppTranslations.commonConversations: 'Conversații',
  AppTranslations.commonPeople: 'Oameni',
  AppTranslations.commonPost: 'Postează',
  AppTranslations.commonStory: 'Povestea',
  AppTranslations.commonReel: 'Tambur',
  AppTranslations.commonProduct: 'Produs',
  AppTranslations.commonImage: 'Imagine',
  AppTranslations.commonVideo: 'Videoclip',
  AppTranslations.commonSticker: 'Autocolant',
  AppTranslations.commonOn: 'Pornit',
  AppTranslations.commonOff: 'Oprit',
  AppTranslations.commonColors: 'Culori',
  AppTranslations.commonGradients: 'Gradiente',
  AppTranslations.commonReset: 'Resetați',
  AppTranslations.commonTimeline: 'Cronologie',
  AppTranslations.timelineAppNotInstalledTitle:
      'Aplicația Timeline nu este instalată',
  AppTranslations.timelineAppNotInstalledMessage:
      'Pentru a deschide acest conținut, instalați mai întâi aplicația Timeline. Doriți să o descărcați acum?',
  AppTranslations.timelineAppCancelAction: 'Anulează',
  AppTranslations.timelineAppDownloadAction: 'Descarcă',
  AppTranslations.sharedPost: 'Postare distribuită',
  AppTranslations.sharedReel: 'Bobina partajată',
  AppTranslations.sharePostTitle: 'Distribuie postarea',
  AppTranslations.shareReelTitle: 'Distribuie Reel',
  AppTranslations.shareSearchHint: 'Căutați conversații sau persoane',
  AppTranslations.shareEmptyTargets:
      'Nu există conversații sau contacte disponibile',
  AppTranslations.profileQuickSettingsSubtitle:
      'Confidențialitate, notificări și preferințe',
  AppTranslations.profileConnectAnother: 'Conectați alt profil',
  AppTranslations.profileAddAccountDisabled:
      'Adăugarea conturilor este dezactivată',
  AppTranslations.profileIdentityEyebrow: 'IDENTITATE',
  AppTranslations.profileSwitcherEyebrow: 'Comutator',
  AppTranslations.profileAttachAnotherAccount:
      'Atașați un alt cont pentru comutare rapidă',
  AppTranslations.profileNoEmailAttached: 'Niciun e-mail atașat',
  AppTranslations.profileReadyToSwitch: 'Gata de schimbare',
  AppTranslations.chatPin: 'Pin',
  AppTranslations.chatUnpin: 'Anulați fixarea',
  AppTranslations.chatConversationPinned: 'Conversația a fost fixată',
  AppTranslations.chatConversationUnpinned: 'Conversația a fost anulată',
  AppTranslations.chatDirectConversation: 'Chat direct',
  AppTranslations.chatGroupConversation: 'Chat de grup',
  AppTranslations.callsTotal: 'Total',
  AppTranslations.callsAll: 'Toate apelurile',
  AppTranslations.callsHeroSubtitle:
      'Urmăriți apelurile pierdute, la care s-a răspuns și apelurile video într-o singură vizualizare.',
  AppTranslations.homeRecentActivity: 'Activitate recentă',
  AppTranslations.chatSettingsSubtitle:
      'Gestionați notificările, starea pinului și acțiunile de conversație.',
  AppTranslations.chatBackgroundSubtitle:
      'Alegeți un fundal personalizat pentru această conversație.',
  AppTranslations.chatRecordingTitle: 'Înregistrare',
  AppTranslations.chatRecordingBody:
      'Atingeți din nou microfonul pentru a opri și trimite',
  AppTranslations.chatInvalidConversationId: 'ID conversație nevalid',
  AppTranslations.chatImageUnavailable: 'Imaginea nu este disponibilă',
  AppTranslations.chatSharedItemOpenFailed:
      'Nu se poate deschide elementul comun',
  AppTranslations.chatVoiceUnavailable: 'Mesaj vocal indisponibil',
  AppTranslations.chatVideoUnavailable: 'Videoclipul nu este disponibil',
  AppTranslations.chatReplyingTo: 'Răspunzând la',
  AppTranslations.chatReplyToYourself: 'Mesajul dvs',
  AppTranslations.chatReplyOriginalUnavailable: 'Mesaj original indisponibil',
  AppTranslations.chatRepliedToStory: 'A răspuns la o poveste',
  AppTranslations.chatReactedToStory: 'A reacționat la o poveste',
  AppTranslations.chatEditingMessage: 'Editarea mesajului',
  AppTranslations.chatMessageCopied: 'Mesaj copiat',
  AppTranslations.forwardTitle: 'Redirecționați mesajul',
  AppTranslations.forwardSearchHint: 'Căutați conversații sau persoane',
  AppTranslations.forwardEmptyTargets:
      'Nu există conversații sau contacte disponibile',
  AppTranslations.forwardPreviewTitle: 'Mesaj redirecționat',
  AppTranslations.forwardSent: 'Mesaj redirecționat cu succes',
};
