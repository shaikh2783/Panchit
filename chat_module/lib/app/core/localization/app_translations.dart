import 'package:get/get.dart';

import 'lang/ar.dart';
import 'lang/de.dart';
import 'lang/el.dart';
import 'lang/en.dart';
import 'lang/es.dart';
import 'lang/fr.dart';
import 'lang/it.dart';
import 'lang/nl.dart';
import 'lang/pt.dart';
import 'lang/pt_br.dart';
import 'lang/ro.dart';
import 'lang/ru.dart';
import 'lang/tr.dart';
import 'lang/uk.dart';

class AppTranslations extends Translations {
  static const String appName = 'Messanger';
  static const String loginHeadline = 'login_headline';
  static const String loginSubtitle = 'login_subtitle';
  static const String loginIdentifierLabel = 'login_identifier_label';
  static const String loginIdentifierHint = 'login_identifier_hint';
  static const String passwordLabel = 'password_label';
  static const String passwordHint = 'password_hint';
  static const String rememberMe = 'remember_me';
  static const String forgotPassword = 'forgot_password';
  static const String forgotPasswordTitle = 'forgot_password_title';
  static const String forgotPasswordSubtitle = 'forgot_password_subtitle';
  static const String forgotPasswordIdentifierLabel =
      'forgot_password_identifier_label';
  static const String forgotPasswordIdentifierHint =
      'forgot_password_identifier_hint';
  static const String forgotPasswordCodeLabel = 'forgot_password_code_label';
  static const String forgotPasswordCodeHint = 'forgot_password_code_hint';
  static const String forgotPasswordNewPasswordLabel =
      'forgot_password_new_password_label';
  static const String forgotPasswordNewPasswordHint =
      'forgot_password_new_password_hint';
  static const String forgotPasswordConfirmPasswordLabel =
      'forgot_password_confirm_password_label';
  static const String forgotPasswordConfirmPasswordHint =
      'forgot_password_confirm_password_hint';
  static const String forgotPasswordRequestAction =
      'forgot_password_request_action';
  static const String forgotPasswordVerifyAction =
      'forgot_password_verify_action';
  static const String forgotPasswordResetAction =
      'forgot_password_reset_action';
  static const String forgotPasswordCodeRequired =
      'forgot_password_code_required';
  static const String forgotPasswordIdentifierRequired =
      'forgot_password_identifier_required';
  static const String forgotPasswordNewPasswordRequired =
      'forgot_password_new_password_required';
  static const String forgotPasswordConfirmPasswordRequired =
      'forgot_password_confirm_password_required';
  static const String forgotPasswordCodeSent = 'forgot_password_code_sent';
  static const String forgotPasswordCodeVerified =
      'forgot_password_code_verified';
  static const String forgotPasswordPasswordUpdated =
      'forgot_password_password_updated';
  static const String forgotPasswordResetHelp = 'forgot_password_reset_help';
  static const String signIn = 'sign_in';
  static const String createAccount = 'create_account';
  static const String alreadyHaveAccount = 'already_have_account';
  static const String dontHaveAccount = 'dont_have_account';
  static const String registerTitle = 'register_title';
  static const String registerSubtitle = 'register_subtitle';
  static const String signUpHeadline = 'sign_up_headline';
  static const String signUpSubtitle = 'sign_up_subtitle';
  static const String signUpToggleTitle = 'sign_up_toggle_title';
  static const String signInToggleTitle = 'sign_in_toggle_title';
  static const String signUpUsernameLabel = 'sign_up_username_label';
  static const String signUpUsernameHint = 'sign_up_username_hint';
  static const String signUpEmailLabel = 'sign_up_email_label';
  static const String signUpEmailHint = 'sign_up_email_hint';
  static const String signUpFirstNameLabel = 'sign_up_first_name_label';
  static const String signUpFirstNameHint = 'sign_up_first_name_hint';
  static const String signUpLastNameLabel = 'sign_up_last_name_label';
  static const String signUpLastNameHint = 'sign_up_last_name_hint';
  static const String signUpGenderLabel = 'sign_up_gender_label';
  static const String signUpGenderMale = 'sign_up_gender_male';
  static const String signUpGenderFemale = 'sign_up_gender_female';
  static const String optionalLabel = 'optional_label';
  static const String signUpConfirmPasswordLabel =
      'sign_up_confirm_password_label';
  static const String signUpConfirmPasswordHint =
      'sign_up_confirm_password_hint';
  static const String signUpUsernameRequired = 'sign_up_username_required';
  static const String signUpUsernameTooShort = 'sign_up_username_too_short';
  static const String signUpEmailRequired = 'sign_up_email_required';
  static const String signUpEmailInvalid = 'sign_up_email_invalid';
  static const String signUpPasswordTooShort = 'sign_up_password_too_short';
  static const String signUpConfirmPasswordRequired =
      'sign_up_confirm_password_required';
  static const String signUpPasswordsDoNotMatch =
      'sign_up_passwords_do_not_match';
  static const String signUpFirstNameRequired = 'sign_up_first_name_required';
  static const String signUpLastNameRequired = 'sign_up_last_name_required';
  static const String signUpFailed = 'sign_up_failed';
  static const String signUpNote = 'sign_up_note';
  static const String signUpAgreementPrefix = 'sign_up_agreement_prefix';
  static const String signUpAgreementAnd = 'sign_up_agreement_and';
  static const String signUpAgreementSuffix = 'sign_up_agreement_suffix';
  static const String signUpTermsOfUse = 'sign_up_terms_of_use';
  static const String signUpPrivacyPolicy = 'sign_up_privacy_policy';
  static const String signUpTermsRequiredTitle = 'sign_up_terms_required_title';
  static const String signUpTermsRequiredMessage =
      'sign_up_terms_required_message';
  static const String webViewPageTitle = 'web_view_page_title';
  static const String secureAccessNote = 'secure_access_note';
  static const String loginFooter = 'login_footer';
  static const String loginWithTimeline = 'login_with_timeline';
  static const String loginWithTimelineSubtitle =
      'login_with_timeline_subtitle';
  static const String identifierRequired = 'identifier_required';
  static const String passwordRequired = 'password_required';
  static const String loading = 'loading';
  static const String homeHeadline = 'home_headline';
  static const String homeSubtitle = 'home_subtitle';
  static const String homeWelcomeBack = 'home_welcome_back';
  static const String homeSearchHint = 'home_search_hint';
  static const String homeSearchEmptyTitle = 'home_search_empty_title';
  static const String homeSearchEmptyBody = 'home_search_empty_body';
  static const String homeSearchErrorTitle = 'home_search_error_title';
  static const String addStory = 'add_story';
  static const String shareStory = 'share_story';
  static const String storyAddText = 'story_add_text';
  static const String storyTextHint = 'story_text_hint';
  static const String storyMediaHint = 'story_media_hint';
  static const String camera = 'camera';
  static const String gallery = 'gallery';
  static const String done = 'done';
  static const String replyToStory = 'reply_to_story';
  static const String storyReplySent = 'story_reply_sent';
  static const String storyReactionSent = 'story_reaction_sent';
  static const String storyPublished = 'story_published';
  static const String storyViews = 'story_views';
  static const String storyViewers = 'story_viewers';
  static const String storyReactions = 'story_reactions';
  static const String noStoryViewers = 'no_story_viewers';
  static const String noStoryReactions = 'no_story_reactions';
  static const String unableToLoadStoryViewers = 'unable_to_load_story_viewers';
  static const String unableToLoadStoryReactions =
      'unable_to_load_story_reactions';
  static const String unableToReplyToStory = 'unable_to_reply_to_story';
  static const String unableToReactToStory = 'unable_to_react_to_story';
  static const String unableToPublishStory = 'unable_to_publish_story';
  static const String storiesLoadFailed = 'stories_load_failed';
  static const String storyFeatureSoon = 'story_feature_soon';
  static const String homeStoriesTitle = 'home_stories_title';
  static const String homeChatsTitle = 'home_chats_title';
  static const String homeTabAll = 'home_tab_all';
  static const String homeTabUnread = 'home_tab_unread';
  static const String homeTabGroups = 'home_tab_groups';
  static const String homeOnlineNow = 'home_online_now';
  static const String homeTypePlaceholder = 'home_type_placeholder';
  static const String homeStatusActive = 'home_status_active';
  static const String homeStatusTyping = 'home_status_typing';
  static const String homeStatusSent = 'home_status_sent';
  static const String homeStatusDelivered = 'home_status_delivered';
  static const String homeStatusVoice = 'home_status_voice';
  static const String homeStatusMuted = 'home_status_muted';
  static const String homeChatsUnavailableTitle =
      'home_chats_unavailable_title';
  static const String homeChatsUnavailableBody = 'home_chats_unavailable_body';
  static const String homeChatsEmptyTitle = 'home_chats_empty_title';
  static const String homeChatsEmptyBody = 'home_chats_empty_body';
  static const String homeChatsEmptyAction = 'home_chats_empty_action';
  static const String retry = 'retry';
  static const String settingsTitle = 'settings_title';
  static const String settingsLanguage = 'settings_language';
  static const String settingsArabic = 'settings_arabic';
  static const String settingsEnglish = 'settings_english';
  static const String settingsFrench = 'settings_french';
  static const String settingsSpanish = 'settings_spanish';
  static const String settingsPortuguese = 'settings_portuguese';
  static const String settingsGerman = 'settings_german';
  static const String settingsTurkish = 'settings_turkish';
  static const String settingsDutch = 'settings_dutch';
  static const String settingsItalian = 'settings_italian';
  static const String settingsRussian = 'settings_russian';
  static const String settingsRomanian = 'settings_romanian';
  static const String settingsPortugueseBrazil = 'settings_portuguese_brazil';
  static const String settingsGreek = 'settings_greek';
  static const String settingsUkrainian = 'settings_ukrainian';
  static const String settingsTheme = 'settings_theme';
  static const String settingsDarkMode = 'settings_dark_mode';
  static const String settingsLightMode = 'settings_light_mode';
  static const String settingsSystemMode = 'settings_system_mode';
  static const String settingsThemeDescription = 'settings_theme_description';
  static const String settingsLanguageSheetDescription =
      'settings_language_sheet_description';
  static const String settingsHeroDescription = 'settings_hero_description';
  static const String settingsPreferencesEyebrow =
      'settings_preferences_eyebrow';
  static const String settingsPreferencesTitle = 'settings_preferences_title';
  static const String settingsAccountEyebrow = 'settings_account_eyebrow';
  static const String settingsAccountTitle = 'settings_account_title';
  static const String settingsAccountControlsTitle =
      'settings_account_controls_title';
  static const String settingsBlockedUsers = 'settings_blocked_users';
  static const String settingsBlockedUsersSubtitle =
      'settings_blocked_users_subtitle';
  static const String settingsDeleteAccount = 'settings_delete_account';
  static const String settingsDeleteAccountSubtitle =
      'settings_delete_account_subtitle';
  static const String settingsDeleteAccountTitle =
      'settings_delete_account_title';
  static const String settingsDeleteAccountMessage =
      'settings_delete_account_message';
  static const String settingsDeleteAccountConfirm =
      'settings_delete_account_confirm';
  static const String settingsDeleteAccountSuccess =
      'settings_delete_account_success';
  static const String settingsLogoutSubtitle = 'settings_logout_subtitle';
  static const String settingsLogout = 'settings_logout';
  static const String settingsLogoutTitle = 'settings_logout_title';
  static const String settingsLogoutMessage = 'settings_logout_message';
  static const String settingsLogoutTimelineBridgeMessage =
      'settings_logout_timeline_bridge_message';
  static const String settingsLogoutCancel = 'settings_logout_cancel';
  static const String settingsLogoutConfirm = 'settings_logout_confirm';
  static const String settingsLegalEyebrow = 'settings_legal_eyebrow';
  static const String settingsLegalTitle = 'settings_legal_title';
  static const String settingsPrivacyPolicy = 'settings_privacy_policy';
  static const String settingsPrivacyPolicySubtitle =
      'settings_privacy_policy_subtitle';
  static const String settingsTermsOfUse = 'settings_terms_of_use';
  static const String settingsTermsOfUseSubtitle =
      'settings_terms_of_use_subtitle';
  static const String settingsCallAccessEyebrow =
      'settings_call_access_eyebrow';
  static const String settingsCallAccessTitle = 'settings_call_access_title';
  static const String settingsCallAccessDescription =
      'settings_call_access_description';
  static const String settingsCallAccessNotifications =
      'settings_call_access_notifications';
  static const String settingsCallAccessNotificationsSubtitle =
      'settings_call_access_notifications_subtitle';
  static const String settingsCallAccessFullScreen =
      'settings_call_access_full_screen';
  static const String settingsCallAccessFullScreenSubtitle =
      'settings_call_access_full_screen_subtitle';
  static const String settingsCallAccessBattery =
      'settings_call_access_battery';
  static const String settingsCallAccessBatterySubtitle =
      'settings_call_access_battery_subtitle';
  static const String settingsCallAccessEnabled =
      'settings_call_access_enabled';
  static const String settingsCallAccessNeedsSetup =
      'settings_call_access_needs_setup';
  static const String settingsCallAccessOpening =
      'settings_call_access_opening';
  static const String navChats = 'nav_chats';
  static const String navGroups = 'nav_groups';
  static const String navContacts = 'nav_contacts';
  static const String navCalls = 'nav_calls';
  static const String navProfile = 'nav_profile';
  static const String navSettings = 'nav_settings';
  static const String composeTitle = 'compose_title';
  static const String composeSearchHint = 'compose_search_hint';
  static const String composeSelectContact = 'compose_select_contact';
  static const String composeOpenConversation = 'compose_open_conversation';
  static const String composeContactsUnavailable =
      'compose_contacts_unavailable';
  static const String composeCannotMessage = 'compose_cannot_message';
  static const String composeNoContacts = 'compose_no_contacts';
  static const String composeRecipientId = 'compose_recipient_id';
  static const String composeRecipientHint = 'compose_recipient_hint';
  static const String composeMessage = 'compose_message';
  static const String composeMessageHint = 'compose_message_hint';
  static const String composeSend = 'compose_send';
  static const String composeRecipientRequired = 'compose_recipient_required';
  static const String composeMessageRequired = 'compose_message_required';
  static const String callsPlaceholder = 'calls_placeholder';
  static const String callsEmptyTitle = 'calls_empty_title';
  static const String callsEmptyBody = 'calls_empty_body';
  static const String callsIncoming = 'calls_incoming';
  static const String callsOutgoing = 'calls_outgoing';
  static const String callsMissed = 'calls_missed';
  static const String callsDeclined = 'calls_declined';
  static const String callsAnswered = 'calls_answered';
  static const String callsOpenChat = 'calls_open_chat';
  static const String groupsTitle = 'groups_title';
  static const String groupsSubtitle = 'groups_subtitle';
  static const String groupsEmptyTitle = 'groups_empty_title';
  static const String groupsEmptyBody = 'groups_empty_body';
  static const String groupsNoMessages = 'groups_no_messages';
  static const String groupsOpenSoon = 'groups_open_soon';
  static const String groupsMember = 'groups_member';
  static const String groupsMembers = 'groups_members';
  static const String groupsOwner = 'groups_owner';
  static const String groupsAdmin = 'groups_admin';
  static const String groupsMemberRole = 'groups_member_role';
  static const String groupsAdminsOnly = 'groups_admins_only';
  static const String groupsMuted = 'groups_muted';
  static const String groupsUnread = 'groups_unread';
  static const String groupsTotal = 'groups_total';
  static const String groupsLatest = 'groups_latest';
  static const String groupsPhoto = 'groups_photo';
  static const String groupsVideo = 'groups_video';
  static const String groupsVoice = 'groups_voice';
  static const String groupsFile = 'groups_file';
  static const String groupsCreate = 'groups_create';
  static const String groupsCreateTitle = 'groups_create_title';
  static const String groupsName = 'groups_name';
  static const String groupsNameHint = 'groups_name_hint';
  static const String groupsDescription = 'groups_description';
  static const String groupsDescriptionHint = 'groups_description_hint';
  static const String groupsNameRequired = 'groups_name_required';
  static const String groupsCreated = 'groups_created';
  static const String groupsCreateFailed = 'groups_create_failed';
  static const String groupChatInputHint = 'group_chat_input_hint';
  static const String groupChatEmptyTitle = 'group_chat_empty_title';
  static const String groupChatEmptyBody = 'group_chat_empty_body';
  static const String groupChatOnlyAdmins = 'group_chat_only_admins';
  static const String groupChatMutedByAdmin = 'group_chat_muted_by_admin';
  static const String groupChatUnableToSend = 'group_chat_unable_to_send';
  static const String groupDetailsTitle = 'group_details_title';
  static const String groupDetailsSubtitle = 'group_details_subtitle';
  static const String groupDetailsNoDescription =
      'group_details_no_description';
  static const String groupDetailsEditInfo = 'group_details_edit_info';
  static const String groupDetailsChangePhoto = 'group_details_change_photo';
  static const String groupDetailsRemovePhoto = 'group_details_remove_photo';
  static const String groupDetailsUploadingPhoto =
      'group_details_uploading_photo';
  static const String groupDetailsAddMembers = 'group_details_add_members';
  static const String groupDetailsCopyLink = 'group_details_copy_link';
  static const String groupDetailsLinkCopied = 'group_details_link_copied';
  static const String groupDetailsChangeLink = 'group_details_change_link';
  static const String groupDetailsChangeLinkSubtitle =
      'group_details_change_link_subtitle';
  static const String groupDetailsChangeLinkConfirmBody =
      'group_details_change_link_confirm_body';
  static const String groupDetailsLinkChanged = 'group_details_link_changed';
  static const String groupDetailsMembersTitle = 'group_details_members_title';
  static const String groupDetailsNotifications = 'group_details_notifications';
  static const String groupDetailsMuteNotifications =
      'group_details_mute_notifications';
  static const String groupDetailsMutedSubtitle =
      'group_details_muted_subtitle';
  static const String groupDetailsUnmutedSubtitle =
      'group_details_unmuted_subtitle';
  static const String groupDetailsPermissions = 'group_details_permissions';
  static const String groupDetailsMemberChat = 'group_details_member_chat';
  static const String groupDetailsMemberChatEnabled =
      'group_details_member_chat_enabled';
  static const String groupDetailsMemberChatDisabled =
      'group_details_member_chat_disabled';
  static const String groupDetailsWhoCanSend = 'group_details_who_can_send';
  static const String groupDetailsWhoCanEdit = 'group_details_who_can_edit';
  static const String groupDetailsWhoCanViewMembers =
      'group_details_who_can_view_members';
  static const String groupDetailsMemberListVisible =
      'group_details_member_list_visible';
  static const String groupDetailsMemberListHidden =
      'group_details_member_list_hidden';
  static const String groupDetailsEveryone = 'group_details_everyone';
  static const String groupDetailsAdminsOption = 'group_details_admins_option';
  static const String groupDetailsSaveChanges = 'group_details_save_changes';
  static const String groupDetailsSaved = 'group_details_saved';
  static const String groupDetailsUnableToLoad = 'group_details_unable_to_load';
  static const String groupDetailsUnableToSave = 'group_details_unable_to_save';
  static const String groupDetailsSelectMembers =
      'group_details_select_members';
  static const String groupDetailsNoContacts = 'group_details_no_contacts';
  static const String groupDetailsAddedMembers = 'group_details_added_members';
  static const String groupInvitationSend = 'group_invitation_send';
  static const String groupInvitationSent = 'group_invitation_sent';
  static const String groupInvitationsTitle = 'group_invitations_title';
  static const String groupInvitationsEmpty = 'group_invitations_empty';
  static const String groupInvitationFrom = 'group_invitation_from';
  static const String groupInvitationAccept = 'group_invitation_accept';
  static const String groupInvitationReject = 'group_invitation_reject';
  static const String groupInvitationAccepted = 'group_invitation_accepted';
  static const String groupInvitationRejected = 'group_invitation_rejected';
  static const String groupInvitationUnableToUpdate =
      'group_invitation_unable_to_update';
  static const String groupJoinRequestsTitle = 'group_join_requests_title';
  static const String groupJoinRequestsEmpty = 'group_join_requests_empty';
  static const String groupJoinRequestsPending = 'group_join_requests_pending';
  static const String groupJoinRequestsApprove = 'group_join_requests_approve';
  static const String groupJoinRequestsReject = 'group_join_requests_reject';
  static const String groupJoinRequestsApproved =
      'group_join_requests_approved';
  static const String groupJoinRequestsRejected =
      'group_join_requests_rejected';
  static const String groupJoinRequestTitle = 'group_join_request_title';
  static const String groupJoinRequestBody = 'group_join_request_body';
  static const String groupJoinRequestSend = 'group_join_request_send';
  static const String groupJoinRequestPending = 'group_join_request_pending';
  static const String groupInviteCardTitle = 'group_invite_card_title';
  static const String groupInviteCardSubtitle = 'group_invite_card_subtitle';
  static const String groupInviteCardJoin = 'group_invite_card_join';
  static const String groupInviteCardAlreadyMember =
      'group_invite_card_already_member';
  static const String groupInviteCardRequestSent =
      'group_invite_card_request_sent';
  static const String groupInviteCardUnavailable =
      'group_invite_card_unavailable';
  static const String groupDetailsPromoteAdmin = 'group_details_promote_admin';
  static const String groupDetailsRemoveAdmin = 'group_details_remove_admin';
  static const String groupDetailsRemoveMember = 'group_details_remove_member';
  static const String groupMemberMute = 'group_member_mute';
  static const String groupMemberUnmute = 'group_member_unmute';
  static const String groupMemberMuted = 'group_member_muted';
  static const String groupAdminPermissionsTitle =
      'group_admin_permissions_title';
  static const String groupAdminPermissionsSaved =
      'group_admin_permissions_saved';
  static const String groupAdminPermissionManageMembers =
      'group_admin_permission_manage_members';
  static const String groupAdminPermissionManageAdmins =
      'group_admin_permission_manage_admins';
  static const String groupAdminPermissionManageAdminRoles =
      'group_admin_permission_manage_admin_roles';
  static const String groupAdminPermissionManageAdminPermissions =
      'group_admin_permission_manage_admin_permissions';
  static const String groupAdminPermissionEditGroup =
      'group_admin_permission_edit_group';
  static const String groupAdminPermissionDeleteMessages =
      'group_admin_permission_delete_messages';
  static const String groupAdminPermissionMuteMembers =
      'group_admin_permission_mute_members';
  static const String groupAdminPermissionManageJoinLink =
      'group_admin_permission_manage_join_link';
  static const String groupMessageDeleteForEveryone =
      'group_message_delete_for_everyone';
  static const String groupMessageDeleted = 'group_message_deleted';
  static const String groupMessageUnableToDelete =
      'group_message_unable_to_delete';
  static const String groupReactionsAuthorsTitle =
      'group_reactions_authors_title';
  static const String groupReactionsEmpty = 'group_reactions_empty';
  static const String groupReactionsUnableToLoad =
      'group_reactions_unable_to_load';
  static const String groupReactionsAdminsOnly = 'group_reactions_admins_only';
  static const String groupDetailsMembersCanViewReactions =
      'group_details_members_can_view_reactions';
  static const String groupDetailsReactionAuthorsVisible =
      'group_details_reaction_authors_visible';
  static const String groupDetailsReactionAuthorsHidden =
      'group_details_reaction_authors_hidden';
  static const String groupDetailsMembersCanCopyLink =
      'group_details_members_can_copy_link';
  static const String groupDetailsJoinLinkVisible =
      'group_details_join_link_visible';
  static const String groupDetailsJoinLinkHidden =
      'group_details_join_link_hidden';
  static const String groupDetailsConfirmRemoveMemberTitle =
      'group_details_confirm_remove_member_title';
  static const String groupDetailsConfirmRemoveMemberBody =
      'group_details_confirm_remove_member_body';
  static const String groupDetailsRemove = 'group_details_remove';
  static const String groupDetailsLeaveGroup = 'group_details_leave_group';
  static const String groupDetailsLeaveGroupAction =
      'group_details_leave_group_action';
  static const String groupDetailsLeaveGroupSubtitle =
      'group_details_leave_group_subtitle';
  static const String groupDetailsLeaveGroupOwnerSubtitle =
      'group_details_leave_group_owner_subtitle';
  static const String groupDetailsConfirmLeaveTitle =
      'group_details_confirm_leave_title';
  static const String groupDetailsConfirmLeaveBody =
      'group_details_confirm_leave_body';
  static const String groupDetailsConfirmLeaveOwnerBody =
      'group_details_confirm_leave_owner_body';
  static const String groupDetailsLeftGroup = 'group_details_left_group';
  static const String groupDetailsUnableToLeave =
      'group_details_unable_to_leave';
  static const String groupReportSafetyTitle = 'group_report_safety_title';
  static const String groupReportTitle = 'group_report_title';
  static const String groupReportSubtitle = 'group_report_subtitle';
  static const String groupReportDescription = 'group_report_description';
  static const String groupReportSubmitted = 'group_report_submitted';
  static const String groupDetailsDeleteGroup = 'group_details_delete_group';
  static const String groupDetailsDeleteGroupAction =
      'group_details_delete_group_action';
  static const String groupDetailsDeleteGroupSubtitle =
      'group_details_delete_group_subtitle';
  static const String groupDetailsConfirmDeleteTitle =
      'group_details_confirm_delete_title';
  static const String groupDetailsConfirmDeleteBody =
      'group_details_confirm_delete_body';
  static const String groupDetailsDeletedGroup = 'group_details_deleted_group';
  static const String groupDetailsUnableToDelete =
      'group_details_unable_to_delete';
  static const String profilePlaceholder = 'profile_placeholder';
  static const String profileCurrentAccount = 'profile_current_account';
  static const String profileConnectedAccounts = 'profile_connected_accounts';
  static const String profileAddAccount = 'profile_add_account';
  static const String profileSwitchAccount = 'profile_switch_account';
  static const String profileRemoveAccount = 'profile_remove_account';
  static const String profileRevokeAccount = 'profile_revoke_account';
  static const String profileAccountUsername = 'profile_account_username';
  static const String profileAccountEmail = 'profile_account_email';
  static const String profileAccountStatus = 'profile_account_status';
  static const String profileAccountCurrent = 'profile_account_current';
  static const String profileAccountMaster = 'profile_account_master';
  static const String profileNoConnectedAccounts =
      'profile_no_connected_accounts';
  static const String profileAddAccountTitle = 'profile_add_account_title';
  static const String profileAddAccountIdentifier =
      'profile_add_account_identifier';
  static const String profileAddAccountIdentifierHint =
      'profile_add_account_identifier_hint';
  static const String profileAddAccountPassword =
      'profile_add_account_password';
  static const String profileAddAccountConfirm = 'profile_add_account_confirm';
  static const String profileAddAccountSuccess = 'profile_add_account_success';
  static const String profileSwitchAccountSuccess =
      'profile_switch_account_success';
  static const String profileRemoveAccountTitle =
      'profile_remove_account_title';
  static const String profileRemoveAccountMessage =
      'profile_remove_account_message';
  static const String profileRemoveAccountSuccess =
      'profile_remove_account_success';
  static const String profileRevokeAccountTitle =
      'profile_revoke_account_title';
  static const String profileRevokeAccountMessage =
      'profile_revoke_account_message';
  static const String profileRevokeAccountSuccess =
      'profile_revoke_account_success';
  static const String profileManageSettings = 'profile_manage_settings';
  static const String profileTimelineBridgeActive =
      'profile_timeline_bridge_active';
  static const String profileLinkedAccountsDisabled =
      'profile_linked_accounts_disabled';
  static const String profileAccountAdded = 'profile_account_added';
  static const String profileAccountEmptyField = 'profile_account_empty_field';
  static const String chatOnlineNow = 'chat_online_now';
  static const String chatSeen = 'chat_seen';
  static const String chatInputHint = 'chat_input_hint';
  static const String chatToday = 'chat_today';
  static const String mediaPlaybackSpeed = 'media_playback_speed';
  static const String mediaMuted = 'media_muted';
  static const String mediaSoundOn = 'media_sound_on';
  static const String mediaFill = 'media_fill';
  static const String mediaFit = 'media_fit';
  static const String mediaLoopOn = 'media_loop_on';
  static const String mediaLoopOff = 'media_loop_off';
  static const String mediaAudio = 'media_audio';
  static const String mediaPause = 'media_pause';
  static const String mediaPlay = 'media_play';
  static const String mediaLoadError = 'media_load_error';
  static const String chatHideKeyboard = 'chat_hide_keyboard';
  static const String chatBlockedInputHint = 'chat_blocked_input_hint';
  static const String chatBlockedUserCannotMessage =
      'chat_blocked_user_cannot_message';
  static const String chatBlockedByMeBanner = 'chat_blocked_by_me_banner';
  static const String chatBlockedByRecipientBanner =
      'chat_blocked_by_recipient_banner';
  static const String chatInfoTitle = 'chat_info_title';
  static const String chatInfoSharedMedia = 'chat_info_shared_media';
  static const String chatInfoSettings = 'chat_info_settings';
  static const String chatInfoAll = 'chat_info_all';
  static const String chatInfoImages = 'chat_info_images';
  static const String chatInfoVideos = 'chat_info_videos';
  static const String chatInfoAudio = 'chat_info_audio';
  static const String chatInfoFiles = 'chat_info_files';
  static const String chatInfoLinks = 'chat_info_links';
  static const String chatInfoNoSharedMedia = 'chat_info_no_shared_media';
  static const String chatInfoOpen = 'chat_info_open';
  static const String chatSettingBackground = 'chat_setting_background';
  static const String chatSettingMute = 'chat_setting_mute';
  static const String chatSettingPin = 'chat_setting_pin';
  static const String chatSettingBlock = 'chat_setting_block';
  static const String chatSettingReport = 'chat_setting_report';
  static const String chatSettingReportSubtitle =
      'chat_setting_report_subtitle';
  static const String chatSettingDelete = 'chat_setting_delete';
  static const String chatSettingApiPending = 'chat_setting_api_pending';
  static const String chatBlockConfirmTitle = 'chat_block_confirm_title';
  static const String chatBlockConfirmMessage = 'chat_block_confirm_message';
  static const String chatBlockConfirmAction = 'chat_block_confirm_action';
  static const String chatUserBlocked = 'chat_user_blocked';
  static const String chatReportTitle = 'chat_report_title';
  static const String chatReportDescription = 'chat_report_description';
  static const String chatReportCategoryLabel = 'chat_report_category_label';
  static const String chatReportCategoryHint = 'chat_report_category_hint';
  static const String chatReportReasonLabel = 'chat_report_reason_label';
  static const String chatReportReasonHint = 'chat_report_reason_hint';
  static const String chatReportSubmit = 'chat_report_submit';
  static const String chatReportSuccess = 'chat_report_success';
  static const String chatReportEmptyCategories =
      'chat_report_empty_categories';
  static const String chatReportCategoryRequired =
      'chat_report_category_required';
  static const String chatReportLoadFailed = 'chat_report_load_failed';
  static const String blockedUsersTitle = 'blocked_users_title';
  static const String blockedUsersEmpty = 'blocked_users_empty';
  static const String blockedUsersUnblock = 'blocked_users_unblock';
  static const String blockedUsersUnblockTitle = 'blocked_users_unblock_title';
  static const String blockedUsersUnblockMessage =
      'blocked_users_unblock_message';
  static const String blockedUsersUserUnblocked =
      'blocked_users_user_unblocked';
  static const String chatDeleteTitle = 'chat_delete_title';
  static const String chatDeleteMessage = 'chat_delete_message';
  static const String chatDeleteConfirm = 'chat_delete_confirm';
  static const String chatDeleted = 'chat_deleted';
  static const String chatMessageDelete = 'chat_message_delete';
  static const String chatMessageEdit = 'chat_message_edit';
  static const String chatMessageReply = 'chat_message_reply';
  static const String chatMessageForward = 'chat_message_forward';
  static const String chatMessageCopy = 'chat_message_copy';
  static const String chatStickerTitle = 'chat_sticker_title';
  static const String chatStickerSubtitle = 'chat_sticker_subtitle';
  static const String chatStickerEmpty = 'chat_sticker_empty';
  static const String chatMessageDeleteTitle = 'chat_message_delete_title';
  static const String chatMessageDeleteMessage = 'chat_message_delete_message';
  static const String chatMessageDeleted = 'chat_message_deleted';
  static const String chatMessageEditPending = 'chat_message_edit_pending';
  static const String callVoice = 'call_voice';
  static const String callVideo = 'call_video';
  static const String callConnecting = 'call_connecting';
  static const String callWaiting = 'call_waiting';
  static const String callMicOff = 'call_mic_off';
  static const String callMicOn = 'call_mic_on';
  static const String callSpeakerOn = 'call_speaker_on';
  static const String callSpeakerOff = 'call_speaker_off';
  static const String callCameraFlip = 'call_camera_flip';
  static const String callMute = 'call_mute';
  static const String callCamera = 'call_camera';
  static const String callSpeaker = 'call_speaker';
  static const String callFlip = 'call_flip';
  static const String callEnd = 'call_end';
  static const String callPermissionDenied = 'call_permission_denied';
  static const String callAgoraDisabled = 'call_agora_disabled';
  static const String callAgoraMissingAppId = 'call_agora_missing_app_id';
  static const String callWebRtcDisabled = 'call_webrtc_disabled';
  static const String callMissingWebRtcConnection =
      'call_missing_webrtc_connection';
  static const String callWaitingForRemoteMedia =
      'call_waiting_for_remote_media';
  static const String callPublishingMedia = 'call_publishing_media';
  static const String callWebRtcSocketClosed = 'call_webrtc_socket_closed';
  static const String callWebRtcTimedOut = 'call_webrtc_timed_out';
  static const String callIncomingVoice = 'call_incoming_voice';
  static const String callIncomingVideo = 'call_incoming_video';
  static const String callRemoteJoined = 'call_remote_joined';
  static const String callRinging = 'call_ringing';
  static const String callNoAnswer = 'call_no_answer';
  static const String callDeclined = 'call_declined';
  static const String callIncoming = 'call_incoming';
  static const String callAccept = 'call_accept';
  static const String callDeclineAction = 'call_decline_action';
  static const String callRecipientBusy = 'call_recipient_busy';
  static const String callRecipientOffline = 'call_recipient_offline';
  static const String callCallerBusy = 'call_caller_busy';
  static const String callDirectOnly = 'call_direct_only';
  static const String callMissingConnection = 'call_missing_connection';
  static const String authFlowHeadline = 'auth_flow_headline';
  static const String authFlowDescription = 'auth_flow_description';
  static const String accountBannedTitle = 'account_banned_title';
  static const String accountBannedBody = 'account_banned_body';
  static const String accountBannedSupport = 'account_banned_support';
  static const String accountBannedContactSupport =
      'account_banned_contact_support';
  static const String authActivationTitle = 'auth_activation_title';
  static const String authActivationDescription = 'auth_activation_description';
  static const String authApprovalTitle = 'auth_approval_title';
  static const String authApprovalDescription = 'auth_approval_description';
  static const String authGettingStartedTitle = 'auth_getting_started_title';
  static const String authGettingStartedDescription =
      'auth_getting_started_description';
  static const String authTwoFactorTitle = 'auth_two_factor_title';
  static const String authTwoFactorDescription = 'auth_two_factor_description';
  static const String verificationCode = 'verification_code';
  static const String verificationCodeHint = 'verification_code_hint';
  static const String verificationCodeRequired = 'verification_code_required';
  static const String resendCode = 'resend_code';
  static const String verifyAndContinue = 'verify_and_continue';
  static const String activationCodeSent = 'activation_code_sent';
  static const String authUnableToLoadState = 'auth_unable_to_load_state';
  static const String authUnableToVerifyCode = 'auth_unable_to_verify_code';
  static const String authUnableToResendCode = 'auth_unable_to_resend_code';
  static const String backToLogin = 'back_to_login';
  static const String loginFailed = 'login_failed';
  static const String commonConversation = 'common_conversation';
  static const String commonChat = 'common_chat';
  static const String commonConversations = 'common_conversations';
  static const String commonPeople = 'common_people';
  static const String commonPost = 'common_post';
  static const String commonStory = 'common_story';
  static const String commonReel = 'common_reel';
  static const String commonProduct = 'common_product';
  static const String commonContact = 'common_contact';
  static const String commonLocation = 'common_location';
  static const String commonImage = 'common_image';
  static const String commonVideo = 'common_video';
  static const String commonSticker = 'common_sticker';
  static const String commonOn = 'common_on';
  static const String commonOff = 'common_off';
  static const String commonColors = 'common_colors';
  static const String commonGradients = 'common_gradients';
  static const String commonReset = 'common_reset';
  static const String commonTimeline = 'common_timeline';
  static const String timelineAppNotInstalledTitle =
      'timeline_app_not_installed_title';
  static const String timelineAppNotInstalledMessage =
      'timeline_app_not_installed_message';
  static const String timelineAppCancelAction = 'timeline_app_cancel_action';
  static const String timelineAppDownloadAction =
      'timeline_app_download_action';
  static const String sharedPost = 'shared_post';
  static const String sharedReel = 'shared_reel';
  static const String sharePostTitle = 'share_post_title';
  static const String shareReelTitle = 'share_reel_title';
  static const String shareSearchHint = 'share_search_hint';
  static const String shareEmptyTargets = 'share_empty_targets';
  static const String profileQuickSettingsSubtitle =
      'profile_quick_settings_subtitle';
  static const String profileConnectAnother = 'profile_connect_another';
  static const String profileAddAccountDisabled =
      'profile_add_account_disabled';
  static const String profileIdentityEyebrow = 'profile_identity_eyebrow';
  static const String profileSwitcherEyebrow = 'profile_switcher_eyebrow';
  static const String profileAttachAnotherAccount =
      'profile_attach_another_account';
  static const String profileNoEmailAttached = 'profile_no_email_attached';
  static const String profileReadyToSwitch = 'profile_ready_to_switch';
  static const String chatPin = 'chat_pin';
  static const String chatUnpin = 'chat_unpin';
  static const String chatConversationPinned = 'chat_conversation_pinned';
  static const String chatConversationUnpinned = 'chat_conversation_unpinned';
  static const String chatDirectConversation = 'chat_direct_conversation';
  static const String chatGroupConversation = 'chat_group_conversation';
  static const String callsTotal = 'calls_total';
  static const String callsAll = 'calls_all';
  static const String callsHeroSubtitle = 'calls_hero_subtitle';
  static const String homeRecentActivity = 'home_recent_activity';
  static const String chatSettingsSubtitle = 'chat_settings_subtitle';
  static const String chatBackgroundSubtitle = 'chat_background_subtitle';
  static const String chatRecordingTitle = 'chat_recording_title';
  static const String chatRecordingBody = 'chat_recording_body';
  static const String chatSendLocation = 'chat_send_location';
  static const String chatSendContact = 'chat_send_contact';
  static const String chatOpenContact = 'chat_open_contact';
  static const String chatContactName = 'chat_contact_name';
  static const String chatContactNameHint = 'chat_contact_name_hint';
  static const String chatContactPhone = 'chat_contact_phone';
  static const String chatContactPhoneHint = 'chat_contact_phone_hint';
  static const String chatContactNameRequired = 'chat_contact_name_required';
  static const String chatContactPhoneRequired = 'chat_contact_phone_required';
  static const String chatOpenLocation = 'chat_open_location';
  static const String chatCurrentLocation = 'chat_current_location';
  static const String chatLocationPermissionDenied =
      'chat_location_permission_denied';
  static const String chatLocationServiceDisabled =
      'chat_location_service_disabled';
  static const String chatLocationFetchFailed = 'chat_location_fetch_failed';
  static const String chatInvalidConversationId =
      'chat_invalid_conversation_id';
  static const String chatImageUnavailable = 'chat_image_unavailable';
  static const String chatSharedItemOpenFailed = 'chat_shared_item_open_failed';
  static const String chatVoiceUnavailable = 'chat_voice_unavailable';
  static const String chatVideoUnavailable = 'chat_video_unavailable';
  static const String chatReplyingTo = 'chat_replying_to';
  static const String chatReplyToYourself = 'chat_reply_to_yourself';
  static const String chatReplyOriginalUnavailable =
      'chat_reply_original_unavailable';
  static const String chatRepliedToStory = 'chat_replied_to_story';
  static const String chatReactedToStory = 'chat_reacted_to_story';
  static const String chatEditingMessage = 'chat_editing_message';
  static const String chatMessageCopied = 'chat_message_copied';
  static const String forwardTitle = 'forward_title';
  static const String forwardSearchHint = 'forward_search_hint';
  static const String forwardEmptyTargets = 'forward_empty_targets';
  static const String forwardPreviewTitle = 'forward_preview_title';
  static const String forwardSent = 'forward_sent';

  @override
  Map<String, Map<String, String>> get keys => {
    'ar': ar,
    'en': en,
    'fr': fr,
    'es': es,
    'pt': pt,
    'de': de,
    'tr': tr,
    'nl': nl,
    'it': it,
    'ru': ru,
    'ro': ro,
    'pt_BR': ptBr,
    'el': el,
    'uk': uk,
  };
}
