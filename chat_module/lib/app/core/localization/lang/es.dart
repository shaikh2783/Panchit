import '../app_translations.dart';
import 'base.dart';

final Map<String, String> es = <String, String>{
  ...buildBaseTranslations(),
  AppTranslations.appName: 'mensajero',
  AppTranslations.loginHeadline: 'Bienvenido de nuevo a tus conversaciones.',
  AppTranslations.loginSubtitle:
      'Inicia sesión para continuar tus chats, administrar cuentas vinculadas y mantenerte cerca de tu gente.',
  AppTranslations.loginIdentifierLabel:
      'Correo electrónico o nombre de usuario',
  AppTranslations.loginIdentifierHint:
      'Introduce tu correo electrónico o nombre de usuario',
  AppTranslations.passwordLabel: 'Contraseña',
  AppTranslations.passwordHint: 'Introduce tu contraseña',
  AppTranslations.rememberMe: 'Recuérdame',
  AppTranslations.forgotPassword: '¿Olvidaste tu contraseña?',
  AppTranslations.signIn: 'Iniciar sesión',
  AppTranslations.createAccount: 'Crear cuenta',
  AppTranslations.alreadyHaveAccount: '¿Ya tienes una cuenta?',
  AppTranslations.dontHaveAccount: '¿No tienes una cuenta?',
  AppTranslations.registerTitle: 'Registrarse',
  AppTranslations.registerSubtitle:
      'Complete los detalles de su cuenta para crear una nueva cuenta de Messenger.',
  AppTranslations.signUpHeadline: 'Crea tu cuenta de mensajería',
  AppTranslations.signUpSubtitle:
      'Únase a la conversación con una cuenta nueva y continúe automáticamente con el siguiente paso de configuración requerido.',
  AppTranslations.signUpToggleTitle: '¿Nuevo aquí?',
  AppTranslations.signInToggleTitle: '¿Ya tienes una cuenta?',
  AppTranslations.signUpUsernameLabel: 'Nombre de usuario',
  AppTranslations.signUpUsernameHint: 'Elige un nombre de usuario',
  AppTranslations.signUpEmailLabel: 'Dirección de correo electrónico',
  AppTranslations.signUpEmailHint:
      'Introduce tu dirección de correo electrónico',
  AppTranslations.signUpFirstNameLabel: 'nombre',
  AppTranslations.signUpFirstNameHint: 'Introduce tu nombre',
  AppTranslations.signUpLastNameLabel: 'apellido',
  AppTranslations.signUpLastNameHint: 'Introduce tu apellido',
  AppTranslations.signUpGenderLabel: 'Género',
  AppTranslations.signUpGenderMale: 'masculino',
  AppTranslations.signUpGenderFemale: 'Mujer',
  AppTranslations.signUpConfirmPasswordLabel: 'Confirmar contraseña',
  AppTranslations.signUpConfirmPasswordHint: 'Vuelva a ingresar su contraseña',
  AppTranslations.signUpUsernameRequired: 'El nombre de usuario es obligatorio',
  AppTranslations.signUpUsernameTooShort:
      'El nombre de usuario debe tener al menos 3 caracteres.',
  AppTranslations.signUpEmailRequired:
      'Se requiere dirección de correo electrónico',
  AppTranslations.signUpEmailInvalid:
      'Introduzca una dirección de correo electrónico válida',
  AppTranslations.signUpPasswordTooShort:
      'La contraseña debe tener al menos 6 caracteres.',
  AppTranslations.signUpConfirmPasswordRequired:
      'Se requiere confirmar la contraseña',
  AppTranslations.signUpPasswordsDoNotMatch: 'Las contraseñas no coinciden',
  AppTranslations.signUpFirstNameRequired: 'El nombre es obligatorio',
  AppTranslations.signUpLastNameRequired: 'Se requiere apellido',
  AppTranslations.signUpFailed: 'No se puede crear la cuenta en este momento',
  AppTranslations.signUpNote:
      'Después de registrarse, Messenger lo guiará automáticamente a través de la activación o cualquier paso de configuración requerido.',
  AppTranslations.signUpAgreementPrefix: 'Estoy de acuerdo con el',
  AppTranslations.signUpAgreementAnd: 'y',
  AppTranslations.signUpAgreementSuffix: 'antes de crear mi cuenta.',
  AppTranslations.signUpTermsOfUse: 'Términos de uso',
  AppTranslations.signUpPrivacyPolicy: 'Política de privacidad',
  AppTranslations.signUpTermsRequiredTitle: 'Se requiere aprobación',
  AppTranslations.signUpTermsRequiredMessage:
      'Primero debe aceptar los Términos de uso y la Política de privacidad.',
  AppTranslations.webViewPageTitle: 'Detalles',
  AppTranslations.secureAccessNote:
      'Inicio de sesión protegido con verificación de sesión basada en el dispositivo.',
  AppTranslations.loginFooter:
      'Creado para mensajería rápida con un flujo de inicio de sesión seguro y enfocado.',
  AppTranslations.loginWithTimeline: 'Continuar con la cuenta Timeline',
  AppTranslations.loginWithTimelineSubtitle:
      'Utilice la cuenta que ya inició sesión dentro de Timeline.',
  AppTranslations.identifierRequired:
      'Se requiere correo electrónico o nombre de usuario',
  AppTranslations.passwordRequired: 'Se requiere contraseña',
  AppTranslations.loading: 'Cargando...',
  AppTranslations.homeHeadline: 'Mensajes',
  AppTranslations.homeSubtitle:
      'Mantente cerca de las personas que te importan.',
  AppTranslations.homeWelcomeBack: 'Bienvenido de nuevo, @nombre',
  AppTranslations.homeSearchHint: 'Buscar conversaciones',
  AppTranslations.homeSearchEmptyTitle: 'No hay conversaciones coincidentes',
  AppTranslations.homeSearchEmptyBody:
      'Pruebe con otro nombre o palabra clave para encontrar una conversación.',
  AppTranslations.addStory: 'Agregar historia',
  AppTranslations.shareStory: 'Compartir historia',
  AppTranslations.storyAddText: 'Agregar texto',
  AppTranslations.storyTextHint: 'Escribe algo...',
  AppTranslations.storyMediaHint:
      'Agrega una foto o un video para compartir tu historia.',
  AppTranslations.camera: 'cámara',
  AppTranslations.gallery: 'Galería',
  AppTranslations.done: 'hecho',
  AppTranslations.replyToStory: 'Responder a la historia',
  AppTranslations.storyReplySent: 'Respuesta de la historia enviada.',
  AppTranslations.storyReactionSent: 'Reacción de la historia enviada.',
  AppTranslations.storyPublished: 'Cuento publicado.',
  AppTranslations.storyViews: 'Vistas',
  AppTranslations.storyViewers: 'Espectadores de historias',
  AppTranslations.storyReactions: 'Reacciones de la historia',
  AppTranslations.noStoryViewers: 'Aún no hay espectadores.',
  AppTranslations.noStoryReactions: 'Aún no hay reacciones.',
  AppTranslations.unableToLoadStoryViewers:
      'No se pueden cargar los visores de historias en este momento.',
  AppTranslations.unableToLoadStoryReactions:
      'No se pueden cargar las reacciones de la historia en este momento.',
  AppTranslations.unableToReplyToStory:
      'No se puede enviar la respuesta a la historia en este momento.',
  AppTranslations.unableToReactToStory:
      'No se puede enviar la reacción de la historia en este momento.',
  AppTranslations.unableToPublishStory:
      'No se puede publicar la historia en este momento.',
  AppTranslations.storiesLoadFailed: 'No se pudieron cargar las historias',
  AppTranslations.storyFeatureSoon:
      'El visor de historias y la publicación vienen a continuación.',
  AppTranslations.homeStoriesTitle: 'Activo ahora',
  AppTranslations.homeChatsTitle: 'Chats recientes',
  AppTranslations.homeTabAll: 'Todos',
  AppTranslations.homeTabUnread: 'No leído',
  AppTranslations.homeTabGroups: 'Grupos',
  AppTranslations.homeOnlineNow: 'en línea ahora',
  AppTranslations.homeTypePlaceholder: 'Escribe un mensaje',
  AppTranslations.homeStatusActive: 'Activo ahora',
  AppTranslations.homeStatusTyping: 'Escribiendo...',
  AppTranslations.homeStatusSent: 'Enviado',
  AppTranslations.homeStatusDelivered: 'Entregado',
  AppTranslations.homeStatusVoice: 'Mensaje de voz',
  AppTranslations.homeStatusMuted: 'Notificaciones silenciadas',
  AppTranslations.homeChatsUnavailableTitle:
      'Los chats en vivo aún no están listos',
  AppTranslations.homeChatsUnavailableBody:
      'El punto final del chat de Messenger todavía devuelve una respuesta de andamiaje del servidor.',
  AppTranslations.homeChatsEmptyTitle: 'Tu bandeja de entrada está lista',
  AppTranslations.homeChatsEmptyBody:
      'Inicie su primera conversación para ver mensajes, respuestas y momentos compartidos que aparecen aquí.',
  AppTranslations.homeChatsEmptyAction: 'Iniciar un chat',
  AppTranslations.retry: 'Reintentar',
  AppTranslations.settingsTitle: 'Configuración',
  AppTranslations.settingsLanguage: 'Idioma',
  AppTranslations.settingsArabic: 'árabe',
  AppTranslations.settingsEnglish: 'ingles',
  AppTranslations.settingsFrench: 'francés',
  AppTranslations.settingsSpanish: 'español',
  AppTranslations.settingsPortuguese: 'portugués',
  AppTranslations.settingsGerman: 'alemán',
  AppTranslations.settingsTurkish: 'turco',
  AppTranslations.settingsDutch: 'holandés',
  AppTranslations.settingsItalian: 'italiano',
  AppTranslations.settingsRussian: 'ruso',
  AppTranslations.settingsRomanian: 'rumano',
  AppTranslations.settingsPortugueseBrazil: 'Portugués (Brasil)',
  AppTranslations.settingsGreek: 'griego',
  AppTranslations.settingsUkrainian: 'ucranio',
  AppTranslations.settingsTheme: 'Tema',
  AppTranslations.settingsDarkMode: 'modo oscuro',
  AppTranslations.settingsLightMode: 'Modo de luz',
  AppTranslations.settingsLanguageSheetDescription:
      'Elija el idioma de la aplicación de una lista limpia.',
  AppTranslations.settingsHeroDescription:
      'Administre el idioma, la apariencia y el acceso a la cuenta desde un solo lugar.',
  AppTranslations.settingsPreferencesEyebrow: 'PREFERENCIAS',
  AppTranslations.settingsPreferencesTitle: 'Experiencia de aplicación',
  AppTranslations.settingsAccountEyebrow: 'CUENTA',
  AppTranslations.settingsAccountTitle: 'Sesión y seguridad',
  AppTranslations.settingsBlockedUsers: 'Usuarios bloqueados',
  AppTranslations.settingsBlockedUsersSubtitle:
      'Revisa las personas bloqueadas y elimina las restricciones cuando sea necesario.',
  AppTranslations.blockedUsersTitle: 'Usuarios bloqueados',
  AppTranslations.blockedUsersEmpty:
      'No se encontraron usuarios bloqueados para esta cuenta en este momento.',
  AppTranslations.blockedUsersUnblock: 'Desbloquear',
  AppTranslations.blockedUsersUnblockTitle: 'Desbloquear usuario',
  AppTranslations.blockedUsersUnblockMessage:
      '¿Quieres eliminar a este usuario de tu lista de bloqueados?',
  AppTranslations.blockedUsersUserUnblocked:
      'Usuario desbloqueado correctamente',
  AppTranslations.settingsDeleteAccount: 'Eliminar cuenta',
  AppTranslations.settingsDeleteAccountSubtitle:
      'Elimina esta cuenta de forma permanente y borra el acceso a Messenger.',
  AppTranslations.settingsDeleteAccountTitle: 'Eliminar cuenta',
  AppTranslations.settingsDeleteAccountMessage:
      'Esta acción es permanente. ¿Seguro que quieres eliminar tu cuenta?',
  AppTranslations.settingsDeleteAccountConfirm: 'Eliminar cuenta',
  AppTranslations.settingsDeleteAccountSuccess:
      'Tu cuenta ha sido eliminada correctamente',
  AppTranslations.settingsLogoutSubtitle:
      'Cerrar sesión en la sesión actual en este dispositivo',
  AppTranslations.settingsLogout: 'Cerrar sesión',
  AppTranslations.settingsLogoutTitle: 'Cerrar sesión',
  AppTranslations.settingsLogoutMessage:
      '¿Estás seguro de que deseas cerrar sesión en Messenger en este dispositivo?',
  AppTranslations.settingsLogoutTimelineBridgeMessage:
      'Se cerrará tu sesión únicamente en Messenger. Su sesión de Timeline permanecerá iniciada en este dispositivo.',
  AppTranslations.settingsLogoutCancel: 'Cancelar',
  AppTranslations.settingsLogoutConfirm: 'Cerrar sesión',
  AppTranslations.settingsLegalEyebrow: 'LEGAL',
  AppTranslations.settingsLegalTitle: 'Privacidad y términos',
  AppTranslations.settingsPrivacyPolicy: 'Política de privacidad',
  AppTranslations.settingsPrivacyPolicySubtitle:
      'Revisa cómo Ukraina.co-Chat recopila, usa y protege los datos de la cuenta.',
  AppTranslations.settingsTermsOfUse: 'Términos de uso',
  AppTranslations.settingsTermsOfUseSubtitle:
      'Lee las reglas, responsabilidades y términos de uso de Ukraina.co-Chat.',
  AppTranslations.navChats: 'Charlas',
  AppTranslations.navCalls: 'llamadas',
  AppTranslations.navProfile: 'Perfil',
  AppTranslations.navSettings: 'Configuración',
  AppTranslations.composeTitle: 'Nueva conversación',
  AppTranslations.composeSearchHint: 'buscar amigos',
  AppTranslations.composeSelectContact: 'Selecciona un amigo primero',
  AppTranslations.composeOpenConversation: 'Conversacion abierta',
  AppTranslations.composeContactsUnavailable:
      'Los contactos aparecerán aquí tan pronto como el punto final esté listo.',
  AppTranslations.composeNoContacts:
      'No hay contactos disponibles en este momento.',
  AppTranslations.composeRecipientId: 'ID de usuario del destinatario',
  AppTranslations.composeRecipientHint: 'Introduzca el ID de usuario',
  AppTranslations.composeMessage: 'primer mensaje',
  AppTranslations.composeMessageHint: 'Escribe tu mensaje',
  AppTranslations.composeSend: 'enviar',
  AppTranslations.composeRecipientRequired:
      'Se requiere ID de usuario del destinatario',
  AppTranslations.composeMessageRequired: 'Se requiere mensaje',
  AppTranslations.callsPlaceholder:
      'La pestaña Llamadas está lista para el siguiente paso de la API.',
  AppTranslations.callsEmptyTitle: 'Aún no hay llamadas',
  AppTranslations.callsEmptyBody:
      'Tus llamadas de voz y video recientes aparecerán aquí.',
  AppTranslations.callsIncoming: 'entrante',
  AppTranslations.callsOutgoing: 'saliente',
  AppTranslations.callsMissed: 'perdido',
  AppTranslations.callsDeclined: 'Rechazado',
  AppTranslations.callsAnswered: 'Respondido',
  AppTranslations.callsOpenChat: 'abrir chat',
  AppTranslations.profilePlaceholder:
      'La pestaña Perfil está reservada para detalles de cuenta e identidad.',
  AppTranslations.profileCurrentAccount: 'cuenta corriente',
  AppTranslations.profileConnectedAccounts: 'Cuentas conectadas',
  AppTranslations.profileAddAccount: 'Agregar cuenta',
  AppTranslations.profileSwitchAccount: 'Cambiar',
  AppTranslations.profileRemoveAccount: 'Quitar',
  AppTranslations.profileRevokeAccount: 'Revocar',
  AppTranslations.profileAccountUsername: 'Nombre de usuario',
  AppTranslations.profileAccountEmail: 'Correo electrónico',
  AppTranslations.profileAccountStatus: 'Estado de la cuenta',
  AppTranslations.profileAccountCurrent: 'Actual',
  AppTranslations.profileAccountMaster: 'maestro',
  AppTranslations.profileNoConnectedAccounts:
      'Aún no se encontraron cuentas conectadas.',
  AppTranslations.profileAddAccountTitle: 'Agregar cuenta conectada',
  AppTranslations.profileAddAccountIdentifier:
      'Correo electrónico o nombre de usuario',
  AppTranslations.profileAddAccountIdentifierHint:
      'Ingrese el correo electrónico o el nombre de usuario de la cuenta vinculada',
  AppTranslations.profileAddAccountPassword: 'Contraseña de cuenta',
  AppTranslations.profileAddAccountConfirm: 'Conectar cuenta',
  AppTranslations.profileAddAccountSuccess:
      'Cuenta conectada agregada exitosamente',
  AppTranslations.profileSwitchAccountSuccess: 'Cuenta cambiada exitosamente',
  AppTranslations.profileRemoveAccountTitle: 'Eliminar cuenta conectada',
  AppTranslations.profileRemoveAccountMessage:
      '¿Estás seguro de que deseas eliminar esta cuenta conectada?',
  AppTranslations.profileRemoveAccountSuccess:
      'La cuenta conectada se eliminó correctamente',
  AppTranslations.profileRevokeAccountTitle: 'Revocar la conexión de la cuenta',
  AppTranslations.profileRevokeAccountMessage:
      '¿Está seguro de que desea revocar la conexión maestra vinculada actual?',
  AppTranslations.profileRevokeAccountSuccess:
      'Conexión de cuenta revocada exitosamente',
  AppTranslations.profileManageSettings: 'Abrir configuración',
  AppTranslations.profileTimelineBridgeActive:
      'La sesión puente de la línea de tiempo está activa en este dispositivo.',
  AppTranslations.profileLinkedAccountsDisabled:
      'El cambio de cuenta conectada está deshabilitado para esta cuenta.',
  AppTranslations.profileAccountAdded: 'Cuenta conectada',
  AppTranslations.profileAccountEmptyField:
      'Se requiere correo electrónico/nombre de usuario y contraseña',
  AppTranslations.chatOnlineNow: 'En línea ahora',
  AppTranslations.chatSeen: 'Visto',
  AppTranslations.chatInputHint: 'Escribe un mensaje',
  AppTranslations.chatInfoTitle: 'información de chat',
  AppTranslations.chatInfoSharedMedia: 'Medios compartidos',
  AppTranslations.chatInfoSettings: 'Configuración de chat',
  AppTranslations.chatInfoAll: 'Todos',
  AppTranslations.chatInfoImages: 'Imágenes',
  AppTranslations.chatInfoVideos: 'Vídeos',
  AppTranslations.chatInfoAudio: 'Audio',
  AppTranslations.chatInfoFiles: 'Archivos',
  AppTranslations.chatInfoLinks: 'Enlaces',
  AppTranslations.chatInfoNoSharedMedia:
      'No se encontró contenido compartido para esta conversación.',
  AppTranslations.chatInfoOpen: 'Abierto',
  AppTranslations.chatSettingBackground: 'Fondo de chat',
  AppTranslations.chatSettingMute: 'Silenciar notificaciones',
  AppTranslations.chatSettingPin: 'Fijar chat',
  AppTranslations.chatSettingBlock: 'Bloquear usuario',
  AppTranslations.chatSettingReport: 'Reportar usuario',
  AppTranslations.chatSettingReportSubtitle:
      'Envía un reporte de seguridad sobre esta cuenta.',
  AppTranslations.chatSettingDelete: 'Eliminar conversación',
  AppTranslations.chatSettingApiPending:
      'Esta configuración está esperando el punto final de API dedicado.',
  AppTranslations.chatReportTitle: 'Reportar usuario',
  AppTranslations.chatReportDescription:
      'Elige el motivo de este reporte. Ukraina.co-Chat lo enviará al equipo de moderación para su revisión.',
  AppTranslations.chatReportCategoryLabel: 'Categoría del reporte',
  AppTranslations.chatReportCategoryHint: 'Selecciona un motivo',
  AppTranslations.chatReportReasonLabel: 'Detalles adicionales',
  AppTranslations.chatReportReasonHint:
      'Agrega más contexto para ayudar a revisar este reporte.',
  AppTranslations.chatReportSubmit: 'Enviar reporte',
  AppTranslations.chatReportSuccess: 'Reporte enviado',
  AppTranslations.chatReportEmptyCategories:
      'No hay categorías de reporte disponibles en este momento.',
  AppTranslations.chatReportCategoryRequired:
      'Selecciona una categoría de reporte antes de continuar.',
  AppTranslations.chatReportLoadFailed:
      'No se pudieron cargar las categorías de reporte en este momento.',
  AppTranslations.chatDeleteTitle: 'Eliminar conversación',
  AppTranslations.chatDeleteMessage:
      '¿Estás seguro de que deseas eliminar esta conversación?',
  AppTranslations.chatDeleteConfirm: 'Eliminar',
  AppTranslations.chatDeleted: 'Conversación eliminada exitosamente',
  AppTranslations.chatMessageDelete: 'Eliminar mensaje',
  AppTranslations.chatMessageEdit: 'Editar mensaje',
  AppTranslations.chatMessageReply: 'Responder',
  AppTranslations.chatMessageForward: 'Adelante',
  AppTranslations.chatMessageCopy: 'Copiar',
  AppTranslations.chatStickerTitle: 'Pegatinas',
  AppTranslations.chatStickerSubtitle:
      'Elija un paquete de pegatinas y envíe una pegatina al instante.',
  AppTranslations.chatStickerEmpty:
      'No hay pegatinas disponibles en este paquete.',
  AppTranslations.chatMessageDeleteTitle: 'Eliminar mensaje',
  AppTranslations.chatMessageDeleteMessage:
      '¿Estás seguro de que deseas eliminar este mensaje?',
  AppTranslations.chatMessageDeleted: 'Mensaje eliminado exitosamente',
  AppTranslations.chatMessageEditPending:
      'La edición de mensajes necesita un punto final API dedicado.',
  AppTranslations.callVoice: 'llamada de voz',
  AppTranslations.callVideo: 'Videollamada',
  AppTranslations.callConnecting: 'Conectando...',
  AppTranslations.callWaiting: 'Esperando a que la otra persona se una',
  AppTranslations.callMicOff: 'Micrófono apagado',
  AppTranslations.callMicOn: 'Micrófono encendido',
  AppTranslations.callSpeakerOn: 'Altavoz encendido',
  AppTranslations.callSpeakerOff: 'Altavoz apagado',
  AppTranslations.callCameraFlip: 'Cambiar cámara',
  AppTranslations.callEnd: 'finalizar llamada',
  AppTranslations.callPermissionDenied:
      'Se denegó el permiso de la cámara o el micrófono.',
  AppTranslations.callAgoraDisabled:
      'Las llamadas Agora están deshabilitadas en settings.dart.',
  AppTranslations.callAgoraMissingAppId:
      'Falta el ID de la aplicación Agora en settings.dart.',
  AppTranslations.callRemoteJoined: 'Conectado',
  AppTranslations.callRinging: 'Sonando...',
  AppTranslations.callNoAnswer: 'No hay respuesta de la otra persona.',
  AppTranslations.callDeclined: 'La llamada fue rechazada.',
  AppTranslations.callIncoming: 'llamada entrante',
  AppTranslations.callAccept: 'Aceptar',
  AppTranslations.callDeclineAction: 'Rechazar',
  AppTranslations.callRecipientBusy:
      'La otra persona está ocupada ahora mismo.',
  AppTranslations.callRecipientOffline: 'La otra persona está desconectada.',
  AppTranslations.callCallerBusy: 'Ya tienes una llamada activa.',
  AppTranslations.callDirectOnly:
      'Las llamadas solo están disponibles en conversaciones directas en este momento.',
  AppTranslations.callMissingConnection:
      'El servidor no devolvió datos completos de conexión de llamada.',
  AppTranslations.authFlowHeadline:
      'Se requiere un paso de autenticación adicional',
  AppTranslations.authFlowDescription:
      'El servidor aceptó su inicio de sesión, pero el siguiente paso requerido es: @step',
  AppTranslations.accountBannedTitle: 'Esta cuenta ha sido baneada.',
  AppTranslations.accountBannedBody:
      'Su cuenta de Messenger está actualmente restringida y no puede usar la aplicación en este momento.',
  AppTranslations.accountBannedSupport:
      'Comuníquese con el soporte o con el administrador del sitio si cree que esto sucedió por error.',
  AppTranslations.accountBannedContactSupport: 'Contactar con soporte',
  AppTranslations.authActivationTitle: 'Se requiere activación',
  AppTranslations.authActivationDescription:
      'Ingrese el código de verificación enviado a su cuenta para continuar.',
  AppTranslations.authApprovalTitle: 'Se requiere aprobación',
  AppTranslations.authApprovalDescription:
      'Tu cuenta está esperando aprobación antes de que Messenger pueda continuar.',
  AppTranslations.authGettingStartedTitle: 'Es necesario empezar',
  AppTranslations.authGettingStartedDescription:
      'Su cuenta necesita un paso de configuración más antes de que Messenger pueda abrirse por completo.',
  AppTranslations.authTwoFactorTitle: 'Verificación de dos factores',
  AppTranslations.authTwoFactorDescription:
      'Ingrese el código de verificación de su método de dos factores configurado.',
  AppTranslations.verificationCode: 'Código de verificación',
  AppTranslations.verificationCodeHint:
      'Ingrese el código exactamente como lo recibió',
  AppTranslations.verificationCodeRequired:
      'Se requiere código de verificación',
  AppTranslations.resendCode: 'Reenviar código',
  AppTranslations.verifyAndContinue: 'Verificar y continuar',
  AppTranslations.activationCodeSent:
      'Se ha enviado un nuevo código de activación.',
  AppTranslations.authUnableToLoadState:
      'No se puede cargar su estado de autenticación en este momento.',
  AppTranslations.authUnableToVerifyCode:
      'No se puede verificar el código en este momento.',
  AppTranslations.authUnableToResendCode:
      'No se puede reenviar el código en este momento.',
  AppTranslations.backToLogin: 'Volver a iniciar sesión',
  AppTranslations.loginFailed: 'No se puede iniciar sesión en este momento',
  AppTranslations.commonConversation: 'Conversación',
  AppTranslations.commonChat: 'Charla',
  AppTranslations.commonConversations: 'Conversaciones',
  AppTranslations.commonPeople: 'gente',
  AppTranslations.commonPost: 'Publicar',
  AppTranslations.commonStory: 'historia',
  AppTranslations.commonReel: 'carrete',
  AppTranslations.commonProduct: 'Producto',
  AppTranslations.commonImage: 'Imagen',
  AppTranslations.commonVideo: 'Vídeo',
  AppTranslations.commonSticker: 'Pegatina',
  AppTranslations.commonOn: 'encendido',
  AppTranslations.commonOff: 'Apagado',
  AppTranslations.commonColors: 'Colores',
  AppTranslations.commonGradients: 'Degradados',
  AppTranslations.commonReset: 'Reiniciar',
  AppTranslations.commonTimeline: 'Línea de tiempo',
  AppTranslations.timelineAppNotInstalledTitle:
      'La aplicación Timeline no está instalada',
  AppTranslations.timelineAppNotInstalledMessage:
      'Para abrir este contenido, primero instala la aplicación Timeline. ¿Quieres descargarla ahora?',
  AppTranslations.timelineAppCancelAction: 'Cancelar',
  AppTranslations.timelineAppDownloadAction: 'Descargar',
  AppTranslations.sharedPost: 'Publicación compartida',
  AppTranslations.sharedReel: 'carrete compartido',
  AppTranslations.sharePostTitle: 'Compartir publicación',
  AppTranslations.shareReelTitle: 'Compartir carrete',
  AppTranslations.shareSearchHint: 'Buscar conversaciones o personas',
  AppTranslations.shareEmptyTargets:
      'No hay conversaciones ni contactos disponibles.',
  AppTranslations.profileQuickSettingsSubtitle:
      'Privacidad, notificaciones y preferencias',
  AppTranslations.profileConnectAnother: 'Conectar otro perfil',
  AppTranslations.profileAddAccountDisabled:
      'Agregar cuentas está deshabilitado',
  AppTranslations.profileIdentityEyebrow: 'IDENTIDAD',
  AppTranslations.profileSwitcherEyebrow: 'CONMUTADOR',
  AppTranslations.profileAttachAnotherAccount:
      'Adjunte otra cuenta para cambiar rápidamente',
  AppTranslations.profileNoEmailAttached: 'No hay correo electrónico adjunto',
  AppTranslations.profileReadyToSwitch: 'Listo para cambiar',
  AppTranslations.chatPin: 'Alfiler',
  AppTranslations.chatUnpin: 'Desanclar',
  AppTranslations.chatConversationPinned: 'Conversación fijada',
  AppTranslations.chatConversationUnpinned: 'Conversación desbloqueada',
  AppTranslations.chatDirectConversation: 'chat directo',
  AppTranslations.chatGroupConversation: 'Chat grupal',
  AppTranslations.callsTotal: 'totales',
  AppTranslations.callsAll: 'todas las llamadas',
  AppTranslations.callsHeroSubtitle:
      'Realice un seguimiento de las videollamadas perdidas, respondidas y en una vista pulida.',
  AppTranslations.homeRecentActivity: 'Actividad reciente',
  AppTranslations.chatSettingsSubtitle:
      'Administre notificaciones, estado de pin y acciones de conversación.',
  AppTranslations.chatBackgroundSubtitle:
      'Elija un fondo personalizado para esta conversación.',
  AppTranslations.chatRecordingTitle: 'Grabación',
  AppTranslations.chatRecordingBody:
      'Toque el micrófono nuevamente para detener y enviar',
  AppTranslations.chatInvalidConversationId: 'ID de conversación no válida',
  AppTranslations.chatImageUnavailable: 'Imagen no disponible',
  AppTranslations.chatSharedItemOpenFailed:
      'No se puede abrir el elemento compartido',
  AppTranslations.chatVoiceUnavailable: 'Mensaje de voz no disponible',
  AppTranslations.chatVideoUnavailable: 'Vídeo no disponible',
  AppTranslations.chatReplyingTo: 'Respondiendo a',
  AppTranslations.chatReplyToYourself: 'tu mensaje',
  AppTranslations.chatReplyOriginalUnavailable:
      'Mensaje original no disponible',
  AppTranslations.chatRepliedToStory: 'Respondió a una historia',
  AppTranslations.chatReactedToStory: 'reaccionó a una historia',
  AppTranslations.chatEditingMessage: 'Editando mensaje',
  AppTranslations.chatMessageCopied: 'Mensaje copiado',
  AppTranslations.forwardTitle: 'Reenviar mensaje',
  AppTranslations.forwardSearchHint: 'Buscar conversaciones o personas',
  AppTranslations.forwardEmptyTargets:
      'No hay conversaciones ni contactos disponibles.',
  AppTranslations.forwardPreviewTitle: 'mensaje reenviado',
  AppTranslations.forwardSent: 'Mensaje reenviado exitosamente',
};
