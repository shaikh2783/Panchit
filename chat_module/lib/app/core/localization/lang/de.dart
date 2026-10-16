import '../app_translations.dart';
import 'base.dart';

final Map<String, String> de = <String, String>{
  ...buildBaseTranslations(),
  AppTranslations.appName: 'Bote',
  AppTranslations.loginHeadline: 'Willkommen zurück zu Ihren Gesprächen',
  AppTranslations.loginSubtitle:
      'Melden Sie sich an, um Ihre Chats fortzusetzen, verknüpfte Konten zu verwalten und in der Nähe Ihrer Leute zu bleiben.',
  AppTranslations.loginIdentifierLabel: 'E-Mail oder Benutzername',
  AppTranslations.loginIdentifierHint:
      'Geben Sie Ihre E-Mail-Adresse oder Ihren Benutzernamen ein',
  AppTranslations.passwordLabel: 'Passwort',
  AppTranslations.passwordHint: 'Geben Sie Ihr Passwort ein',
  AppTranslations.rememberMe: 'Erinnere dich an mich',
  AppTranslations.forgotPassword: 'Passwort vergessen?',
  AppTranslations.signIn: 'Melden Sie sich an',
  AppTranslations.createAccount: 'Konto erstellen',
  AppTranslations.alreadyHaveAccount: 'Sie haben bereits ein Konto?',
  AppTranslations.dontHaveAccount: 'Sie haben noch kein Konto?',
  AppTranslations.registerTitle: 'Registrieren',
  AppTranslations.registerSubtitle:
      'Geben Sie Ihre Kontodaten ein, um ein neues Messenger-Konto zu erstellen.',
  AppTranslations.signUpHeadline: 'Erstellen Sie Ihr Messenger-Konto',
  AppTranslations.signUpSubtitle:
      'Nehmen Sie mit einem neuen Konto an der Konversation teil und fahren Sie automatisch mit dem nächsten erforderlichen Einrichtungsschritt fort.',
  AppTranslations.signUpToggleTitle: 'Neu hier?',
  AppTranslations.signInToggleTitle: 'Sie haben bereits ein Konto?',
  AppTranslations.signUpUsernameLabel: 'Benutzername',
  AppTranslations.signUpUsernameHint: 'Wählen Sie einen Benutzernamen',
  AppTranslations.signUpEmailLabel: 'E-Mail-Adresse',
  AppTranslations.signUpEmailHint: 'Geben Sie Ihre E-Mail-Adresse ein',
  AppTranslations.signUpFirstNameLabel: 'Vorname',
  AppTranslations.signUpFirstNameHint: 'Geben Sie Ihren Vornamen ein',
  AppTranslations.signUpLastNameLabel: 'Nachname',
  AppTranslations.signUpLastNameHint: 'Geben Sie Ihren Nachnamen ein',
  AppTranslations.signUpGenderLabel: 'Geschlecht',
  AppTranslations.signUpGenderMale: 'Männlich',
  AppTranslations.signUpGenderFemale: 'Weiblich',
  AppTranslations.signUpConfirmPasswordLabel: 'Passwort bestätigen',
  AppTranslations.signUpConfirmPasswordHint:
      'Geben Sie Ihr Passwort erneut ein',
  AppTranslations.signUpUsernameRequired: 'Benutzername ist erforderlich',
  AppTranslations.signUpUsernameTooShort:
      'Der Benutzername muss mindestens 3 Zeichen lang sein',
  AppTranslations.signUpEmailRequired: 'E-Mail-Adresse ist erforderlich',
  AppTranslations.signUpEmailInvalid:
      'Geben Sie eine gültige E-Mail-Adresse ein',
  AppTranslations.signUpPasswordTooShort:
      'Das Passwort muss mindestens 6 Zeichen lang sein',
  AppTranslations.signUpConfirmPasswordRequired:
      'Zur Bestätigung ist ein Passwort erforderlich',
  AppTranslations.signUpPasswordsDoNotMatch: 'Passwörter stimmen nicht überein',
  AppTranslations.signUpFirstNameRequired: 'Der Vorname ist erforderlich',
  AppTranslations.signUpLastNameRequired: 'Nachname ist erforderlich',
  AppTranslations.signUpFailed: 'Das Konto kann derzeit nicht erstellt werden',
  AppTranslations.signUpNote:
      'Nach der Anmeldung führt Sie Messenger automatisch durch die Aktivierung oder alle erforderlichen Einrichtungsschritte.',
  AppTranslations.signUpAgreementPrefix: 'Ich stimme dem zu',
  AppTranslations.signUpAgreementAnd: 'und',
  AppTranslations.signUpAgreementSuffix: 'bevor ich mein Konto erstelle.',
  AppTranslations.signUpTermsOfUse: 'Nutzungsbedingungen',
  AppTranslations.signUpPrivacyPolicy: 'Datenschutzrichtlinie',
  AppTranslations.signUpTermsRequiredTitle: 'Genehmigung erforderlich',
  AppTranslations.signUpTermsRequiredMessage:
      'Sie müssen zunächst den Nutzungsbedingungen und der Datenschutzrichtlinie zustimmen.',
  AppTranslations.webViewPageTitle: 'Details',
  AppTranslations.secureAccessNote:
      'Geschützte Anmeldung mit gerätebezogener Sitzungsüberprüfung.',
  AppTranslations.loginFooter:
      'Entwickelt für schnelles Versenden von Nachrichten mit einem gezielten und sicheren Anmeldeablauf.',
  AppTranslations.loginWithTimeline: 'Fahren Sie mit dem Timeline-Konto fort',
  AppTranslations.loginWithTimelineSubtitle:
      'Verwenden Sie das Konto, das bereits in Timeline angemeldet ist.',
  AppTranslations.identifierRequired:
      'E-Mail oder Benutzername sind erforderlich',
  AppTranslations.passwordRequired: 'Passwort ist erforderlich',
  AppTranslations.loading: 'Laden...',
  AppTranslations.homeHeadline: 'Nachrichten',
  AppTranslations.homeSubtitle:
      'Bleiben Sie nah bei den Menschen, die Ihnen am Herzen liegen.',
  AppTranslations.homeWelcomeBack: 'Willkommen zurück, @name',
  AppTranslations.homeSearchHint: 'Gespräche durchsuchen',
  AppTranslations.homeSearchEmptyTitle: 'Keine passenden Gespräche',
  AppTranslations.homeSearchEmptyBody:
      'Versuchen Sie es mit einem anderen Namen oder Schlüsselwort, um eine Konversation zu finden.',
  AppTranslations.addStory: 'Geschichte hinzufügen',
  AppTranslations.shareStory: 'Geschichte teilen',
  AppTranslations.storyAddText: 'Text hinzufügen',
  AppTranslations.storyTextHint: 'Schreibe etwas...',
  AppTranslations.storyMediaHint:
      'Fügen Sie ein Foto oder Video hinzu, um Ihre Geschichte zu teilen.',
  AppTranslations.camera: 'Kamera',
  AppTranslations.gallery: 'Galerie',
  AppTranslations.done: 'Fertig',
  AppTranslations.replyToStory: 'Auf die Geschichte antworten',
  AppTranslations.storyReplySent: 'Story-Antwort gesendet.',
  AppTranslations.storyReactionSent: 'Story-Reaktion gesendet.',
  AppTranslations.storyPublished: 'Geschichte veröffentlicht.',
  AppTranslations.storyViews: 'Ansichten',
  AppTranslations.storyViewers: 'Story-Zuschauer',
  AppTranslations.storyReactions: 'Story-Reaktionen',
  AppTranslations.noStoryViewers: 'Noch keine Zuschauer.',
  AppTranslations.noStoryReactions: 'Noch keine Reaktionen.',
  AppTranslations.unableToLoadStoryViewers:
      'Story-Viewer können derzeit nicht geladen werden.',
  AppTranslations.unableToLoadStoryReactions:
      'Story-Reaktionen können derzeit nicht geladen werden.',
  AppTranslations.unableToReplyToStory:
      'Die Story-Antwort kann derzeit nicht gesendet werden.',
  AppTranslations.unableToReactToStory:
      'Die Story-Reaktion kann derzeit nicht gesendet werden.',
  AppTranslations.unableToPublishStory:
      'Die Geschichte kann derzeit nicht veröffentlicht werden.',
  AppTranslations.storiesLoadFailed: 'Die Storys konnten nicht geladen werden',
  AppTranslations.storyFeatureSoon:
      'Als nächstes kommen Story Viewer und Veröffentlichung.',
  AppTranslations.homeStoriesTitle: 'Jetzt aktiv',
  AppTranslations.homeChatsTitle: 'Aktuelle Chats',
  AppTranslations.homeTabAll: 'Alle',
  AppTranslations.homeTabUnread: 'Ungelesen',
  AppTranslations.homeTabGroups: 'Gruppen',
  AppTranslations.homeOnlineNow: 'Jetzt online',
  AppTranslations.homeTypePlaceholder: 'Geben Sie eine Nachricht ein',
  AppTranslations.homeStatusActive: 'Jetzt aktiv',
  AppTranslations.homeStatusTyping: 'Tippen...',
  AppTranslations.homeStatusSent: 'Gesendet',
  AppTranslations.homeStatusDelivered: 'Geliefert',
  AppTranslations.homeStatusVoice: 'Sprachnachricht',
  AppTranslations.homeStatusMuted: 'Benachrichtigungen stummgeschaltet',
  AppTranslations.homeChatsUnavailableTitle:
      'Live-Chats sind noch nicht fertig',
  AppTranslations.homeChatsUnavailableBody:
      'Der Messenger-Chat-Endpunkt gibt immer noch eine Gerüstantwort vom Server zurück.',
  AppTranslations.homeChatsEmptyTitle: 'Ihr Posteingang ist fertig',
  AppTranslations.homeChatsEmptyBody:
      'Starten Sie Ihr erstes Gespräch, um hier Nachrichten, Antworten und geteilte Momente zu sehen.',
  AppTranslations.homeChatsEmptyAction: 'Starten Sie einen Chat',
  AppTranslations.retry: 'Versuchen Sie es noch einmal',
  AppTranslations.settingsTitle: 'Einstellungen',
  AppTranslations.settingsLanguage: 'Sprache',
  AppTranslations.settingsArabic: 'Arabisch',
  AppTranslations.settingsEnglish: 'Englisch',
  AppTranslations.settingsFrench: 'Französisch',
  AppTranslations.settingsSpanish: 'Spanisch',
  AppTranslations.settingsPortuguese: 'Portugiesisch',
  AppTranslations.settingsGerman: 'Deutsch',
  AppTranslations.settingsTurkish: 'Türkisch',
  AppTranslations.settingsDutch: 'Niederländisch',
  AppTranslations.settingsItalian: 'Italienisch',
  AppTranslations.settingsRussian: 'Russisch',
  AppTranslations.settingsRomanian: 'Rumänisch',
  AppTranslations.settingsPortugueseBrazil: 'Portugiesisch (Brasilien)',
  AppTranslations.settingsGreek: 'Griechisch',
  AppTranslations.settingsUkrainian: 'ukrainisch',
  AppTranslations.settingsTheme: 'Thema',
  AppTranslations.settingsDarkMode: 'Dunkler Modus',
  AppTranslations.settingsLightMode: 'Lichtmodus',
  AppTranslations.settingsLanguageSheetDescription:
      'Wählen Sie die App-Sprache aus einer übersichtlichen Liste aus.',
  AppTranslations.settingsHeroDescription:
      'Verwalten Sie Sprache, Erscheinungsbild und Kontozugriff von einem Ort aus.',
  AppTranslations.settingsPreferencesEyebrow: 'EINSTELLUNGEN',
  AppTranslations.settingsPreferencesTitle: 'App-Erlebnis',
  AppTranslations.settingsAccountEyebrow: 'KONTO',
  AppTranslations.settingsAccountTitle: 'Sitzung und Sicherheit',
  AppTranslations.settingsBlockedUsers: 'Blockierte Benutzer',
  AppTranslations.settingsBlockedUsersSubtitle:
      'Überprüfen Sie blockierte Personen und heben Sie Einschränkungen bei Bedarf auf.',
  AppTranslations.blockedUsersTitle: 'Blockierte Benutzer',
  AppTranslations.blockedUsersEmpty:
      'Für dieses Konto wurden derzeit keine blockierten Benutzer gefunden.',
  AppTranslations.blockedUsersUnblock: 'Blockierung aufheben',
  AppTranslations.blockedUsersUnblockTitle: 'Benutzer entsperren',
  AppTranslations.blockedUsersUnblockMessage:
      'Möchten Sie diesen Benutzer aus Ihrer Sperrliste entfernen?',
  AppTranslations.blockedUsersUserUnblocked:
      'Die Blockierung des Benutzers wurde erfolgreich aufgehoben',
  AppTranslations.settingsDeleteAccount: 'Konto löschen',
  AppTranslations.settingsDeleteAccountSubtitle:
      'Entfernen Sie dieses Konto dauerhaft und löschen Sie den Zugriff auf Messenger.',
  AppTranslations.settingsDeleteAccountTitle: 'Konto löschen',
  AppTranslations.settingsDeleteAccountMessage:
      'Diese Aktion ist dauerhaft. Möchten Sie Ihr Konto wirklich löschen?',
  AppTranslations.settingsDeleteAccountConfirm: 'Konto löschen',
  AppTranslations.settingsDeleteAccountSuccess:
      'Ihr Konto wurde erfolgreich gelöscht',
  AppTranslations.settingsLogoutSubtitle:
      'Melden Sie sich von der aktuellen Sitzung auf diesem Gerät ab',
  AppTranslations.settingsLogout: 'Abmelden',
  AppTranslations.settingsLogoutTitle: 'Abmelden',
  AppTranslations.settingsLogoutMessage:
      'Sind Sie sicher, dass Sie sich auf diesem Gerät vom Messenger abmelden möchten?',
  AppTranslations.settingsLogoutTimelineBridgeMessage:
      'Sie werden nur vom Messenger abgemeldet. Ihre Timeline-Sitzung bleibt auf diesem Gerät angemeldet.',
  AppTranslations.settingsLogoutCancel: 'Abbrechen',
  AppTranslations.settingsLogoutConfirm: 'Abmelden',
  AppTranslations.settingsLegalEyebrow: 'RECHTLICHES',
  AppTranslations.settingsLegalTitle: 'Datenschutz und Bedingungen',
  AppTranslations.settingsPrivacyPolicy: 'Datenschutzrichtlinie',
  AppTranslations.settingsPrivacyPolicySubtitle:
      'Erfahren Sie, wie Ukraina.co-Chat Kontodaten sammelt, verwendet und schützt.',
  AppTranslations.settingsTermsOfUse: 'Nutzungsbedingungen',
  AppTranslations.settingsTermsOfUseSubtitle:
      'Lesen Sie die Regeln, Verantwortlichkeiten und Nutzungsbedingungen für Ukraina.co-Chat.',
  AppTranslations.navChats: 'Chats',
  AppTranslations.navCalls: 'Anrufe',
  AppTranslations.navProfile: 'Profil',
  AppTranslations.navSettings: 'Einstellungen',
  AppTranslations.composeTitle: 'Neues Gespräch',
  AppTranslations.composeSearchHint: 'Suche Freunde',
  AppTranslations.composeSelectContact: 'Wählen Sie zuerst einen Freund aus',
  AppTranslations.composeOpenConversation: 'Offenes Gespräch',
  AppTranslations.composeContactsUnavailable:
      'Kontakte werden hier angezeigt, sobald der Endpunkt bereit ist.',
  AppTranslations.composeNoContacts: 'Im Moment sind keine Kontakte verfügbar.',
  AppTranslations.composeRecipientId: 'Benutzer-ID des Empfängers',
  AppTranslations.composeRecipientHint: 'Geben Sie die Benutzer-ID ein',
  AppTranslations.composeMessage: 'Erste Nachricht',
  AppTranslations.composeMessageHint: 'Schreiben Sie Ihre Nachricht',
  AppTranslations.composeSend: 'Senden',
  AppTranslations.composeRecipientRequired:
      'Die Benutzer-ID des Empfängers ist erforderlich',
  AppTranslations.composeMessageRequired: 'Nachricht ist erforderlich',
  AppTranslations.callsPlaceholder:
      'Die Registerkarte „Aufrufe“ ist für den nächsten API-Schritt bereit.',
  AppTranslations.callsEmptyTitle: 'Noch keine Anrufe',
  AppTranslations.callsEmptyBody:
      'Hier werden Ihre letzten Sprach- und Videoanrufe angezeigt.',
  AppTranslations.callsIncoming: 'Eingehend',
  AppTranslations.callsOutgoing: 'Ausgehend',
  AppTranslations.callsMissed: 'Verpasst',
  AppTranslations.callsDeclined: 'Abgelehnt',
  AppTranslations.callsAnswered: 'Beantwortet',
  AppTranslations.callsOpenChat: 'Chat öffnen',
  AppTranslations.profilePlaceholder:
      'Die Registerkarte „Profil“ ist für Konto- und Identitätsdetails reserviert.',
  AppTranslations.profileCurrentAccount: 'Girokonto',
  AppTranslations.profileConnectedAccounts: 'Verbundene Konten',
  AppTranslations.profileAddAccount: 'Konto hinzufügen',
  AppTranslations.profileSwitchAccount: 'Wechseln',
  AppTranslations.profileRemoveAccount: 'Entfernen',
  AppTranslations.profileRevokeAccount: 'Widerrufen',
  AppTranslations.profileAccountUsername: 'Benutzername',
  AppTranslations.profileAccountEmail: 'E-Mail',
  AppTranslations.profileAccountStatus: 'Kontostatus',
  AppTranslations.profileAccountCurrent: 'Aktuell',
  AppTranslations.profileAccountMaster: 'Meister',
  AppTranslations.profileNoConnectedAccounts:
      'Es wurden noch keine verbundenen Konten gefunden.',
  AppTranslations.profileAddAccountTitle: 'Verbundenes Konto hinzufügen',
  AppTranslations.profileAddAccountIdentifier: 'E-Mail oder Benutzername',
  AppTranslations.profileAddAccountIdentifierHint:
      'Geben Sie die E-Mail-Adresse oder den Benutzernamen des verknüpften Kontos ein',
  AppTranslations.profileAddAccountPassword: 'Kontopasswort',
  AppTranslations.profileAddAccountConfirm: 'Konto verbinden',
  AppTranslations.profileAddAccountSuccess:
      'Verbundenes Konto erfolgreich hinzugefügt',
  AppTranslations.profileSwitchAccountSuccess: 'Kontowechsel erfolgreich',
  AppTranslations.profileRemoveAccountTitle: 'Verbundenes Konto entfernen',
  AppTranslations.profileRemoveAccountMessage:
      'Möchten Sie dieses verbundene Konto wirklich entfernen?',
  AppTranslations.profileRemoveAccountSuccess:
      'Verbundenes Konto erfolgreich entfernt',
  AppTranslations.profileRevokeAccountTitle: 'Kontoverbindung widerrufen',
  AppTranslations.profileRevokeAccountMessage:
      'Sind Sie sicher, dass Sie die aktuell verknüpfte Master-Verbindung widerrufen möchten?',
  AppTranslations.profileRevokeAccountSuccess:
      'Kontoverbindung erfolgreich widerrufen',
  AppTranslations.profileManageSettings: 'Einstellungen öffnen',
  AppTranslations.profileTimelineBridgeActive:
      'Die Timeline-Bridge-Sitzung ist auf diesem Gerät aktiv.',
  AppTranslations.profileLinkedAccountsDisabled:
      'Der Wechsel zwischen verbundenen Konten ist für dieses Konto deaktiviert.',
  AppTranslations.profileAccountAdded: 'Konto verbunden',
  AppTranslations.profileAccountEmptyField:
      'E-Mail/Benutzername und Passwort sind erforderlich',
  AppTranslations.chatOnlineNow: 'Jetzt online',
  AppTranslations.chatSeen: 'Gesehen',
  AppTranslations.chatInputHint: 'Geben Sie eine Nachricht ein',
  AppTranslations.chatInfoTitle: 'Chat-Informationen',
  AppTranslations.chatInfoSharedMedia: 'Geteilte Medien',
  AppTranslations.chatInfoSettings: 'Chat-Einstellungen',
  AppTranslations.chatInfoAll: 'Alle',
  AppTranslations.chatInfoImages: 'Bilder',
  AppTranslations.chatInfoVideos: 'Videos',
  AppTranslations.chatInfoAudio: 'Audio',
  AppTranslations.chatInfoFiles: 'Dateien',
  AppTranslations.chatInfoLinks: 'Links',
  AppTranslations.chatInfoNoSharedMedia:
      'Für diese Konversation wurde kein freigegebener Inhalt gefunden.',
  AppTranslations.chatInfoOpen: 'Offen',
  AppTranslations.chatSettingBackground: 'Chat-Hintergrund',
  AppTranslations.chatSettingMute: 'Benachrichtigungen stummschalten',
  AppTranslations.chatSettingPin: 'Pin-Chat',
  AppTranslations.chatSettingBlock: 'Benutzer blockieren',
  AppTranslations.chatSettingReport: 'Benutzer melden',
  AppTranslations.chatSettingReportSubtitle:
      'Senden Sie eine Sicherheitsmeldung zu diesem Konto.',
  AppTranslations.chatSettingDelete: 'Konversation löschen',
  AppTranslations.chatSettingApiPending:
      'Diese Einstellung wartet auf den dedizierten API-Endpunkt.',
  AppTranslations.chatReportTitle: 'Benutzer melden',
  AppTranslations.chatReportDescription:
      'Wählen Sie den Grund für diese Meldung aus. Ukraina.co-Chat sendet sie zur Prüfung an das Moderationsteam.',
  AppTranslations.chatReportCategoryLabel: 'Meldekategorie',
  AppTranslations.chatReportCategoryHint: 'Wählen Sie einen Grund',
  AppTranslations.chatReportReasonLabel: 'Zusätzliche Details',
  AppTranslations.chatReportReasonHint:
      'Fügen Sie weitere Informationen hinzu, damit die Meldung geprüft werden kann.',
  AppTranslations.chatReportSubmit: 'Meldung senden',
  AppTranslations.chatReportSuccess: 'Meldung gesendet',
  AppTranslations.chatReportEmptyCategories:
      'Derzeit sind keine Meldekategorien verfügbar.',
  AppTranslations.chatReportCategoryRequired:
      'Bitte wählen Sie eine Meldekategorie aus, bevor Sie fortfahren.',
  AppTranslations.chatReportLoadFailed:
      'Meldekategorien konnten derzeit nicht geladen werden.',
  AppTranslations.chatDeleteTitle: 'Konversation löschen',
  AppTranslations.chatDeleteMessage:
      'Sind Sie sicher, dass Sie diese Konversation löschen möchten?',
  AppTranslations.chatDeleteConfirm: 'Löschen',
  AppTranslations.chatDeleted: 'Konversation erfolgreich gelöscht',
  AppTranslations.chatMessageDelete: 'Nachricht löschen',
  AppTranslations.chatMessageEdit: 'Nachricht bearbeiten',
  AppTranslations.chatMessageReply: 'Antwort',
  AppTranslations.chatMessageForward: 'Vorwärts',
  AppTranslations.chatMessageCopy: 'Kopieren',
  AppTranslations.chatStickerTitle: 'Aufkleber',
  AppTranslations.chatStickerSubtitle:
      'Wählen Sie ein Aufkleberpaket und versenden Sie sofort einen Aufkleber.',
  AppTranslations.chatStickerEmpty:
      'In diesem Paket sind keine Aufkleber verfügbar.',
  AppTranslations.chatMessageDeleteTitle: 'Nachricht löschen',
  AppTranslations.chatMessageDeleteMessage:
      'Sind Sie sicher, dass Sie diese Nachricht löschen möchten?',
  AppTranslations.chatMessageDeleted: 'Nachricht erfolgreich gelöscht',
  AppTranslations.chatMessageEditPending:
      'Für die Nachrichtenbearbeitung ist ein dedizierter API-Endpunkt erforderlich.',
  AppTranslations.callVoice: 'Sprachanruf',
  AppTranslations.callVideo: 'Videoanruf',
  AppTranslations.callConnecting: 'Verbinden...',
  AppTranslations.callWaiting: 'Warten auf den Beitritt der anderen Person',
  AppTranslations.callMicOff: 'Mikrofon aus',
  AppTranslations.callMicOn: 'Mikrofon an',
  AppTranslations.callSpeakerOn: 'Lautsprecher eingeschaltet',
  AppTranslations.callSpeakerOff: 'Lautsprecher aus',
  AppTranslations.callCameraFlip: 'Kamera wechseln',
  AppTranslations.callEnd: 'Anruf beenden',
  AppTranslations.callPermissionDenied:
      'Die Kamera- oder Mikrofonberechtigung wurde verweigert.',
  AppTranslations.callAgoraDisabled:
      'Agora-Aufrufe sind in „settings.dart“ deaktiviert.',
  AppTranslations.callAgoraMissingAppId:
      'Die Agora-App-ID fehlt in „settings.dart“.',
  AppTranslations.callRemoteJoined: 'Verbunden',
  AppTranslations.callRinging: 'Klingeln...',
  AppTranslations.callNoAnswer: 'Keine Antwort von der anderen Person.',
  AppTranslations.callDeclined: 'Der Anruf wurde abgelehnt.',
  AppTranslations.callIncoming: 'Eingehender Anruf',
  AppTranslations.callAccept: 'Akzeptiere',
  AppTranslations.callDeclineAction: 'Ablehnen',
  AppTranslations.callRecipientBusy:
      'Die andere Person ist gerade beschäftigt.',
  AppTranslations.callRecipientOffline: 'Die andere Person ist offline.',
  AppTranslations.callCallerBusy: 'Sie haben bereits einen aktiven Anruf.',
  AppTranslations.callDirectOnly:
      'Anrufe sind derzeit nur in direkten Gesprächen möglich.',
  AppTranslations.callMissingConnection:
      'Der Server hat keine vollständigen Anrufverbindungsdaten zurückgegeben.',
  AppTranslations.authFlowHeadline:
      'Zusätzlicher Authentifizierungsschritt erforderlich',
  AppTranslations.authFlowDescription:
      'Der Server hat Ihre Anmeldung akzeptiert, aber der nächste erforderliche Schritt ist: @step',
  AppTranslations.accountBannedTitle: 'Dieses Konto wurde gesperrt',
  AppTranslations.accountBannedBody:
      'Ihr Messenger-Konto ist derzeit eingeschränkt und Sie können die App derzeit nicht verwenden.',
  AppTranslations.accountBannedSupport:
      'Bitte wenden Sie sich an den Support oder den Site-Administrator, wenn Sie glauben, dass dies ein Fehler war.',
  AppTranslations.accountBannedContactSupport: 'Kontaktieren Sie den Support',
  AppTranslations.authActivationTitle: 'Aktivierung erforderlich',
  AppTranslations.authActivationDescription:
      'Geben Sie den an Ihr Konto gesendeten Bestätigungscode ein, um fortzufahren.',
  AppTranslations.authApprovalTitle: 'Genehmigung erforderlich',
  AppTranslations.authApprovalDescription:
      'Ihr Konto wartet auf die Genehmigung, bevor Messenger fortfahren kann.',
  AppTranslations.authGettingStartedTitle: 'Einstieg erforderlich',
  AppTranslations.authGettingStartedDescription:
      'Ihr Konto benötigt einen weiteren Einrichtungsschritt, bevor Messenger vollständig geöffnet werden kann.',
  AppTranslations.authTwoFactorTitle: 'Zwei-Faktor-Verifizierung',
  AppTranslations.authTwoFactorDescription:
      'Geben Sie den Verifizierungscode Ihrer konfigurierten Zwei-Faktor-Methode ein.',
  AppTranslations.verificationCode: 'Bestätigungscode',
  AppTranslations.verificationCodeHint:
      'Geben Sie den Code genau so ein, wie Sie ihn erhalten haben',
  AppTranslations.verificationCodeRequired:
      'Ein Bestätigungscode ist erforderlich',
  AppTranslations.resendCode: 'Code erneut senden',
  AppTranslations.verifyAndContinue: 'Überprüfen und fortfahren',
  AppTranslations.activationCodeSent:
      'Ein neuer Aktivierungscode wurde gesendet.',
  AppTranslations.authUnableToLoadState:
      'Ihr Authentifizierungsstatus kann derzeit nicht geladen werden.',
  AppTranslations.authUnableToVerifyCode:
      'Der Code kann derzeit nicht überprüft werden.',
  AppTranslations.authUnableToResendCode:
      'Der Code kann derzeit nicht erneut gesendet werden.',
  AppTranslations.backToLogin: 'Zurück zum Login',
  AppTranslations.loginFailed: 'Anmeldung ist momentan nicht möglich',
  AppTranslations.commonConversation: 'Gespräch',
  AppTranslations.commonChat: 'Chatten',
  AppTranslations.commonConversations: 'Gespräche',
  AppTranslations.commonPeople: 'Menschen',
  AppTranslations.commonPost: 'Beitrag',
  AppTranslations.commonStory: 'Geschichte',
  AppTranslations.commonReel: 'Rolle',
  AppTranslations.commonProduct: 'Produkt',
  AppTranslations.commonImage: 'Bild',
  AppTranslations.commonVideo: 'Video',
  AppTranslations.commonSticker: 'Aufkleber',
  AppTranslations.commonOn: 'Auf',
  AppTranslations.commonOff: 'Aus',
  AppTranslations.commonColors: 'Farben',
  AppTranslations.commonGradients: 'Farbverläufe',
  AppTranslations.commonReset: 'Zurücksetzen',
  AppTranslations.commonTimeline: 'Zeitleiste',
  AppTranslations.timelineAppNotInstalledTitle:
      'Die Timeline-App ist nicht installiert',
  AppTranslations.timelineAppNotInstalledMessage:
      'Um diesen Inhalt zu öffnen, installieren Sie zuerst die Timeline-App. Möchten Sie sie jetzt herunterladen?',
  AppTranslations.timelineAppCancelAction: 'Abbrechen',
  AppTranslations.timelineAppDownloadAction: 'Herunterladen',
  AppTranslations.sharedPost: 'Geteilter Beitrag',
  AppTranslations.sharedReel: 'Geteilte Rolle',
  AppTranslations.sharePostTitle: 'Beitrag teilen',
  AppTranslations.shareReelTitle: 'Rolle teilen',
  AppTranslations.shareSearchHint: 'Suchen Sie nach Gesprächen oder Personen',
  AppTranslations.shareEmptyTargets: 'Keine Gespräche oder Kontakte verfügbar',
  AppTranslations.profileQuickSettingsSubtitle:
      'Datenschutz, Benachrichtigungen und Einstellungen',
  AppTranslations.profileConnectAnother: 'Verbinden Sie ein anderes Profil',
  AppTranslations.profileAddAccountDisabled:
      'Das Hinzufügen von Konten ist deaktiviert',
  AppTranslations.profileIdentityEyebrow: 'IDENTITÄT',
  AppTranslations.profileSwitcherEyebrow: 'SCHALTER',
  AppTranslations.profileAttachAnotherAccount:
      'Fügen Sie ein weiteres Konto hinzu, um schnell zu wechseln',
  AppTranslations.profileNoEmailAttached: 'Keine E-Mail angehängt',
  AppTranslations.profileReadyToSwitch: 'Bereit zum Wechsel',
  AppTranslations.chatPin: 'Pin',
  AppTranslations.chatUnpin: 'Lösen',
  AppTranslations.chatConversationPinned: 'Konversation angepinnt',
  AppTranslations.chatConversationUnpinned: 'Konversation gelöst',
  AppTranslations.chatDirectConversation: 'Direkter Chat',
  AppTranslations.chatGroupConversation: 'Gruppenchat',
  AppTranslations.callsTotal: 'Insgesamt',
  AppTranslations.callsAll: 'Alle Anrufe',
  AppTranslations.callsHeroSubtitle:
      'Verfolgen Sie verpasste, angenommene und Videoanrufe in einer übersichtlichen Ansicht.',
  AppTranslations.homeRecentActivity: 'Aktuelle Aktivität',
  AppTranslations.chatSettingsSubtitle:
      'Verwalten Sie Benachrichtigungen, Pin-Status und Konversationsaktionen.',
  AppTranslations.chatBackgroundSubtitle:
      'Wählen Sie einen benutzerdefinierten Hintergrund für diese Konversation.',
  AppTranslations.chatRecordingTitle: 'Aufnahme',
  AppTranslations.chatRecordingBody:
      'Tippen Sie erneut auf das Mikrofon, um den Vorgang zu stoppen und zu senden',
  AppTranslations.chatInvalidConversationId: 'Ungültige Konversations-ID',
  AppTranslations.chatImageUnavailable: 'Bild nicht verfügbar',
  AppTranslations.chatSharedItemOpenFailed:
      'Geteiltes Element kann nicht geöffnet werden',
  AppTranslations.chatVoiceUnavailable: 'Sprachnachricht nicht verfügbar',
  AppTranslations.chatVideoUnavailable: 'Video nicht verfügbar',
  AppTranslations.chatReplyingTo: 'Antwort auf',
  AppTranslations.chatReplyToYourself: 'Ihre Nachricht',
  AppTranslations.chatReplyOriginalUnavailable:
      'Originalnachricht nicht verfügbar',
  AppTranslations.chatRepliedToStory: 'Auf eine Geschichte geantwortet',
  AppTranslations.chatReactedToStory: 'Auf eine Geschichte reagiert',
  AppTranslations.chatEditingMessage: 'Nachricht wird bearbeitet',
  AppTranslations.chatMessageCopied: 'Nachricht kopiert',
  AppTranslations.forwardTitle: 'Nachricht weiterleiten',
  AppTranslations.forwardSearchHint: 'Suchen Sie nach Gesprächen oder Personen',
  AppTranslations.forwardEmptyTargets:
      'Keine Gespräche oder Kontakte verfügbar',
  AppTranslations.forwardPreviewTitle: 'Weitergeleitete Nachricht',
  AppTranslations.forwardSent: 'Nachricht erfolgreich weitergeleitet',
};
