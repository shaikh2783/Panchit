import '../../../core/license/license_runtime.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get signIn => LicenseRuntime.endpoint('signIn');
  static String get signUp => LicenseRuntime.endpoint('signUp');
  static String get authState => LicenseRuntime.endpoint('authState');
  static String get authTwoFactorVerify =>
      LicenseRuntime.endpoint('authTwoFactorVerify');
  static String get authActivationVerify =>
      LicenseRuntime.endpoint('authActivationVerify');
  static String get authActivationEmailResend =>
      LicenseRuntime.endpoint('authActivationEmailResend');
  static String get authForgotPassword =>
      LicenseRuntime.endpoint('authForgotPassword');
  static String get authForgotPasswordConfirm =>
      LicenseRuntime.endpoint('authForgotPasswordConfirm');
  static String get authForgotPasswordReset =>
      LicenseRuntime.endpoint('authForgotPasswordReset');
  static String get userDeleteAccount =>
      LicenseRuntime.endpoint('userDeleteAccount');

  static String get signOut => LicenseRuntime.endpoint('signOut');
  static String get appSettings => LicenseRuntime.endpoint('appSettings');
  static String get userOneSignalRegister =>
      LicenseRuntime.endpoint('userOneSignalRegister');
  static String get userOneSignalDelete =>
      LicenseRuntime.endpoint('userOneSignalDelete');
  static String get userFcmRegister =>
      LicenseRuntime.endpoint('userFcmRegister');
  static String get userFcmDelete => LicenseRuntime.endpoint('userFcmDelete');
  static String get userBlockedList =>
      LicenseRuntime.endpoint('userBlockedList');
  static String get userBlock => LicenseRuntime.endpoint('userBlock');
  static String get userUnblock => LicenseRuntime.endpoint('userUnblock');
  static const String groupsChatManifest =
      '/api-addon-messangr/groups-chat/manifest';
  static const String groupsChatReactionTypes =
      '/api-addon-messangr/groups-chat/reactions/types';
  static const String groupsChatGroups =
      '/api-addon-messangr/groups-chat/groups';
  static const String groupsChatUploadPhoto =
      '/api-addon-messangr/groups-chat/upload/photo';
  static const String groupsChatUploadVideo =
      '/api-addon-messangr/groups-chat/upload/video';
  static const String groupsChatUploadVoiceNote =
      '/api-addon-messangr/groups-chat/upload/voice-note';
  static const String groupsChatUploadFile =
      '/api-addon-messangr/groups-chat/upload/file';
  static const String userReportCategories =
      '/api-addon-messangr/user/report/categories';
  static const String userReport = '/api-addon-messangr/user/report';

  static String get connectedAccounts =>
      LicenseRuntime.endpoint('connectedAccounts');
  static String get connectedAccountsAdd =>
      LicenseRuntime.endpoint('connectedAccountsAdd');
  static String get connectedAccountsSwitch =>
      LicenseRuntime.endpoint('connectedAccountsSwitch');
  static String get connectedAccountsRemove =>
      LicenseRuntime.endpoint('connectedAccountsRemove');
  static String get connectedAccountsRevoke =>
      LicenseRuntime.endpoint('connectedAccountsRevoke');
  static String get authBridgeOpenChat =>
      LicenseRuntime.endpoint('authBridgeOpenChat');
  static String get chatManifest => LicenseRuntime.endpoint('chatManifest');
  static String get storiesList => LicenseRuntime.endpoint('storiesList');
  static String get storiesPublish => LicenseRuntime.endpoint('storiesPublish');
  static String get storiesReply => LicenseRuntime.endpoint('storiesReply');
  static String get storiesReact => LicenseRuntime.endpoint('storiesReact');
  static String get storiesView => LicenseRuntime.endpoint('storiesView');
  static String get storiesViewers => LicenseRuntime.endpoint('storiesViewers');
  static String get storiesReactions =>
      LicenseRuntime.endpoint('storiesReactions');
  static String get chatOpen => LicenseRuntime.endpoint('chatOpen');
  static String get chatLaunchToken =>
      LicenseRuntime.endpoint('chatLaunchToken');
  static String get chatConversations =>
      LicenseRuntime.endpoint('chatConversations');
  static String get chatConversation =>
      LicenseRuntime.endpoint('chatConversation');
  static String get chatConversationStatus =>
      LicenseRuntime.endpoint('chatConversationStatus');
  static String get chatShared => LicenseRuntime.endpoint('chatShared');
  static String get chatMessages => LicenseRuntime.endpoint('chatMessages');
  static String get chatMessagesChanges =>
      LicenseRuntime.endpoint('chatMessagesChanges');
  static String get chatContacts => LicenseRuntime.endpoint('chatContacts');
  static String get chatMessage => LicenseRuntime.endpoint('chatMessage');
  static String get chatMessageForward =>
      LicenseRuntime.endpoint('chatMessageForward');
  static String get chatActionsSeen =>
      LicenseRuntime.endpoint('chatActionsSeen');
  static String get chatNotificationsMute =>
      LicenseRuntime.endpoint('chatNotificationsMute');
  static String get chatNotificationsUnmute =>
      LicenseRuntime.endpoint('chatNotificationsUnmute');
  static String get chatNotificationsMuted =>
      LicenseRuntime.endpoint('chatNotificationsMuted');
  static String get chatCalls => LicenseRuntime.endpoint('chatCalls');
  static String get chatCallSettings =>
      LicenseRuntime.endpoint('chatCallSettings');
  static String get chatCallBootstrap =>
      LicenseRuntime.endpoint('chatCallBootstrap');
  static String get chatCallStart => LicenseRuntime.endpoint('chatCallStart');
  static const String chatCallInvite = '/api-addon-messangr/chat/calls/invite';
  static const String chatCallParticipants =
      '/api-addon-messangr/chat/calls/participants';
  static const String chatCallLeave = '/api-addon-messangr/chat/calls/leave';
  static const String chatCallSignals =
      '/api-addon-messangr/chat/calls/signals';
  static const String chatCallSignalsAck =
      '/api-addon-messangr/chat/calls/signals/ack';
  static const String chatCallIceConfig =
      '/api-addon-messangr/chat/calls/ice-config';
  static String get chatCallAnswer => LicenseRuntime.endpoint('chatCallAnswer');
  static String get chatCallDecline =>
      LicenseRuntime.endpoint('chatCallDecline');
  static String get chatCallCancel => LicenseRuntime.endpoint('chatCallCancel');
  static String get chatCallEnd => LicenseRuntime.endpoint('chatCallEnd');

  static String get chatCallUpdate => LicenseRuntime.endpoint('chatCallUpdate');
  static const String chatCallCheckResponse =
      '/api-addon-messangr/chat/calls/check-response';
  static String get chatCallCheckNew =>
      LicenseRuntime.endpoint('chatCallCheckNew');
  static String get chatReactionTypes =>
      LicenseRuntime.endpoint('chatReactionTypes');
  static String get chatReactionReact =>
      LicenseRuntime.endpoint('chatReactionReact');
  static String get chatBackgrounds =>
      LicenseRuntime.endpoint('chatBackgrounds');
  static String get chatStickers => LicenseRuntime.endpoint('chatStickers');
  static String get chatStickerPacks =>
      LicenseRuntime.endpoint('chatStickerPacks');
  static String get chatUploadPhoto =>
      LicenseRuntime.endpoint('chatUploadPhoto');
  static String get chatUploadVideo =>
      LicenseRuntime.endpoint('chatUploadVideo');
  static String get chatUploadVoiceNote =>
      LicenseRuntime.endpoint('chatUploadVoiceNote');
  static String get chatUploadFile => LicenseRuntime.endpoint('chatUploadFile');
}
