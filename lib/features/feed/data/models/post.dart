import 'post_link.dart';
import 'post_event.dart';
import 'post_funding.dart';
import 'post_offer.dart';
import 'post_course.dart';
import 'post_colored_pattern.dart';
import 'post_live.dart';
import 'post_audio.dart';
import 'post_media.dart';
import 'package:snginepro/features/merits/data/models/merit_models.dart';

class Post {
  Post({
    required this.id,
    required this.authorName,
    required this.publishedAt,
    required this.text,
    required this.postType,
    this.authorAvatarUrl,
    this.authorId,
    this.authorUsername,
    this.authorType = 'user',
    // ⚠️ ONLINE STATUS FIELDS
    this.authorIsOnline = false,
    this.authorLastSeen,
    this.pageId,
    this.pageName,
    this.pageTitle,
    // ⚠️ NEW FIELDS FOR GROUP SUPPORT
    this.inGroup = false,
    this.groupId,
    this.groupName,
    this.groupTitle,
    this.groupPicture,
    // ⚠️ NEW FIELDS FOR EVENT SUPPORT
    this.inEvent = false,
    this.event,
    this.commentsCount = 0,
    this.reactionsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.reviewsCount = 0,
    this.isVerified = false,
    this.myReaction,
    this.privacy = 'public',
    Map<String, int>? reactionBreakdown,
    this.permalink,
    this.video,
    this.photos,
    this.ogImage,
    this.poll,
    this.link,
    this.audio,
    // ⚠️ NEW FIELDS FOR POST MANAGEMENT
    this.isSaved = false,
    this.isPinned = false,
    this.isHidden = false,
    this.commentsDisabled = false,
    this.tipsEnabled = false,
    // 🔞 FOR ADULT FIELD
    this.forAdult = false,
    // 💰 PROMOTED POST FIELD
    this.isPromoted = false,
    // 📢 AD FIELD
    this.isAd = false,
    // � ANONYMOUS POST FIELD
    this.isAnonymous = false,
    // �📢 AD DATA FIELDS
    this.campaignTitle,
    this.campaignDescription,
    this.campaignUrl,
    this.adsImage,
    this.adsVideo,
    this.actionButtonText,
    this.actionButtonUrl,
    this.campaignId,
    this.adsType,
    this.campaignBidding,
    this.targetName,
    this.targetPicture,
    this.adPageId,
    this.adGroupId,
    this.adEventId,
    this.adPostId,
    // ⚠️ NEW FIELDS FOR SHARED POSTS AND ARTICLES
    this.originPost,
    this.blog,
    // 💰 FUNDING FIELD
    this.funding,
    // 🏷️ OFFER FIELD
    this.offer,
    // 📚 COURSE FIELD
    this.course,
    // 🎨 COLORED PATTERN FIELD
    this.coloredPattern,
    // 📺 LIVE STREAMING FIELD
    this.live,
    // 😊 FEELINGS FIELDS
    this.feelingAction,
    this.feelingValue,
    this.feelingIcon,
    // 📺 MEDIA FIELD (YouTube, Vimeo, etc.)
    this.media,
    // 💳 PAID POST FIELDS
    this.isPaid = false,
    this.needsPayment = false,
    this.forSubscriptions = false,
    this.postPrice,
    this.paidText,
    this.isCompetitionEntry = false,
    this.competitionId,
    this.competitionName,
    this.competitionStatus,
    this.competitionRank,
    this.competitionCategory,
    this.competitionBadgeText,
    this.isWinner = false,
    this.winnerRank,
    // 🎖️ MERIT FIELD
    this.merit,
    // ⏱️ VIDEO DURATION (seconds)
    this.videoDurationSeconds,
    // 🎵 REEL SOUND FIELDS
    this.soundId,
    this.soundTitle,
    this.soundUrl,
    // 📦 PRODUCT FIELDS
    this.available = true,
    this.productId,
    this.productName,
    this.productStatus,
    this.productLocation,
    this.productCategoryName,
    this.isDigital = false,
    this.productUrl,
    this.productFile,
  }) : reactionBreakdown = reactionBreakdown ?? const <String, int>{},
       topReactions = _topReactions(reactionBreakdown ?? const {}),
       reactionsCountFormatted = _formatCount(reactionsCount),
       commentsCountFormatted = _formatCount(commentsCount),
       sharesCountFormatted = _formatCount(sharesCount),
       viewsCountFormatted = _formatCount(viewsCount),
       reviewsCountFormatted = _formatCount(reviewsCount);

  final int id;
  final String authorName;
  final String publishedAt;
  final String text;
  final String postType;
  final String? authorAvatarUrl;
  final String? authorId;
  final String? authorUsername;
  final String authorType; // 'user' or 'page'
  // ⚠️ ONLINE STATUS FIELDS
  final bool authorIsOnline; // حالة الاتصال للمؤلف
  final String? authorLastSeen; // آخر ظهور للمؤلف
  final String? pageId;
  final String? pageName;
  final String? pageTitle;
  // ⚠️ NEW FIELDS FOR GROUP SUPPORT
  final bool inGroup; // هل المنشور في مجموعة
  final String? groupId; // معرف المجموعة
  final String? groupName; // اسم المجموعة (username)
  final String? groupTitle; // عنوان المجموعة
  final String? groupPicture; // صورة المجموعة
  // ⚠️ NEW FIELDS FOR EVENT SUPPORT
  final bool inEvent; // هل المنشور في حدث
  final PostEvent? event; // معلومات الحدث
  final int commentsCount;
  final int reactionsCount;
  final int sharesCount;
  final int viewsCount; // عدد المشاهدات
  final int reviewsCount; // عدد التقييمات/المراجعات
  final bool isVerified;
  final String? myReaction;
  final String privacy;
  final Map<String, int> reactionBreakdown;

