import '../app_translations.dart';
import 'base.dart';

final Map<String, String> nl = <String, String>{
  ...buildBaseTranslations(),
  AppTranslations.appName: 'Boodschapper',
  AppTranslations.loginHeadline: 'Welkom terug bij je gesprekken',
  AppTranslations.loginSubtitle:
      'Meld u aan om uw chats voort te zetten, gekoppelde accounts te beheren en dicht bij uw mensen te blijven.',
  AppTranslations.loginIdentifierLabel: 'E-mailadres of gebruikersnaam',
  AppTranslations.loginIdentifierHint:
      'Voer uw e-mailadres of gebruikersnaam in',
  AppTranslations.passwordLabel: 'Wachtwoord',
  AppTranslations.passwordHint: 'Voer uw wachtwoord in',
  AppTranslations.rememberMe: 'Onthoud mij',
  AppTranslations.forgotPassword: 'Wachtwoord vergeten?',
  AppTranslations.signIn: 'Log in',
  AppTranslations.createAccount: 'Account aanmaken',
  AppTranslations.alreadyHaveAccount: 'Heeft u al een account?',
  AppTranslations.dontHaveAccount: 'Heeft u geen account?',
  AppTranslations.registerTitle: 'Register',
  AppTranslations.registerSubtitle:
      'Vul uw accountgegevens in om een ​​nieuw Messenger-account aan te maken.',
  AppTranslations.signUpHeadline: 'Maak uw Messenger-account aan',
  AppTranslations.signUpSubtitle:
      'Neem deel aan het gesprek met een nieuw account en ga automatisch door naar de volgende vereiste installatiestap.',
  AppTranslations.signUpToggleTitle: 'Nieuw hier?',
  AppTranslations.signInToggleTitle: 'Heeft u al een account?',
  AppTranslations.signUpUsernameLabel: 'Gebruikersnaam',
  AppTranslations.signUpUsernameHint: 'Kies een gebruikersnaam',
  AppTranslations.signUpEmailLabel: 'E-mailadres',
  AppTranslations.signUpEmailHint: 'Voer uw e-mailadres in',
  AppTranslations.signUpFirstNameLabel: 'Voornaam',
  AppTranslations.signUpFirstNameHint: 'Voer uw voornaam in',
  AppTranslations.signUpLastNameLabel: 'Achternaam',
  AppTranslations.signUpLastNameHint: 'Voer uw achternaam in',
  AppTranslations.signUpGenderLabel: 'Geslacht',
  AppTranslations.signUpGenderMale: 'Mannelijk',
  AppTranslations.signUpGenderFemale: 'Vrouwelijk',
  AppTranslations.signUpConfirmPasswordLabel: 'Bevestig wachtwoord',
  AppTranslations.signUpConfirmPasswordHint: 'Voer uw wachtwoord opnieuw in',
  AppTranslations.signUpUsernameRequired: 'Gebruikersnaam is vereist',
  AppTranslations.signUpUsernameTooShort:
      'De gebruikersnaam moet minimaal 3 tekens lang zijn',
  AppTranslations.signUpEmailRequired: 'E-mailadres is vereist',
  AppTranslations.signUpEmailInvalid: 'Voer een geldig e-mailadres in',
  AppTranslations.signUpPasswordTooShort:
      'Wachtwoord moet minimaal 6 tekens lang zijn',
  AppTranslations.signUpConfirmPasswordRequired:
      'Bevestig dat het wachtwoord vereist is',
  AppTranslations.signUpPasswordsDoNotMatch: 'Wachtwoorden komen niet overeen',
  AppTranslations.signUpFirstNameRequired: 'Voornaam is vereist',
  AppTranslations.signUpLastNameRequired: 'Achternaam is vereist',
  AppTranslations.signUpFailed: 'Kan het account momenteel niet aanmaken',
  AppTranslations.signUpNote:
      'Nadat u zich heeft aangemeld, begeleidt Messenger u automatisch door de activering of elke vereiste installatiestap.',
  AppTranslations.signUpAgreementPrefix: 'Ik ga akkoord met de',
  AppTranslations.signUpAgreementAnd: 'En',
  AppTranslations.signUpAgreementSuffix: 'voordat ik mijn account aanmaakte.',
  AppTranslations.signUpTermsOfUse: 'Gebruiksvoorwaarden',
  AppTranslations.signUpPrivacyPolicy: 'Privacybeleid',
  AppTranslations.signUpTermsRequiredTitle: 'Goedkeuring vereist',
  AppTranslations.signUpTermsRequiredMessage:
      'U moet eerst akkoord gaan met de gebruiksvoorwaarden en het privacybeleid.',
  AppTranslations.webViewPageTitle: 'Details',
  AppTranslations.secureAccessNote:
      'Beveiligd inloggen met apparaatbewuste sessieverificatie.',
  AppTranslations.loginFooter:
      'Gebouwd voor snelle berichtenuitwisseling met een gerichte en veilige inlogstroom.',
  AppTranslations.loginWithTimeline: 'Ga verder met Tijdlijnaccount',
  AppTranslations.loginWithTimelineSubtitle:
      'Gebruik het account dat al is aangemeld in Timeline.',
  AppTranslations.identifierRequired:
      'E-mailadres of gebruikersnaam is vereist',
  AppTranslations.passwordRequired: 'Wachtwoord is vereist',
  AppTranslations.loading: 'Laden...',
  AppTranslations.homeHeadline: 'Berichten',
  AppTranslations.homeSubtitle: 'Blijf dicht bij de mensen om wie je geeft.',
  AppTranslations.homeWelcomeBack: 'Welkom terug, @naam',
  AppTranslations.homeSearchHint: 'Zoek gesprekken',
  AppTranslations.homeSearchEmptyTitle: 'Geen overeenkomende gesprekken',
  AppTranslations.homeSearchEmptyBody:
      'Probeer een andere naam of trefwoord om een ​​gesprek te vinden.',
  AppTranslations.addStory: 'Verhaal toevoegen',
  AppTranslations.shareStory: 'Deel verhaal',
  AppTranslations.storyAddText: 'Voeg tekst toe',
  AppTranslations.storyTextHint: 'Schrijf iets...',
  AppTranslations.storyMediaHint:
      'Voeg een foto of video toe om uw verhaal te delen.',
  AppTranslations.camera: 'Camera',
  AppTranslations.gallery: 'Galerij',
  AppTranslations.done: 'Klaar',
  AppTranslations.replyToStory: 'Reageer op verhaal',
  AppTranslations.storyReplySent: 'Verhaalantwoord verzonden.',
  AppTranslations.storyReactionSent: 'Verhaalreactie verzonden.',
  AppTranslations.storyPublished: 'Verhaal gepubliceerd.',
  AppTranslations.storyViews: 'Bekeken',
  AppTranslations.storyViewers: 'Verhaalkijkers',
  AppTranslations.storyReactions: 'Verhaalreacties',
  AppTranslations.noStoryViewers: 'Nog geen kijkers.',
  AppTranslations.noStoryReactions: 'Nog geen reacties.',
  AppTranslations.unableToLoadStoryViewers:
      'Kan verhaalviewers momenteel niet laden.',
  AppTranslations.unableToLoadStoryReactions:
      'Kan verhaalreacties momenteel niet laden.',
  AppTranslations.unableToReplyToStory:
      'Kan het verhaalantwoord nu niet verzenden.',
  AppTranslations.unableToReactToStory:
      'Kan de verhaalreactie momenteel niet verzenden.',
  AppTranslations.unableToPublishStory:
      'Kan het verhaal momenteel niet publiceren.',
  AppTranslations.storiesLoadFailed: 'Kan verhalen niet laden',
  AppTranslations.storyFeatureSoon: 'Verhaalviewer en publicatie komen daarna.',
  AppTranslations.homeStoriesTitle: 'Nu actief',
  AppTranslations.homeChatsTitle: 'Recente chats',
  AppTranslations.homeTabAll: 'Alle',
  AppTranslations.homeTabUnread: 'Ongelezen',
  AppTranslations.homeTabGroups: 'Groepen',
  AppTranslations.homeOnlineNow: 'nu online',
  AppTranslations.homeTypePlaceholder: 'Typ een bericht',
  AppTranslations.homeStatusActive: 'Nu actief',
  AppTranslations.homeStatusTyping: 'Typen...',
  AppTranslations.homeStatusSent: 'Verstuurd',
  AppTranslations.homeStatusDelivered: 'Afgeleverd',
  AppTranslations.homeStatusVoice: 'Spraakbericht',
  AppTranslations.homeStatusMuted: 'Meldingen gedempt',
  AppTranslations.homeChatsUnavailableTitle: 'Livechats zijn nog niet klaar',
  AppTranslations.homeChatsUnavailableBody:
      'Het Messenger-chat-eindpunt retourneert nog steeds een steigerantwoord van de server.',
  AppTranslations.homeChatsEmptyTitle: 'Je inbox is klaar',
  AppTranslations.homeChatsEmptyBody:
      'Begin uw eerste gesprek en zie hier berichten, antwoorden en gedeelde momenten verschijnen.',
  AppTranslations.homeChatsEmptyAction: 'Start een chat',
  AppTranslations.retry: 'Opnieuw proberen',
  AppTranslations.settingsTitle: 'Instellingen',
  AppTranslations.settingsLanguage: 'Taal',
  AppTranslations.settingsArabic: 'Arabisch',
  AppTranslations.settingsEnglish: 'Engels',
  AppTranslations.settingsFrench: 'Frans',
  AppTranslations.settingsSpanish: 'Spaans',
  AppTranslations.settingsPortuguese: 'Portugees',
  AppTranslations.settingsGerman: 'Duits',
  AppTranslations.settingsTurkish: 'Turks',
  AppTranslations.settingsDutch: 'Nederlands',
  AppTranslations.settingsItalian: 'Italiaans',
  AppTranslations.settingsRussian: 'Russisch',
  AppTranslations.settingsRomanian: 'Roemeense',
  AppTranslations.settingsPortugueseBrazil: 'Portugees (Brazilië)',
  AppTranslations.settingsGreek: 'Grieks',
  AppTranslations.settingsUkrainian: 'Oekraïens',
  AppTranslations.settingsTheme: 'Thema',
  AppTranslations.settingsDarkMode: 'Donkere modus',
  AppTranslations.settingsLightMode: 'Lichte modus',
  AppTranslations.settingsLanguageSheetDescription:
      'Kies de app-taal uit een schone lijst.',
  AppTranslations.settingsHeroDescription:
      'Beheer taal, uiterlijk en accounttoegang vanaf één plek.',
  AppTranslations.settingsPreferencesEyebrow: 'VOORKEUREN',
  AppTranslations.settingsPreferencesTitle: 'App-ervaring',
  AppTranslations.settingsAccountEyebrow: 'REKENING',
  AppTranslations.settingsAccountTitle: 'Sessie en beveiliging',
  AppTranslations.settingsBlockedUsers: 'Geblokkeerde gebruikers',
  AppTranslations.settingsBlockedUsersSubtitle:
      'Bekijk geblokkeerde personen en verwijder beperkingen wanneer nodig.',
  AppTranslations.blockedUsersTitle: 'Geblokkeerde gebruikers',
  AppTranslations.blockedUsersEmpty:
      'Er zijn momenteel geen geblokkeerde gebruikers gevonden voor dit account.',
  AppTranslations.blockedUsersUnblock: 'Deblokkeren',
  AppTranslations.blockedUsersUnblockTitle: 'Gebruiker deblokkeren',
  AppTranslations.blockedUsersUnblockMessage:
      'Wil je deze gebruiker uit je blokkeerlijst verwijderen?',
  AppTranslations.blockedUsersUserUnblocked:
      'Gebruiker succesvol gedeblokkeerd',
  AppTranslations.settingsDeleteAccount: 'Account verwijderen',
  AppTranslations.settingsDeleteAccountSubtitle:
      'Verwijder dit account permanent en wis de toegang tot Messenger.',
  AppTranslations.settingsDeleteAccountTitle: 'Account verwijderen',
  AppTranslations.settingsDeleteAccountMessage:
      'Deze actie is permanent. Weet je zeker dat je je account wilt verwijderen?',
  AppTranslations.settingsDeleteAccountConfirm: 'Account verwijderen',
  AppTranslations.settingsDeleteAccountSuccess:
      'Je account is succesvol verwijderd',
  AppTranslations.settingsLogoutSubtitle:
      'Meld u af bij de huidige sessie op dit apparaat',
  AppTranslations.settingsLogout: 'Uitloggen',
  AppTranslations.settingsLogoutTitle: 'Uitloggen',
  AppTranslations.settingsLogoutMessage:
      'Weet je zeker dat je wilt uitloggen bij Messenger op dit apparaat?',
  AppTranslations.settingsLogoutTimelineBridgeMessage:
      'Je wordt alleen uitgelogd bij Messenger. Bij uw tijdlijnsessie blijft u ingelogd op dit apparaat.',
  AppTranslations.settingsLogoutCancel: 'Annuleren',
  AppTranslations.settingsLogoutConfirm: 'Uitloggen',
  AppTranslations.settingsLegalEyebrow: 'JURIDISCH',
  AppTranslations.settingsLegalTitle: 'Privacy en voorwaarden',
  AppTranslations.settingsPrivacyPolicy: 'Privacybeleid',
  AppTranslations.settingsPrivacyPolicySubtitle:
      'Bekijk hoe Ukraina.co-Chat accountgegevens verzamelt, gebruikt en beschermt.',
  AppTranslations.settingsTermsOfUse: 'Gebruiksvoorwaarden',
  AppTranslations.settingsTermsOfUseSubtitle:
      'Lees de regels, verantwoordelijkheden en gebruiksvoorwaarden van Ukraina.co-Chat.',
  AppTranslations.navChats: 'Chats',
  AppTranslations.navCalls: 'Oproepen',
  AppTranslations.navProfile: 'Profiel',
  AppTranslations.navSettings: 'Instellingen',
  AppTranslations.composeTitle: 'Nieuw gesprek',
  AppTranslations.composeSearchHint: 'Zoek vrienden',
  AppTranslations.composeSelectContact: 'Selecteer eerst een vriend',
  AppTranslations.composeOpenConversation: 'Open gesprek',
  AppTranslations.composeContactsUnavailable:
      'Contactpersonen verschijnen hier zodra het eindpunt gereed is.',
  AppTranslations.composeNoContacts:
      'Er zijn momenteel geen contacten beschikbaar.',
  AppTranslations.composeRecipientId: 'Gebruikers-ID van de ontvanger',
  AppTranslations.composeRecipientHint: 'Voer de gebruikers-ID in',
  AppTranslations.composeMessage: 'Eerste bericht',
  AppTranslations.composeMessageHint: 'Schrijf uw bericht',
  AppTranslations.composeSend: 'Versturen',
  AppTranslations.composeRecipientRequired:
      'De gebruikers-ID van de ontvanger is vereist',
  AppTranslations.composeMessageRequired: 'Bericht is vereist',
  AppTranslations.callsPlaceholder:
      'Het tabblad Gesprekken is klaar voor de volgende API-stap.',
  AppTranslations.callsEmptyTitle: 'Nog geen oproepen',
  AppTranslations.callsEmptyBody:
      'Hier verschijnen uw recente spraak- en video-oproepen.',
  AppTranslations.callsIncoming: 'Inkomend',
  AppTranslations.callsOutgoing: 'Uitgaand',
  AppTranslations.callsMissed: 'Gemist',
  AppTranslations.callsDeclined: 'Afgewezen',
  AppTranslations.callsAnswered: 'Beantwoord',
  AppTranslations.callsOpenChat: 'Chat openen',
  AppTranslations.profilePlaceholder:
      'Het tabblad Profiel is gereserveerd voor account- en identiteitsgegevens.',
  AppTranslations.profileCurrentAccount: 'Lopende rekening',
  AppTranslations.profileConnectedAccounts: 'Verbonden accounts',
  AppTranslations.profileAddAccount: 'Account toevoegen',
  AppTranslations.profileSwitchAccount: 'Schakelaar',
  AppTranslations.profileRemoveAccount: 'Verwijderen',
  AppTranslations.profileRevokeAccount: 'Herroepen',
  AppTranslations.profileAccountUsername: 'Gebruikersnaam',
  AppTranslations.profileAccountEmail: 'E-mail',
  AppTranslations.profileAccountStatus: 'Accountstatus',
  AppTranslations.profileAccountCurrent: 'Huidig',
  AppTranslations.profileAccountMaster: 'Meester',
  AppTranslations.profileNoConnectedAccounts:
      'Er zijn nog geen gekoppelde accounts gevonden.',
  AppTranslations.profileAddAccountTitle: 'Verbonden account toevoegen',
  AppTranslations.profileAddAccountIdentifier: 'E-mailadres of gebruikersnaam',
  AppTranslations.profileAddAccountIdentifierHint:
      'Voer het e-mailadres of de gebruikersnaam van het gekoppelde account in',
  AppTranslations.profileAddAccountPassword: 'Accountwachtwoord',
  AppTranslations.profileAddAccountConfirm: 'Account koppelen',
  AppTranslations.profileAddAccountSuccess:
      'Verbonden account succesvol toegevoegd',
  AppTranslations.profileSwitchAccountSuccess: 'Account is succesvol gewijzigd',
  AppTranslations.profileRemoveAccountTitle: 'Verbonden account verwijderen',
  AppTranslations.profileRemoveAccountMessage:
      'Weet u zeker dat u dit gekoppelde account wilt verwijderen?',
  AppTranslations.profileRemoveAccountSuccess:
      'Verbonden account succesvol verwijderd',
  AppTranslations.profileRevokeAccountTitle: 'Accountkoppeling intrekken',
  AppTranslations.profileRevokeAccountMessage:
      'Weet u zeker dat u de huidige gekoppelde hoofdverbinding wilt intrekken?',
  AppTranslations.profileRevokeAccountSuccess:
      'Accountverbinding is succesvol ingetrokken',
  AppTranslations.profileManageSettings: 'Instellingen openen',
  AppTranslations.profileTimelineBridgeActive:
      'Tijdlijnbridgesessie is actief op dit apparaat.',
  AppTranslations.profileLinkedAccountsDisabled:
      'Het schakelen tussen verbonden accounts is uitgeschakeld voor dit account.',
  AppTranslations.profileAccountAdded: 'Account verbonden',
  AppTranslations.profileAccountEmptyField:
      'E-mail/gebruikersnaam en wachtwoord zijn vereist',
  AppTranslations.chatOnlineNow: 'Nu online',
  AppTranslations.chatSeen: 'Gezien',
  AppTranslations.chatInputHint: 'Typ een bericht',
  AppTranslations.chatInfoTitle: 'Chat-informatie',
  AppTranslations.chatInfoSharedMedia: 'Gedeelde media',
  AppTranslations.chatInfoSettings: 'Chat-instellingen',
  AppTranslations.chatInfoAll: 'Alle',
  AppTranslations.chatInfoImages: 'Afbeeldingen',
  AppTranslations.chatInfoVideos: 'Video\'s',
  AppTranslations.chatInfoAudio: 'Audio',
  AppTranslations.chatInfoFiles: 'Bestanden',
  AppTranslations.chatInfoLinks: 'Koppelingen',
  AppTranslations.chatInfoNoSharedMedia:
      'Er is geen gedeelde inhoud gevonden voor dit gesprek.',
  AppTranslations.chatInfoOpen: 'Open',
  AppTranslations.chatSettingBackground: 'Chatachtergrond',
  AppTranslations.chatSettingMute: 'Meldingen dempen',
  AppTranslations.chatSettingPin: 'Pinchat',
  AppTranslations.chatSettingBlock: 'Gebruiker blokkeren',
  AppTranslations.chatSettingReport: 'Gebruiker melden',
  AppTranslations.chatSettingReportSubtitle:
      'Stuur een veiligheidsmelding over dit account.',
  AppTranslations.chatSettingDelete: 'Gesprek verwijderen',
  AppTranslations.chatSettingApiPending:
      'Deze instelling wacht op het speciale API-eindpunt.',
  AppTranslations.chatReportTitle: 'Gebruiker melden',
  AppTranslations.chatReportDescription:
      'Kies de reden voor deze melding. Ukraina.co-Chat stuurt deze naar het moderatieteam voor beoordeling.',
  AppTranslations.chatReportCategoryLabel: 'Meldingscategorie',
  AppTranslations.chatReportCategoryHint: 'Kies een reden',
  AppTranslations.chatReportReasonLabel: 'Extra details',
  AppTranslations.chatReportReasonHint:
      'Voeg meer context toe om de beoordeling van deze melding te ondersteunen.',
  AppTranslations.chatReportSubmit: 'Melding verzenden',
  AppTranslations.chatReportSuccess: 'Melding verzonden',
  AppTranslations.chatReportEmptyCategories:
      'Er zijn momenteel geen meldingscategorieën beschikbaar.',
  AppTranslations.chatReportCategoryRequired:
      'Kies een meldingscategorie voordat je doorgaat.',
  AppTranslations.chatReportLoadFailed:
      'Meldingscategorieën kunnen momenteel niet worden geladen.',
  AppTranslations.chatDeleteTitle: 'Gesprek verwijderen',
  AppTranslations.chatDeleteMessage:
      'Weet je zeker dat je dit gesprek wilt verwijderen?',
  AppTranslations.chatDeleteConfirm: 'Verwijderen',
  AppTranslations.chatDeleted: 'Gesprek is succesvol verwijderd',
  AppTranslations.chatMessageDelete: 'Bericht verwijderen',
  AppTranslations.chatMessageEdit: 'Bericht bewerken',
  AppTranslations.chatMessageReply: 'Antwoord',
  AppTranslations.chatMessageForward: 'Vooruit',
  AppTranslations.chatMessageCopy: 'Kopiëren',
  AppTranslations.chatStickerTitle: 'Stickers',
  AppTranslations.chatStickerSubtitle:
      'Kies een stickerpakket en stuur direct een sticker.',
  AppTranslations.chatStickerEmpty:
      'Er zijn geen stickers beschikbaar in dit pakket.',
  AppTranslations.chatMessageDeleteTitle: 'Bericht verwijderen',
  AppTranslations.chatMessageDeleteMessage:
      'Weet je zeker dat je dit bericht wilt verwijderen?',
  AppTranslations.chatMessageDeleted: 'Bericht succesvol verwijderd',
  AppTranslations.chatMessageEditPending:
      'Voor het bewerken van berichten is een speciaal API-eindpunt nodig.',
  AppTranslations.callVoice: 'Spraakoproep',
  AppTranslations.callVideo: 'Videogesprek',
  AppTranslations.callConnecting: 'Verbinden...',
  AppTranslations.callWaiting: 'Wachten tot de andere persoon zich aansluit',
  AppTranslations.callMicOff: 'Microfoon uit',
  AppTranslations.callMicOn: 'Microfoon aan',
  AppTranslations.callSpeakerOn: 'Luidspreker aan',
  AppTranslations.callSpeakerOff: 'Luidspreker uit',
  AppTranslations.callCameraFlip: 'Camera wisselen',
  AppTranslations.callEnd: 'Beëindig gesprek',
  AppTranslations.callPermissionDenied:
      'Camera- of microfoontoestemming is geweigerd.',
  AppTranslations.callAgoraDisabled:
      'Agora-bellen is uitgeschakeld in settings.dart.',
  AppTranslations.callAgoraMissingAppId:
      'Agora App-ID ontbreekt in settings.dart.',
  AppTranslations.callRemoteJoined: 'Aangesloten',
  AppTranslations.callRinging: 'Bellen...',
  AppTranslations.callNoAnswer: 'Geen antwoord van de andere persoon.',
  AppTranslations.callDeclined: 'De oproep werd afgewezen.',
  AppTranslations.callIncoming: 'Inkomend gesprek',
  AppTranslations.callAccept: 'Accepteren',
  AppTranslations.callDeclineAction: 'Afwijzen',
  AppTranslations.callRecipientBusy: 'De andere persoon is momenteel bezig.',
  AppTranslations.callRecipientOffline: 'De andere persoon is offline.',
  AppTranslations.callCallerBusy: 'U heeft al een actief gesprek.',
  AppTranslations.callDirectOnly:
      'Oproepen zijn momenteel alleen beschikbaar in directe gesprekken.',
  AppTranslations.callMissingConnection:
      'De server heeft geen volledige verbindingsgegevens geretourneerd.',
  AppTranslations.authFlowHeadline: 'Extra authenticatiestap vereist',
  AppTranslations.authFlowDescription:
      'De server heeft uw aanmelding geaccepteerd, maar de volgende vereiste stap is: @step',
  AppTranslations.accountBannedTitle: 'Dit account is geblokkeerd',
  AppTranslations.accountBannedBody:
      'Je Messenger-account is momenteel beperkt en kan de app momenteel niet gebruiken.',
  AppTranslations.accountBannedSupport:
      'Neem contact op met de ondersteuning of de sitebeheerder als u denkt dat dit per ongeluk is gebeurd.',
  AppTranslations.accountBannedContactSupport:
      'Neem contact op met ondersteuning',
  AppTranslations.authActivationTitle: 'Activering vereist',
  AppTranslations.authActivationDescription:
      'Voer de verificatiecode in die naar uw account is verzonden om door te gaan.',
  AppTranslations.authApprovalTitle: 'Goedkeuring vereist',
  AppTranslations.authApprovalDescription:
      'Je account wacht op goedkeuring voordat Messenger verder kan gaan.',
  AppTranslations.authGettingStartedTitle: 'Aan de slag vereist',
  AppTranslations.authGettingStartedDescription:
      'Je account heeft nog één installatiestap nodig voordat Messenger volledig kan worden geopend.',
  AppTranslations.authTwoFactorTitle: 'Tweefactorauthenticatie',
  AppTranslations.authTwoFactorDescription:
      'Voer de verificatiecode van uw geconfigureerde tweefactormethode in.',
  AppTranslations.verificationCode: 'Verificatiecode',
  AppTranslations.verificationCodeHint:
      'Voer de code precies in zoals ontvangen',
  AppTranslations.verificationCodeRequired: 'Verificatiecode is vereist',
  AppTranslations.resendCode: 'Code opnieuw verzenden',
  AppTranslations.verifyAndContinue: 'Verifieer en ga verder',
  AppTranslations.activationCodeSent:
      'Er is een nieuwe activatiecode verzonden.',
  AppTranslations.authUnableToLoadState:
      'Kan uw authenticatiestatus momenteel niet laden.',
  AppTranslations.authUnableToVerifyCode:
      'Kan de code momenteel niet verifiëren.',
  AppTranslations.authUnableToResendCode:
      'Kan de code momenteel niet opnieuw verzenden.',
  AppTranslations.backToLogin: 'Terug naar inloggen',
  AppTranslations.loginFailed: 'Kan momenteel niet inloggen',
  AppTranslations.commonConversation: 'Gesprek',
  AppTranslations.commonChat: 'Chatten',
  AppTranslations.commonConversations: 'Gesprekken',
  AppTranslations.commonPeople: 'Mensen',
  AppTranslations.commonPost: 'Na',
  AppTranslations.commonStory: 'Verhaal',
  AppTranslations.commonReel: 'Haspel',
  AppTranslations.commonProduct: 'Product',
  AppTranslations.commonImage: 'Afbeelding',
  AppTranslations.commonVideo: 'Video',
  AppTranslations.commonSticker: 'Sticker',
  AppTranslations.commonOn: 'Op',
  AppTranslations.commonOff: 'Uit',
  AppTranslations.commonColors: 'Kleuren',
  AppTranslations.commonGradients: 'Verlopen',
  AppTranslations.commonReset: 'Opnieuw instellen',
  AppTranslations.commonTimeline: 'Tijdlijn',
  AppTranslations.timelineAppNotInstalledTitle:
      'De Timeline-app is niet geïnstalleerd',
  AppTranslations.timelineAppNotInstalledMessage:
      'Installeer eerst de Timeline-app om deze inhoud te openen. Wil je die nu downloaden?',
  AppTranslations.timelineAppCancelAction: 'Annuleren',
  AppTranslations.timelineAppDownloadAction: 'Downloaden',
  AppTranslations.sharedPost: 'Gedeeld bericht',
  AppTranslations.sharedReel: 'Gedeelde spoel',
  AppTranslations.sharePostTitle: 'Deel bericht',
  AppTranslations.shareReelTitle: 'Deel spoel',
  AppTranslations.shareSearchHint: 'Zoek gesprekken of mensen',
  AppTranslations.shareEmptyTargets: 'Geen gesprekken of contacten beschikbaar',
  AppTranslations.profileQuickSettingsSubtitle:
      'Privacy, meldingen en voorkeuren',
  AppTranslations.profileConnectAnother: 'Koppel een ander profiel',
  AppTranslations.profileAddAccountDisabled:
      'Het toevoegen van accounts is uitgeschakeld',
  AppTranslations.profileIdentityEyebrow: 'IDENTITEIT',
  AppTranslations.profileSwitcherEyebrow: 'SCHAKELAAR',
  AppTranslations.profileAttachAnotherAccount:
      'Voeg nog een account toe voor snel overstappen',
  AppTranslations.profileNoEmailAttached: 'Geen e-mail bijgevoegd',
  AppTranslations.profileReadyToSwitch: 'Klaar om te schakelen',
  AppTranslations.chatPin: 'Pin',
  AppTranslations.chatUnpin: 'Losmaken',
  AppTranslations.chatConversationPinned: 'Gesprek vastgezet',
  AppTranslations.chatConversationUnpinned: 'Gesprek losgemaakt',
  AppTranslations.chatDirectConversation: 'Directe chat',
  AppTranslations.chatGroupConversation: 'Groepschat',
  AppTranslations.callsTotal: 'Totaal',
  AppTranslations.callsAll: 'Alle oproepen',
  AppTranslations.callsHeroSubtitle:
      'Volg gemiste, beantwoorde en videogesprekken in één overzichtelijke weergave.',
  AppTranslations.homeRecentActivity: 'Recente activiteit',
  AppTranslations.chatSettingsSubtitle:
      'Beheer meldingen, pinstatus en gespreksacties.',
  AppTranslations.chatBackgroundSubtitle:
      'Kies een aangepaste achtergrond voor dit gesprek.',
  AppTranslations.chatRecordingTitle: 'Opname',
  AppTranslations.chatRecordingBody:
      'Tik nogmaals op de microfoon om te stoppen en te verzenden',
  AppTranslations.chatInvalidConversationId: 'Ongeldige gespreks-ID',
  AppTranslations.chatImageUnavailable: 'Afbeelding niet beschikbaar',
  AppTranslations.chatSharedItemOpenFailed: 'Kan gedeeld item niet openen',
  AppTranslations.chatVoiceUnavailable: 'Spraakbericht niet beschikbaar',
  AppTranslations.chatVideoUnavailable: 'Video niet beschikbaar',
  AppTranslations.chatReplyingTo: 'Reageren op',
  AppTranslations.chatReplyToYourself: 'Jouw bericht',
  AppTranslations.chatReplyOriginalUnavailable:
      'Origineel bericht niet beschikbaar',
  AppTranslations.chatRepliedToStory: 'Heeft gereageerd op een verhaal',
  AppTranslations.chatReactedToStory: 'Gereageerd op een verhaal',
  AppTranslations.chatEditingMessage: 'Bericht bewerken',
  AppTranslations.chatMessageCopied: 'Bericht gekopieerd',
  AppTranslations.forwardTitle: 'Bericht doorsturen',
  AppTranslations.forwardSearchHint: 'Zoek gesprekken of mensen',
  AppTranslations.forwardEmptyTargets:
      'Geen gesprekken of contacten beschikbaar',
  AppTranslations.forwardPreviewTitle: 'Doorgestuurd bericht',
  AppTranslations.forwardSent: 'Bericht succesvol doorgestuurd',
};
