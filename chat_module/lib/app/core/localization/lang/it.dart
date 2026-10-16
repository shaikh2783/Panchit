import '../app_translations.dart';
import 'base.dart';

final Map<String, String> it = <String, String>{
  ...buildBaseTranslations(),
  AppTranslations.appName: 'Messaggero',
  AppTranslations.loginHeadline: 'Bentornati alle vostre conversazioni',
  AppTranslations.loginSubtitle:
      'Accedi per continuare le tue chat, gestire gli account collegati e rimanere vicino alle tue persone.',
  AppTranslations.loginIdentifierLabel: 'E-mail o nome utente',
  AppTranslations.loginIdentifierHint:
      'Inserisci la tua email o il nome utente',
  AppTranslations.passwordLabel: 'Parola d\'ordine',
  AppTranslations.passwordHint: 'Inserisci la tua password',
  AppTranslations.rememberMe: 'Ricordati di me',
  AppTranslations.forgotPassword: 'Password dimenticata?',
  AppTranslations.signIn: 'Accedi',
  AppTranslations.createAccount: 'Crea un account',
  AppTranslations.alreadyHaveAccount: 'Hai già un account?',
  AppTranslations.dontHaveAccount: 'Non hai un account?',
  AppTranslations.registerTitle: 'Registrati',
  AppTranslations.registerSubtitle:
      'Inserisci i dettagli del tuo account per creare un nuovo account Messenger.',
  AppTranslations.signUpHeadline: 'Crea il tuo account Messenger',
  AppTranslations.signUpSubtitle:
      'Partecipa alla conversazione con un nuovo account e continua automaticamente con il successivo passaggio di configurazione richiesto.',
  AppTranslations.signUpToggleTitle: 'Nuovo qui?',
  AppTranslations.signInToggleTitle: 'Hai già un account?',
  AppTranslations.signUpUsernameLabel: 'Nome utente',
  AppTranslations.signUpUsernameHint: 'Scegli un nome utente',
  AppTranslations.signUpEmailLabel: 'Indirizzo e-mail',
  AppTranslations.signUpEmailHint: 'Inserisci il tuo indirizzo email',
  AppTranslations.signUpFirstNameLabel: 'Nome',
  AppTranslations.signUpFirstNameHint: 'Inserisci il tuo nome',
  AppTranslations.signUpLastNameLabel: 'Cognome',
  AppTranslations.signUpLastNameHint: 'Inserisci il tuo cognome',
  AppTranslations.signUpGenderLabel: 'Genere',
  AppTranslations.signUpGenderMale: 'Maschio',
  AppTranslations.signUpGenderFemale: 'Femmina',
  AppTranslations.signUpConfirmPasswordLabel: 'Conferma la password',
  AppTranslations.signUpConfirmPasswordHint: 'Reinserisci la tua password',
  AppTranslations.signUpUsernameRequired: 'Il nome utente è obbligatorio',
  AppTranslations.signUpUsernameTooShort:
      'Il nome utente deve contenere almeno 3 caratteri',
  AppTranslations.signUpEmailRequired: 'L\'indirizzo e-mail è obbligatorio',
  AppTranslations.signUpEmailInvalid: 'Inserisci un indirizzo email valido',
  AppTranslations.signUpPasswordTooShort:
      'La password deve contenere almeno 6 caratteri',
  AppTranslations.signUpConfirmPasswordRequired:
      'È richiesta la conferma della password',
  AppTranslations.signUpPasswordsDoNotMatch: 'Le password non corrispondono',
  AppTranslations.signUpFirstNameRequired: 'Il nome è obbligatorio',
  AppTranslations.signUpLastNameRequired: 'Il cognome è obbligatorio',
  AppTranslations.signUpFailed:
      'Impossibile creare l\'account in questo momento',
  AppTranslations.signUpNote:
      'Dopo la registrazione, Messenger ti guiderà automaticamente attraverso l\'attivazione o qualsiasi passaggio di configurazione richiesto.',
  AppTranslations.signUpAgreementPrefix: 'Sono d\'accordo con',
  AppTranslations.signUpAgreementAnd: 'e',
  AppTranslations.signUpAgreementSuffix: 'prima di creare il mio account.',
  AppTranslations.signUpTermsOfUse: 'Condizioni d\'uso',
  AppTranslations.signUpPrivacyPolicy: 'Informativa sulla privacy',
  AppTranslations.signUpTermsRequiredTitle: 'È necessaria l\'approvazione',
  AppTranslations.signUpTermsRequiredMessage:
      'È necessario prima accettare i Termini di utilizzo e l\'Informativa sulla privacy.',
  AppTranslations.webViewPageTitle: 'Dettagli',
  AppTranslations.secureAccessNote:
      'Accesso protetto con verifica della sessione compatibile con il dispositivo.',
  AppTranslations.loginFooter:
      'Progettato per la messaggistica veloce con un flusso di accesso mirato e sicuro.',
  AppTranslations.loginWithTimeline: 'Continua con l\'account Cronologia',
  AppTranslations.loginWithTimelineSubtitle:
      'Utilizza l\'account a cui hai già effettuato l\'accesso nella Timeline.',
  AppTranslations.identifierRequired: 'E-mail o nome utente sono obbligatori',
  AppTranslations.passwordRequired: 'È richiesta la password',
  AppTranslations.loading: 'Caricamento...',
  AppTranslations.homeHeadline: 'Messaggi',
  AppTranslations.homeSubtitle: 'Stai vicino alle persone a cui tieni.',
  AppTranslations.homeWelcomeBack: 'Bentornato, @nome',
  AppTranslations.homeSearchHint: 'Cerca conversazioni',
  AppTranslations.homeSearchEmptyTitle: 'Nessuna conversazione corrispondente',
  AppTranslations.homeSearchEmptyBody:
      'Prova un altro nome o una parola chiave per trovare una conversazione.',
  AppTranslations.addStory: 'Aggiungi storia',
  AppTranslations.shareStory: 'Condividi la storia',
  AppTranslations.storyAddText: 'Aggiungi testo',
  AppTranslations.storyTextHint: 'Scrivi qualcosa...',
  AppTranslations.storyMediaHint:
      'Aggiungi una foto o un video per condividere la tua storia.',
  AppTranslations.camera: 'Fotocamera',
  AppTranslations.gallery: 'Galleria',
  AppTranslations.done: 'Fatto',
  AppTranslations.replyToStory: 'Rispondi alla storia',
  AppTranslations.storyReplySent: 'Risposta alla storia inviata.',
  AppTranslations.storyReactionSent: 'Reazione alla storia inviata.',
  AppTranslations.storyPublished: 'Storia pubblicata.',
  AppTranslations.storyViews: 'Viste',
  AppTranslations.storyViewers: 'Spettatori di storie',
  AppTranslations.storyReactions: 'Reazioni alla storia',
  AppTranslations.noStoryViewers: 'Ancora nessun visualizzatore.',
  AppTranslations.noStoryReactions: 'Nessuna reazione ancora.',
  AppTranslations.unableToLoadStoryViewers:
      'Impossibile caricare i visualizzatori di storie in questo momento.',
  AppTranslations.unableToLoadStoryReactions:
      'Impossibile caricare le reazioni alla storia in questo momento.',
  AppTranslations.unableToReplyToStory:
      'Impossibile inviare la risposta alla storia in questo momento.',
  AppTranslations.unableToReactToStory:
      'Impossibile inviare la reazione alla storia in questo momento.',
  AppTranslations.unableToPublishStory:
      'Impossibile pubblicare la storia in questo momento.',
  AppTranslations.storiesLoadFailed: 'Impossibile caricare le storie',
  AppTranslations.storyFeatureSoon:
      'Il visualizzatore di storie e la pubblicazione vengono dopo.',
  AppTranslations.homeStoriesTitle: 'Attivo adesso',
  AppTranslations.homeChatsTitle: 'Chat recenti',
  AppTranslations.homeTabAll: 'Tutto',
  AppTranslations.homeTabUnread: 'Non letto',
  AppTranslations.homeTabGroups: 'Gruppi',
  AppTranslations.homeOnlineNow: 'in linea adesso',
  AppTranslations.homeTypePlaceholder: 'Digita un messaggio',
  AppTranslations.homeStatusActive: 'Attivo adesso',
  AppTranslations.homeStatusTyping: 'Digitando...',
  AppTranslations.homeStatusSent: 'Inviato',
  AppTranslations.homeStatusDelivered: 'Consegnato',
  AppTranslations.homeStatusVoice: 'Messaggio vocale',
  AppTranslations.homeStatusMuted: 'Notifiche disattivate',
  AppTranslations.homeChatsUnavailableTitle:
      'Le chat dal vivo non sono ancora pronte',
  AppTranslations.homeChatsUnavailableBody:
      'L\'endpoint della chat di Messenger sta ancora restituendo una risposta allo scaffold dal server.',
  AppTranslations.homeChatsEmptyTitle: 'La tua casella di posta è pronta',
  AppTranslations.homeChatsEmptyBody:
      'Avvia la tua prima conversazione per visualizzare qui messaggi, risposte e momenti condivisi.',
  AppTranslations.homeChatsEmptyAction: 'Avvia una chat',
  AppTranslations.retry: 'Riprova',
  AppTranslations.settingsTitle: 'Impostazioni',
  AppTranslations.settingsLanguage: 'Lingua',
  AppTranslations.settingsArabic: 'Arabo',
  AppTranslations.settingsEnglish: 'Inglese',
  AppTranslations.settingsFrench: 'francese',
  AppTranslations.settingsSpanish: 'spagnolo',
  AppTranslations.settingsPortuguese: 'portoghese',
  AppTranslations.settingsGerman: 'tedesco',
  AppTranslations.settingsTurkish: 'Turco',
  AppTranslations.settingsDutch: 'olandese',
  AppTranslations.settingsItalian: 'italiano',
  AppTranslations.settingsRussian: 'Russo',
  AppTranslations.settingsRomanian: 'rumeno',
  AppTranslations.settingsPortugueseBrazil: 'Portoghese (Brasile)',
  AppTranslations.settingsGreek: 'greco',
  AppTranslations.settingsUkrainian: 'ucraino',
  AppTranslations.settingsTheme: 'Tema',
  AppTranslations.settingsDarkMode: 'Modalità oscura',
  AppTranslations.settingsLightMode: 'Modalità luce',
  AppTranslations.settingsLanguageSheetDescription:
      'Scegli la lingua dell\'app da un elenco pulito.',
  AppTranslations.settingsHeroDescription:
      'Gestisci la lingua, l\'aspetto e l\'accesso all\'account da un unico posto.',
  AppTranslations.settingsPreferencesEyebrow: 'PREFERENZE',
  AppTranslations.settingsPreferencesTitle: 'Esperienza con l\'app',
  AppTranslations.settingsAccountEyebrow: 'CONTO',
  AppTranslations.settingsAccountTitle: 'Sessione e sicurezza',
  AppTranslations.settingsBlockedUsers: 'Utenti bloccati',
  AppTranslations.settingsBlockedUsersSubtitle:
      'Controlla le persone bloccate e rimuovi le restrizioni quando necessario.',
  AppTranslations.blockedUsersTitle: 'Utenti bloccati',
  AppTranslations.blockedUsersEmpty:
      'Nessun utente bloccato trovato per questo account al momento.',
  AppTranslations.blockedUsersUnblock: 'Sblocca',
  AppTranslations.blockedUsersUnblockTitle: 'Sblocca utente',
  AppTranslations.blockedUsersUnblockMessage:
      'Vuoi rimuovere questo utente dalla tua lista dei bloccati?',
  AppTranslations.blockedUsersUserUnblocked: 'Utente sbloccato con successo',
  AppTranslations.settingsDeleteAccount: 'Elimina account',
  AppTranslations.settingsDeleteAccountSubtitle:
      'Rimuovi definitivamente questo account e cancella l’accesso a Messenger.',
  AppTranslations.settingsDeleteAccountTitle: 'Elimina account',
  AppTranslations.settingsDeleteAccountMessage:
      'Questa azione è permanente. Sei sicuro di voler eliminare il tuo account?',
  AppTranslations.settingsDeleteAccountConfirm: 'Elimina account',
  AppTranslations.settingsDeleteAccountSuccess:
      'Il tuo account è stato eliminato con successo',
  AppTranslations.settingsLogoutSubtitle:
      'Esci dalla sessione corrente su questo dispositivo',
  AppTranslations.settingsLogout: 'Esci',
  AppTranslations.settingsLogoutTitle: 'Esci',
  AppTranslations.settingsLogoutMessage:
      'Sei sicuro di voler uscire da Messenger su questo dispositivo?',
  AppTranslations.settingsLogoutTimelineBridgeMessage:
      'Verrai disconnesso solo da Messenger. L\'accesso alla tua sessione della Timeline rimarrà su questo dispositivo.',
  AppTranslations.settingsLogoutCancel: 'Annulla',
  AppTranslations.settingsLogoutConfirm: 'Esci',
  AppTranslations.settingsLegalEyebrow: 'LEGALE',
  AppTranslations.settingsLegalTitle: 'Privacy e termini',
  AppTranslations.settingsPrivacyPolicy: 'Informativa sulla privacy',
  AppTranslations.settingsPrivacyPolicySubtitle:
      'Scopri come Ukraina.co-Chat raccoglie, usa e protegge i dati dell’account.',
  AppTranslations.settingsTermsOfUse: 'Condizioni d\'uso',
  AppTranslations.settingsTermsOfUseSubtitle:
      'Leggi le regole, le responsabilità e i termini di utilizzo di Ukraina.co-Chat.',
  AppTranslations.navChats: 'Chat',
  AppTranslations.navCalls: 'Chiamate',
  AppTranslations.navProfile: 'Profilo',
  AppTranslations.navSettings: 'Impostazioni',
  AppTranslations.composeTitle: 'Nuova conversazione',
  AppTranslations.composeSearchHint: 'Cerca amici',
  AppTranslations.composeSelectContact: 'Seleziona prima un amico',
  AppTranslations.composeOpenConversation: 'Conversazione aperta',
  AppTranslations.composeContactsUnavailable:
      'I contatti verranno visualizzati qui non appena l\'endpoint sarà pronto.',
  AppTranslations.composeNoContacts: 'Nessun contatto disponibile al momento.',
  AppTranslations.composeRecipientId: 'ID utente destinatario',
  AppTranslations.composeRecipientHint: 'Immettere l\'ID utente',
  AppTranslations.composeMessage: 'Primo messaggio',
  AppTranslations.composeMessageHint: 'Scrivi il tuo messaggio',
  AppTranslations.composeSend: 'Invia',
  AppTranslations.composeRecipientRequired:
      'L\'ID utente del destinatario è obbligatorio',
  AppTranslations.composeMessageRequired: 'Il messaggio è obbligatorio',
  AppTranslations.callsPlaceholder:
      'La scheda Chiamate è pronta per il passaggio successivo dell\'API.',
  AppTranslations.callsEmptyTitle: 'Nessuna chiamata ancora',
  AppTranslations.callsEmptyBody:
      'Le tue recenti chiamate vocali e video verranno visualizzate qui.',
  AppTranslations.callsIncoming: 'In arrivo',
  AppTranslations.callsOutgoing: 'In uscita',
  AppTranslations.callsMissed: 'Mancato',
  AppTranslations.callsDeclined: 'Rifiutato',
  AppTranslations.callsAnswered: 'Risposto',
  AppTranslations.callsOpenChat: 'Apri la chat',
  AppTranslations.profilePlaceholder:
      'La scheda Profilo è riservata ai dettagli dell\'account e dell\'identità.',
  AppTranslations.profileCurrentAccount: 'Conto corrente',
  AppTranslations.profileConnectedAccounts: 'Conti collegati',
  AppTranslations.profileAddAccount: 'Aggiungi account',
  AppTranslations.profileSwitchAccount: 'Cambia',
  AppTranslations.profileRemoveAccount: 'Rimuovi',
  AppTranslations.profileRevokeAccount: 'Revoca',
  AppTranslations.profileAccountUsername: 'Nome utente',
  AppTranslations.profileAccountEmail: 'E-mail',
  AppTranslations.profileAccountStatus: 'Stato dell\'account',
  AppTranslations.profileAccountCurrent: 'Corrente',
  AppTranslations.profileAccountMaster: 'Maestro',
  AppTranslations.profileNoConnectedAccounts:
      'Nessun account collegato è stato ancora trovato.',
  AppTranslations.profileAddAccountTitle: 'Aggiungi account connesso',
  AppTranslations.profileAddAccountIdentifier: 'E-mail o nome utente',
  AppTranslations.profileAddAccountIdentifierHint:
      'Inserisci l\'e-mail o il nome utente dell\'account collegato',
  AppTranslations.profileAddAccountPassword: 'Password dell\'account',
  AppTranslations.profileAddAccountConfirm: 'Connetti conto',
  AppTranslations.profileAddAccountSuccess:
      'Account connesso aggiunto correttamente',
  AppTranslations.profileSwitchAccountSuccess: 'Account cambiato con successo',
  AppTranslations.profileRemoveAccountTitle: 'Rimuovi l\'account collegato',
  AppTranslations.profileRemoveAccountMessage:
      'Sei sicuro di voler rimuovere questo account connesso?',
  AppTranslations.profileRemoveAccountSuccess:
      'Account connesso rimosso correttamente',
  AppTranslations.profileRevokeAccountTitle: 'Revoca connessione account',
  AppTranslations.profileRevokeAccountMessage:
      'Sei sicuro di voler revocare la connessione principale collegata corrente?',
  AppTranslations.profileRevokeAccountSuccess:
      'Connessione all\'account revocata con successo',
  AppTranslations.profileManageSettings: 'Apri le impostazioni',
  AppTranslations.profileTimelineBridgeActive:
      'La sessione Bridge della sequenza temporale è attiva su questo dispositivo.',
  AppTranslations.profileLinkedAccountsDisabled:
      'Il cambio dell\'account connesso è disabilitato per questo account.',
  AppTranslations.profileAccountAdded: 'Conto collegato',
  AppTranslations.profileAccountEmptyField:
      'Sono richiesti email/nome utente e password',
  AppTranslations.chatOnlineNow: 'In linea adesso',
  AppTranslations.chatSeen: 'Visto',
  AppTranslations.chatInputHint: 'Digita un messaggio',
  AppTranslations.chatInfoTitle: 'Informazioni sulla chat',
  AppTranslations.chatInfoSharedMedia: 'Supporti condivisi',
  AppTranslations.chatInfoSettings: 'Impostazioni della chat',
  AppTranslations.chatInfoAll: 'Tutto',
  AppTranslations.chatInfoImages: 'Immagini',
  AppTranslations.chatInfoVideos: 'Video',
  AppTranslations.chatInfoAudio: 'Audio',
  AppTranslations.chatInfoFiles: 'File',
  AppTranslations.chatInfoLinks: 'Collegamenti',
  AppTranslations.chatInfoNoSharedMedia:
      'Nessun contenuto condiviso trovato per questa conversazione.',
  AppTranslations.chatInfoOpen: 'Aperto',
  AppTranslations.chatSettingBackground: 'Sfondo della chat',
  AppTranslations.chatSettingMute: 'Notifiche disattivate',
  AppTranslations.chatSettingPin: 'Blocca chat',
  AppTranslations.chatSettingBlock: 'Blocca utente',
  AppTranslations.chatSettingReport: 'Segnala utente',
  AppTranslations.chatSettingReportSubtitle:
      'Invia una segnalazione di sicurezza su questo account.',
  AppTranslations.chatSettingDelete: 'Elimina conversazione',
  AppTranslations.chatSettingApiPending:
      'Questa impostazione è in attesa dell\'endpoint API dedicato.',
  AppTranslations.chatReportTitle: 'Segnala utente',
  AppTranslations.chatReportDescription:
      'Scegli il motivo della segnalazione. Ukraina.co-Chat la invierà al team di moderazione per la revisione.',
  AppTranslations.chatReportCategoryLabel: 'Categoria della segnalazione',
  AppTranslations.chatReportCategoryHint: 'Seleziona un motivo',
  AppTranslations.chatReportReasonLabel: 'Dettagli aggiuntivi',
  AppTranslations.chatReportReasonHint:
      'Aggiungi più contesto per aiutare la revisione di questa segnalazione.',
  AppTranslations.chatReportSubmit: 'Invia segnalazione',
  AppTranslations.chatReportSuccess: 'Segnalazione inviata',
  AppTranslations.chatReportEmptyCategories:
      'Nessuna categoria di segnalazione disponibile al momento.',
  AppTranslations.chatReportCategoryRequired:
      'Seleziona una categoria di segnalazione prima di continuare.',
  AppTranslations.chatReportLoadFailed:
      'Impossibile caricare le categorie di segnalazione in questo momento.',
  AppTranslations.chatDeleteTitle: 'Elimina conversazione',
  AppTranslations.chatDeleteMessage:
      'Sei sicuro di voler eliminare questa conversazione?',
  AppTranslations.chatDeleteConfirm: 'Elimina',
  AppTranslations.chatDeleted: 'Conversazione eliminata correttamente',
  AppTranslations.chatMessageDelete: 'Elimina messaggio',
  AppTranslations.chatMessageEdit: 'Modifica messaggio',
  AppTranslations.chatMessageReply: 'Rispondi',
  AppTranslations.chatMessageForward: 'Avanti',
  AppTranslations.chatMessageCopy: 'Copia',
  AppTranslations.chatStickerTitle: 'Adesivi',
  AppTranslations.chatStickerSubtitle:
      'Scegli un pacchetto di adesivi e invia subito un adesivo.',
  AppTranslations.chatStickerEmpty:
      'Nessun adesivo disponibile in questo pacchetto.',
  AppTranslations.chatMessageDeleteTitle: 'Elimina messaggio',
  AppTranslations.chatMessageDeleteMessage:
      'Sei sicuro di voler eliminare questo messaggio?',
  AppTranslations.chatMessageDeleted: 'Messaggio eliminato con successo',
  AppTranslations.chatMessageEditPending:
      'La modifica dei messaggi richiede un endpoint API dedicato.',
  AppTranslations.callVoice: 'Chiamata vocale',
  AppTranslations.callVideo: 'Videochiamata',
  AppTranslations.callConnecting: 'Connessione...',
  AppTranslations.callWaiting: 'In attesa che l\'altra persona si unisca',
  AppTranslations.callMicOff: 'Microfono spento',
  AppTranslations.callMicOn: 'Microfono acceso',
  AppTranslations.callSpeakerOn: 'Altoparlante acceso',
  AppTranslations.callSpeakerOff: 'Altoparlante spento',
  AppTranslations.callCameraFlip: 'Cambia fotocamera',
  AppTranslations.callEnd: 'Termina chiamata',
  AppTranslations.callPermissionDenied:
      'L\'autorizzazione alla fotocamera o al microfono è stata negata.',
  AppTranslations.callAgoraDisabled:
      'Le chiamate Agora sono disabilitate in settings.dart.',
  AppTranslations.callAgoraMissingAppId:
      'L\'ID dell\'app Agora manca in settings.dart.',
  AppTranslations.callRemoteJoined: 'Connesso',
  AppTranslations.callRinging: 'Squillo...',
  AppTranslations.callNoAnswer: 'Nessuna risposta dall\'altra persona.',
  AppTranslations.callDeclined: 'La chiamata è stata rifiutata.',
  AppTranslations.callIncoming: 'Chiamata in arrivo',
  AppTranslations.callAccept: 'Accetta',
  AppTranslations.callDeclineAction: 'Rifiutare',
  AppTranslations.callRecipientBusy:
      'L\'altra persona è occupata in questo momento.',
  AppTranslations.callRecipientOffline: 'L\'altra persona è offline.',
  AppTranslations.callCallerBusy: 'Hai già una chiamata attiva.',
  AppTranslations.callDirectOnly:
      'Al momento le chiamate sono disponibili solo nelle conversazioni dirette.',
  AppTranslations.callMissingConnection:
      'Il server non ha restituito i dati completi della connessione della chiamata.',
  AppTranslations.authFlowHeadline:
      'È necessario un ulteriore passaggio di autenticazione',
  AppTranslations.authFlowDescription:
      'Il server ha accettato il tuo login, ma il passaggio successivo richiesto è: @step',
  AppTranslations.accountBannedTitle: 'Questo account è stato bannato',
  AppTranslations.accountBannedBody:
      'Il tuo account Messenger è attualmente limitato e non puoi utilizzare l\'app in questo momento.',
  AppTranslations.accountBannedSupport:
      'Contatta l\'assistenza o l\'amministratore del sito se ritieni che ciò sia avvenuto per errore.',
  AppTranslations.accountBannedContactSupport: 'Contatta l\'assistenza',
  AppTranslations.authActivationTitle: 'È richiesta l\'attivazione',
  AppTranslations.authActivationDescription:
      'Inserisci il codice di verifica inviato al tuo account per continuare.',
  AppTranslations.authApprovalTitle: 'È necessaria l\'approvazione',
  AppTranslations.authApprovalDescription:
      'Il tuo account è in attesa di approvazione prima che Messenger possa continuare.',
  AppTranslations.authGettingStartedTitle: 'È necessario iniziare',
  AppTranslations.authGettingStartedDescription:
      'Il tuo account necessita di un ulteriore passaggio di configurazione prima che Messenger possa aprirsi completamente.',
  AppTranslations.authTwoFactorTitle: 'Verifica a due fattori',
  AppTranslations.authTwoFactorDescription:
      'Inserisci il codice di verifica dal metodo a due fattori configurato.',
  AppTranslations.verificationCode: 'Codice di verifica',
  AppTranslations.verificationCodeHint:
      'Inserisci il codice esattamente come ricevuto',
  AppTranslations.verificationCodeRequired: 'È richiesto il codice di verifica',
  AppTranslations.resendCode: 'Invia nuovamente il codice',
  AppTranslations.verifyAndContinue: 'Verifica e continua',
  AppTranslations.activationCodeSent:
      'È stato inviato un nuovo codice di attivazione.',
  AppTranslations.authUnableToLoadState:
      'Impossibile caricare il tuo stato di autenticazione in questo momento.',
  AppTranslations.authUnableToVerifyCode:
      'Impossibile verificare il codice in questo momento.',
  AppTranslations.authUnableToResendCode:
      'Impossibile inviare nuovamente il codice in questo momento.',
  AppTranslations.backToLogin: 'Torna al login',
  AppTranslations.loginFailed: 'Impossibile accedere in questo momento',
  AppTranslations.commonConversation: 'Conversazione',
  AppTranslations.commonChat: 'Chatta',
  AppTranslations.commonConversations: 'Conversazioni',
  AppTranslations.commonPeople: 'Persone',
  AppTranslations.commonPost: 'Posta',
  AppTranslations.commonStory: 'Storia',
  AppTranslations.commonReel: 'Bobina',
  AppTranslations.commonProduct: 'Prodotto',
  AppTranslations.commonImage: 'Immagine',
  AppTranslations.commonVideo: 'Video',
  AppTranslations.commonSticker: 'Adesivo',
  AppTranslations.commonOn: 'Su',
  AppTranslations.commonOff: 'Spento',
  AppTranslations.commonColors: 'Colori',
  AppTranslations.commonGradients: 'Gradienti',
  AppTranslations.commonReset: 'Ripristina',
  AppTranslations.commonTimeline: 'Cronologia',
  AppTranslations.timelineAppNotInstalledTitle:
      'L\'app Timeline non è installata',
  AppTranslations.timelineAppNotInstalledMessage:
      'Per aprire questo contenuto, installa prima l\'app Timeline. Vuoi scaricarla ora?',
  AppTranslations.timelineAppCancelAction: 'Annulla',
  AppTranslations.timelineAppDownloadAction: 'Scarica',
  AppTranslations.sharedPost: 'Posta condivisa',
  AppTranslations.sharedReel: 'Bobina condivisa',
  AppTranslations.sharePostTitle: 'Condividi il messaggio',
  AppTranslations.shareReelTitle: 'Condividi bobina',
  AppTranslations.shareSearchHint: 'Cerca conversazioni o persone',
  AppTranslations.shareEmptyTargets:
      'Nessuna conversazione o contatto disponibile',
  AppTranslations.profileQuickSettingsSubtitle:
      'Privacy, notifiche e preferenze',
  AppTranslations.profileConnectAnother: 'Connetti un altro profilo',
  AppTranslations.profileAddAccountDisabled:
      'L\'aggiunta di account è disabilitata',
  AppTranslations.profileIdentityEyebrow: 'IDENTITÀ',
  AppTranslations.profileSwitcherEyebrow: 'CAMBIATORE',
  AppTranslations.profileAttachAnotherAccount:
      'Collega un altro account per un passaggio rapido',
  AppTranslations.profileNoEmailAttached: 'Nessuna e-mail allegata',
  AppTranslations.profileReadyToSwitch: 'Pronto per cambiare',
  AppTranslations.chatPin: 'Perno',
  AppTranslations.chatUnpin: 'Sblocca',
  AppTranslations.chatConversationPinned: 'Conversazione bloccata',
  AppTranslations.chatConversationUnpinned: 'Conversazione sbloccata',
  AppTranslations.chatDirectConversation: 'Chiacchierata diretta',
  AppTranslations.chatGroupConversation: 'Chat di gruppo',
  AppTranslations.callsTotal: 'Totale',
  AppTranslations.callsAll: 'Tutte le chiamate',
  AppTranslations.callsHeroSubtitle:
      'Tieni traccia delle chiamate perse, delle risposte e delle videochiamate in un\'unica visualizzazione ottimizzata.',
  AppTranslations.homeRecentActivity: 'Attività recente',
  AppTranslations.chatSettingsSubtitle:
      'Gestisci notifiche, stato del pin e azioni di conversazione.',
  AppTranslations.chatBackgroundSubtitle:
      'Scegli uno sfondo personalizzato per questa conversazione.',
  AppTranslations.chatRecordingTitle: 'Registrazione',
  AppTranslations.chatRecordingBody:
      'Tocca nuovamente il microfono per interrompere e inviare',
  AppTranslations.chatInvalidConversationId: 'ID conversazione non valido',
  AppTranslations.chatImageUnavailable: 'Immagine non disponibile',
  AppTranslations.chatSharedItemOpenFailed:
      'Impossibile aprire l\'elemento condiviso',
  AppTranslations.chatVoiceUnavailable: 'Messaggio vocale non disponibile',
  AppTranslations.chatVideoUnavailable: 'Video non disponibile',
  AppTranslations.chatReplyingTo: 'Rispondere a',
  AppTranslations.chatReplyToYourself: 'Il tuo messaggio',
  AppTranslations.chatReplyOriginalUnavailable:
      'Messaggio originale non disponibile',
  AppTranslations.chatRepliedToStory: 'Risposto a una storia',
  AppTranslations.chatReactedToStory: 'Reagito a una storia',
  AppTranslations.chatEditingMessage: 'Modifica del messaggio',
  AppTranslations.chatMessageCopied: 'Messaggio copiato',
  AppTranslations.forwardTitle: 'Inoltrare il messaggio',
  AppTranslations.forwardSearchHint: 'Cerca conversazioni o persone',
  AppTranslations.forwardEmptyTargets:
      'Nessuna conversazione o contatto disponibile',
  AppTranslations.forwardPreviewTitle: 'Messaggio inoltrato',
  AppTranslations.forwardSent: 'Messaggio inoltrato con successo',
};