  // 🚀 POST MANAGEMENT FIELDS
  final bool isSaved; // هل المنشور محفوظ (i_save)
  final bool isPinned; // هل المنشور مثبت (pinned)
  final bool isHidden; // هل المنشور مخفي (is_hidden)
  final bool commentsDisabled; // هل التعليقات معطلة (comments_disabled)
  final bool tipsEnabled; // هل الـ Tips مفعلة للمنشور
  final bool forAdult; // 🔞 هل المحتوى للبالغين فقط (for_adult)
  final bool isPromoted; // 💰 هل المنشور مدفوع/مروج (promoted/boosted)
  final bool isAd; // 📢 هل هذا إعلان (is_ad)
  final bool isAnonymous; // 👤 هل المنشور مجهول الهوية (is_anonymous)
  final bool available; // متاح (للمنتجات)
  final String? productId; // معرف المنتج (للمنتجات)
  final String? productName; // اسم المنتج
  final String? productStatus; // حالة المنتج (new/old)
  final String? productLocation; // موقع المنتج
  final String? productCategoryName; // اسم فئة المنتج
  final bool isDigital; // هل المنتج رقمي
  final String? productUrl; // رابط التحميل للمنتجات الرقمية
  final String? productFile; // معرف الملف المرفوع

  // 📢 AD FIELDS (only used when isAd = true)
  final String? campaignTitle;
  final String? campaignDescription;
  final String? campaignUrl;
  final String? adsImage;
  final String? adsVideo;
  final String? actionButtonText;
  final String? actionButtonUrl;
  final int? campaignId;
  final String? adsType; // نوع الإعلان: "page", "group", "url", "post", "event"
  final String? campaignBidding; // نوع التتبع: "click" أو "view"
  final String? targetName; // اسم الهدف
  final String? targetPicture; // صورة الهدف
  final int? adPageId; // معرف الصفحة (إذا كان ads_type = "page")
  final int? adGroupId; // معرف المجموعة (إذا كان ads_type = "group")
  final int? adEventId; // معرف الحدث (إذا كان ads_type = "event")
  final int? adPostId; // معرف المنشور (إذا كان ads_type = "post")

  final List<String> topReactions;
  final String? permalink;
  final PostVideo? video;
  final List<PostPhoto>? photos;
  final String?
  ogImage; // 📷 الصورة الافتراضية من og_image عندما لا توجد photos
  final PostPoll? poll;
  final PostLink? link;
  final PostAudio? audio;
  final PostMedia? media; // 📺 معلومات الوسائط (YouTube, Vimeo, etc.)

  // ⚠️ NEW FIELDS FOR SHARED POSTS AND ARTICLES
  final Post? originPost; // المنشور الأصلي للمنشورات المشاركة
  final PostBlog? blog; // محتوى المقال
  // 💰 FUNDING FIELD
  final PostFunding? funding; // معلومات حملة التبرع
  // 🏷️ OFFER FIELD
  final PostOffer? offer; // معلومات العرض
  // 📚 COURSE FIELD
  final PostCourse? course; // معلومات الدورة التعليمية
  // 🎨 COLORED PATTERN FIELD
  final PostColoredPattern? coloredPattern; // خلفية ملونة أو منقوشة
  // 📺 LIVE STREAMING FIELD
  final PostLive? live; // معلومات البث المباشر
  // 😊 FEELINGS FIELDS
  final String? feelingAction; // نوع الشعور (Feeling, Listening To, إلخ)
  final String? feelingValue; // قيمة الشعور (Happy, Song Name, إلخ)
  final String? feelingIcon; // أيقونة الشعور

  // 💳 PAID POST FIELDS
  final bool isPaid; // هل المنشور مدفوع
  final bool needsPayment; // هل يحتاج إلى دفع لعرض المحتوى
  final bool forSubscriptions; // هل الدفع عبر الاشتراكات فقط
  final double? postPrice; // سعر المنشور (إن وجد)
  final String? paidText; // نص المعاينة للمنشور المدفوع
  final bool isCompetitionEntry;
  final int? competitionId;
  final String? competitionName;
  final String? competitionStatus;
  final int? competitionRank;
  final String? competitionCategory;
  final String? competitionBadgeText;
  final bool isWinner;
  final int? winnerRank;

  // 🎖️ MERIT FIELD
  final Merit? merit; // معلومات الجدارة إذا كان المنشور عن جدارة

  // ⏱️ VIDEO DURATION (seconds)
  final int? videoDurationSeconds;

  // 🎵 REEL SOUND FIELDS — sound_id/sound_title come top-level per the reels
  // contract (§14); soundUrl only when the backend embeds the sound object.
  final int? soundId;
  final String? soundTitle;
  final String? soundUrl;

  final String reactionsCountFormatted;
  final String commentsCountFormatted;
  final String sharesCountFormatted;
  final String viewsCountFormatted;
  final String reviewsCountFormatted;

  bool get isReacted => myReaction != null;

  bool get hasVideo => video?.hasAnySource ?? false;

  bool get isVideoPost =>
      hasVideo &&
      (postType == 'video' || postType == 'live' || postType == 'reel');

  bool get hasPhotos => photos != null && photos!.isNotEmpty;

  bool get hasAnyPhoto => hasPhotos || (ogImage != null && ogImage!.isNotEmpty);

  bool get hasPoll => poll != null;

  bool get hasLink => link != null;

  bool get hasAudio => audio != null;

  bool get isAudioPost => postType == 'audio' && hasAudio;

  bool get isPagePost => authorType == 'page' && pageId != null;

  bool get isGroupPost => inGroup && groupId != null;

  bool get isEventPost => inEvent && event != null;

