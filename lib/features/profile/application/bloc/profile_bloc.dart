import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:snginepro/core/bloc/base_bloc.dart';
import 'package:snginepro/core/network/api_exception.dart';
import 'package:snginepro/features/feed/data/models/post.dart';
import 'package:snginepro/features/profile/data/models/user_profile_model.dart';
import 'package:snginepro/features/profile/data/services/profile_api_service.dart';
// Events
abstract class ProfileEvent extends BaseEvent {}
class LoadProfileEvent extends ProfileEvent {
  final String? userId; // null للملف الشخصي الحالي
  LoadProfileEvent({this.userId});
  @override
  List<Object?> get props => [userId];
}
class UpdateProfileEvent extends ProfileEvent {
  final String? name;
  final String? bio;
  final String? location;
  final String? website;
  final String? avatarPath;
  final String? coverPath;
  UpdateProfileEvent({
    this.name,
    this.bio,
    this.location,
    this.website,
    this.avatarPath,
    this.coverPath,
  });
  @override
  List<Object?> get props => [name, bio, location, website, avatarPath, coverPath];
}
class LoadUserPostsEvent extends ProfileEvent {
  final String userId;
  LoadUserPostsEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}
class FollowUserEvent extends ProfileEvent {
  final String userId;
  FollowUserEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}
class UnfollowUserEvent extends ProfileEvent {
  final String userId;
  UnfollowUserEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}
class BlockUserEvent extends ProfileEvent {
  final String userId;
  BlockUserEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}
class UnblockUserEvent extends ProfileEvent {
  final String userId;
  UnblockUserEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}
class UpdatePrivacySettingsEvent extends ProfileEvent {
  final Map<String, dynamic> settings;
  UpdatePrivacySettingsEvent(this.settings);
  @override
  List<Object?> get props => [settings];
}
// States
abstract class ProfileState extends BaseState {
  const ProfileState({
    super.isLoading,
    super.errorMessage,
    this.profile,
    this.userPosts = const [],
    this.isFollowing = false,
    this.isBlocked = false,
  });
  final UserProfile? profile;
  final List<Post> userPosts;
  final bool isFollowing;
  final bool isBlocked;
  @override
  List<Object?> get props => [
        ...super.props,
        profile,
        userPosts,
        isFollowing,
        isBlocked,
      ];
}
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}
class ProfileLoading extends ProfileState {
  const ProfileLoading({
    super.profile,
    super.userPosts,
    super.isFollowing,
    super.isBlocked,
  }) : super(isLoading: true);
}
class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required super.profile,
    super.userPosts,
    super.isFollowing,
    super.isBlocked,
  });
}
class ProfileError extends ProfileState {
  const ProfileError(
    String message, {
    super.profile,
    super.userPosts,
    super.isFollowing,
    super.isBlocked,
  }) : super(errorMessage: message);
}
class ProfileUpdated extends ProfileState {
  const ProfileUpdated({
    required super.profile,
    super.userPosts,
    super.isFollowing,
    super.isBlocked,
  });
}
class UserPostsLoaded extends ProfileState {
  const UserPostsLoaded({
    required super.profile,
    required super.userPosts,
    super.isFollowing,
    super.isBlocked,
  });
}
class FollowStatusChanged extends ProfileState {
  const FollowStatusChanged({
    required super.profile,
    super.userPosts,
    required super.isFollowing,
    super.isBlocked,
  });
}
class BlockStatusChanged extends ProfileState {
  const BlockStatusChanged({
    required super.profile,
    super.userPosts,
    super.isFollowing,
    required super.isBlocked,
  });
}
// Bloc
class ProfileBloc extends BaseBloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._apiService) : super(const ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<LoadUserPostsEvent>(_onLoadUserPosts);
    // TODO: Implement other events when the backend APIs are available
    // on<UpdateProfileEvent>(_onUpdateProfile);
    // on<FollowUserEvent>(_onFollowUser);
    // on<UnfollowUserEvent>(_onUnfollowUser);
    // on<BlockUserEvent>(_onBlockUser);
    // on<UnblockUserEvent>(_onUnblockUser);
    // on<UpdatePrivacySettingsEvent>(_onUpdatePrivacySettings);
  }
  final ProfileApiService _apiService;
  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading(
      profile: state.profile,
      userPosts: state.userPosts,
      isFollowing: state.isFollowing,
      isBlocked: state.isBlocked,
    ));
    try {
      UserProfileResponse profileResponse;
      bool isFollowing = false;
      bool isBlocked = false;
      if (event.userId == null) {
        // Load current user's profile
        profileResponse = await _apiService.getMyProfile();
      } else {
        // Load other user's profile
        profileResponse = await _apiService.getProfileById(int.parse(event.userId!));
        // Check relationship status from the response
        isFollowing = profileResponse.relationship.isFollowing;
        isBlocked = profileResponse.relationship.isBlocked;
      }
      emit(ProfileLoaded(
        profile: profileResponse.profile,
        userPosts: state.userPosts,
        isFollowing: isFollowing,
        isBlocked: isBlocked,
      ));
    } on ApiException catch (e) {
      emit(ProfileError(
        e.message,
        profile: state.profile,
        userPosts: state.userPosts,
        isFollowing: state.isFollowing,
        isBlocked: state.isBlocked,
      ));
    } catch (e) {
      emit(ProfileError(
        e.toString(),
        profile: state.profile,
        userPosts: state.userPosts,
        isFollowing: state.isFollowing,
        isBlocked: state.isBlocked,
      ));
    }
  }
  Future<void> _onLoadUserPosts(
    LoadUserPostsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      // TODO: Implement when posts API service is available for specific user
      // For now, we'll just keep the current state
      emit(UserPostsLoaded(
        profile: state.profile,
        userPosts: [], // Empty list for now
        isFollowing: state.isFollowing,
        isBlocked: state.isBlocked,
      ));
    } on ApiException catch (e) {
      emit(ProfileError(
        e.message,
        profile: state.profile,
        userPosts: state.userPosts,
        isFollowing: state.isFollowing,
        isBlocked: state.isBlocked,
      ));
    }
  }
}