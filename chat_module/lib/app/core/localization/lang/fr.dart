import '../app_translations.dart';
import 'base.dart';

final Map<String, String> fr = <String, String>{
  ...buildBaseTranslations(),
  AppTranslations.appName: 'Messager',
  AppTranslations.loginHeadline: 'Bon retour dans vos conversations',
  AppTranslations.loginSubtitle:
      'Connectez-vous pour poursuivre vos discussions, gérer les comptes associés et rester proche de vos collaborateurs.',
  AppTranslations.loginIdentifierLabel: 'E-mail ou nom d\'utilisateur',
  AppTranslations.loginIdentifierHint:
      'Entrez votre email ou votre nom d\'utilisateur',
  AppTranslations.passwordLabel: 'Mot de passe',
  AppTranslations.passwordHint: 'Entrez votre mot de passe',
  AppTranslations.rememberMe: 'Souviens-toi de moi',
  AppTranslations.forgotPassword: 'Mot de passe oublié ?',
  AppTranslations.signIn: 'Connectez-vous',
  AppTranslations.createAccount: 'Créer un compte',
  AppTranslations.alreadyHaveAccount: 'Vous avez déjà un compte ?',
  AppTranslations.dontHaveAccount: 'Vous n\'avez pas de compte ?',
  AppTranslations.registerTitle: 'S\'inscrire',
  AppTranslations.registerSubtitle:
      'Remplissez les détails de votre compte pour créer un nouveau compte Messenger.',
  AppTranslations.signUpHeadline: 'Créez votre compte Messenger',
  AppTranslations.signUpSubtitle:
      'Rejoignez la conversation avec un nouveau compte et passez automatiquement à l\'étape de configuration requise suivante.',
  AppTranslations.signUpToggleTitle: 'Nouveau ici ?',
  AppTranslations.signInToggleTitle: 'Vous avez déjà un compte ?',
  AppTranslations.signUpUsernameLabel: 'Nom d\'utilisateur',
  AppTranslations.signUpUsernameHint: 'Choisissez un nom d\'utilisateur',
  AppTranslations.signUpEmailLabel: 'Adresse e-mail',
  AppTranslations.signUpEmailHint: 'Entrez votre adresse e-mail',
  AppTranslations.signUpFirstNameLabel: 'Prénom',
  AppTranslations.signUpFirstNameHint: 'Entrez votre prénom',
  AppTranslations.signUpLastNameLabel: 'Nom de famille',
  AppTranslations.signUpLastNameHint: 'Entrez votre nom de famille',
  AppTranslations.signUpGenderLabel: 'Sexe',
  AppTranslations.signUpGenderMale: 'Mâle',
  AppTranslations.signUpGenderFemale: 'Femme',
  AppTranslations.signUpConfirmPasswordLabel: 'Confirmer le mot de passe',
  AppTranslations.signUpConfirmPasswordHint: 'Ressaisissez votre mot de passe',
  AppTranslations.signUpUsernameRequired: 'Le nom d\'utilisateur est requis',
  AppTranslations.signUpUsernameTooShort:
      'Le nom d\'utilisateur doit comporter au moins 3 caractères',
  AppTranslations.signUpEmailRequired: 'L\'adresse e-mail est requise',
  AppTranslations.signUpEmailInvalid: 'Entrez une adresse e-mail valide',
  AppTranslations.signUpPasswordTooShort:
      'Le mot de passe doit contenir au moins 6 caractères',
  AppTranslations.signUpConfirmPasswordRequired:
      'Confirmer que le mot de passe est requis',
  AppTranslations.signUpPasswordsDoNotMatch:
      'Les mots de passe ne correspondent pas',
  AppTranslations.signUpFirstNameRequired: 'Le prénom est obligatoire',
  AppTranslations.signUpLastNameRequired: 'Le nom de famille est obligatoire',
  AppTranslations.signUpFailed: 'Impossible de créer le compte pour le moment',
  AppTranslations.signUpNote:
      'Après votre inscription, Messenger vous guidera automatiquement tout au long de l’activation ou de toute étape de configuration requise.',
  AppTranslations.signUpAgreementPrefix: 'J\'accepte le',
  AppTranslations.signUpAgreementAnd: 'et',
  AppTranslations.signUpAgreementSuffix: 'avant de créer mon compte.',
  AppTranslations.signUpTermsOfUse: 'Conditions d\'utilisation',
  AppTranslations.signUpPrivacyPolicy: 'Politique de confidentialité',
  AppTranslations.signUpTermsRequiredTitle: 'Approbation requise',
  AppTranslations.signUpTermsRequiredMessage:
      'Vous devez d’abord accepter les conditions d’utilisation et la politique de confidentialité.',
  AppTranslations.webViewPageTitle: 'Détails',
  AppTranslations.secureAccessNote:
      'Connexion protégée avec vérification de session adaptée à l\'appareil.',
  AppTranslations.loginFooter:
      'Conçu pour une messagerie rapide avec un flux de connexion ciblé et sécurisé.',
  AppTranslations.loginWithTimeline: 'Continuer avec le compte Timeline',
  AppTranslations.loginWithTimelineSubtitle:
      'Utilisez le compte déjà connecté dans Timeline.',
  AppTranslations.identifierRequired:
      'L\'e-mail ou le nom d\'utilisateur est requis',
  AppTranslations.passwordRequired: 'Le mot de passe est requis',
  AppTranslations.loading: 'Chargement...',
  AppTranslations.homeHeadline: 'Messages',
  AppTranslations.homeSubtitle:
      'Restez proche des personnes qui vous sont chères.',
  AppTranslations.homeWelcomeBack: 'Bon retour, @name',
  AppTranslations.homeSearchHint: 'Rechercher des conversations',
  AppTranslations.homeSearchEmptyTitle: 'Aucune conversation correspondante',
  AppTranslations.homeSearchEmptyBody:
      'Essayez un autre nom ou un autre mot-clé pour rechercher une conversation.',
  AppTranslations.addStory: 'Ajouter une histoire',
  AppTranslations.shareStory: 'Partager l\'histoire',
  AppTranslations.storyAddText: 'Ajouter du texte',
  AppTranslations.storyTextHint: 'Écrivez quelque chose...',
  AppTranslations.storyMediaHint:
      'Ajoutez une photo ou une vidéo pour partager votre histoire.',
  AppTranslations.camera: 'Appareil photo',
  AppTranslations.gallery: 'Galerie',
  AppTranslations.done: 'Terminé',
  AppTranslations.replyToStory: 'Répondre à l\'histoire',
  AppTranslations.storyReplySent: 'Réponse à l\'histoire envoyée.',
  AppTranslations.storyReactionSent: 'Réaction à l\'histoire envoyée.',
  AppTranslations.storyPublished: 'Histoire publiée.',
  AppTranslations.storyViews: 'Vues',
  AppTranslations.storyViewers: 'Téléspectateurs d\'histoires',
  AppTranslations.storyReactions: 'Réactions à l\'histoire',
  AppTranslations.noStoryViewers: 'Aucun spectateur pour l\'instant.',
  AppTranslations.noStoryReactions: 'Aucune réaction pour l\'instant.',
  AppTranslations.unableToLoadStoryViewers:
      'Impossible de charger les visionneuses d\'histoires pour le moment.',
  AppTranslations.unableToLoadStoryReactions:
      'Impossible de charger les réactions de l\'histoire pour le moment.',
  AppTranslations.unableToReplyToStory:
      'Impossible d\'envoyer la réponse à l\'histoire pour le moment.',
  AppTranslations.unableToReactToStory:
      'Impossible d\'envoyer la réaction à l\'histoire pour le moment.',
  AppTranslations.unableToPublishStory:
      'Impossible de publier l\'histoire pour le moment.',
  AppTranslations.storiesLoadFailed: 'Échec du chargement des histoires',
  AppTranslations.storyFeatureSoon:
      'La visionneuse d’histoires et la publication viennent ensuite.',
  AppTranslations.homeStoriesTitle: 'Actif maintenant',
  AppTranslations.homeChatsTitle: 'Discussions récentes',
  AppTranslations.homeTabAll: 'Tout',
  AppTranslations.homeTabUnread: 'Non lu',
  AppTranslations.homeTabGroups: 'Groupes',
  AppTranslations.homeOnlineNow: 'en ligne maintenant',
  AppTranslations.homeTypePlaceholder: 'Tapez un message',
  AppTranslations.homeStatusActive: 'Actif maintenant',
  AppTranslations.homeStatusTyping: 'En tapant...',
  AppTranslations.homeStatusSent: 'Envoyé',
  AppTranslations.homeStatusDelivered: 'Livré',
  AppTranslations.homeStatusVoice: 'Message vocal',
  AppTranslations.homeStatusMuted: 'Notifications désactivées',
  AppTranslations.homeChatsUnavailableTitle:
      'Les chats en direct ne sont pas encore prêts',
  AppTranslations.homeChatsUnavailableBody:
      'Le point de terminaison de discussion Messenger renvoie toujours une réponse d’échafaudage du serveur.',
  AppTranslations.homeChatsEmptyTitle: 'Votre boîte de réception est prête',
  AppTranslations.homeChatsEmptyBody:
      'Démarrez votre première conversation pour voir les messages, les réponses et les moments partagés apparaître ici.',
  AppTranslations.homeChatsEmptyAction: 'Démarrer une discussion',
  AppTranslations.retry: 'Réessayer',
  AppTranslations.settingsTitle: 'Paramètres',
  AppTranslations.settingsLanguage: 'Langue',
  AppTranslations.settingsArabic: 'arabe',
  AppTranslations.settingsEnglish: 'Anglais',
  AppTranslations.settingsFrench: 'Français',
  AppTranslations.settingsSpanish: 'Espagnol',
  AppTranslations.settingsPortuguese: 'Portugais',
  AppTranslations.settingsGerman: 'Allemand',
  AppTranslations.settingsTurkish: 'Turc',
  AppTranslations.settingsDutch: 'Néerlandais',
  AppTranslations.settingsItalian: 'Italien',
  AppTranslations.settingsRussian: 'russe',
  AppTranslations.settingsRomanian: 'Roumain',
  AppTranslations.settingsPortugueseBrazil: 'Portugais (Brésil)',
  AppTranslations.settingsGreek: 'grec',
  AppTranslations.settingsUkrainian: 'ukrainien',
  AppTranslations.settingsTheme: 'Thème',
  AppTranslations.settingsDarkMode: 'Mode sombre',
  AppTranslations.settingsLightMode: 'Mode lumière',
  AppTranslations.settingsLanguageSheetDescription:
      'Choisissez la langue de l\'application dans une liste propre.',
  AppTranslations.settingsHeroDescription:
      'Gérez la langue, l’apparence et l’accès au compte à partir d’un seul endroit.',
  AppTranslations.settingsPreferencesEyebrow: 'PRÉFÉRENCES',
  AppTranslations.settingsPreferencesTitle: 'Expérience d\'application',
  AppTranslations.settingsAccountEyebrow: 'COMPTE',
  AppTranslations.settingsAccountTitle: 'Séance et sécurité',
  AppTranslations.settingsBlockedUsers: 'Utilisateurs bloqués',
  AppTranslations.settingsBlockedUsersSubtitle:
      'Consultez les personnes bloquées et retirez les restrictions si nécessaire.',
  AppTranslations.blockedUsersTitle: 'Utilisateurs bloqués',
  AppTranslations.blockedUsersEmpty:
      'Aucun utilisateur bloqué n’a été trouvé pour ce compte pour le moment.',
  AppTranslations.blockedUsersUnblock: 'Débloquer',
  AppTranslations.blockedUsersUnblockTitle: 'Débloquer l’utilisateur',
  AppTranslations.blockedUsersUnblockMessage:
      'Voulez-vous retirer cet utilisateur de votre liste de blocage ?',
  AppTranslations.blockedUsersUserUnblocked: 'Utilisateur débloqué avec succès',
  AppTranslations.settingsDeleteAccount: 'Supprimer le compte',
  AppTranslations.settingsDeleteAccountSubtitle:
      'Supprimez définitivement ce compte et l’accès à Messenger.',
  AppTranslations.settingsDeleteAccountTitle: 'Supprimer le compte',
  AppTranslations.settingsDeleteAccountMessage:
      'Cette action est définitive. Voulez-vous vraiment supprimer votre compte ?',
  AppTranslations.settingsDeleteAccountConfirm: 'Supprimer le compte',
  AppTranslations.settingsDeleteAccountSuccess:
      'Votre compte a été supprimé avec succès',
  AppTranslations.settingsLogoutSubtitle:
      'Se déconnecter de la session en cours sur cet appareil',
  AppTranslations.settingsLogout: 'Se déconnecter',
  AppTranslations.settingsLogoutTitle: 'Se déconnecter',
  AppTranslations.settingsLogoutMessage:
      'Êtes-vous sûr de vouloir vous déconnecter de Messenger sur cet appareil ?',
  AppTranslations.settingsLogoutTimelineBridgeMessage:
      'Vous serez déconnecté de Messenger uniquement. Votre session Timeline restera connectée sur cet appareil.',
  AppTranslations.settingsLogoutCancel: 'Annuler',
  AppTranslations.settingsLogoutConfirm: 'Se déconnecter',
  AppTranslations.settingsLegalEyebrow: 'LÉGAL',
  AppTranslations.settingsLegalTitle: 'Confidentialité et conditions',
  AppTranslations.settingsPrivacyPolicy: 'Politique de confidentialité',
  AppTranslations.settingsPrivacyPolicySubtitle:
      'Découvrez comment Ukraina.co-Chat collecte, utilise et protège les données du compte.',
  AppTranslations.settingsTermsOfUse: 'Conditions d\'utilisation',
  AppTranslations.settingsTermsOfUseSubtitle:
      'Lisez les règles, responsabilités et conditions d’utilisation de Ukraina.co-Chat.',
  AppTranslations.navChats: 'Discussions',
  AppTranslations.navCalls: 'Appels',
  AppTranslations.navProfile: 'Profil',
  AppTranslations.navSettings: 'Paramètres',
  AppTranslations.composeTitle: 'Nouvelle conversation',
  AppTranslations.composeSearchHint: 'Rechercher des amis',
  AppTranslations.composeSelectContact: 'Sélectionnez d\'abord un ami',
  AppTranslations.composeOpenConversation: 'Conversation ouverte',
  AppTranslations.composeContactsUnavailable:
      'Les contacts apparaîtront ici dès que le point de terminaison sera prêt.',
  AppTranslations.composeNoContacts: 'Aucun contact disponible pour le moment.',
  AppTranslations.composeRecipientId: 'ID utilisateur du destinataire',
  AppTranslations.composeRecipientHint:
      'Entrez l\'identifiant de l\'utilisateur',
  AppTranslations.composeMessage: 'Premier message',
  AppTranslations.composeMessageHint: 'Écrivez votre message',
  AppTranslations.composeSend: 'Envoyer',
  AppTranslations.composeRecipientRequired:
      'L\'ID utilisateur du destinataire est requis',
  AppTranslations.composeMessageRequired: 'Le message est requis',
  AppTranslations.callsPlaceholder:
      'L\'onglet Appels est prêt pour la prochaine étape de l\'API.',
  AppTranslations.callsEmptyTitle: 'Aucun appel pour l\'instant',
  AppTranslations.callsEmptyBody:
      'Vos récents appels vocaux et vidéo apparaîtront ici.',
  AppTranslations.callsIncoming: 'Entrant',
  AppTranslations.callsOutgoing: 'Sortant',
  AppTranslations.callsMissed: 'Manqué',
  AppTranslations.callsDeclined: 'Refusé',
  AppTranslations.callsAnswered: 'Répondu',
  AppTranslations.callsOpenChat: 'Ouvrir le chat',
  AppTranslations.profilePlaceholder:
      'L\'onglet Profil est réservé aux détails du compte et de l\'identité.',
  AppTranslations.profileCurrentAccount: 'Compte courant',
  AppTranslations.profileConnectedAccounts: 'Comptes connectés',
  AppTranslations.profileAddAccount: 'Ajouter un compte',
  AppTranslations.profileSwitchAccount: 'Changer',
  AppTranslations.profileRemoveAccount: 'Supprimer',
  AppTranslations.profileRevokeAccount: 'Révoquer',
  AppTranslations.profileAccountUsername: 'Nom d\'utilisateur',
  AppTranslations.profileAccountEmail: 'Courriel',
  AppTranslations.profileAccountStatus: 'Statut du compte',
  AppTranslations.profileAccountCurrent: 'Actuel',
  AppTranslations.profileAccountMaster: 'Maître',
  AppTranslations.profileNoConnectedAccounts:
      'Aucun compte connecté n\'a encore été trouvé.',
  AppTranslations.profileAddAccountTitle: 'Ajouter un compte connecté',
  AppTranslations.profileAddAccountIdentifier: 'E-mail ou nom d\'utilisateur',
  AppTranslations.profileAddAccountIdentifierHint:
      'Entrez l\'e-mail ou le nom d\'utilisateur du compte lié',
  AppTranslations.profileAddAccountPassword: 'Mot de passe du compte',
  AppTranslations.profileAddAccountConfirm: 'Connecter le compte',
  AppTranslations.profileAddAccountSuccess:
      'Compte connecté ajouté avec succès',
  AppTranslations.profileSwitchAccountSuccess:
      'Le compte a été changé avec succès',
  AppTranslations.profileRemoveAccountTitle: 'Supprimer le compte connecté',
  AppTranslations.profileRemoveAccountMessage:
      'Êtes-vous sûr de vouloir supprimer ce compte connecté ?',
  AppTranslations.profileRemoveAccountSuccess:
      'Compte connecté supprimé avec succès',
  AppTranslations.profileRevokeAccountTitle: 'Révoquer la connexion au compte',
  AppTranslations.profileRevokeAccountMessage:
      'Êtes-vous sûr de vouloir révoquer la connexion principale liée actuelle ?',
  AppTranslations.profileRevokeAccountSuccess:
      'Connexion au compte révoquée avec succès',
  AppTranslations.profileManageSettings: 'Ouvrir les paramètres',
  AppTranslations.profileTimelineBridgeActive:
      'La session Timeline Bridge est active sur cet appareil.',
  AppTranslations.profileLinkedAccountsDisabled:
      'Le changement de compte connecté est désactivé pour ce compte.',
  AppTranslations.profileAccountAdded: 'Compte connecté',
  AppTranslations.profileAccountEmptyField:
      'L\'e-mail/nom d\'utilisateur et le mot de passe sont requis',
  AppTranslations.chatOnlineNow: 'En ligne maintenant',
  AppTranslations.chatSeen: 'Vu',
  AppTranslations.chatInputHint: 'Tapez un message',
  AppTranslations.chatInfoTitle: 'Informations sur le chat',
  AppTranslations.chatInfoSharedMedia: 'Médias partagés',
  AppTranslations.chatInfoSettings: 'Paramètres de discussion',
  AppTranslations.chatInfoAll: 'Tout',
  AppTranslations.chatInfoImages: 'Images',
  AppTranslations.chatInfoVideos: 'Vidéos',
  AppTranslations.chatInfoAudio: 'Audio',
  AppTranslations.chatInfoFiles: 'Fichiers',
  AppTranslations.chatInfoLinks: 'Liens',
  AppTranslations.chatInfoNoSharedMedia:
      'Aucun contenu partagé trouvé pour cette conversation.',
  AppTranslations.chatInfoOpen: 'Ouvert',
  AppTranslations.chatSettingBackground: 'Fond de discussion',
  AppTranslations.chatSettingMute: 'Désactiver les notifications',
  AppTranslations.chatSettingPin: 'Épingler le chat',
  AppTranslations.chatSettingBlock: 'Bloquer l\'utilisateur',
  AppTranslations.chatSettingReport: 'Signaler l\'utilisateur',
  AppTranslations.chatSettingReportSubtitle:
      'Envoyez un signalement de sécurité concernant ce compte.',
  AppTranslations.chatSettingDelete: 'Supprimer la conversation',
  AppTranslations.chatSettingApiPending:
      'Ce paramètre attend le point de terminaison de l\'API dédié.',
  AppTranslations.chatReportTitle: 'Signaler l\'utilisateur',
  AppTranslations.chatReportDescription:
      'Choisissez la raison de ce signalement. Ukraina.co-Chat l’enverra à l’équipe de modération pour examen.',
  AppTranslations.chatReportCategoryLabel: 'Catégorie du signalement',
  AppTranslations.chatReportCategoryHint: 'Choisissez une raison',
  AppTranslations.chatReportReasonLabel: 'Détails supplémentaires',
  AppTranslations.chatReportReasonHint:
      'Ajoutez plus de contexte pour aider à examiner ce signalement.',
  AppTranslations.chatReportSubmit: 'Envoyer le signalement',
  AppTranslations.chatReportSuccess: 'Signalement envoyé',
  AppTranslations.chatReportEmptyCategories:
      'Aucune catégorie de signalement n’est disponible pour le moment.',
  AppTranslations.chatReportCategoryRequired:
      'Veuillez choisir une catégorie de signalement avant de continuer.',
  AppTranslations.chatReportLoadFailed:
      'Impossible de charger les catégories de signalement pour le moment.',
  AppTranslations.chatDeleteTitle: 'Supprimer la conversation',
  AppTranslations.chatDeleteMessage:
      'Êtes-vous sûr de vouloir supprimer cette conversation ?',
  AppTranslations.chatDeleteConfirm: 'Supprimer',
  AppTranslations.chatDeleted: 'Conversation supprimée avec succès',
  AppTranslations.chatMessageDelete: 'Supprimer le message',
  AppTranslations.chatMessageEdit: 'Modifier le message',
  AppTranslations.chatMessageReply: 'Répondre',
  AppTranslations.chatMessageForward: 'En avant',
  AppTranslations.chatMessageCopy: 'Copier',
  AppTranslations.chatStickerTitle: 'Autocollants',
  AppTranslations.chatStickerSubtitle:
      'Choisissez un pack d\'autocollants et envoyez un autocollant instantanément.',
  AppTranslations.chatStickerEmpty:
      'Aucun autocollant disponible dans ce pack.',
  AppTranslations.chatMessageDeleteTitle: 'Supprimer le message',
  AppTranslations.chatMessageDeleteMessage:
      'Êtes-vous sûr de vouloir supprimer ce message ?',
  AppTranslations.chatMessageDeleted: 'Message supprimé avec succès',
  AppTranslations.chatMessageEditPending:
      'L’édition des messages nécessite un point de terminaison d’API dédié.',
  AppTranslations.callVoice: 'Appel vocal',
  AppTranslations.callVideo: 'Appel vidéo',
  AppTranslations.callConnecting: 'Connexion...',
  AppTranslations.callWaiting: 'En attendant que l\'autre personne rejoigne',
  AppTranslations.callMicOff: 'Micro éteint',
  AppTranslations.callMicOn: 'Micro activé',
  AppTranslations.callSpeakerOn: 'Haut-parleur activé',
  AppTranslations.callSpeakerOff: 'Haut-parleur éteint',
  AppTranslations.callCameraFlip: 'Changer de caméra',
  AppTranslations.callEnd: 'Terminer l\'appel',
  AppTranslations.callPermissionDenied:
      'L\'autorisation de la caméra ou du microphone a été refusée.',
  AppTranslations.callAgoraDisabled:
      'Les appels Agora sont désactivés dans settings.dart.',
  AppTranslations.callAgoraMissingAppId:
      'L\'ID de l\'application Agora est manquant dans settings.dart.',
  AppTranslations.callRemoteJoined: 'Connecté',
  AppTranslations.callRinging: 'Sonnerie...',
  AppTranslations.callNoAnswer: 'Aucune réponse de l\'autre personne.',
  AppTranslations.callDeclined: 'L\'appel a été refusé.',
  AppTranslations.callIncoming: 'Appel entrant',
  AppTranslations.callAccept: 'Accepter',
  AppTranslations.callDeclineAction: 'Refuser',
  AppTranslations.callRecipientBusy:
      'L’autre personne est occupée en ce moment.',
  AppTranslations.callRecipientOffline: 'L\'autre personne est hors ligne.',
  AppTranslations.callCallerBusy: 'Vous avez déjà un appel actif.',
  AppTranslations.callDirectOnly:
      'Les appels ne sont disponibles que dans les conversations directes pour le moment.',
  AppTranslations.callMissingConnection:
      'Le serveur n\'a pas renvoyé les données complètes de connexion d\'appel.',
  AppTranslations.authFlowHeadline:
      'Étape d\'authentification supplémentaire requise',
  AppTranslations.authFlowDescription:
      'Le serveur a accepté votre connexion, mais la prochaine étape requise est : @step',
  AppTranslations.accountBannedTitle: 'Ce compte a été banni',
  AppTranslations.accountBannedBody:
      'Votre compte Messenger est actuellement restreint et vous ne pouvez pas utiliser l\'application pour le moment.',
  AppTranslations.accountBannedSupport:
      'Veuillez contacter le support ou l\'administrateur du site si vous pensez que cela s\'est produit par erreur.',
  AppTranslations.accountBannedContactSupport: 'Contacter l\'assistance',
  AppTranslations.authActivationTitle: 'Activation requise',
  AppTranslations.authActivationDescription:
      'Saisissez le code de vérification envoyé à votre compte pour continuer.',
  AppTranslations.authApprovalTitle: 'Approbation requise',
  AppTranslations.authApprovalDescription:
      'Votre compte est en attente d\'approbation avant que Messenger puisse continuer.',
  AppTranslations.authGettingStartedTitle: 'Prise en main obligatoire',
  AppTranslations.authGettingStartedDescription:
      'Votre compte nécessite une étape de configuration supplémentaire avant que Messenger puisse s\'ouvrir complètement.',
  AppTranslations.authTwoFactorTitle: 'Vérification à deux facteurs',
  AppTranslations.authTwoFactorDescription:
      'Entrez le code de vérification de votre méthode à deux facteurs configurée.',
  AppTranslations.verificationCode: 'Code de vérification',
  AppTranslations.verificationCodeHint:
      'Entrez le code exactement tel que reçu',
  AppTranslations.verificationCodeRequired:
      'Un code de vérification est requis',
  AppTranslations.resendCode: 'Renvoyer le code',
  AppTranslations.verifyAndContinue: 'Vérifier et continuer',
  AppTranslations.activationCodeSent:
      'Un nouveau code d\'activation a été envoyé.',
  AppTranslations.authUnableToLoadState:
      'Impossible de charger votre état d\'authentification pour le moment.',
  AppTranslations.authUnableToVerifyCode:
      'Impossible de vérifier le code pour le moment.',
  AppTranslations.authUnableToResendCode:
      'Impossible de renvoyer le code pour le moment.',
  AppTranslations.backToLogin: 'Retour à la connexion',
  AppTranslations.loginFailed: 'Impossible de se connecter pour le moment',
  AppTranslations.commonConversation: 'Conversation',
  AppTranslations.commonChat: 'Discuter',
  AppTranslations.commonConversations: 'Conversations',
  AppTranslations.commonPeople: 'Les gens',
  AppTranslations.commonPost: 'Publier',
  AppTranslations.commonStory: 'Histoire',
  AppTranslations.commonReel: 'Bobine',
  AppTranslations.commonProduct: 'Produit',
  AppTranslations.commonImage: 'Images',
  AppTranslations.commonVideo: 'Vidéo',
  AppTranslations.commonSticker: 'Autocollant',
  AppTranslations.commonOn: 'Sur',
  AppTranslations.commonOff: 'Désactivé',
  AppTranslations.commonColors: 'Couleurs',
  AppTranslations.commonGradients: 'Dégradés',
  AppTranslations.commonReset: 'Réinitialiser',
  AppTranslations.commonTimeline: 'Chronologie',
  AppTranslations.timelineAppNotInstalledTitle:
      'L’application Timeline n’est pas installée',
  AppTranslations.timelineAppNotInstalledMessage:
      'Pour ouvrir ce contenu, installez d’abord l’application Timeline. Voulez-vous la télécharger maintenant ?',
  AppTranslations.timelineAppCancelAction: 'Annuler',
  AppTranslations.timelineAppDownloadAction: 'Télécharger',
  AppTranslations.sharedPost: 'Publication partagée',
  AppTranslations.sharedReel: 'Bobine partagée',
  AppTranslations.sharePostTitle: 'Partager la publication',
  AppTranslations.shareReelTitle: 'Partager la bobine',
  AppTranslations.shareSearchHint:
      'Rechercher des conversations ou des personnes',
  AppTranslations.shareEmptyTargets:
      'Aucune conversation ou contact disponible',
  AppTranslations.profileQuickSettingsSubtitle:
      'Confidentialité, notifications et préférences',
  AppTranslations.profileConnectAnother: 'Connecter un autre profil',
  AppTranslations.profileAddAccountDisabled:
      'L\'ajout de comptes est désactivé',
  AppTranslations.profileIdentityEyebrow: 'IDENTITÉ',
  AppTranslations.profileSwitcherEyebrow: 'COMMUTATEUR',
  AppTranslations.profileAttachAnotherAccount:
      'Attachez un autre compte pour un changement rapide',
  AppTranslations.profileNoEmailAttached: 'Aucun email en pièce jointe',
  AppTranslations.profileReadyToSwitch: 'Prêt à changer',
  AppTranslations.chatPin: 'Épingle',
  AppTranslations.chatUnpin: 'Désépingler',
  AppTranslations.chatConversationPinned: 'Conversation épinglée',
  AppTranslations.chatConversationUnpinned: 'Conversation désépinglée',
  AppTranslations.chatDirectConversation: 'Chat direct',
  AppTranslations.chatGroupConversation: 'Discussion de groupe',
  AppTranslations.callsTotal: 'Total',
  AppTranslations.callsAll: 'Tous les appels',
  AppTranslations.callsHeroSubtitle:
      'Suivez les appels manqués, répondus et vidéo dans une seule vue raffinée.',
  AppTranslations.homeRecentActivity: 'Activité récente',
  AppTranslations.chatSettingsSubtitle:
      'Gérez les notifications, l\'état des broches et les actions de conversation.',
  AppTranslations.chatBackgroundSubtitle:
      'Choisissez un arrière-plan personnalisé pour cette conversation.',
  AppTranslations.chatRecordingTitle: 'Enregistrement',
  AppTranslations.chatRecordingBody:
      'Appuyez à nouveau sur le microphone pour arrêter et envoyer',
  AppTranslations.chatInvalidConversationId:
      'Identifiant de conversation invalide',
  AppTranslations.chatImageUnavailable: 'Image indisponible',
  AppTranslations.chatSharedItemOpenFailed:
      'Impossible d\'ouvrir l\'élément partagé',
  AppTranslations.chatVoiceUnavailable: 'Message vocal indisponible',
  AppTranslations.chatVideoUnavailable: 'Vidéo indisponible',
  AppTranslations.chatReplyingTo: 'Répondre à',
  AppTranslations.chatReplyToYourself: 'Votre message',
  AppTranslations.chatReplyOriginalUnavailable:
      'Message d\'origine indisponible',
  AppTranslations.chatRepliedToStory: 'J\'ai répondu à une histoire',
  AppTranslations.chatReactedToStory: 'J\'ai réagi à une histoire',
  AppTranslations.chatEditingMessage: 'Modification du message',
  AppTranslations.chatMessageCopied: 'Message copié',
  AppTranslations.forwardTitle: 'Transférer le message',
  AppTranslations.forwardSearchHint:
      'Rechercher des conversations ou des personnes',
  AppTranslations.forwardEmptyTargets:
      'Aucune conversation ou contact disponible',
  AppTranslations.forwardPreviewTitle: 'Message transféré',
  AppTranslations.forwardSent: 'Message transféré avec succès',
};