  bool get isSharedPost => postType == 'shared' && originPost != null;

  bool get isArticlePost => postType == 'article' && blog != null;

  bool get isFundingPost => postType == 'funding' && funding != null;

  bool get isOfferPost => postType == 'offer' && offer != null;

  bool get isCoursePost => postType == 'course' && course != null;

  bool get isMeritPost => postType == 'merit' && merit != null;

  bool get isProductPost => postType == 'product';

  bool get hasColoredPattern => coloredPattern != null;

  bool get hasBlog => blog != null;

  bool get hasLive => live != null;

  bool get isLivePost => postType == 'live' && hasLive;

  bool get isActiveLive => isLivePost && live!.isActive;

  factory Post.fromJson(Map<String, dynamic> json) {
    try {
      String? myReaction;

      if (json['viewer_reaction'] is Map<String, dynamic>) {
        final viewerReaction = json['viewer_reaction']['reaction'];
        if (viewerReaction is String && viewerReaction.isNotEmpty) {
          myReaction = viewerReaction;
        }
      }

      if (myReaction == null) {
        final iReaction = json['i_reaction'];
        if (iReaction is String && iReaction.isNotEmpty) {
          myReaction = iReaction;
        }
      }

      if (myReaction == null && _bool(json['i_react'])) {
        myReaction = 'like';
      }

      final userId =
          _string(json['user_id']) ?? _string(json['post_author_id']);
      final username =
          _string(json['user_name']) ?? _string(json['post_author_username']);
      final authorType = _string(json['user_type']) ?? 'user';
      final pageId = _string(json['page_id']);
      final pageName = _string(json['page_name']);
      final pageTitle = _string(json['page_title']);

      // ⚠️ NEW: Parse group information
      final inGroup = _bool(json['in_group']);
      final tipsEnabled = _bool(json['tips_enabled']);
      final forAdult = _bool(json['for_adult']);
      final isAnonymous = _bool(json['is_anonymous']);

      final photos = PostPhoto.listFromJson(json['photos']);
      final ogImage = _string(json['og_image']);

        // Try parse nested product object
        final Map<String, dynamic>? productObj =
          json['product'] is Map<String, dynamic>
            ? json['product'] as Map<String, dynamic>
            : null;

        // 🎵 Reel sound: top-level sound_id/sound_title, or nested in the
        // reel object (reel.sound_id / embedded reel.sound music object)
        final Map<String, dynamic>? reelObj =
            json['reel'] is Map<String, dynamic>
                ? json['reel'] as Map<String, dynamic>
                : null;
        final Map<String, dynamic>? soundObj =
            reelObj?['sound'] is Map<String, dynamic>
                ? reelObj!['sound'] as Map<String, dynamic>
                : (json['sound'] is Map<String, dynamic>
                    ? json['sound'] as Map<String, dynamic>
                    : null);
        final String? soundIdRaw = _string(json['sound_id']) ??
            _string(reelObj?['sound_id']) ??
            _string(soundObj?['id']);

        return Post(
        id: _int(json['post_id']),
        // 👤 Handle anonymous posts - show "anonymous_user" key for translation
        authorName: isAnonymous ? 'anonymous_user' : _authorName(json),
        publishedAt: _string(json['time']) ?? '',
        text: _string(json['text']) ?? _string(json['text']) ?? '',
        postType: _string(json['post_type']) ?? '',
        // 👤 Handle anonymous posts - hide avatar
        authorAvatarUrl: isAnonymous ? null : _authorAvatar(json),
        authorId: isAnonymous ? null : userId,
        authorUsername: isAnonymous ? null : username,
        authorType: authorType,
        // ⚠️ ONLINE STATUS FIELDS
        authorIsOnline: _bool(json['author_is_online']),
        authorLastSeen: _string(json['author_last_seen']),
        pageId: pageId,
        pageName: pageName,
        pageTitle: pageTitle,
        // ⚠️ NEW: Group fields
        inGroup: inGroup,
        groupId: _string(json['group_id']),
        groupName: _string(json['group_name']),
        groupTitle: _string(json['group_title']),
        groupPicture: _string(json['group_picture']),
        // ⚠️ NEW: Event fields - Handle different event data structures
        inEvent:
            _bool(json['in_event']) ||
            json['post_type'] == 'event' ||
            json['post_type'] == 'event_cover',
        event: _parseEventData(json),
        commentsCount: _int(json['comments']),
        reactionsCount: _int(json['reactions_total_count']),
        sharesCount: _int(json['shares']),
        viewsCount: _int(json['views']),
        reviewsCount: _int(json['reviews_count']) != 0
            ? _int(json['reviews_count'])
            : 0,
        isVerified:
            _bool(json['post_author_verified']) || _bool(json['user_verified']),
        myReaction: myReaction,
        privacy: _string(json['privacy']) ?? 'public',
        reactionBreakdown: _parseReactions(json['reactions']),
        permalink: _string(json['post_author_url']),
        video: PostVideo.maybeFromJson(json['video'] ?? json['reel']),
        soundId: soundIdRaw != null ? int.tryParse(soundIdRaw) : null,
        soundTitle: _string(json['sound_title']) ?? _string(soundObj?['title']),
        soundUrl: _string(json['sound_url']) ?? _string(soundObj?['sound']),
        photos: photos,
        ogImage: ogImage,
        poll: PostPoll.maybeFromJson(json['poll']),
        link: PostLink.maybeFromJson(json['link']),
        audio: PostAudio.maybeFromJson(json['audio']),
        media: json['media'] != null ? PostMedia.fromJson(json['media']) : null,
        // ⚠️ HIGH PRIORITY - Parse new fields (handle both string and boolean values)
        isSaved: _bool(json['i_save']),
        isPinned: _bool(json['pinned']),
        isHidden: _bool(json['is_hidden']),
        commentsDisabled: _bool(json['comments_disabled']),
        tipsEnabled: tipsEnabled,
        // 🔞 FOR ADULT SUPPORT
        forAdult: forAdult,
        // 💰 PROMOTED POST SUPPORT
        isPromoted:
            _bool(json['is_promoted']) ||
            _bool(json['is_boosted']) ||
            _bool(json['boosted']),
        // 📢 AD SUPPORT
        isAd: _bool(json['is_ad']),
        // � ANONYMOUS POST SUPPORT
        isAnonymous: isAnonymous,
        // 📦 PRODUCT FIELDS
        available: productObj != null
          ? _bool(productObj['available'])
          : _bool(json['available']),
        productId: productObj != null ? _string(productObj['product_id']) : null,
        productName: productObj != null
          ? _string(productObj['name'])
          : (_string(json['og_title']) ?? _string(json['title'])),
        productStatus:
          productObj != null ? _string(productObj['status']) : null,
        productLocation: productObj != null
          ? _string(productObj['location'])
          : _string(json['location']),
        productCategoryName: productObj != null
          ? _string(productObj['category_name'])
          : null,
        // �📢 AD DATA FIELDS
        isDigital: productObj != null ? _bool(productObj['is_digital']) : false,
        productUrl: productObj != null ? (_string(productObj['product_download_url']) ?? _string(productObj['product_url'])) : null,
        productFile: productObj != null ? (_string(productObj['product_file_source']) ?? _string(productObj['product_file'])) : null,
        campaignTitle:
            _string(json['campaign_title']) ??
            _string(json['ads_title']) ??
            _string(json['title']),
        campaignDescription:
            _string(json['campaign_description']) ??
            _string(json['ads_description']) ??
            _string(json['description']),
        campaignUrl: _string(json['campaign_url']) ?? _string(json['url']),
        adsImage: _string(json['ads_image']),
        adsVideo: _string(json['ads_video']),
        actionButtonText: json['action_button'] != null
            ? _string((json['action_button'] as Map<String, dynamic>)['text'])
            : null,
        actionButtonUrl: json['action_button'] != null
            ? _string((json['action_button'] as Map<String, dynamic>)['url'])
            : null,
        campaignId: _int(json['campaign_id']) != 0
            ? _int(json['campaign_id'])
            : null,
        adsType: _string(json['ads_type']),
        campaignBidding: _string(json['campaign_bidding']),
        targetName: _string(json['target_name']),
        targetPicture:
            _string(json['target_picture']) ??
            (json['target'] != null
                ? _string((json['target'] as Map<String, dynamic>)['picture'])
                : null),
        adPageId: _int(json['page_id']) != 0 ? _int(json['page_id']) : null,
        adGroupId: _int(json['group_id']) != 0 ? _int(json['group_id']) : null,
        adEventId: _int(json['event_id']) != 0 ? _int(json['event_id']) : null,
        adPostId: _int(json['post_id']) != 0 ? _int(json['post_id']) : null,
        // ⚠️ NEW FIELDS FOR SHARED POSTS AND ARTICLES
        originPost: json['origin'] != null
            ? Post.fromJson(json['origin'])
            : null,
        blog: PostBlog.maybeFromJson(
          json['blog'],
          fallbackPostId: _string(json['post_id']),
        ),
        // 💰 FUNDING SUPPORT
        funding: PostFunding.maybeFromJson(json['funding']),
        // 🏷️ OFFER SUPPORT
        offer: PostOffer.maybeFromJson(json['offer']),
        // 📚 COURSE SUPPORT
        course: PostCourse.maybeFromJson(json['course']),
        // 🎨 COLORED PATTERN SUPPORT
        coloredPattern: PostColoredPattern.maybeFromJson(
          json['colored_pattern'],
        ),
        // 📺 LIVE STREAMING SUPPORT
        live: json['live'] != null
            ? PostLive.fromJson(json['live'] as Map<String, dynamic>)
            : null,
        // 😊 FEELINGS SUPPORT
        feelingAction: _string(json['feeling_action']),
        feelingValue: _string(json['feeling_value']),
        feelingIcon: _string(json['feeling_icon']),
        // 💳 PAID POST SUPPORT
        isPaid: _bool(json['is_paid']),
        needsPayment: _bool(json['needs_payment']),
        forSubscriptions: _bool(json['for_subscriptions']),
        postPrice: productObj != null
          ? _double(productObj['price'])
          : _double(json['post_price']),
        paidText: _string(json['paid_text']),
        isCompetitionEntry:
            _bool(json['is_competition_entry']) ||
            _bool(json['competition_entry']) ||
            _int(json['competition_id']) > 0,
        competitionId:
            _int(json['competition_id']) != 0 ? _int(json['competition_id']) : null,
        competitionName:
            _string(json['competition_name']) ?? _string(json['contest_name']),
        competitionStatus:
            _string(json['competition_status']) ?? _string(json['contest_status']),
        competitionRank: _int(
                  json['competition_rank'] ?? json['entry_rank'],
                ) !=
                0
            ? _int(json['competition_rank'] ?? json['entry_rank'])
            : null,
        competitionCategory:
            _string(json['competition_category']) ??
            _string(json['contest_category']),
        competitionBadgeText: _string(json['competition_badge_text']),
        isWinner: _bool(json['is_winner']) || _int(json['winner_rank']) > 0,
        winnerRank:
            _int(json['winner_rank']) != 0 ? _int(json['winner_rank']) : null,
        // 🎖️ MERIT SUPPORT
        merit: json['merit'] != null
            ? Merit.fromJson(json['merit'] as Map<String, dynamic>)
            : null,
        // ⏱️ VIDEO DURATION
        videoDurationSeconds:
            _int(
                  json['video_duration'] ??
                      json['duration'] ??
                      json['video_length'],
                ) !=
                0
            ? _int(
                json['video_duration'] ??
                    json['duration'] ??
                    json['video_length'],
              )
            : null,
      );
    } catch (e) {
      rethrow; // Re-throw to let the caller handle it
    }
  }

