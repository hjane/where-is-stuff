import '../core/auth/user_info.dart';

class UserProfile extends UserInfo {
  final int roomCount;
  final int furnitureCount;
  final int itemCount;

  const UserProfile({
    required super.id,
    super.email,
    super.nickname,
    super.avatarUrl,
    super.gender,
    super.isAnonymous,
    super.memberStatus,
    super.points,
    required super.createdAt,
    super.updatedAt,
    this.roomCount = 0,
    this.furnitureCount = 0,
    this.itemCount = 0,
  });

  @override
  UserProfile copyWith({
    String? id,
    String? email,
    String? nickname,
    String? avatarUrl,
    Gender? gender,
    bool? isAnonymous,
    MemberStatus? memberStatus,
    int? points,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? roomCount,
    int? furnitureCount,
    int? itemCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      memberStatus: memberStatus ?? this.memberStatus,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roomCount: roomCount ?? this.roomCount,
      furnitureCount: furnitureCount ?? this.furnitureCount,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      gender: json['gender'] != null
          ? Gender.values[json['gender'] as int]
          : null,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      memberStatus: MemberStatus.values[json['member_status'] as int? ?? 0],
      points: json['points'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      roomCount: json['room_count'] as int? ?? 0,
      furnitureCount: json['furniture_count'] as int? ?? 0,
      itemCount: json['item_count'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'room_count': roomCount,
      'furniture_count': furnitureCount,
      'item_count': itemCount,
    };
  }
}
