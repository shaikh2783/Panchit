import '../app_translations.dart';
import 'base.dart';

final Map<String, String> uk = <String, String>{
  ...buildBaseTranslations(),
  AppTranslations.appName: 'Messenger',
  AppTranslations.loginHeadline: 'Ласкаво просимо до ваших розмов',
  AppTranslations.loginSubtitle:
      'Увійдіть, щоб продовжувати спілкуватися в чатах, керувати пов’язаними обліковими записами та залишатися поруч зі своїми людьми.',
  AppTranslations.loginIdentifierLabel:
      'Електронна пошта або ім\'я користувача',
  AppTranslations.loginIdentifierHint:
      'Введіть адресу електронної пошти або ім\'я користувача',
  AppTranslations.passwordLabel: 'Пароль',
  AppTranslations.passwordHint: 'Введіть свій пароль',
  AppTranslations.rememberMe: 'пам\'ятай мене',
  AppTranslations.forgotPassword: 'Забули пароль?',
  AppTranslations.signIn: 'Увійдіть',
  AppTranslations.createAccount: 'Створити акаунт',
  AppTranslations.alreadyHaveAccount: 'Вже маєте акаунт?',
  AppTranslations.dontHaveAccount: 'Немає облікового запису?',
  AppTranslations.registerTitle: 'зареєструватися',
  AppTranslations.registerSubtitle:
      'Заповніть дані свого облікового запису, щоб створити новий обліковий запис Messenger.',
  AppTranslations.signUpHeadline: 'Створіть свій обліковий запис Messenger',
  AppTranslations.signUpSubtitle:
      'Приєднайтеся до розмови за допомогою нового облікового запису та автоматично перейдіть до наступного необхідного кроку налаштування.',
  AppTranslations.signUpToggleTitle: 'Новий тут?',
  AppTranslations.signInToggleTitle: 'Вже маєте акаунт?',
  AppTranslations.signUpUsernameLabel: 'Ім\'я користувача',
  AppTranslations.signUpUsernameHint: 'Виберіть ім\'я користувача',
  AppTranslations.signUpEmailLabel: 'Адреса електронної пошти',
  AppTranslations.signUpEmailHint: 'Введіть адресу електронної пошти',
  AppTranslations.signUpFirstNameLabel: 'ім\'я',
  AppTranslations.signUpFirstNameHint: 'Введіть своє ім\'я',
  AppTranslations.signUpLastNameLabel: 'Прізвище',
  AppTranslations.signUpLastNameHint: 'Введіть своє прізвище',
  AppTranslations.signUpGenderLabel: 'Стать',
  AppTranslations.signUpGenderMale: 'Чоловік',
  AppTranslations.signUpGenderFemale: 'Жінка',
  AppTranslations.signUpConfirmPasswordLabel: 'Підтвердьте пароль',
  AppTranslations.signUpConfirmPasswordHint: 'Повторно введіть пароль',
  AppTranslations.signUpUsernameRequired: 'Потрібно ввести ім\'я користувача',
  AppTranslations.signUpUsernameTooShort:
      'Ім\'я користувача має бути не менше 3 символів',
  AppTranslations.signUpEmailRequired:
      'Необхідно вказати адресу електронної пошти',
  AppTranslations.signUpEmailInvalid: 'Введіть дійсну адресу електронної пошти',
  AppTranslations.signUpPasswordTooShort: 'Пароль має бути не менше 6 символів',
  AppTranslations.signUpConfirmPasswordRequired: 'Потрібно підтвердити пароль',
  AppTranslations.signUpPasswordsDoNotMatch: 'Паролі не збігаються',
  AppTranslations.signUpFirstNameRequired: 'Ім\'я обов\'язкове',
  AppTranslations.signUpLastNameRequired: 'Прізвище обов’язкове',
  AppTranslations.signUpFailed: 'Зараз неможливо створити обліковий запис',
  AppTranslations.signUpNote:
      'Після реєстрації Messenger автоматично проведе вас через активацію або будь-який необхідний крок налаштування.',
  AppTranslations.signUpAgreementPrefix: 'Я згоден на',
  AppTranslations.signUpAgreementAnd: 'і',
  AppTranslations.signUpAgreementSuffix: 'перед створенням облікового запису.',
  AppTranslations.signUpTermsOfUse: 'Умови використання',
  AppTranslations.signUpPrivacyPolicy: 'Політика конфіденційності',
  AppTranslations.signUpTermsRequiredTitle: 'Потрібне схвалення',
  AppTranslations.signUpTermsRequiredMessage:
      'Ви повинні спочатку погодитися з Умовами використання та Політикою конфіденційності.',
  AppTranslations.webViewPageTitle: 'Подробиці',
  AppTranslations.secureAccessNote:
      'Захищений вхід із підтвердженням сеансу з урахуванням пристрою.',
  AppTranslations.loginFooter:
      'Створено для швидкого обміну повідомленнями з цілеспрямованим і безпечним входом.',
  AppTranslations.loginWithTimeline: 'Продовжити з обліковим записом Timeline',
  AppTranslations.loginWithTimelineSubtitle:
      'Використовуйте обліковий запис, у який ви вже ввійшли на часовій шкалі.',
  AppTranslations.identifierRequired:
      'Необхідно вказати електронну адресу або ім’я користувача',
  AppTranslations.passwordRequired: 'Необхідно ввести пароль',
  AppTranslations.loading: 'Завантаження...',
  AppTranslations.homeHeadline: 'Повідомлення',
  AppTranslations.homeSubtitle:
      'Залишайтеся поруч із людьми, які вам небайдужі.',
  AppTranslations.homeWelcomeBack: 'Ласкаво просимо назад, @name',
  AppTranslations.homeSearchHint: 'Пошук розмов',
  AppTranslations.homeSearchEmptyTitle: 'Немає відповідних розмов',
  AppTranslations.homeSearchEmptyBody:
      'Спробуйте інше ім’я або ключове слово, щоб знайти розмову.',
  AppTranslations.addStory: 'Додати історію',
  AppTranslations.shareStory: 'Поділіться історією',
  AppTranslations.storyAddText: 'Додайте текст',
  AppTranslations.storyTextHint: 'Напиши щось...',
  AppTranslations.storyMediaHint:
      'Додайте фото чи відео, щоб поділитися своєю історією.',
  AppTranslations.camera: 'Камера',
  AppTranslations.gallery: 'Галерея',
  AppTranslations.done: 'Готово',
  AppTranslations.replyToStory: 'Відповідь на історію',
  AppTranslations.storyReplySent: 'Відповідь на історію надіслано.',
  AppTranslations.storyReactionSent: 'Реакція на історію надіслана.',
  AppTranslations.storyPublished: 'Оповідання опубліковано.',
  AppTranslations.storyViews: 'Перегляди',
  AppTranslations.storyViewers: 'Глядачі історії',
  AppTranslations.storyReactions: 'Реакція історії',
  AppTranslations.noStoryViewers: 'Глядачів ще немає.',
  AppTranslations.noStoryReactions: 'Реакцій поки немає.',
  AppTranslations.unableToLoadStoryViewers:
      'Наразі неможливо завантажити засоби перегляду історій.',
  AppTranslations.unableToLoadStoryReactions:
      'Зараз неможливо завантажити реакцію на історію.',
  AppTranslations.unableToReplyToStory:
      'Зараз неможливо надіслати відповідь на історію.',
  AppTranslations.unableToReactToStory:
      'Зараз неможливо надіслати реакцію на історію.',
  AppTranslations.unableToPublishStory: 'Зараз неможливо опублікувати історію.',
  AppTranslations.storiesLoadFailed: 'Не вдалося завантажити історії',
  AppTranslations.storyFeatureSoon:
      'На черзі — програма перегляду історій і публікація.',
  AppTranslations.homeStoriesTitle: 'Активний зараз',
  AppTranslations.homeChatsTitle: 'Останні чати',
  AppTranslations.homeTabAll: 'всі',
  AppTranslations.homeTabUnread: 'Непрочитаний',
  AppTranslations.homeTabGroups: 'Групи',
  AppTranslations.homeOnlineNow: 'онлайн зараз',
  AppTranslations.homeTypePlaceholder: 'Введіть повідомлення',
  AppTranslations.homeStatusActive: 'Активний зараз',
  AppTranslations.homeStatusTyping: 'Введення...',
  AppTranslations.homeStatusSent: 'Надіслано',
  AppTranslations.homeStatusDelivered: 'Доставлено',
  AppTranslations.homeStatusVoice: 'Голосове повідомлення',
  AppTranslations.homeStatusMuted: 'Сповіщення вимкнено',
  AppTranslations.homeChatsUnavailableTitle: 'Живі чати ще не готові',
  AppTranslations.homeChatsUnavailableBody:
      'Кінцева точка чату Messenger все ще повертає відповідь каркаса від сервера.',
  AppTranslations.homeChatsEmptyTitle: 'Ваша скринька готова',
  AppTranslations.homeChatsEmptyBody:
      'Почніть свою першу розмову, щоб побачити тут повідомлення, відповіді та спільні моменти.',
  AppTranslations.homeChatsEmptyAction: 'Розпочати чат',
  AppTranslations.retry: 'Повторіть спробу',
  AppTranslations.settingsTitle: 'Налаштування',
  AppTranslations.settingsLanguage: 'Мова',
  AppTranslations.settingsArabic: 'арабська',
  AppTranslations.settingsEnglish: 'англійська',
  AppTranslations.settingsFrench: 'французька',
  AppTranslations.settingsSpanish: 'Іспанська',
  AppTranslations.settingsPortuguese: 'португальська',
  AppTranslations.settingsGerman: 'Німецький',
  AppTranslations.settingsTurkish: 'турецька',
  AppTranslations.settingsDutch: 'голландська',
  AppTranslations.settingsItalian: 'італійська',
  AppTranslations.settingsRussian: 'російська',
  AppTranslations.settingsRomanian: 'румунська',
  AppTranslations.settingsPortugueseBrazil: 'португальська (Бразилія)',
  AppTranslations.settingsGreek: 'грецька',
  AppTranslations.settingsUkrainian: 'українська',
  AppTranslations.settingsTheme: 'Тема',
  AppTranslations.settingsDarkMode: 'Темний режим',
  AppTranslations.settingsLightMode: 'Світловий режим',
  AppTranslations.settingsLanguageSheetDescription:
      'Виберіть мову програми з чистого списку.',
  AppTranslations.settingsHeroDescription:
      'Керуйте мовою, зовнішнім виглядом і доступом до облікового запису з одного місця.',
  AppTranslations.settingsPreferencesEyebrow: 'НАЛАШТУВАННЯ',
  AppTranslations.settingsPreferencesTitle: 'Досвід додатка',
  AppTranslations.settingsAccountEyebrow: 'ОБЛІКОВИЙ ЗАПИС',
  AppTranslations.settingsAccountTitle: 'Сеанс і безпека',
  AppTranslations.settingsBlockedUsers: 'Заблоковані користувачі',
  AppTranslations.settingsBlockedUsersSubtitle:
      'Переглядайте заблокованих людей і знімайте обмеження за потреби.',
  AppTranslations.blockedUsersTitle: 'Заблоковані користувачі',
  AppTranslations.blockedUsersEmpty:
      'Наразі для цього облікового запису не знайдено заблокованих користувачів.',
  AppTranslations.blockedUsersUnblock: 'Розблокувати',
  AppTranslations.blockedUsersUnblockTitle: 'Розблокувати користувача',
  AppTranslations.blockedUsersUnblockMessage:
      'Ви хочете видалити цього користувача зі списку заблокованих?',
  AppTranslations.blockedUsersUserUnblocked: 'Користувача успішно розблоковано',
  AppTranslations.settingsDeleteAccount: 'Видалити акаунт',
  AppTranslations.settingsDeleteAccountSubtitle:
      'Назавжди видаліть цей акаунт і доступ до Messenger.',
  AppTranslations.settingsDeleteAccountTitle: 'Видалити акаунт',
  AppTranslations.settingsDeleteAccountMessage:
      'Ця дія незворотна. Ви впевнені, що хочете видалити свій акаунт?',
  AppTranslations.settingsDeleteAccountConfirm: 'Видалити акаунт',
  AppTranslations.settingsDeleteAccountSuccess: 'Ваш акаунт успішно видалено',
  AppTranslations.settingsLogoutSubtitle:
      'Вийти з поточного сеансу на цьому пристрої',
  AppTranslations.settingsLogout: 'Вийти',
  AppTranslations.settingsLogoutTitle: 'Вийти',
  AppTranslations.settingsLogoutMessage:
      'Ви впевнені, що бажаєте вийти з Messenger на цьому пристрої?',
  AppTranslations.settingsLogoutTimelineBridgeMessage:
      'Ви вийдете лише з Messenger. Ваш сеанс хронології залишатиметься в обліковому записі на цьому пристрої.',
  AppTranslations.settingsLogoutCancel: 'Скасувати',
  AppTranslations.settingsLogoutConfirm: 'Вийти',
  AppTranslations.settingsLegalEyebrow: 'ЮРИДИЧНЕ',
  AppTranslations.settingsLegalTitle: 'Конфіденційність і умови',
  AppTranslations.settingsPrivacyPolicy: 'Політика конфіденційності',
  AppTranslations.settingsPrivacyPolicySubtitle:
      'Дізнайтеся, як Ukraina.co-Chat збирає, використовує та захищає дані облікового запису.',
  AppTranslations.settingsTermsOfUse: 'Умови використання',
  AppTranslations.settingsTermsOfUseSubtitle:
      'Прочитайте правила, відповідальність і умови використання Ukraina.co-Chat.',
  AppTranslations.navChats: 'Чати',
  AppTranslations.navCalls: 'Дзвінки',
  AppTranslations.navProfile: 'Профіль',
  AppTranslations.navSettings: 'Налаштування',
  AppTranslations.composeTitle: 'Нова розмова',
  AppTranslations.composeSearchHint: 'Пошук друзів',
  AppTranslations.composeSelectContact: 'Спочатку виберіть друга',
  AppTranslations.composeOpenConversation: 'Відкрита розмова',
  AppTranslations.composeContactsUnavailable:
      'Контакти з’являться тут, щойно кінцева точка буде готова.',
  AppTranslations.composeNoContacts: 'Зараз немає доступних контактів.',
  AppTranslations.composeRecipientId: 'ID користувача одержувача',
  AppTranslations.composeRecipientHint: 'Введіть ідентифікатор користувача',
  AppTranslations.composeMessage: 'Перше повідомлення',
  AppTranslations.composeMessageHint: 'Напишіть своє повідомлення',
  AppTranslations.composeSend: 'Надіслати',
  AppTranslations.composeRecipientRequired:
      'Потрібен ідентифікатор користувача одержувача',
  AppTranslations.composeMessageRequired: 'Необхідне повідомлення',
  AppTranslations.callsPlaceholder:
      'Вкладка викликів готова до наступного кроку API.',
  AppTranslations.callsEmptyTitle: 'Дзвінків ще немає',
  AppTranslations.callsEmptyBody:
      'Тут відображатимуться ваші останні голосові та відеодзвінки.',
  AppTranslations.callsIncoming: 'Вхідні',
  AppTranslations.callsOutgoing: 'Вихідний',
  AppTranslations.callsMissed: 'Пропущений',
  AppTranslations.callsDeclined: 'Відхилено',
  AppTranslations.callsAnswered: 'відповів',
  AppTranslations.callsOpenChat: 'Відкрити чат',
  AppTranslations.profilePlaceholder:
      'Вкладка профілю зарезервована для даних облікового запису та особи.',
  AppTranslations.profileCurrentAccount: 'Поточний рахунок',
  AppTranslations.profileConnectedAccounts: 'Підключені облікові записи',
  AppTranslations.profileAddAccount: 'Додати акаунт',
  AppTranslations.profileSwitchAccount: 'Перемикач',
  AppTranslations.profileRemoveAccount: 'видалити',
  AppTranslations.profileRevokeAccount: 'Відкликати',
  AppTranslations.profileAccountUsername: 'Ім\'я користувача',
  AppTranslations.profileAccountEmail: 'Електронна пошта',
  AppTranslations.profileAccountStatus: 'Статус рахунку',
  AppTranslations.profileAccountCurrent: 'поточний',
  AppTranslations.profileAccountMaster: 'майстер',
  AppTranslations.profileNoConnectedAccounts:
      'Підключених облікових записів ще не знайдено.',
  AppTranslations.profileAddAccountTitle: 'Додайте підключений обліковий запис',
  AppTranslations.profileAddAccountIdentifier:
      'Електронна пошта або ім\'я користувача',
  AppTranslations.profileAddAccountIdentifierHint:
      'Введіть електронну адресу зв’язаного облікового запису або ім’я користувача',
  AppTranslations.profileAddAccountPassword: 'Пароль облікового запису',
  AppTranslations.profileAddAccountConfirm: 'Підключити обліковий запис',
  AppTranslations.profileAddAccountSuccess:
      'Підключений обліковий запис успішно додано',
  AppTranslations.profileSwitchAccountSuccess:
      'Обліковий запис успішно змінено',
  AppTranslations.profileRemoveAccountTitle:
      'Видалити підключений обліковий запис',
  AppTranslations.profileRemoveAccountMessage:
      'Ви впевнені, що хочете видалити цей підключений обліковий запис?',
  AppTranslations.profileRemoveAccountSuccess:
      'Підключений обліковий запис успішно видалено',
  AppTranslations.profileRevokeAccountTitle:
      'Скасувати підключення до облікового запису',
  AppTranslations.profileRevokeAccountMessage:
      'Ви впевнені, що бажаєте скасувати поточне пов’язане головне підключення?',
  AppTranslations.profileRevokeAccountSuccess:
      'Підключення облікового запису успішно скасовано',
  AppTranslations.profileManageSettings: 'Відкрийте налаштування',
  AppTranslations.profileTimelineBridgeActive:
      'На цьому пристрої активний сеанс мосту часової шкали.',
  AppTranslations.profileLinkedAccountsDisabled:
      'Перемикання підключених облікових записів вимкнено для цього облікового запису.',
  AppTranslations.profileAccountAdded: 'Обліковий запис підключено',
  AppTranslations.profileAccountEmptyField:
      'Необхідно вказати електронну адресу/ім’я користувача та пароль',
  AppTranslations.chatOnlineNow: 'Онлайн зараз',
  AppTranslations.chatSeen: 'Бачив',
  AppTranslations.chatInputHint: 'Введіть повідомлення',
  AppTranslations.chatInfoTitle: 'Інформація про чат',
  AppTranslations.chatInfoSharedMedia: 'Спільні медіа',
  AppTranslations.chatInfoSettings: 'Налаштування чату',
  AppTranslations.chatInfoAll: 'всі',
  AppTranslations.chatInfoImages: 'Зображення',
  AppTranslations.chatInfoVideos: 'Відео',
  AppTranslations.chatInfoAudio: 'Аудіо',
  AppTranslations.chatInfoFiles: 'Файли',
  AppTranslations.chatInfoLinks: 'Посилання',
  AppTranslations.chatInfoNoSharedMedia:
      'Для цієї розмови не знайдено спільного вмісту.',
  AppTranslations.chatInfoOpen: 'відкритий',
  AppTranslations.chatSettingBackground: 'Фон чату',
  AppTranslations.chatSettingMute: 'Вимкнути сповіщення',
  AppTranslations.chatSettingPin: 'Закріпити чат',
  AppTranslations.chatSettingBlock: 'Заблокувати користувача',
  AppTranslations.chatSettingReport: 'Поскаржитися на користувача',
  AppTranslations.chatSettingReportSubtitle:
      'Надішліть скаргу щодо безпеки цього облікового запису.',
  AppTranslations.chatSettingDelete: 'Видалити бесіду',
  AppTranslations.chatSettingApiPending:
      'Цей параметр очікує виділеної кінцевої точки API.',
  AppTranslations.chatReportTitle: 'Поскаржитися на користувача',
  AppTranslations.chatReportDescription:
      'Виберіть причину цієї скарги. Ukraina.co-Chat надішле її команді модерації для перевірки.',
  AppTranslations.chatReportCategoryLabel: 'Категорія скарги',
  AppTranslations.chatReportCategoryHint: 'Виберіть причину',
  AppTranslations.chatReportReasonLabel: 'Додаткові деталі',
  AppTranslations.chatReportReasonHint:
      'Додайте більше контексту, щоб допомогти з перевіркою цієї скарги.',
  AppTranslations.chatReportSubmit: 'Надіслати скаргу',
  AppTranslations.chatReportSuccess: 'Скаргу надіслано',
  AppTranslations.chatReportEmptyCategories:
      'Наразі категорії скарг недоступні.',
  AppTranslations.chatReportCategoryRequired:
      'Будь ласка, виберіть категорію скарги перед продовженням.',
  AppTranslations.chatReportLoadFailed:
      'Не вдалося завантажити категорії скарг зараз.',
  AppTranslations.chatDeleteTitle: 'Видалити бесіду',
  AppTranslations.chatDeleteMessage:
      'Ви впевнені, що хочете видалити цю розмову?',
  AppTranslations.chatDeleteConfirm: 'Видалити',
  AppTranslations.chatDeleted: 'Бесіду успішно видалено',
  AppTranslations.chatMessageDelete: 'Видалити повідомлення',
  AppTranslations.chatMessageEdit: 'Редагувати повідомлення',
  AppTranslations.chatMessageReply: 'Відповісти',
  AppTranslations.chatMessageForward: 'вперед',
  AppTranslations.chatMessageCopy: 'Копія',
  AppTranslations.chatStickerTitle: 'наклейки',
  AppTranslations.chatStickerSubtitle:
      'Виберіть набір наклейок і миттєво надішліть наклейку.',
  AppTranslations.chatStickerEmpty: 'У цьому пакеті немає наклейок.',
  AppTranslations.chatMessageDeleteTitle: 'Видалити повідомлення',
  AppTranslations.chatMessageDeleteMessage:
      'Ви впевнені, що хочете видалити це повідомлення?',
  AppTranslations.chatMessageDeleted: 'Повідомлення успішно видалено',
  AppTranslations.chatMessageEditPending:
      'Для редагування повідомлень потрібна спеціальна кінцева точка API.',
  AppTranslations.callVoice: 'Голосовий виклик',
  AppTranslations.callVideo: 'Відеодзвінок',
  AppTranslations.callConnecting: 'Підключення...',
  AppTranslations.callWaiting: 'Чекаємо, поки інша особа приєднається',
  AppTranslations.callMicOff: 'Мікрофон вимкнено',
  AppTranslations.callMicOn: 'Мікрофон включений',
  AppTranslations.callSpeakerOn: 'Динамік включений',
  AppTranslations.callSpeakerOff: 'Динамік вимкнено',
  AppTranslations.callCameraFlip: 'Переключити камеру',
  AppTranslations.callEnd: 'Завершити дзвінок',
  AppTranslations.callPermissionDenied:
      'Відмовлено в дозволі на камеру чи мікрофон.',
  AppTranslations.callAgoraDisabled: 'Виклики Agora вимкнено в settings.dart.',
  AppTranslations.callAgoraMissingAppId:
      'У файлі settings.dart відсутній ідентифікатор програми Agora.',
  AppTranslations.callRemoteJoined: 'Підключено',
  AppTranslations.callRinging: 'Дзвінок...',
  AppTranslations.callNoAnswer: 'Немає відповіді від іншої особи.',
  AppTranslations.callDeclined: 'Дзвінок було відхилено.',
  AppTranslations.callIncoming: 'Вхідний дзвінок',
  AppTranslations.callAccept: 'прийняти',
  AppTranslations.callDeclineAction: 'відхилити',
  AppTranslations.callRecipientBusy: 'Інша особа зараз зайнята.',
  AppTranslations.callRecipientOffline: 'Інша особа офлайн.',
  AppTranslations.callCallerBusy: 'У вас уже є активний дзвінок.',
  AppTranslations.callDirectOnly:
      'Дзвінки зараз доступні лише в прямих розмовах.',
  AppTranslations.callMissingConnection:
      'Сервер не повернув повні дані з’єднання виклику.',
  AppTranslations.authFlowHeadline: 'Потрібен додатковий етап автентифікації',
  AppTranslations.authFlowDescription:
      'Сервер прийняв ваш логін, але наступний необхідний крок: @step',
  AppTranslations.accountBannedTitle: 'Цей обліковий запис забанено',
  AppTranslations.accountBannedBody:
      'Ваш обліковий запис Messenger наразі обмежено, і зараз ви не можете використовувати програму.',
  AppTranslations.accountBannedSupport:
      'Будь ласка, зверніться до служби підтримки або адміністратора сайту, якщо ви вважаєте, що це сталося помилково.',
  AppTranslations.accountBannedContactSupport: 'Зверніться до служби підтримки',
  AppTranslations.authActivationTitle: 'Потрібна активація',
  AppTranslations.authActivationDescription:
      'Щоб продовжити, введіть код підтвердження, надісланий на ваш обліковий запис.',
  AppTranslations.authApprovalTitle: 'Потрібне схвалення',
  AppTranslations.authApprovalDescription:
      'Ваш обліковий запис очікує на підтвердження, перш ніж Messenger зможе продовжити роботу.',
  AppTranslations.authGettingStartedTitle: 'Необхідно почати роботу',
  AppTranslations.authGettingStartedDescription:
      'Ваш обліковий запис потребує ще одного кроку налаштування, перш ніж програма Messenger зможе повністю відкритися.',
  AppTranslations.authTwoFactorTitle: 'Двофакторна перевірка',
  AppTranslations.authTwoFactorDescription:
      'Введіть код підтвердження з налаштованого двофакторного методу.',
  AppTranslations.verificationCode: 'Код підтвердження',
  AppTranslations.verificationCodeHint: 'Введіть код точно так, як отримано',
  AppTranslations.verificationCodeRequired: 'Потрібен код підтвердження',
  AppTranslations.resendCode: 'Повторно надіслати код',
  AppTranslations.verifyAndContinue: 'Перевірити та продовжити',
  AppTranslations.activationCodeSent: 'Новий код активації надіслано.',
  AppTranslations.authUnableToLoadState:
      'Зараз неможливо завантажити ваш стан автентифікації.',
  AppTranslations.authUnableToVerifyCode: 'Зараз неможливо перевірити код.',
  AppTranslations.authUnableToResendCode:
      'Зараз неможливо повторно надіслати код.',
  AppTranslations.backToLogin: 'Назад до входу',
  AppTranslations.loginFailed: 'Зараз неможливо ввійти',
  AppTranslations.commonConversation: 'Розмова',
  AppTranslations.commonChat: 'Чат',
  AppTranslations.commonConversations: 'Розмови',
  AppTranslations.commonPeople: 'Люди',
  AppTranslations.commonPost: 'Опублікувати',
  AppTranslations.commonStory: 'Розповідь',
  AppTranslations.commonReel: 'котушка',
  AppTranslations.commonProduct: 'Продукт',
  AppTranslations.commonImage: 'Зображення',
  AppTranslations.commonVideo: 'відео',
  AppTranslations.commonSticker: 'наклейка',
  AppTranslations.commonOn: 'Увімкнено',
  AppTranslations.commonOff: 'Вимкнено',
  AppTranslations.commonColors: 'Кольори',
  AppTranslations.commonGradients: 'градієнти',
  AppTranslations.commonReset: 'Скинути',
  AppTranslations.commonTimeline: 'Хронологія',
  AppTranslations.timelineAppNotInstalledTitle:
      'Додаток Timeline не встановлено',
  AppTranslations.timelineAppNotInstalledMessage:
      'Щоб відкрити цей вміст, спочатку встановіть додаток Timeline. Бажаєте завантажити його зараз?',
  AppTranslations.timelineAppCancelAction: 'Скасувати',
  AppTranslations.timelineAppDownloadAction: 'Завантажити',
  AppTranslations.sharedPost: 'Спільний допис',
  AppTranslations.sharedReel: 'Спільна котушка',
  AppTranslations.sharePostTitle: 'Поділитися публікацією',
  AppTranslations.shareReelTitle: 'Share Reel',
  AppTranslations.shareSearchHint: 'Пошук розмов або людей',
  AppTranslations.shareEmptyTargets: 'Немає розмов або контактів',
  AppTranslations.profileQuickSettingsSubtitle:
      'Конфіденційність, сповіщення та налаштування',
  AppTranslations.profileConnectAnother: 'Підключіть інший профіль',
  AppTranslations.profileAddAccountDisabled:
      'Додавання облікових записів вимкнено',
  AppTranslations.profileIdentityEyebrow: 'ІДЕНТИЧНІСТЬ',
  AppTranslations.profileSwitcherEyebrow: 'ПЕРЕМИКАЧ',
  AppTranslations.profileAttachAnotherAccount:
      'Приєднайте інший обліковий запис для швидкого переходу',
  AppTranslations.profileNoEmailAttached: 'Електронна пошта не додається',
  AppTranslations.profileReadyToSwitch: 'Готовий до перемикання',
  AppTranslations.chatPin: 'Pin',
  AppTranslations.chatUnpin: 'Відкріпити',
  AppTranslations.chatConversationPinned: 'Бесіду закріплено',
  AppTranslations.chatConversationUnpinned: 'Бесіду відкріплено',
  AppTranslations.chatDirectConversation: 'Прямий чат',
  AppTranslations.chatGroupConversation: 'Груповий чат',
  AppTranslations.callsTotal: 'Всього',
  AppTranslations.callsAll: 'Всі дзвінки',
  AppTranslations.callsHeroSubtitle:
      'Відстежуйте пропущені виклики, виклики, на які відповіли та відеодзвінки, в одному досконалому режимі.',
  AppTranslations.homeRecentActivity: 'Остання діяльність',
  AppTranslations.chatSettingsSubtitle:
      'Керуйте сповіщеннями, станом закріплення та діями в розмові.',
  AppTranslations.chatBackgroundSubtitle:
      'Виберіть власний фон для цієї розмови.',
  AppTranslations.chatRecordingTitle: 'Запис',
  AppTranslations.chatRecordingBody:
      'Торкніться мікрофона ще раз, щоб зупинити та надіслати',
  AppTranslations.chatInvalidConversationId: 'Недійсний ідентифікатор бесіди',
  AppTranslations.chatImageUnavailable: 'Зображення недоступне',
  AppTranslations.chatSharedItemOpenFailed:
      'Неможливо відкрити спільний елемент',
  AppTranslations.chatVoiceUnavailable: 'Голосове повідомлення недоступне',
  AppTranslations.chatVideoUnavailable: 'Відео недоступне',
  AppTranslations.chatReplyingTo: 'Відповідаючи на',
  AppTranslations.chatReplyToYourself: 'Ваше повідомлення',
  AppTranslations.chatReplyOriginalUnavailable:
      'Оригінал повідомлення недоступний',
  AppTranslations.chatRepliedToStory: 'Відповів на історію',
  AppTranslations.chatReactedToStory: 'Відреагував на історію',
  AppTranslations.chatEditingMessage: 'Редагування повідомлення',
  AppTranslations.chatMessageCopied: 'Повідомлення скопійовано',
  AppTranslations.forwardTitle: 'Переслати повідомлення',
  AppTranslations.forwardSearchHint: 'Пошук розмов або людей',
  AppTranslations.forwardEmptyTargets: 'Немає розмов або контактів',
  AppTranslations.forwardPreviewTitle: 'Переслане повідомлення',
  AppTranslations.forwardSent: 'Повідомлення успішно переслано',
};