  Post copyWith({
    int? id,
    String? authorName,
    String? publishedAt,
    String? text,
    String? postType,
    String? authorAvatarUrl,
    String? authorId,
    String? authorUsername,
    String? authorType,
    // ⚠️ ONLINE STATUS PARAMETERS
    bool? authorIsOnline,
    String? authorLastSeen,
    String? pageId,
    String? pageName,
    String? pageTitle,
    // ⚠️ NEW: Group parameters
    bool? inGroup,
    String? groupId,
    String? groupName,
    String? groupTitle,
    String? groupPicture,
    // ⚠️ NEW: Event parameters
    bool? inEvent,
    PostEvent? event,
    int? commentsCount,
    int? reactionsCount,
    int? sharesCount,
    int? viewsCount,
    int? reviewsCount,
    bool? isVerified,
    String? myReaction,
    bool? clearMyReaction,
    String? privacy,
    Map<String, int>? reactionBreakdown,
    String? permalink,
    PostVideo? video,
    List<PostPhoto>? photos,
    String? ogImage,
    PostPoll? poll,
    PostLink? link,
    PostAudio? audio,
    // 🚀 NEW FIELDS FOR POST MANAGEMENT
    bool? isSaved,
    bool? isPinned,
    bool? isHidden,
    bool? commentsDisabled,
    bool? tipsEnabled,
    bool? forAdult,
    bool? isPromoted,
    bool? isAd,
    bool? isAnonymous,
    // 📦 PRODUCT PARAMETER
    bool? available,
    String? productId,
    String? productName,
    String? productStatus,
    String? productLocation,
    String? productCategoryName,
    bool? isDigital,
    String? productUrl,
    String? productFile,
    // 📢 AD DATA PARAMETERS
    String? campaignTitle,
    String? campaignDescription,
    String? campaignUrl,
    String? adsImage,
    String? adsVideo,
    String? actionButtonText,
    String? actionButtonUrl,
    int? campaignId,
    String? adsType,
    String? campaignBidding,
    String? targetName,
    String? targetPicture,
    int? adPageId,
    int? adGroupId,
    int? adEventId,
    int? adPostId,
    // ⚠️ NEW FIELDS FOR SHARED POSTS AND ARTICLES
    Post? originPost,
    PostBlog? blog,
    // 💰 FUNDING PARAMETER
    PostFunding? funding,
    // 🏷️ OFFER PARAMETER
    PostOffer? offer,
    // 📚 COURSE PARAMETER
    PostCourse? course,
    // 🎨 COLORED PATTERN PARAMETER
    PostColoredPattern? coloredPattern,
    // 📺 LIVE STREAMING PARAMETER
    PostLive? live,
    // 😊 FEELINGS PARAMETERS
    String? feelingAction,
    String? feelingValue,
    String? feelingIcon,
    // 💳 PAID POST PARAMETERS
    bool? isPaid,
    bool? needsPayment,
    bool? forSubscriptions,
    double? postPrice,
    String? paidText,
    bool? isCompetitionEntry,
    int? competitionId,
    String? competitionName,
    String? competitionStatus,
    int? competitionRank,
    String? competitionCategory,
    String? competitionBadgeText,
    bool? isWinner,
    int? winnerRank,
    // 🎖️ MERIT PARAMETER
    Merit? merit,
    // ⏱️ VIDEO DURATION
    int? videoDurationSeconds,
    // 🎵 REEL SOUND PARAMETERS
    int? soundId,
    String? soundTitle,
    String? soundUrl,
  }) {
    return Post(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      publishedAt: publishedAt ?? this.publishedAt,
      text: text ?? this.text,
      postType: postType ?? this.postType,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorType: authorType ?? this.authorType,
      // ⚠️ ONLINE STATUS FIELDS
      authorIsOnline: authorIsOnline ?? this.authorIsOnline,
      authorLastSeen: authorLastSeen ?? this.authorLastSeen,
      pageId: pageId ?? this.pageId,
      pageName: pageName ?? this.pageName,
      pageTitle: pageTitle ?? this.pageTitle,
      // ⚠️ NEW: Group fields
      inGroup: inGroup ?? this.inGroup,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupTitle: groupTitle ?? this.groupTitle,
      groupPicture: groupPicture ?? this.groupPicture,
      // ⚠️ NEW: Event fields
      inEvent: inEvent ?? this.inEvent,
      event: event ?? this.event,
      commentsCount: commentsCount ?? this.commentsCount,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isVerified: isVerified ?? this.isVerified,
      myReaction: clearMyReaction == true
          ? null
          : myReaction ?? this.myReaction,
      privacy: privacy ?? this.privacy,
      reactionBreakdown: reactionBreakdown ?? this.reactionBreakdown,
      permalink: permalink ?? this.permalink,
      video: video ?? this.video,
      photos: photos ?? this.photos,
      ogImage: ogImage ?? this.ogImage,
      poll: poll ?? this.poll,
      link: link ?? this.link,
      audio: audio ?? this.audio,
      // 🚀 NEW FIELDS FOR POST MANAGEMENT
      isSaved: isSaved ?? this.isSaved,
      isPinned: isPinned ?? this.isPinned,
      isHidden: isHidden ?? this.isHidden,
      commentsDisabled: commentsDisabled ?? this.commentsDisabled,
      tipsEnabled: tipsEnabled ?? this.tipsEnabled,
      forAdult: forAdult ?? this.forAdult,
      isPromoted: isPromoted ?? this.isPromoted,
      isAd: isAd ?? this.isAd,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      // 📦 PRODUCT FIELD
      available: available ?? this.available,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        productStatus: productStatus ?? this.productStatus,
        productLocation: productLocation ?? this.productLocation,
        productCategoryName:
          productCategoryName ?? this.productCategoryName,
        isDigital: isDigital ?? this.isDigital,
        productUrl: productUrl ?? this.productUrl,
        productFile: productFile ?? this.productFile,
      // 📢 AD DATA FIELDS
      campaignTitle: campaignTitle ?? this.campaignTitle,
      campaignDescription: campaignDescription ?? this.campaignDescription,
      campaignUrl: campaignUrl ?? this.campaignUrl,
      adsImage: adsImage ?? this.adsImage,
      adsVideo: adsVideo ?? this.adsVideo,
      actionButtonText: actionButtonText ?? this.actionButtonText,
      actionButtonUrl: actionButtonUrl ?? this.actionButtonUrl,
      campaignId: campaignId ?? this.campaignId,
      adsType: adsType ?? this.adsType,
      campaignBidding: campaignBidding ?? this.campaignBidding,
      targetName: targetName ?? this.targetName,
      targetPicture: targetPicture ?? this.targetPicture,
      adPageId: adPageId ?? this.adPageId,
      adGroupId: adGroupId ?? this.adGroupId,
      adEventId: adEventId ?? this.adEventId,
      adPostId: adPostId ?? this.adPostId,
      // ⚠️ NEW FIELDS FOR SHARED POSTS AND ARTICLES
      originPost: originPost ?? this.originPost,
      blog: blog ?? this.blog,
      // 💰 FUNDING FIELD
      funding: funding ?? this.funding,
      // 🏷️ OFFER FIELD
      offer: offer ?? this.offer,
      // 📚 COURSE FIELD
      course: course ?? this.course,
      // 🎨 COLORED PATTERN FIELD
      coloredPattern: coloredPattern ?? this.coloredPattern,
      // 📺 LIVE STREAMING FIELD
      live: live ?? this.live,
      // 😊 FEELINGS FIELDS
      feelingAction: feelingAction ?? this.feelingAction,
      feelingValue: feelingValue ?? this.feelingValue,
      feelingIcon: feelingIcon ?? this.feelingIcon,
      // 💳 PAID POST FIELDS
      isPaid: isPaid ?? this.isPaid,
      needsPayment: needsPayment ?? this.needsPayment,
      forSubscriptions: forSubscriptions ?? this.forSubscriptions,
      postPrice: postPrice ?? this.postPrice,
      paidText: paidText ?? this.paidText,
      isCompetitionEntry: isCompetitionEntry ?? this.isCompetitionEntry,
      competitionId: competitionId ?? this.competitionId,
      competitionName: competitionName ?? this.competitionName,
      competitionStatus: competitionStatus ?? this.competitionStatus,
      competitionRank: competitionRank ?? this.competitionRank,
      competitionCategory: competitionCategory ?? this.competitionCategory,
      competitionBadgeText: competitionBadgeText ?? this.competitionBadgeText,
      isWinner: isWinner ?? this.isWinner,
      winnerRank: winnerRank ?? this.winnerRank,
      // 🎖️ MERIT FIELD
      merit: merit ?? this.merit,
      // ⏱️ VIDEO DURATION
      videoDurationSeconds: videoDurationSeconds ?? this.videoDurationSeconds,
      // 🎵 REEL SOUND FIELDS
      soundId: soundId ?? this.soundId,
      soundTitle: soundTitle ?? this.soundTitle,
      soundUrl: soundUrl ?? this.soundUrl,
    );
  }

