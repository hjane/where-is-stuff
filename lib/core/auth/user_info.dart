enum Gender {
  male,
  female,
}

enum MemberStatus {
  free,
  basic,
  premium,
}

class UserInfo {
  final String id;
  final String? email;
  final String? nickname;
  final String? avatarUrl;
  final Gender? gender;
  final bool isAnonymous;
  final MemberStatus memberStatus;
  final int points;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserInfo({
    required this.id,
    this.email,
    this.nickname,
    this.avatarUrl,
    this.gender,
    this.isAnonymous = false,
    this.memberStatus = MemberStatus.free,
    this.points = 0,
    required this.createdAt,
    this.updatedAt,
  });

  UserInfo copyWith({
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
  }) {
    return UserInfo(
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
    );
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'gender': gender?.index,
      'is_anonymous': isAnonymous,
      'member_status': memberStatus.index,
      'points': points,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
