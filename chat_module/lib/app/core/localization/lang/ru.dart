import '../app_translations.dart';
import 'base.dart';

final Map<String, String> ru = <String, String>{
  ...buildBaseTranslations(),
  AppTranslations.appName: 'Мессенджер',
  AppTranslations.loginHeadline: 'Добро пожаловать обратно в ваши беседы',
  AppTranslations.loginSubtitle:
      'Войдите в систему, чтобы продолжить общение, управлять связанными учетными записями и оставаться рядом со своими людьми.',
  AppTranslations.loginIdentifierLabel:
      'Электронная почта или имя пользователя',
  AppTranslations.loginIdentifierHint:
      'Введите адрес электронной почты или имя пользователя',
  AppTranslations.passwordLabel: 'Пароль',
  AppTranslations.passwordHint: 'Введите свой пароль',
  AppTranslations.rememberMe: 'Запомни меня',
  AppTranslations.forgotPassword: 'Забыли пароль?',
  AppTranslations.signIn: 'Войти',
  AppTranslations.createAccount: 'Создать учетную запись',
  AppTranslations.alreadyHaveAccount: 'У вас уже есть аккаунт?',
  AppTranslations.dontHaveAccount: 'У вас нет учетной записи?',
  AppTranslations.registerTitle: 'Зарегистрироваться',
  AppTranslations.registerSubtitle:
      'Заполните данные своей учетной записи, чтобы создать новую учетную запись Messenger.',
  AppTranslations.signUpHeadline: 'Создайте свою учетную запись Мессенджера',
  AppTranslations.signUpSubtitle:
      'Присоединяйтесь к разговору с новой учетной записью и автоматически переходите к следующему необходимому шагу настройки.',
  AppTranslations.signUpToggleTitle: 'Впервые здесь?',
  AppTranslations.signInToggleTitle: 'У вас уже есть аккаунт?',
  AppTranslations.signUpUsernameLabel: 'Имя пользователя',
  AppTranslations.signUpUsernameHint: 'Выберите имя пользователя',
  AppTranslations.signUpEmailLabel: 'Адрес электронной почты',
  AppTranslations.signUpEmailHint: 'Введите свой адрес электронной почты',
  AppTranslations.signUpFirstNameLabel: 'Имя',
  AppTranslations.signUpFirstNameHint: 'Введите свое имя',
  AppTranslations.signUpLastNameLabel: 'Фамилия',
  AppTranslations.signUpLastNameHint: 'Введите свою фамилию',
  AppTranslations.signUpGenderLabel: 'Пол',
  AppTranslations.signUpGenderMale: 'Мужской',
  AppTranslations.signUpGenderFemale: 'Женский',
  AppTranslations.signUpConfirmPasswordLabel: 'Подтвердите пароль',
  AppTranslations.signUpConfirmPasswordHint: 'Повторно введите свой пароль',
  AppTranslations.signUpUsernameRequired: 'Требуется имя пользователя',
  AppTranslations.signUpUsernameTooShort:
      'Имя пользователя должно быть не менее 3 символов',
  AppTranslations.signUpEmailRequired: 'Требуется адрес электронной почты',
  AppTranslations.signUpEmailInvalid:
      'Введите действительный адрес электронной почты',
  AppTranslations.signUpPasswordTooShort:
      'Пароль должен быть не менее 6 символов',
  AppTranslations.signUpConfirmPasswordRequired:
      'Требуется подтверждение пароля',
  AppTranslations.signUpPasswordsDoNotMatch: 'Пароли не совпадают',
  AppTranslations.signUpFirstNameRequired: 'Требуется имя',
  AppTranslations.signUpLastNameRequired: 'Требуется фамилия',
  AppTranslations.signUpFailed:
      'Невозможно создать учетную запись прямо сейчас',
  AppTranslations.signUpNote:
      'После регистрации Messenger автоматически проведет вас через активацию или любой необходимый этап настройки.',
  AppTranslations.signUpAgreementPrefix: 'Я согласен на',
  AppTranslations.signUpAgreementAnd: 'и',
  AppTranslations.signUpAgreementSuffix:
      'прежде чем создать свою учетную запись.',
  AppTranslations.signUpTermsOfUse: 'Условия использования',
  AppTranslations.signUpPrivacyPolicy: 'Политика конфиденциальности',
  AppTranslations.signUpTermsRequiredTitle: 'Требуется одобрение',
  AppTranslations.signUpTermsRequiredMessage:
      'Сначала вы должны согласиться с Условиями использования и Политикой конфиденциальности.',
  AppTranslations.webViewPageTitle: 'Подробности',
  AppTranslations.secureAccessNote:
      'Защищенный вход с проверкой сеанса с учетом устройства.',
  AppTranslations.loginFooter:
      'Создано для быстрого обмена сообщениями с целенаправленным и безопасным процессом входа в систему.',
  AppTranslations.loginWithTimeline: 'Продолжить с учетной записью Timeline',
  AppTranslations.loginWithTimelineSubtitle:
      'Используйте учетную запись, в которую уже выполнен вход в Timeline.',
  AppTranslations.identifierRequired:
      'Требуется адрес электронной почты или имя пользователя',
  AppTranslations.passwordRequired: 'Требуется пароль',
  AppTranslations.loading: 'Загрузка...',
  AppTranslations.homeHeadline: 'Сообщения',
  AppTranslations.homeSubtitle: 'Будьте рядом с людьми, которые вам дороги.',
  AppTranslations.homeWelcomeBack: 'С возвращением, @name',
  AppTranslations.homeSearchHint: 'Поиск бесед',
  AppTranslations.homeSearchEmptyTitle: 'Нет подходящих разговоров',
  AppTranslations.homeSearchEmptyBody:
      'Попробуйте другое имя или ключевое слово, чтобы найти разговор.',
  AppTranslations.addStory: 'Добавить историю',
  AppTranslations.shareStory: 'Поделиться историей',
  AppTranslations.storyAddText: 'Добавить текст',
  AppTranslations.storyTextHint: 'Напишите что-нибудь...',
  AppTranslations.storyMediaHint:
      'Добавьте фото или видео, чтобы поделиться своей историей.',
  AppTranslations.camera: 'Камера',
  AppTranslations.gallery: 'Галерея',
  AppTranslations.done: 'Готово',
  AppTranslations.replyToStory: 'Ответ на историю',
  AppTranslations.storyReplySent: 'Ответ на историю отправлен.',
  AppTranslations.storyReactionSent: 'Реакция на историю отправлена.',
  AppTranslations.storyPublished: 'Рассказ опубликован.',
  AppTranslations.storyViews: 'Просмотры',
  AppTranslations.storyViewers: 'Зрители историй',
  AppTranslations.storyReactions: 'Реакции на истории',
  AppTranslations.noStoryViewers: 'Зрителей пока нет.',
  AppTranslations.noStoryReactions: 'Реакций пока нет.',
  AppTranslations.unableToLoadStoryViewers:
      'Сейчас невозможно загрузить средства просмотра историй.',
  AppTranslations.unableToLoadStoryReactions:
      'Невозможно загрузить реакции на историю прямо сейчас.',
  AppTranslations.unableToReplyToStory:
      'Невозможно отправить ответ на историю прямо сейчас.',
  AppTranslations.unableToReactToStory:
      'Невозможно отправить реакцию на историю прямо сейчас.',
  AppTranslations.unableToPublishStory:
      'Невозможно опубликовать историю прямо сейчас.',
  AppTranslations.storiesLoadFailed: 'Не удалось загрузить истории.',
  AppTranslations.storyFeatureSoon:
      'Следующими будут просмотрщик историй и публикация.',
  AppTranslations.homeStoriesTitle: 'Активен сейчас',
  AppTranslations.homeChatsTitle: 'Недавние чаты',
  AppTranslations.homeTabAll: 'Все',
  AppTranslations.homeTabUnread: 'Непрочитано',
  AppTranslations.homeTabGroups: 'Группы',
  AppTranslations.homeOnlineNow: 'сейчас онлайн',
  AppTranslations.homeTypePlaceholder: 'Введите сообщение',
  AppTranslations.homeStatusActive: 'Активен сейчас',
  AppTranslations.homeStatusTyping: 'Ввод...',
  AppTranslations.homeStatusSent: 'Отправлено',
  AppTranslations.homeStatusDelivered: 'Доставлено',
  AppTranslations.homeStatusVoice: 'Голосовое сообщение',
  AppTranslations.homeStatusMuted: 'Уведомления отключены',
  AppTranslations.homeChatsUnavailableTitle: 'Живые чаты еще не готовы',
  AppTranslations.homeChatsUnavailableBody:
      'Конечная точка чата Messenger по-прежнему возвращает ответ scaffold от сервера.',
  AppTranslations.homeChatsEmptyTitle: 'Ваш почтовый ящик готов',
  AppTranslations.homeChatsEmptyBody:
      'Начните свой первый разговор, чтобы увидеть здесь сообщения, ответы и общие моменты.',
  AppTranslations.homeChatsEmptyAction: 'Начать чат',
  AppTranslations.retry: 'Повторить попытку',
  AppTranslations.settingsTitle: 'Настройки',
  AppTranslations.settingsLanguage: 'Язык',
  AppTranslations.settingsArabic: 'арабский',
  AppTranslations.settingsEnglish: 'английский',
  AppTranslations.settingsFrench: 'французский',
  AppTranslations.settingsSpanish: 'испанский',
  AppTranslations.settingsPortuguese: 'португальский',
  AppTranslations.settingsGerman: 'немецкий',
  AppTranslations.settingsTurkish: 'турецкий',
  AppTranslations.settingsDutch: 'голландский',
  AppTranslations.settingsItalian: 'итальянский',
  AppTranslations.settingsRussian: 'русский',
  AppTranslations.settingsRomanian: 'румынский',
  AppTranslations.settingsPortugueseBrazil: 'Португальский (Бразилия)',
  AppTranslations.settingsGreek: 'Греческий',
  AppTranslations.settingsUkrainian: 'Украинский',
  AppTranslations.settingsTheme: 'Тема',
  AppTranslations.settingsDarkMode: 'Темный режим',
  AppTranslations.settingsLightMode: 'Светлый режим',
  AppTranslations.settingsLanguageSheetDescription:
      'Выберите язык приложения из чистого списка.',
  AppTranslations.settingsHeroDescription:
      'Управляйте языком, внешним видом и доступом к учетной записи из одного места.',
  AppTranslations.settingsPreferencesEyebrow: 'ПРЕДПОЧТЕНИЯ',
  AppTranslations.settingsPreferencesTitle: 'Опыт работы с приложением',
  AppTranslations.settingsAccountEyebrow: 'СЧЕТ',
  AppTranslations.settingsAccountTitle: 'Сессия и безопасность',
  AppTranslations.settingsBlockedUsers: 'Заблокированные пользователи',
  AppTranslations.settingsBlockedUsersSubtitle:
      'Просматривайте заблокированных людей и снимайте ограничения при необходимости.',
  AppTranslations.blockedUsersTitle: 'Заблокированные пользователи',
  AppTranslations.blockedUsersEmpty:
      'Для этой учетной записи сейчас нет заблокированных пользователей.',
  AppTranslations.blockedUsersUnblock: 'Разблокировать',
  AppTranslations.blockedUsersUnblockTitle: 'Разблокировать пользователя',
  AppTranslations.blockedUsersUnblockMessage:
      'Вы хотите удалить этого пользователя из списка заблокированных?',
  AppTranslations.blockedUsersUserUnblocked:
      'Пользователь успешно разблокирован',
  AppTranslations.settingsDeleteAccount: 'Удалить аккаунт',
  AppTranslations.settingsDeleteAccountSubtitle:
      'Навсегда удалите этот аккаунт и доступ к Messenger.',
  AppTranslations.settingsDeleteAccountTitle: 'Удалить аккаунт',
  AppTranslations.settingsDeleteAccountMessage:
      'Это действие необратимо. Вы уверены, что хотите удалить свой аккаунт?',
  AppTranslations.settingsDeleteAccountConfirm: 'Удалить аккаунт',
  AppTranslations.settingsDeleteAccountSuccess:
      'Ваш аккаунт был успешно удален',
  AppTranslations.settingsLogoutSubtitle:
      'Выйти из текущего сеанса на этом устройстве',
  AppTranslations.settingsLogout: 'Выйти',
  AppTranslations.settingsLogoutTitle: 'Выйти',
  AppTranslations.settingsLogoutMessage:
      'Вы уверены, что хотите выйти из Messenger на этом устройстве?',
  AppTranslations.settingsLogoutTimelineBridgeMessage:
      'Вы выйдете только из Messenger. Ваш сеанс временной шкалы останется в системе на этом устройстве.',
  AppTranslations.settingsLogoutCancel: 'Отмена',
  AppTranslations.settingsLogoutConfirm: 'Выйти',
  AppTranslations.settingsLegalEyebrow: 'ЮРИДИЧЕСКОЕ',
  AppTranslations.settingsLegalTitle: 'Конфиденциальность и условия',
  AppTranslations.settingsPrivacyPolicy: 'Политика конфиденциальности',
  AppTranslations.settingsPrivacyPolicySubtitle:
      'Узнайте, как Ukraina.co-Chat собирает, использует и защищает данные аккаунта.',
  AppTranslations.settingsTermsOfUse: 'Условия использования',
  AppTranslations.settingsTermsOfUseSubtitle:
      'Прочитайте правила, обязанности и условия использования Ukraina.co-Chat.',
  AppTranslations.navChats: 'Чаты',
  AppTranslations.navCalls: 'Звонки',
  AppTranslations.navProfile: 'Профиль',
  AppTranslations.navSettings: 'Настройки',
  AppTranslations.composeTitle: 'Новый разговор',
  AppTranslations.composeSearchHint: 'Поиск друзей',
  AppTranslations.composeSelectContact: 'Сначала выберите друга',
  AppTranslations.composeOpenConversation: 'Открытый разговор',
  AppTranslations.composeContactsUnavailable:
      'Контакты появятся здесь, как только конечная точка будет готова.',
  AppTranslations.composeNoContacts:
      'На данный момент нет доступных контактов.',
  AppTranslations.composeRecipientId: 'Идентификатор пользователя получателя',
  AppTranslations.composeRecipientHint: 'Введите идентификатор пользователя',
  AppTranslations.composeMessage: 'Первое сообщение',
  AppTranslations.composeMessageHint: 'Напишите свое сообщение',
  AppTranslations.composeSend: 'Отправить',
  AppTranslations.composeRecipientRequired:
      'Требуется идентификатор пользователя получателя.',
  AppTranslations.composeMessageRequired: 'Требуется сообщение',
  AppTranslations.callsPlaceholder:
      'Вкладка «Вызовы» готова к следующему шагу API.',
  AppTranslations.callsEmptyTitle: 'Пока нет звонков',
  AppTranslations.callsEmptyBody:
      'Здесь появятся ваши недавние голосовые и видеовызовы.',
  AppTranslations.callsIncoming: 'Входящий',
  AppTranslations.callsOutgoing: 'Исходящий',
  AppTranslations.callsMissed: 'Пропущен',
  AppTranslations.callsDeclined: 'Отклонено',
  AppTranslations.callsAnswered: 'Ответил',
  AppTranslations.callsOpenChat: 'Открыть чат',
  AppTranslations.profilePlaceholder:
      'Вкладка «Профиль» зарезервирована для сведений об учетной записи и личности.',
  AppTranslations.profileCurrentAccount: 'Текущий счет',
  AppTranslations.profileConnectedAccounts: 'Подключенные аккаунты',
  AppTranslations.profileAddAccount: 'Добавить аккаунт',
  AppTranslations.profileSwitchAccount: 'Переключатель',
  AppTranslations.profileRemoveAccount: 'Удалить',
  AppTranslations.profileRevokeAccount: 'Отозвать',
  AppTranslations.profileAccountUsername: 'Имя пользователя',
  AppTranslations.profileAccountEmail: 'электронная почта',
  AppTranslations.profileAccountStatus: 'Статус аккаунта',
  AppTranslations.profileAccountCurrent: 'Текущий',
  AppTranslations.profileAccountMaster: 'Мастер',
  AppTranslations.profileNoConnectedAccounts:
      'Подключенных аккаунтов пока не обнаружено.',
  AppTranslations.profileAddAccountTitle: 'Добавить подключенный аккаунт',
  AppTranslations.profileAddAccountIdentifier:
      'Электронная почта или имя пользователя',
  AppTranslations.profileAddAccountIdentifierHint:
      'Введите адрес электронной почты связанной учетной записи или имя пользователя.',
  AppTranslations.profileAddAccountPassword: 'Пароль учетной записи',
  AppTranslations.profileAddAccountConfirm: 'Подключить аккаунт',
  AppTranslations.profileAddAccountSuccess:
      'Подключенная учетная запись успешно добавлена',
  AppTranslations.profileSwitchAccountSuccess: 'Аккаунт успешно переключен',
  AppTranslations.profileRemoveAccountTitle: 'Удалить подключенный аккаунт',
  AppTranslations.profileRemoveAccountMessage:
      'Вы уверены, что хотите удалить эту подключенную учетную запись?',
  AppTranslations.profileRemoveAccountSuccess:
      'Подключенная учетная запись успешно удалена',
  AppTranslations.profileRevokeAccountTitle: 'Отменить подключение к аккаунту',
  AppTranslations.profileRevokeAccountMessage:
      'Вы уверены, что хотите отменить текущее связанное главное соединение?',
  AppTranslations.profileRevokeAccountSuccess:
      'Подключение к аккаунту успешно отозвано',
  AppTranslations.profileManageSettings: 'Открыть настройки',
  AppTranslations.profileTimelineBridgeActive:
      'На этом устройстве активен сеанс Timeline Bridge.',
  AppTranslations.profileLinkedAccountsDisabled:
      'Для этой учетной записи отключено переключение подключенных учетных записей.',
  AppTranslations.profileAccountAdded: 'Аккаунт подключен',
  AppTranslations.profileAccountEmptyField:
      'Требуется адрес электронной почты/имя пользователя и пароль.',
  AppTranslations.chatOnlineNow: 'Сейчас онлайн',
  AppTranslations.chatSeen: 'видел',
  AppTranslations.chatInputHint: 'Введите сообщение',
  AppTranslations.chatInfoTitle: 'Информация о чате',
  AppTranslations.chatInfoSharedMedia: 'Общие медиа',
  AppTranslations.chatInfoSettings: 'Настройки чата',
  AppTranslations.chatInfoAll: 'Все',
  AppTranslations.chatInfoImages: 'Изображения',
  AppTranslations.chatInfoVideos: 'Видео',
  AppTranslations.chatInfoAudio: 'Аудио',
  AppTranslations.chatInfoFiles: 'Файлы',
  AppTranslations.chatInfoLinks: 'Ссылки',
  AppTranslations.chatInfoNoSharedMedia:
      'Для этого разговора не найден общий контент.',
  AppTranslations.chatInfoOpen: 'Открыть',
  AppTranslations.chatSettingBackground: 'Фон чата',
  AppTranslations.chatSettingMute: 'Отключить уведомления',
  AppTranslations.chatSettingPin: 'Закрепить чат',
  AppTranslations.chatSettingBlock: 'Заблокировать пользователя',
  AppTranslations.chatSettingReport: 'Пожаловаться на пользователя',
  AppTranslations.chatSettingReportSubtitle:
      'Отправьте жалобу по безопасности на этот аккаунт.',
  AppTranslations.chatSettingDelete: 'Удалить разговор',
  AppTranslations.chatSettingApiPending:
      'Этот параметр ожидает выделенной конечной точки API.',
  AppTranslations.chatReportTitle: 'Пожаловаться на пользователя',
  AppTranslations.chatReportDescription:
      'Выберите причину жалобы. Ukraina.co-Chat отправит ее команде модерации на рассмотрение.',
  AppTranslations.chatReportCategoryLabel: 'Категория жалобы',
  AppTranslations.chatReportCategoryHint: 'Выберите причину',
  AppTranslations.chatReportReasonLabel: 'Дополнительные сведения',
  AppTranslations.chatReportReasonHint:
      'Добавьте больше контекста, чтобы помочь в рассмотрении этой жалобы.',
  AppTranslations.chatReportSubmit: 'Отправить жалобу',
  AppTranslations.chatReportSuccess: 'Жалоба отправлена',
  AppTranslations.chatReportEmptyCategories:
      'Категории жалоб сейчас недоступны.',
  AppTranslations.chatReportCategoryRequired:
      'Пожалуйста, выберите категорию жалобы перед продолжением.',
  AppTranslations.chatReportLoadFailed:
      'Не удалось загрузить категории жалоб прямо сейчас.',
  AppTranslations.chatDeleteTitle: 'Удалить разговор',
  AppTranslations.chatDeleteMessage:
      'Вы уверены, что хотите удалить этот разговор?',
  AppTranslations.chatDeleteConfirm: 'Удалить',
  AppTranslations.chatDeleted: 'Разговор успешно удален',
  AppTranslations.chatMessageDelete: 'Удалить сообщение',
  AppTranslations.chatMessageEdit: 'Редактировать сообщение',
  AppTranslations.chatMessageReply: 'Ответить',
  AppTranslations.chatMessageForward: 'Вперед',
  AppTranslations.chatMessageCopy: 'Копировать',
  AppTranslations.chatStickerTitle: 'Наклейки',
  AppTranslations.chatStickerSubtitle:
      'Выберите набор стикеров и мгновенно отправьте его.',
  AppTranslations.chatStickerEmpty: 'В этом наборе нет наклеек.',
  AppTranslations.chatMessageDeleteTitle: 'Удалить сообщение',
  AppTranslations.chatMessageDeleteMessage:
      'Вы уверены, что хотите удалить это сообщение?',
  AppTranslations.chatMessageDeleted: 'Сообщение успешно удалено',
  AppTranslations.chatMessageEditPending:
      'Для редактирования сообщений требуется выделенная конечная точка API.',
  AppTranslations.callVoice: 'Голосовой вызов',
  AppTranslations.callVideo: 'Видеозвонок',
  AppTranslations.callConnecting: 'Подключение...',
  AppTranslations.callWaiting: 'Ожидание подключения другого человека',
  AppTranslations.callMicOff: 'Микрофон выключен',
  AppTranslations.callMicOn: 'Микрофон включен',
  AppTranslations.callSpeakerOn: 'Динамик включен',
  AppTranslations.callSpeakerOff: 'Динамик выключен',
  AppTranslations.callCameraFlip: 'Переключить камеру',
  AppTranslations.callEnd: 'Завершить вызов',
  AppTranslations.callPermissionDenied:
      'Разрешение на использование камеры или микрофона было отклонено.',
  AppTranslations.callAgoraDisabled: 'Вызов Агоры отключен в settings.dart.',
  AppTranslations.callAgoraMissingAppId:
      'Идентификатор приложения Agora отсутствует в файле settings.dart.',
  AppTranslations.callRemoteJoined: 'Подключено',
  AppTranslations.callRinging: 'Звонок...',
  AppTranslations.callNoAnswer: 'Никакого ответа от другого человека.',
  AppTranslations.callDeclined: 'Вызов был отклонен.',
  AppTranslations.callIncoming: 'Входящий звонок',
  AppTranslations.callAccept: 'Принять',
  AppTranslations.callDeclineAction: 'Снижение',
  AppTranslations.callRecipientBusy: 'Другой человек сейчас занят.',
  AppTranslations.callRecipientOffline: 'Другой человек не в сети.',
  AppTranslations.callCallerBusy: 'У вас уже есть активный звонок.',
  AppTranslations.callDirectOnly:
      'Звонки сейчас доступны только в прямых разговорах.',
  AppTranslations.callMissingConnection:
      'Сервер не вернул полные данные о соединении вызова.',
  AppTranslations.authFlowHeadline:
      'Требуется дополнительный этап аутентификации',
  AppTranslations.authFlowDescription:
      'Сервер принял ваш логин, но следующий обязательный шаг: @step',
  AppTranslations.accountBannedTitle: 'Этот аккаунт заблокирован',
  AppTranslations.accountBannedBody:
      'Ваша учетная запись Messenger в настоящее время ограничена и не может использовать приложение прямо сейчас.',
  AppTranslations.accountBannedSupport:
      'Пожалуйста, свяжитесь со службой поддержки или администратором сайта, если вы считаете, что это произошло по ошибке.',
  AppTranslations.accountBannedContactSupport: 'Связаться со службой поддержки',
  AppTranslations.authActivationTitle: 'Требуется активация',
  AppTranslations.authActivationDescription:
      'Введите код подтверждения, отправленный на вашу учетную запись, чтобы продолжить.',
  AppTranslations.authApprovalTitle: 'Требуется одобрение',
  AppTranslations.authApprovalDescription:
      'Ваша учетная запись ожидает одобрения, прежде чем Messenger сможет продолжить работу.',
  AppTranslations.authGettingStartedTitle: 'Требуется начало работы',
  AppTranslations.authGettingStartedDescription:
      'Прежде чем Messenger сможет открыться полностью, вашей учетной записи потребуется еще один шаг настройки.',
  AppTranslations.authTwoFactorTitle: 'Двухфакторная проверка',
  AppTranslations.authTwoFactorDescription:
      'Введите код подтверждения из настроенного вами двухфакторного метода.',
  AppTranslations.verificationCode: 'Код подтверждения',
  AppTranslations.verificationCodeHint:
      'Введите код в том виде, в каком он был получен',
  AppTranslations.verificationCodeRequired: 'Требуется код подтверждения',
  AppTranslations.resendCode: 'Отправить код повторно',
  AppTranslations.verifyAndContinue: 'Подтвердить и продолжить',
  AppTranslations.activationCodeSent: 'Был отправлен новый код активации.',
  AppTranslations.authUnableToLoadState:
      'Невозможно загрузить ваш статус аутентификации прямо сейчас.',
  AppTranslations.authUnableToVerifyCode:
      'Невозможно проверить код прямо сейчас.',
  AppTranslations.authUnableToResendCode:
      'Сейчас невозможно повторно отправить код.',
  AppTranslations.backToLogin: 'Вернуться к входу',
  AppTranslations.loginFailed: 'Невозможно войти в систему прямо сейчас',
  AppTranslations.commonConversation: 'Разговор',
  AppTranslations.commonChat: 'Чат',
  AppTranslations.commonConversations: 'Разговоры',
  AppTranslations.commonPeople: 'Люди',
  AppTranslations.commonPost: 'Сообщение',
  AppTranslations.commonStory: 'История',
  AppTranslations.commonReel: 'Катушка',
  AppTranslations.commonProduct: 'Продукт',
  AppTranslations.commonImage: 'Изображение',
  AppTranslations.commonVideo: 'Видео',
  AppTranslations.commonSticker: 'наклейка',
  AppTranslations.commonOn: 'Вкл.',
  AppTranslations.commonOff: 'Выкл.',
  AppTranslations.commonColors: 'Цвета',
  AppTranslations.commonGradients: 'Градиенты',
  AppTranslations.commonReset: 'Сброс',
  AppTranslations.commonTimeline: 'Хронология',
  AppTranslations.timelineAppNotInstalledTitle:
      'Приложение Timeline не установлено',
  AppTranslations.timelineAppNotInstalledMessage:
      'Чтобы открыть этот контент, сначала установите приложение Timeline. Хотите скачать его сейчас?',
  AppTranslations.timelineAppCancelAction: 'Отмена',
  AppTranslations.timelineAppDownloadAction: 'Скачать',
  AppTranslations.sharedPost: 'Поделилась публикацией',
  AppTranslations.sharedReel: 'Общий ролик',
  AppTranslations.sharePostTitle: 'Поделиться публикацией',
  AppTranslations.shareReelTitle: 'Поделиться роликом',
  AppTranslations.shareSearchHint: 'Поиск разговоров или людей',
  AppTranslations.shareEmptyTargets: 'Нет доступных разговоров и контактов',
  AppTranslations.profileQuickSettingsSubtitle:
      'Конфиденциальность, уведомления и настройки',
  AppTranslations.profileConnectAnother: 'Подключить другой профиль',
  AppTranslations.profileAddAccountDisabled: 'Добавление аккаунтов отключено',
  AppTranslations.profileIdentityEyebrow: 'ИДЕНТИЧНОСТЬ',
  AppTranslations.profileSwitcherEyebrow: 'ПЕРЕКЛЮЧАТЕЛЬ',
  AppTranslations.profileAttachAnotherAccount:
      'Прикрепите другой аккаунт для быстрого переключения',
  AppTranslations.profileNoEmailAttached: 'Электронная почта не прикреплена',
  AppTranslations.profileReadyToSwitch: 'Готов переключиться',
  AppTranslations.chatPin: 'Пин-код',
  AppTranslations.chatUnpin: 'Открепить',
  AppTranslations.chatConversationPinned: 'Разговор закреплен',
  AppTranslations.chatConversationUnpinned: 'Разговор откреплен',
  AppTranslations.chatDirectConversation: 'Прямой чат',
  AppTranslations.chatGroupConversation: 'Групповой чат',
  AppTranslations.callsTotal: 'Итого',
  AppTranslations.callsAll: 'Все звонки',
  AppTranslations.callsHeroSubtitle:
      'Отслеживайте пропущенные, отвеченные и видеовызовы в одном удобном представлении.',
  AppTranslations.homeRecentActivity: 'Недавняя активность',
  AppTranslations.chatSettingsSubtitle:
      'Управляйте уведомлениями, состоянием закрепления и действиями в разговоре.',
  AppTranslations.chatBackgroundSubtitle:
      'Выберите собственный фон для этого разговора.',
  AppTranslations.chatRecordingTitle: 'Запись',
  AppTranslations.chatRecordingBody:
      'Коснитесь микрофона еще раз, чтобы остановить и отправить сообщение.',
  AppTranslations.chatInvalidConversationId: 'Неверный идентификатор беседы',
  AppTranslations.chatImageUnavailable: 'Изображение недоступно',
  AppTranslations.chatSharedItemOpenFailed: 'Невозможно открыть общий элемент',
  AppTranslations.chatVoiceUnavailable: 'Голосовое сообщение недоступно',
  AppTranslations.chatVideoUnavailable: 'Видео недоступно',
  AppTranslations.chatReplyingTo: 'Ответ на',
  AppTranslations.chatReplyToYourself: 'Ваше сообщение',
  AppTranslations.chatReplyOriginalUnavailable: 'Исходное сообщение недоступно',
  AppTranslations.chatRepliedToStory: 'Ответил на историю',
  AppTranslations.chatReactedToStory: 'Отреагировал на историю',
  AppTranslations.chatEditingMessage: 'Редактирование сообщения',
  AppTranslations.chatMessageCopied: 'Сообщение скопировано',
  AppTranslations.forwardTitle: 'Переслать сообщение',
  AppTranslations.forwardSearchHint: 'Поиск разговоров или людей',
  AppTranslations.forwardEmptyTargets: 'Нет доступных разговоров и контактов',
  AppTranslations.forwardPreviewTitle: 'Пересланное сообщение',
  AppTranslations.forwardSent: 'Сообщение успешно отправлено',
};