  static bool _bool(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    if (value is num) {
      return value == 1;
    }
    return false;
  }

  static String? _string(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  static int _int(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value.toString());
    return parsed ?? 0;
  }

  static double? _double(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed;
  }

  static String _authorName(Map<String, dynamic> json) {
    // If the post is from a page, use the page name
    final pageTitle = _string(json['page_title']);
    if (pageTitle != null && pageTitle.trim().isNotEmpty) {
      return pageTitle.trim();
    }

    final pageName = _string(json['page_name']);
    if (pageName != null && pageName.trim().isNotEmpty) {
      return pageName.trim();
    }

    // If it's from a regular user
    final fromPost = _string(json['post_author_name']);
    if (fromPost != null && fromPost.trim().isNotEmpty) {
      return fromPost.trim();
    }
    final first = _string(json['user_firstname']);
    final last = _string(json['user_lastname']);
    final parts = [first, last]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    final username = _string(json['user_name']);
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return 'User';
  }

  static String? _authorAvatar(Map<String, dynamic> json) {
    // If the post is from a page, use the page image
    final pagePicture = _string(json['page_picture']);
    if (pagePicture != null && pagePicture.isNotEmpty) {
      return pagePicture;
    }

    // If it's from a regular user
    final postAvatar = _string(json['post_author_picture']);
    if (postAvatar != null && postAvatar.isNotEmpty) {
      return postAvatar;
    }
    final userAvatar = _string(json['user_picture']);
    if (userAvatar != null && userAvatar.isNotEmpty) {
      return userAvatar;
    }
    return null;
  }

