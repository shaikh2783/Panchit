import '../app_translations.dart';
import 'base.dart';

final Map<String, String> el = <String, String>{
  ...buildBaseTranslations(),
  AppTranslations.appName: 'Messenger',
  AppTranslations.loginHeadline: 'Καλώς ήρθατε πίσω στις συνομιλίες σας',
  AppTranslations.loginSubtitle:
      'Συνδεθείτε για να συνεχίσετε τις συνομιλίες σας, να διαχειριστείτε τους συνδεδεμένους λογαριασμούς και να παραμείνετε κοντά στους ανθρώπους σας.',
  AppTranslations.loginIdentifierLabel: 'email ή όνομα χρήστη',
  AppTranslations.loginIdentifierHint:
      'Εισαγάγετε το email ή το όνομα χρήστη σας',
  AppTranslations.passwordLabel: 'Κωδικός πρόσβασης',
  AppTranslations.passwordHint: 'Εισαγάγετε τον κωδικό πρόσβασής σας',
  AppTranslations.rememberMe: 'Θυμήσου με',
  AppTranslations.forgotPassword: 'Ξεχάσατε τον κωδικό πρόσβασης;',
  AppTranslations.signIn: 'Συνδεθείτε',
  AppTranslations.createAccount: 'Δημιουργία λογαριασμού',
  AppTranslations.alreadyHaveAccount: 'Έχετε ήδη λογαριασμό;',
  AppTranslations.dontHaveAccount: 'Δεν έχετε λογαριασμό;',
  AppTranslations.registerTitle: 'Εγγραφή',
  AppTranslations.registerSubtitle:
      'Συμπληρώστε τα στοιχεία του λογαριασμού σας για να δημιουργήσετε έναν νέο λογαριασμό Messenger.',
  AppTranslations.signUpHeadline:
      'Δημιουργήστε τον λογαριασμό σας στο Messenger',
  AppTranslations.signUpSubtitle:
      'Εγγραφείτε στη συνομιλία με έναν νέο λογαριασμό και συνεχίστε αυτόματα στο επόμενο απαιτούμενο βήμα ρύθμισης.',
  AppTranslations.signUpToggleTitle: 'Νέος εδώ;',
  AppTranslations.signInToggleTitle: 'Έχετε ήδη λογαριασμό;',
  AppTranslations.signUpUsernameLabel: 'Όνομα χρήστη',
  AppTranslations.signUpUsernameHint: 'Επιλέξτε ένα όνομα χρήστη',
  AppTranslations.signUpEmailLabel: 'Διεύθυνση ηλεκτρονικού ταχυδρομείου',
  AppTranslations.signUpEmailHint: 'Εισαγάγετε τη διεύθυνση email σας',
  AppTranslations.signUpFirstNameLabel: 'Όνομα',
  AppTranslations.signUpFirstNameHint: 'Εισαγάγετε το όνομά σας',
  AppTranslations.signUpLastNameLabel: 'Επώνυμο',
  AppTranslations.signUpLastNameHint: 'Εισαγάγετε το επώνυμό σας',
  AppTranslations.signUpGenderLabel: 'Φύλο',
  AppTranslations.signUpGenderMale: 'Αρσενικό',
  AppTranslations.signUpGenderFemale: 'Θηλυκό',
  AppTranslations.signUpConfirmPasswordLabel: 'Επιβεβαίωση κωδικού πρόσβασης',
  AppTranslations.signUpConfirmPasswordHint:
      'Εισαγάγετε ξανά τον κωδικό πρόσβασής σας',
  AppTranslations.signUpUsernameRequired: 'Απαιτείται όνομα χρήστη',
  AppTranslations.signUpUsernameTooShort:
      'Το όνομα χρήστη πρέπει να αποτελείται από τουλάχιστον 3 χαρακτήρες',
  AppTranslations.signUpEmailRequired: 'Απαιτείται διεύθυνση email',
  AppTranslations.signUpEmailInvalid: 'Εισαγάγετε μια έγκυρη διεύθυνση email',
  AppTranslations.signUpPasswordTooShort:
      'Ο κωδικός πρόσβασης πρέπει να αποτελείται από τουλάχιστον 6 χαρακτήρες',
  AppTranslations.signUpConfirmPasswordRequired:
      'Απαιτείται επιβεβαίωση κωδικού πρόσβασης',
  AppTranslations.signUpPasswordsDoNotMatch:
      'Οι κωδικοί πρόσβασης δεν ταιριάζουν',
  AppTranslations.signUpFirstNameRequired: 'Το όνομα είναι υποχρεωτικό',
  AppTranslations.signUpLastNameRequired: 'Το επώνυμο είναι υποχρεωτικό',
  AppTranslations.signUpFailed:
      'Δεν είναι δυνατή η δημιουργία του λογαριασμού αυτήν τη στιγμή',
  AppTranslations.signUpNote:
      'Μετά την εγγραφή, το Messenger θα σας καθοδηγήσει αυτόματα στην ενεργοποίηση ή σε οποιοδήποτε απαραίτητο βήμα ρύθμισης.',
  AppTranslations.signUpAgreementPrefix: 'Συμφωνώ με το',
  AppTranslations.signUpAgreementAnd: 'και',
  AppTranslations.signUpAgreementSuffix: 'πριν δημιουργήσω τον λογαριασμό μου.',
  AppTranslations.signUpTermsOfUse: 'Όροι Χρήσης',
  AppTranslations.signUpPrivacyPolicy: 'Πολιτική Απορρήτου',
  AppTranslations.signUpTermsRequiredTitle: 'Απαιτείται έγκριση',
  AppTranslations.signUpTermsRequiredMessage:
      'Πρέπει πρώτα να συμφωνήσετε με τους Όρους Χρήσης και την Πολιτική Απορρήτου.',
  AppTranslations.webViewPageTitle: 'Λεπτομέρειες',
  AppTranslations.secureAccessNote:
      'Προστατευμένη σύνδεση με επαλήθευση συνεδρίας με γνώση της συσκευής.',
  AppTranslations.loginFooter:
      'Σχεδιασμένο για γρήγορη ανταλλαγή μηνυμάτων με εστιασμένη και ασφαλή ροή εισόδου.',
  AppTranslations.loginWithTimeline: 'Συνεχίστε με τον λογαριασμό Timeline',
  AppTranslations.loginWithTimelineSubtitle:
      'Χρησιμοποιήστε τον λογαριασμό που είναι ήδη συνδεδεμένος στο Χρονολόγιο.',
  AppTranslations.identifierRequired: 'Απαιτείται email ή όνομα χρήστη',
  AppTranslations.passwordRequired: 'Απαιτείται κωδικός πρόσβασης',
  AppTranslations.loading: 'Φόρτωση...',
  AppTranslations.homeHeadline: 'Μηνύματα',
  AppTranslations.homeSubtitle:
      'Μείνετε κοντά στους ανθρώπους που σας ενδιαφέρουν.',
  AppTranslations.homeWelcomeBack: 'Καλώς ήρθες πίσω, @name',
  AppTranslations.homeSearchHint: 'Αναζήτηση συνομιλιών',
  AppTranslations.homeSearchEmptyTitle: 'Δεν υπάρχουν αντίστοιχες συνομιλίες',
  AppTranslations.homeSearchEmptyBody:
      'Δοκιμάστε άλλο όνομα ή λέξη-κλειδί για να βρείτε μια συνομιλία.',
  AppTranslations.addStory: 'Προσθήκη ιστορίας',
  AppTranslations.shareStory: 'Κοινή χρήση ιστορίας',
  AppTranslations.storyAddText: 'Προσθήκη κειμένου',
  AppTranslations.storyTextHint: 'Γράψε κάτι...',
  AppTranslations.storyMediaHint:
      'Προσθέστε μια φωτογραφία ή ένα βίντεο για να μοιραστείτε την ιστορία σας.',
  AppTranslations.camera: 'Κάμερα',
  AppTranslations.gallery: 'Γκαλερί',
  AppTranslations.done: 'Έγινε',
  AppTranslations.replyToStory: 'Απάντηση στην ιστορία',
  AppTranslations.storyReplySent: 'Η απάντηση της ιστορίας εστάλη.',
  AppTranslations.storyReactionSent: 'Στάλθηκε η αντίδραση της ιστορίας.',
  AppTranslations.storyPublished: 'Δημοσιεύτηκε η ιστορία.',
  AppTranslations.storyViews: 'Απόψεις',
  AppTranslations.storyViewers: 'Θεατές ιστορίας',
  AppTranslations.storyReactions: 'Αντιδράσεις ιστορίας',
  AppTranslations.noStoryViewers: 'Δεν υπάρχουν ακόμη θεατές.',
  AppTranslations.noStoryReactions: 'Καμία αντίδραση ακόμα.',
  AppTranslations.unableToLoadStoryViewers:
      'Δεν είναι δυνατή η φόρτωση θεατών ιστορίας αυτήν τη στιγμή.',
  AppTranslations.unableToLoadStoryReactions:
      'Δεν είναι δυνατή η φόρτωση των αντιδράσεων ιστορίας αυτήν τη στιγμή.',
  AppTranslations.unableToReplyToStory:
      'Δεν είναι δυνατή η αποστολή της απάντησης της ιστορίας αυτήν τη στιγμή.',
  AppTranslations.unableToReactToStory:
      'Δεν είναι δυνατή η αποστολή της αντίδρασης της ιστορίας αυτήν τη στιγμή.',
  AppTranslations.unableToPublishStory:
      'Δεν είναι δυνατή η δημοσίευση της ιστορίας αυτήν τη στιγμή.',
  AppTranslations.storiesLoadFailed: 'Αποτυχία φόρτωσης ιστοριών',
  AppTranslations.storyFeatureSoon:
      'Η προβολή και η δημοσίευση ιστορίας ακολουθούν.',
  AppTranslations.homeStoriesTitle: 'Ενεργός τώρα',
  AppTranslations.homeChatsTitle: 'Πρόσφατες συνομιλίες',
  AppTranslations.homeTabAll: 'Όλα',
  AppTranslations.homeTabUnread: 'Μη αναγνωσμένο',
  AppTranslations.homeTabGroups: 'Ομάδες',
  AppTranslations.homeOnlineNow: 'online τώρα',
  AppTranslations.homeTypePlaceholder: 'Πληκτρολογήστε ένα μήνυμα',
  AppTranslations.homeStatusActive: 'Ενεργός τώρα',
  AppTranslations.homeStatusTyping: 'Πληκτρολογώντας...',
  AppTranslations.homeStatusSent: 'Στάλθηκε',
  AppTranslations.homeStatusDelivered: 'Παραδόθηκε',
  AppTranslations.homeStatusVoice: 'Φωνητικό μήνυμα',
  AppTranslations.homeStatusMuted: 'Οι ειδοποιήσεις τέθηκαν σε σίγαση',
  AppTranslations.homeChatsUnavailableTitle:
      'Οι ζωντανές συνομιλίες δεν είναι ακόμη έτοιμες',
  AppTranslations.homeChatsUnavailableBody:
      'Το τελικό σημείο συνομιλίας του Messenger εξακολουθεί να επιστρέφει μια απόκριση από τον διακομιστή.',
  AppTranslations.homeChatsEmptyTitle: 'Τα εισερχόμενά σας είναι έτοιμα',
  AppTranslations.homeChatsEmptyBody:
      'Ξεκινήστε την πρώτη σας συνομιλία για να δείτε μηνύματα, απαντήσεις και κοινές στιγμές να εμφανίζονται εδώ.',
  AppTranslations.homeChatsEmptyAction: 'Ξεκινήστε μια συνομιλία',
  AppTranslations.retry: 'Επανάληψη',
  AppTranslations.settingsTitle: 'Ρυθμίσεις',
  AppTranslations.settingsLanguage: 'Γλώσσα',
  AppTranslations.settingsArabic: 'Αραβικά',
  AppTranslations.settingsEnglish: 'Αγγλικά',
  AppTranslations.settingsFrench: 'Γαλλικά',
  AppTranslations.settingsSpanish: 'Ισπανικά',
  AppTranslations.settingsPortuguese: 'Πορτογαλικά',
  AppTranslations.settingsGerman: 'Γερμανός',
  AppTranslations.settingsTurkish: 'Τουρκικά',
  AppTranslations.settingsDutch: 'Ολλανδικά',
  AppTranslations.settingsItalian: 'ιταλική',
  AppTranslations.settingsRussian: 'Ρωσική',
  AppTranslations.settingsRomanian: 'Ρουμάνικα',
  AppTranslations.settingsPortugueseBrazil: 'Πορτογαλικά (Βραζιλία)',
  AppTranslations.settingsGreek: 'Έλληνας',
  AppTranslations.settingsUkrainian: 'Ουκρανός',
  AppTranslations.settingsTheme: 'Θέμα',
  AppTranslations.settingsDarkMode: 'Σκοτεινή λειτουργία',
  AppTranslations.settingsLightMode: 'Λειτουργία φωτός',
  AppTranslations.settingsLanguageSheetDescription:
      'Επιλέξτε τη γλώσσα της εφαρμογής από μια καθαρή λίστα.',
  AppTranslations.settingsHeroDescription:
      'Διαχειριστείτε τη γλώσσα, την εμφάνιση και την πρόσβαση στον λογαριασμό από ένα μέρος.',
  AppTranslations.settingsPreferencesEyebrow: 'ΠΡΟΤΙΜΗΣΕΙΣ',
  AppTranslations.settingsPreferencesTitle: 'Εμπειρία εφαρμογής',
  AppTranslations.settingsAccountEyebrow: 'ΛΟΓΑΡΙΑΣΜΟΣ',
  AppTranslations.settingsAccountTitle: 'Συνεδρία και ασφάλεια',
  AppTranslations.settingsBlockedUsers: 'Αποκλεισμένοι χρήστες',
  AppTranslations.settingsBlockedUsersSubtitle:
      'Ελέγξτε τα αποκλεισμένα άτομα και αφαιρέστε περιορισμούς όταν χρειάζεται.',
  AppTranslations.blockedUsersTitle: 'Αποκλεισμένοι χρήστες',
  AppTranslations.blockedUsersEmpty:
      'Δεν βρέθηκαν αποκλεισμένοι χρήστες για αυτόν τον λογαριασμό αυτή τη στιγμή.',
  AppTranslations.blockedUsersUnblock: 'Κατάργηση αποκλεισμού',
  AppTranslations.blockedUsersUnblockTitle: 'Κατάργηση αποκλεισμού χρήστη',
  AppTranslations.blockedUsersUnblockMessage:
      'Θέλετε να αφαιρέσετε αυτόν τον χρήστη από τη λίστα αποκλεισμένων;',
  AppTranslations.blockedUsersUserUnblocked:
      'Η κατάργηση αποκλεισμού του χρήστη ολοκληρώθηκε με επιτυχία',
  AppTranslations.settingsDeleteAccount: 'Διαγραφή λογαριασμού',
  AppTranslations.settingsDeleteAccountSubtitle:
      'Καταργήστε οριστικά αυτόν τον λογαριασμό και την πρόσβαση στο Messenger.',
  AppTranslations.settingsDeleteAccountTitle: 'Διαγραφή λογαριασμού',
  AppTranslations.settingsDeleteAccountMessage:
      'Αυτή η ενέργεια είναι μόνιμη. Είστε βέβαιοι ότι θέλετε να διαγράψετε τον λογαριασμό σας;',
  AppTranslations.settingsDeleteAccountConfirm: 'Διαγραφή λογαριασμού',
  AppTranslations.settingsDeleteAccountSuccess:
      'Ο λογαριασμός σας διαγράφηκε με επιτυχία',
  AppTranslations.settingsLogoutSubtitle:
      'Αποσυνδεθείτε από την τρέχουσα περίοδο σύνδεσης σε αυτήν τη συσκευή',
  AppTranslations.settingsLogout: 'Αποσυνδεθείτε',
  AppTranslations.settingsLogoutTitle: 'Αποσυνδεθείτε',
  AppTranslations.settingsLogoutMessage:
      'Είστε βέβαιοι ότι θέλετε να αποσυνδεθείτε από το Messenger σε αυτήν τη συσκευή;',
  AppTranslations.settingsLogoutTimelineBridgeMessage:
      'Θα αποσυνδεθείτε μόνο από το Messenger. Η περίοδος σύνδεσης στο Χρονολόγιό σας θα παραμείνει συνδεδεμένη σε αυτήν τη συσκευή.',
  AppTranslations.settingsLogoutCancel: 'Ακύρωση',
  AppTranslations.settingsLogoutConfirm: 'Αποσυνδεθείτε',
  AppTranslations.settingsLegalEyebrow: 'ΝΟΜΙΚΑ',
  AppTranslations.settingsLegalTitle: 'Απόρρητο και όροι',
  AppTranslations.settingsPrivacyPolicy: 'Πολιτική απορρήτου',
  AppTranslations.settingsPrivacyPolicySubtitle:
      'Δείτε πώς το Ukraina.co-Chat συλλέγει, χρησιμοποιεί και προστατεύει τα δεδομένα λογαριασμού.',
  AppTranslations.settingsTermsOfUse: 'Όροι χρήσης',
  AppTranslations.settingsTermsOfUseSubtitle:
      'Διαβάστε τους κανόνες, τις ευθύνες και τους όρους χρήσης του Ukraina.co-Chat.',
  AppTranslations.navChats: 'Συνομιλίες',
  AppTranslations.navCalls: 'κλήσεις',
  AppTranslations.navProfile: 'Προφίλ',
  AppTranslations.navSettings: 'Ρυθμίσεις',
  AppTranslations.composeTitle: 'Νέα συνομιλία',
  AppTranslations.composeSearchHint: 'Αναζήτηση φίλων',
  AppTranslations.composeSelectContact: 'Επιλέξτε πρώτα έναν φίλο',
  AppTranslations.composeOpenConversation: 'Ανοιχτή συνομιλία',
  AppTranslations.composeContactsUnavailable:
      'Οι επαφές θα εμφανιστούν εδώ μόλις το τελικό σημείο είναι έτοιμο.',
  AppTranslations.composeNoContacts:
      'Δεν υπάρχουν διαθέσιμες επαφές αυτήν τη στιγμή.',
  AppTranslations.composeRecipientId: 'Αναγνωριστικό χρήστη παραλήπτη',
  AppTranslations.composeRecipientHint: 'Εισαγάγετε το αναγνωριστικό χρήστη',
  AppTranslations.composeMessage: 'Πρώτο μήνυμα',
  AppTranslations.composeMessageHint: 'Γράψτε το μήνυμά σας',
  AppTranslations.composeSend: 'Αποστολή',
  AppTranslations.composeRecipientRequired:
      'Απαιτείται αναγνωριστικό χρήστη παραλήπτη',
  AppTranslations.composeMessageRequired: 'Απαιτείται μήνυμα',
  AppTranslations.callsPlaceholder:
      'Η καρτέλα κλήσεων είναι έτοιμη για το επόμενο βήμα API.',
  AppTranslations.callsEmptyTitle: 'Δεν υπάρχουν ακόμη κλήσεις',
  AppTranslations.callsEmptyBody:
      'Οι πρόσφατες φωνητικές και βιντεοκλήσεις σας θα εμφανιστούν εδώ.',
  AppTranslations.callsIncoming: 'Εισερχόμενα',
  AppTranslations.callsOutgoing: 'Εξερχόμενη',
  AppTranslations.callsMissed: 'Χάθηκε',
  AppTranslations.callsDeclined: 'Απορρίφθηκε',
  AppTranslations.callsAnswered: 'Απάντησε',
  AppTranslations.callsOpenChat: 'Ανοίξτε τη συνομιλία',
  AppTranslations.profilePlaceholder:
      'Η καρτέλα Προφίλ είναι δεσμευμένη για στοιχεία λογαριασμού και ταυτότητας.',
  AppTranslations.profileCurrentAccount: 'Τρεχούμενος λογαριασμός',
  AppTranslations.profileConnectedAccounts: 'Συνδεδεμένοι λογαριασμοί',
  AppTranslations.profileAddAccount: 'Προσθήκη λογαριασμού',
  AppTranslations.profileSwitchAccount: 'Διακόπτης',
  AppTranslations.profileRemoveAccount: 'Αφαίρεση',
  AppTranslations.profileRevokeAccount: 'Ανάκληση',
  AppTranslations.profileAccountUsername: 'Όνομα χρήστη',
  AppTranslations.profileAccountEmail: 'Email',
  AppTranslations.profileAccountStatus: 'Κατάσταση λογαριασμού',
  AppTranslations.profileAccountCurrent: 'Τρέχον',
  AppTranslations.profileAccountMaster: 'Δάσκαλος',
  AppTranslations.profileNoConnectedAccounts:
      'Δεν βρέθηκαν ακόμη συνδεδεμένοι λογαριασμοί.',
  AppTranslations.profileAddAccountTitle: 'Προσθήκη συνδεδεμένου λογαριασμού',
  AppTranslations.profileAddAccountIdentifier: 'email ή όνομα χρήστη',
  AppTranslations.profileAddAccountIdentifierHint:
      'Εισαγάγετε τη διεύθυνση ηλεκτρονικού ταχυδρομείου ή το όνομα χρήστη του συνδεδεμένου λογαριασμού',
  AppTranslations.profileAddAccountPassword: 'Κωδικός πρόσβασης λογαριασμού',
  AppTranslations.profileAddAccountConfirm: 'Σύνδεση λογαριασμού',
  AppTranslations.profileAddAccountSuccess:
      'Ο συνδεδεμένος λογαριασμός προστέθηκε με επιτυχία',
  AppTranslations.profileSwitchAccountSuccess:
      'Ο λογαριασμός άλλαξε με επιτυχία',
  AppTranslations.profileRemoveAccountTitle:
      'Κατάργηση συνδεδεμένου λογαριασμού',
  AppTranslations.profileRemoveAccountMessage:
      'Είστε βέβαιοι ότι θέλετε να καταργήσετε αυτόν τον συνδεδεμένο λογαριασμό;',
  AppTranslations.profileRemoveAccountSuccess:
      'Ο συνδεδεμένος λογαριασμός καταργήθηκε με επιτυχία',
  AppTranslations.profileRevokeAccountTitle: 'Ανάκληση σύνδεσης λογαριασμού',
  AppTranslations.profileRevokeAccountMessage:
      'Είστε βέβαιοι ότι θέλετε να ανακαλέσετε την τρέχουσα συνδεδεμένη κύρια σύνδεση;',
  AppTranslations.profileRevokeAccountSuccess:
      'Η σύνδεση λογαριασμού ανακλήθηκε με επιτυχία',
  AppTranslations.profileManageSettings: 'Ανοίξτε τις ρυθμίσεις',
  AppTranslations.profileTimelineBridgeActive:
      'Η περίοδος σύνδεσης γέφυρας χρόνου είναι ενεργή σε αυτήν τη συσκευή.',
  AppTranslations.profileLinkedAccountsDisabled:
      'Η εναλλαγή συνδεδεμένου λογαριασμού είναι απενεργοποιημένη για αυτόν τον λογαριασμό.',
  AppTranslations.profileAccountAdded: 'Ο λογαριασμός συνδέθηκε',
  AppTranslations.profileAccountEmptyField:
      'Απαιτούνται email/όνομα χρήστη και κωδικός πρόσβασης',
  AppTranslations.chatOnlineNow: 'Online τώρα',
  AppTranslations.chatSeen: 'Βλέπεται',
  AppTranslations.chatInputHint: 'Πληκτρολογήστε ένα μήνυμα',
  AppTranslations.chatInfoTitle: 'Πληροφορίες συνομιλίας',
  AppTranslations.chatInfoSharedMedia: 'Κοινόχρηστα μέσα',
  AppTranslations.chatInfoSettings: 'Ρυθμίσεις συνομιλίας',
  AppTranslations.chatInfoAll: 'Όλα',
  AppTranslations.chatInfoImages: 'εικόνες',
  AppTranslations.chatInfoVideos: 'Βίντεο',
  AppTranslations.chatInfoAudio: 'Ήχος',
  AppTranslations.chatInfoFiles: 'Αρχεία',
  AppTranslations.chatInfoLinks: 'Σύνδεσμοι',
  AppTranslations.chatInfoNoSharedMedia:
      'Δεν βρέθηκε κοινόχρηστο περιεχόμενο για αυτήν τη συνομιλία.',
  AppTranslations.chatInfoOpen: 'Ανοίξτε',
  AppTranslations.chatSettingBackground: 'Φόντο συνομιλίας',
  AppTranslations.chatSettingMute: 'Σίγαση ειδοποιήσεων',
  AppTranslations.chatSettingPin: 'Καρφιτσώστε τη συνομιλία',
  AppTranslations.chatSettingBlock: 'Αποκλεισμός χρήστη',
  AppTranslations.chatSettingReport: 'Αναφορά χρήστη',
  AppTranslations.chatSettingReportSubtitle:
      'Στείλτε μια αναφορά ασφάλειας για αυτόν τον λογαριασμό.',
  AppTranslations.chatSettingDelete: 'Διαγραφή συνομιλίας',
  AppTranslations.chatSettingApiPending:
      'Αυτή η ρύθμιση περιμένει το αποκλειστικό τελικό σημείο του API.',
  AppTranslations.chatReportTitle: 'Αναφορά χρήστη',
  AppTranslations.chatReportDescription:
      'Επιλέξτε τον λόγο της αναφοράς. Το Ukraina.co-Chat θα τη στείλει στην ομάδα ελέγχου για εξέταση.',
  AppTranslations.chatReportCategoryLabel: 'Κατηγορία αναφοράς',
  AppTranslations.chatReportCategoryHint: 'Επιλέξτε έναν λόγο',
  AppTranslations.chatReportReasonLabel: 'Πρόσθετες λεπτομέρειες',
  AppTranslations.chatReportReasonHint:
      'Προσθέστε περισσότερες πληροφορίες για να βοηθήσετε στον έλεγχο της αναφοράς.',
  AppTranslations.chatReportSubmit: 'Υποβολή αναφοράς',
  AppTranslations.chatReportSuccess: 'Η αναφορά υποβλήθηκε',
  AppTranslations.chatReportEmptyCategories:
      'Δεν υπάρχουν διαθέσιμες κατηγορίες αναφοράς αυτή τη στιγμή.',
  AppTranslations.chatReportCategoryRequired:
      'Παρακαλώ επιλέξτε κατηγορία αναφοράς πριν συνεχίσετε.',
  AppTranslations.chatReportLoadFailed:
      'Δεν ήταν δυνατή η φόρτωση των κατηγοριών αναφοράς αυτή τη στιγμή.',
  AppTranslations.chatDeleteTitle: 'Διαγραφή συνομιλίας',
  AppTranslations.chatDeleteMessage:
      'Είστε βέβαιοι ότι θέλετε να διαγράψετε αυτήν τη συνομιλία;',
  AppTranslations.chatDeleteConfirm: 'Διαγραφή',
  AppTranslations.chatDeleted: 'Η συνομιλία διαγράφηκε με επιτυχία',
  AppTranslations.chatMessageDelete: 'Διαγραφή μηνύματος',
  AppTranslations.chatMessageEdit: 'Επεξεργασία μηνύματος',
  AppTranslations.chatMessageReply: 'Απάντηση',
  AppTranslations.chatMessageForward: 'Εμπρός',
  AppTranslations.chatMessageCopy: 'Αντιγραφή',
  AppTranslations.chatStickerTitle: 'Αυτοκόλλητα',
  AppTranslations.chatStickerSubtitle:
      'Επιλέξτε ένα πακέτο αυτοκόλλητων και στείλτε ένα αυτοκόλλητο αμέσως.',
  AppTranslations.chatStickerEmpty:
      'Δεν υπάρχουν αυτοκόλλητα διαθέσιμα σε αυτό το πακέτο.',
  AppTranslations.chatMessageDeleteTitle: 'Διαγραφή μηνύματος',
  AppTranslations.chatMessageDeleteMessage:
      'Είστε βέβαιοι ότι θέλετε να διαγράψετε αυτό το μήνυμα;',
  AppTranslations.chatMessageDeleted: 'Το μήνυμα διαγράφηκε με επιτυχία',
  AppTranslations.chatMessageEditPending:
      'Η επεξεργασία μηνυμάτων χρειάζεται ένα αποκλειστικό τελικό σημείο API.',
  AppTranslations.callVoice: 'Φωνητική κλήση',
  AppTranslations.callVideo: 'Βιντεοκλήση',
  AppTranslations.callConnecting: 'Σύνδεση...',
  AppTranslations.callWaiting: 'Αναμονή για συμμετοχή του άλλου',
  AppTranslations.callMicOff: 'Το μικρόφωνο απενεργοποιημένο',
  AppTranslations.callMicOn: 'Μικρόφωνο ενεργοποιημένο',
  AppTranslations.callSpeakerOn: 'Ενεργό ηχείο',
  AppTranslations.callSpeakerOff: 'Σβήσε το ηχείο',
  AppTranslations.callCameraFlip: 'Εναλλαγή κάμερας',
  AppTranslations.callEnd: 'Τερματισμός κλήσης',
  AppTranslations.callPermissionDenied:
      'Απορρίφθηκε η άδεια κάμερας ή μικροφώνου.',
  AppTranslations.callAgoraDisabled:
      'Η κλήση Αγοράς είναι απενεργοποιημένη στο settings.dart.',
  AppTranslations.callAgoraMissingAppId:
      'Το αναγνωριστικό εφαρμογής Agora λείπει στο settings.dart.',
  AppTranslations.callRemoteJoined: 'Συνδεδεμένος',
  AppTranslations.callRinging: 'Κουδούνισμα...',
  AppTranslations.callNoAnswer: 'Καμία απάντηση από τον άλλον.',
  AppTranslations.callDeclined: 'Η κλήση απορρίφθηκε.',
  AppTranslations.callIncoming: 'Εισερχόμενη κλήση',
  AppTranslations.callAccept: 'Αποδοχή',
  AppTranslations.callDeclineAction: 'Απόρριψη',
  AppTranslations.callRecipientBusy:
      'Το άλλο άτομο είναι απασχολημένο αυτή τη στιγμή.',
  AppTranslations.callRecipientOffline: 'Το άλλο άτομο είναι εκτός σύνδεσης.',
  AppTranslations.callCallerBusy: 'Έχετε ήδη μια ενεργή κλήση.',
  AppTranslations.callDirectOnly:
      'Οι κλήσεις είναι διαθέσιμες μόνο σε απευθείας συνομιλίες αυτήν τη στιγμή.',
  AppTranslations.callMissingConnection:
      'Ο διακομιστής δεν επέστρεψε πλήρη δεδομένα σύνδεσης κλήσης.',
  AppTranslations.authFlowHeadline:
      'Απαιτείται πρόσθετο βήμα ελέγχου ταυτότητας',
  AppTranslations.authFlowDescription:
      'Ο διακομιστής αποδέχτηκε τη σύνδεσή σας, αλλά το επόμενο απαραίτητο βήμα είναι: @step',
  AppTranslations.accountBannedTitle: 'Αυτός ο λογαριασμός έχει αποκλειστεί',
  AppTranslations.accountBannedBody:
      'Ο λογαριασμός σας στο Messenger είναι προς το παρόν περιορισμένος και δεν μπορεί να χρησιμοποιήσει την εφαρμογή αυτήν τη στιγμή.',
  AppTranslations.accountBannedSupport:
      'Επικοινωνήστε με την υποστήριξη ή τον διαχειριστή του ιστότοπου εάν πιστεύετε ότι αυτό συνέβη κατά λάθος.',
  AppTranslations.accountBannedContactSupport:
      'Επικοινωνήστε με την υποστήριξη',
  AppTranslations.authActivationTitle: 'Απαιτείται ενεργοποίηση',
  AppTranslations.authActivationDescription:
      'Εισαγάγετε τον κωδικό επαλήθευσης που στάλθηκε στον λογαριασμό σας για να συνεχίσετε.',
  AppTranslations.authApprovalTitle: 'Απαιτείται έγκριση',
  AppTranslations.authApprovalDescription:
      'Ο λογαριασμός σας περιμένει έγκριση για να συνεχίσει το Messenger.',
  AppTranslations.authGettingStartedTitle: 'Απαιτείται η έναρξη',
  AppTranslations.authGettingStartedDescription:
      'Ο λογαριασμός σας χρειάζεται ένα ακόμη βήμα ρύθμισης για να ανοίξει πλήρως το Messenger.',
  AppTranslations.authTwoFactorTitle: 'Επαλήθευση δύο παραγόντων',
  AppTranslations.authTwoFactorDescription:
      'Εισαγάγετε τον κωδικό επαλήθευσης από τη διαμορφωμένη μέθοδο δύο παραγόντων.',
  AppTranslations.verificationCode: 'Κωδικός επαλήθευσης',
  AppTranslations.verificationCodeHint:
      'Εισαγάγετε τον κωδικό ακριβώς όπως λάβατε',
  AppTranslations.verificationCodeRequired: 'Απαιτείται κωδικός επαλήθευσης',
  AppTranslations.resendCode: 'Επανάληψη αποστολής κωδικού',
  AppTranslations.verifyAndContinue: 'Επαληθεύστε και συνεχίστε',
  AppTranslations.activationCodeSent: 'Έχει σταλεί νέος κωδικός ενεργοποίησης.',
  AppTranslations.authUnableToLoadState:
      'Δεν είναι δυνατή η φόρτωση της κατάστασης ελέγχου ταυτότητας αυτήν τη στιγμή.',
  AppTranslations.authUnableToVerifyCode:
      'Δεν είναι δυνατή η επαλήθευση του κωδικού αυτήν τη στιγμή.',
  AppTranslations.authUnableToResendCode:
      'Δεν είναι δυνατή η εκ νέου αποστολή του κωδικού αυτήν τη στιγμή.',
  AppTranslations.backToLogin: 'Επιστροφή στην είσοδο',
  AppTranslations.loginFailed: 'Δεν είναι δυνατή η σύνδεση αυτήν τη στιγμή',
  AppTranslations.commonConversation: 'Συνομιλία',
  AppTranslations.commonChat: 'Συνομιλία',
  AppTranslations.commonConversations: 'συνομιλίες',
  AppTranslations.commonPeople: 'Άνθρωποι',
  AppTranslations.commonPost: 'Ανάρτηση',
  AppTranslations.commonStory: 'Ιστορία',
  AppTranslations.commonReel: 'Καρούλι',
  AppTranslations.commonProduct: 'Προϊόν',
  AppTranslations.commonImage: 'Εικόνα',
  AppTranslations.commonVideo: 'Βίντεο',
  AppTranslations.commonSticker: 'Αυτοκόλλητο',
  AppTranslations.commonOn: 'Ενεργό',
  AppTranslations.commonOff: 'Απενεργοποίηση',
  AppTranslations.commonColors: 'Χρώματα',
  AppTranslations.commonGradients: 'Διαβαθμίσεις',
  AppTranslations.commonReset: 'Επαναφορά',
  AppTranslations.commonTimeline: 'Χρονολόγιο',
  AppTranslations.timelineAppNotInstalledTitle:
      'Η εφαρμογή Timeline δεν είναι εγκατεστημένη',
  AppTranslations.timelineAppNotInstalledMessage:
      'Για να ανοίξετε αυτό το περιεχόμενο, εγκαταστήστε πρώτα την εφαρμογή Timeline. Θέλετε να τη κατεβάσετε τώρα;',
  AppTranslations.timelineAppCancelAction: 'Ακύρωση',
  AppTranslations.timelineAppDownloadAction: 'Λήψη',
  AppTranslations.sharedPost: 'Κοινή ανάρτηση',
  AppTranslations.sharedReel: 'Κοινόχρηστος κύλινδρος',
  AppTranslations.sharePostTitle: 'Κοινή χρήση ανάρτησης',
  AppTranslations.shareReelTitle: 'Share Reel',
  AppTranslations.shareSearchHint: 'Αναζήτηση συνομιλιών ή ατόμων',
  AppTranslations.shareEmptyTargets:
      'Δεν υπάρχουν διαθέσιμες συνομιλίες ή επαφές',
  AppTranslations.profileQuickSettingsSubtitle:
      'Απόρρητο, ειδοποιήσεις και προτιμήσεις',
  AppTranslations.profileConnectAnother: 'Συνδέστε ένα άλλο προφίλ',
  AppTranslations.profileAddAccountDisabled:
      'Η προσθήκη λογαριασμών είναι απενεργοποιημένη',
  AppTranslations.profileIdentityEyebrow: 'ΤΑΥΤΟΤΗΤΑ',
  AppTranslations.profileSwitcherEyebrow: 'ΔΙΑΚΟΠΤΗΣ',
  AppTranslations.profileAttachAnotherAccount:
      'Επισυνάψτε έναν άλλο λογαριασμό για γρήγορη εναλλαγή',
  AppTranslations.profileNoEmailAttached: 'Δεν επισυνάπτεται email',
  AppTranslations.profileReadyToSwitch: 'Έτοιμο για εναλλαγή',
  AppTranslations.chatPin: 'Καρφίτσα',
  AppTranslations.chatUnpin: 'Ξεκαρφίτσωμα',
  AppTranslations.chatConversationPinned: 'Η συνομιλία καρφιτσώθηκε',
  AppTranslations.chatConversationUnpinned: 'Η συνομιλία ξεκαρφιτσώθηκε',
  AppTranslations.chatDirectConversation: 'Απευθείας συνομιλία',
  AppTranslations.chatGroupConversation: 'Ομαδική συνομιλία',
  AppTranslations.callsTotal: 'Σύνολο',
  AppTranslations.callsAll: 'Όλες οι κλήσεις',
  AppTranslations.callsHeroSubtitle:
      'Παρακολουθήστε τις αναπάντητες, τις απαντημένες και τις βιντεοκλήσεις σε μία καθαρή προβολή.',
  AppTranslations.homeRecentActivity: 'Πρόσφατη δραστηριότητα',
  AppTranslations.chatSettingsSubtitle:
      'Διαχειριστείτε τις ειδοποιήσεις, την κατάσταση καρφίτσας και τις ενέργειες συνομιλίας.',
  AppTranslations.chatBackgroundSubtitle:
      'Επιλέξτε ένα προσαρμοσμένο φόντο για αυτήν τη συνομιλία.',
  AppTranslations.chatRecordingTitle: 'Ηχογράφηση',
  AppTranslations.chatRecordingBody:
      'Πατήστε ξανά το μικρόφωνο για διακοπή και αποστολή',
  AppTranslations.chatInvalidConversationId:
      'Μη έγκυρο αναγνωριστικό συνομιλίας',
  AppTranslations.chatImageUnavailable: 'Η εικόνα δεν είναι διαθέσιμη',
  AppTranslations.chatSharedItemOpenFailed:
      'Δεν είναι δυνατό το άνοιγμα κοινόχρηστου στοιχείου',
  AppTranslations.chatVoiceUnavailable:
      'Το φωνητικό μήνυμα δεν είναι διαθέσιμο',
  AppTranslations.chatVideoUnavailable: 'Το βίντεο δεν είναι διαθέσιμο',
  AppTranslations.chatReplyingTo: 'Απαντώντας σε',
  AppTranslations.chatReplyToYourself: 'Το μήνυμά σας',
  AppTranslations.chatReplyOriginalUnavailable:
      'Το αρχικό μήνυμα δεν είναι διαθέσιμο',
  AppTranslations.chatRepliedToStory: 'Απάντησε σε μια ιστορία',
  AppTranslations.chatReactedToStory: 'Αντέδρασε σε μια ιστορία',
  AppTranslations.chatEditingMessage: 'Επεξεργασία μηνύματος',
  AppTranslations.chatMessageCopied: 'Το μήνυμα αντιγράφηκε',
  AppTranslations.forwardTitle: 'Προώθηση μηνύματος',
  AppTranslations.forwardSearchHint: 'Αναζήτηση συνομιλιών ή ατόμων',
  AppTranslations.forwardEmptyTargets:
      'Δεν υπάρχουν διαθέσιμες συνομιλίες ή επαφές',
  AppTranslations.forwardPreviewTitle: 'Προωθήθηκε μήνυμα',
  AppTranslations.forwardSent: 'Το μήνυμα προωθήθηκε με επιτυχία',
};