  static Map<String, int> _parseReactions(Object? value) {
    if (value is Map<String, dynamic>) {
      return value.map((key, dynamic val) => MapEntry(key, _int(val)));
    }
    return const {};
  }

  static List<String> _topReactions(Map<String, int> breakdown) {
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .take(3)
        .toList();
  }

  static String _formatCount(int value) {
    if (value >= 1000000) {
      final fixed = (value / 1000000).toStringAsFixed(1);
      return '${_trimTrailingZero(fixed)}M';
    }
    if (value >= 1000) {
      final fixed = (value / 1000).toStringAsFixed(1);
      return '${_trimTrailingZero(fixed)}K';
    }
    return value.toString();
  }

  static String _trimTrailingZero(String value) {
    return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
  }

  static PostEvent? _parseEventData(Map<String, dynamic> json) {
    // If there's an event object, use it
    if (json['event'] != null && json['event'] is Map<String, dynamic>) {
      return PostEvent.fromJson(json['event']);
    }

    // If this is an event-related post but event data is in main level
    if (json['post_type'] == 'event' ||
        json['post_type'] == 'event_cover' ||
        _bool(json['in_event'])) {
      // Check if we have event fields at root level
      if (json['event_title'] != null || json['event_id'] != null) {
        return PostEvent.fromJson(json);
      }
    }

    return null;
  }

  /// Create a copy of this post with updated reaction
  Post copyWithReaction(String? reaction) {
    // إذا كان التفاعل 'remove'، نعتبره null
    final newReaction = (reaction == 'remove') ? null : reaction;

    // Calculate new reaction breakdown
    final newBreakdown = Map<String, int>.from(reactionBreakdown);

    // Remove old reaction
    if (myReaction != null) {
      newBreakdown[myReaction!] = (newBreakdown[myReaction!] ?? 1) - 1;
      if (newBreakdown[myReaction!]! <= 0) {
        newBreakdown.remove(myReaction!);
      }
    }

    // Add new reaction (only if not 'remove')
    if (newReaction != null) {
      newBreakdown[newReaction] = (newBreakdown[newReaction] ?? 0) + 1;
    }

    // Calculate new total count
    final hadReaction = myReaction != null;
    final hasReaction = newReaction != null;
    final newReactionsCount =
        reactionsCount + (hasReaction ? 1 : 0) - (hadReaction ? 1 : 0);

    return Post(
      id: id,
      authorName: authorName,
      publishedAt: publishedAt,
      text: text,
      postType: postType,
      authorAvatarUrl: authorAvatarUrl,
      authorId: authorId,
      authorUsername: authorUsername,
      authorType: authorType,
      // ⚠️ ONLINE STATUS FIELDS - مطلوب للحفاظ على حالة الاتصال
      authorIsOnline: authorIsOnline,
      authorLastSeen: authorLastSeen,
      pageId: pageId,
      pageName: pageName,
      pageTitle: pageTitle,
      // Group support
      inGroup: inGroup,
      groupId: groupId,
      groupName: groupName,
      groupTitle: groupTitle,
      groupPicture: groupPicture,
      // Event support
      inEvent: inEvent,
      event: event,
      commentsCount: commentsCount,
      reactionsCount: newReactionsCount,
      sharesCount: sharesCount,
      viewsCount: viewsCount,
      reviewsCount: reviewsCount,
      isVerified: isVerified,
      myReaction: newReaction, // استخدام newReaction بدلاً من reaction
      privacy: privacy,
      reactionBreakdown: newBreakdown,
      permalink: permalink,
      video: video,
      photos: photos,
      ogImage: ogImage,
      poll: poll,
      link: link,
      audio: audio,
      // Post management
      isSaved: isSaved,
      isPinned: isPinned,
      isHidden: isHidden,
      commentsDisabled: commentsDisabled,
      tipsEnabled: tipsEnabled,
      forAdult: forAdult,
      isPromoted: isPromoted,
      isAd: isAd,
      // Ad data
      campaignTitle: campaignTitle,
      campaignDescription: campaignDescription,
      campaignUrl: campaignUrl,
      adsImage: adsImage,
      actionButtonText: actionButtonText,
      actionButtonUrl: actionButtonUrl,
      campaignId: campaignId,
      adsType: adsType,
      campaignBidding: campaignBidding,
      targetName: targetName,
      targetPicture: targetPicture,
      adPageId: adPageId,
      adGroupId: adGroupId,
      adEventId: adEventId,
      adPostId: adPostId,
      // Shared posts and articles
      originPost: originPost,
      blog: blog,
      // 💰 FUNDING FIELD - مطلوب لحفظ معلومات التبرع
      funding: funding,
      // 🏷️ OFFER FIELD - مطلوب للحفاظ على بيانات العروض
      offer: offer,
      // 📚 COURSE FIELD - مطلوب للحفاظ على بيانات الدورات
      course: course,
      // 🎨 COLORED PATTERN - مطلوب لحفظ النمط الملون
      coloredPattern: coloredPattern,
      // 📺 LIVE STREAMING FIELD - مطلوب للحفاظ على بيانات البث المباشر
      live: live,
      // 😊 FEELING FIELDS - مطلوب للحفاظ على بيانات المشاعر
      feelingAction: feelingAction,
      feelingValue: feelingValue,
      feelingIcon: feelingIcon,
      // 💳 PAID POST FIELDS - الحفاظ على حالة الدفع
      isPaid: isPaid,
      needsPayment: needsPayment,
      forSubscriptions: forSubscriptions,
      postPrice: postPrice,
      paidText: paidText,
      isCompetitionEntry: isCompetitionEntry,
      competitionId: competitionId,
      competitionName: competitionName,
      competitionStatus: competitionStatus,
      competitionRank: competitionRank,
      competitionCategory: competitionCategory,
      competitionBadgeText: competitionBadgeText,
      isWinner: isWinner,
      winnerRank: winnerRank,
      // 🎖️ MERIT FIELD - الحفاظ على بيانات الجدارة
      merit: merit,
      // ⏱️ VIDEO DURATION
      videoDurationSeconds: videoDurationSeconds,
      // 🎵 REEL SOUND FIELDS
      soundId: soundId,
      soundTitle: soundTitle,
      soundUrl: soundUrl,
    );
  }
}

class PostVideo {
  PostVideo({
    required this.originalSource,
    required this.availableSources,
    required this.thumbnail,
    required this.categoryName,
    this.viewCount = 0,
  });

  final String originalSource;
  final Map<String, String> availableSources;
  final String thumbnail;
  final String categoryName;
  final int viewCount;

  bool get hasAnySource =>
      originalSource.isNotEmpty || availableSources.isNotEmpty;

  Uri? bestSourceUri() {
    if (availableSources.isNotEmpty) {
      final preferredOrder = [
        '2160p',
        '1440p',
        '1080p',
        '720p',
        '480p',
        '360p',
        '240p',
      ];
      for (final quality in preferredOrder) {
        final url = availableSources[quality];
        if (url != null && url.isNotEmpty) {
          return Uri.tryParse(url);
        }
      }
    }
    if (originalSource.isNotEmpty) {
      return Uri.tryParse(originalSource);
    }
    return null;
  }

  static PostVideo? maybeFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final original = Post._string(value['source']) ?? '';
    final sources = <String, String>{};
    const qualities = [
      'source_2160p',
      'source_1440p',
      'source_1080p',
      'source_720p',
      'source_480p',
      'source_360p',
      'source_240p',
    ];
    for (final key in qualities) {
      final url = Post._string(value[key]);
      if (url != null && url.isNotEmpty) {
        sources[key.replaceFirst('source_', '')] = url;
      }
    }
    if (original.isEmpty && sources.isEmpty) {
      return null;
    }
    return PostVideo(
      originalSource: original,
      availableSources: sources,
      thumbnail: Post._string(value['thumbnail']) ?? '',
      categoryName: Post._string(value['category_name']) ?? '',
      viewCount: Post._int(value['views']),
    );
  }
}

class PostPhoto {
  PostPhoto({
    required this.id,
    required this.source,
    this.votes = 0,
    this.blur = false, // ✅ إضافة حقل blur
  });

  final int id;
  final String source;
  final int votes;
  final bool blur; // ✅ هل الصورة محجوبة (للمحتوى للبالغين)

  static PostPhoto? maybeFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final id = Post._int(value['photo_id']);
    final source = Post._string(value['source']);
    if (id == 0 || source == null || source.isEmpty) {
      return null;
    }

    // تجاهل الفيديوهات التي تأتي في حقل photos بالخطأ
    final lowerSource = source.toLowerCase();
    if (lowerSource.endsWith('.mp4') ||
        lowerSource.endsWith('.mov') ||
        lowerSource.endsWith('.avi') ||
        lowerSource.endsWith('.webm') ||
        lowerSource.contains('/videos/')) {
      return null;
    }

    return PostPhoto(
      id: id,
      source: source,
      votes: Post._int(value['votes']),
      blur: Post._bool(value['blur']), // ✅ إضافة blur من JSON
    );
  }

  static List<PostPhoto>? listFromJson(Object? value) {
    if (value is! List) return null;
    final photos = value
        .map((item) => PostPhoto.maybeFromJson(item))
        .whereType<PostPhoto>()
        .toList();
    return photos.isEmpty ? null : photos;
  }
}

class PostPoll {
  PostPoll({required this.id, required this.votes, required this.options});

  final int id;
  final int votes;
  final List<PollOption> options;

  static PostPoll? maybeFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final id = Post._int(value['poll_id']);
    final options = PollOption.listFromJson(value['options']);
    if (id == 0 || options.isEmpty) {
      return null;
    }
    return PostPoll(id: id, votes: Post._int(value['votes']), options: options);
  }
}

class PollOption {
  PollOption({
    required this.id,
    required this.text,
    required this.votes,
    this.checked = false,
  });

  final int id;
  final String text;
  final int votes;
  final bool checked;

  double percentage(int totalVotes) {
    if (totalVotes == 0) return 0;
    return (votes / totalVotes) * 100;
  }

  static PollOption? maybeFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }
    final id = Post._int(value['option_id']);
    final text = Post._string(value['text']);
    if (id == 0 || text == null || text.isEmpty) {
      return null;
    }
    return PollOption(
      id: id,
      text: text,
      votes: Post._int(value['votes']),
      checked: Post._bool(value['checked']),
    );
  }

  static List<PollOption> listFromJson(Object? value) {
    if (value is! List) {
      return [];
    }
    return value
        .map((item) => PollOption.maybeFromJson(item))
        .whereType<PollOption>()
        .toList();
  }
}

/// نموذج لمحتوى المقال
class PostBlog {
  const PostBlog({
    required this.articleId,
    required this.title,
    required this.text,
    this.cover,
    this.categoryName,
    this.tags,
    this.textSnippet,
  });

  final String articleId;
  final String title;
  final String text;
  final String? cover;
  final String? categoryName;
  final String? tags;
  final String? textSnippet;

  static PostBlog? maybeFromJson(Object? value, {String? fallbackPostId}) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    // استخدام article_id أولاً، ثم post_id من blog، ثم fallbackPostId من parent Post
    final post_id = Post._string(value['post_id']);

    final title = Post._string(value['title']);
    final text =
        Post._string(value['parsed_text']) ?? Post._string(value['text']);

    if (post_id == null || title == null || text == null) {
      return null;
    }

    return PostBlog(
      articleId: post_id,
      title: title,
      text: text,
      cover:
          Post._string(value['parsed_cover']) ?? Post._string(value['cover']),
      categoryName: Post._string(value['category_name']),
      tags: Post._string(value['tags']),
      textSnippet: Post._string(value['text_snippet']),
    );
  }
}
