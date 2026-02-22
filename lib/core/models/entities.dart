/// Entity classes aligned with Go backend response structs.
library;

class UserEntity {
  final String id;
  final String? name;
  final String? email;
  final String phoneNumber;
  final String? gender;
  final bool hasProfile;
  final bool isVerified;
  final bool isActive;
  final String? token;
  final String? createdAt;
  final String? updatedAt;

  const UserEntity({
    required this.id,
    this.name,
    this.email,
    required this.phoneNumber,
    this.gender,
    this.hasProfile = false,
    required this.isVerified,
    required this.isActive,
    this.token,
    this.createdAt,
    this.updatedAt,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: (json['phone_number'] ?? '').toString(),
      gender: json['gender']?.toString(),
      hasProfile: json['has_profile'] == true,
      isVerified: json['is_verified'] == true,
      isActive: json['is_active'] == true,
      token: json['token']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        'phone_number': phoneNumber,
        if (gender != null) 'gender': gender,
        'has_profile': hasProfile,
        'is_verified': isVerified,
        'is_active': isActive,
      };
}

class RunnerProfileEntity {
  final String id;
  final String userId;
  final double avgPace;
  final int preferredDistance;
  final String preferredTime;
  final double latitude;
  final double longitude;
  final bool womenOnlyMode;
  final String? image;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const RunnerProfileEntity({
    required this.id,
    required this.userId,
    required this.avgPace,
    required this.preferredDistance,
    required this.preferredTime,
    required this.latitude,
    required this.longitude,
    required this.womenOnlyMode,
    this.image,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory RunnerProfileEntity.fromJson(Map<String, dynamic> json) {
    return RunnerProfileEntity(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      avgPace: (json['avg_pace'] as num?)?.toDouble() ?? 0,
      preferredDistance: (json['preferred_distance'] as num?)?.toInt() ?? 0,
      preferredTime: (json['preferred_time'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      womenOnlyMode: json['women_only_mode'] == true,
      image: json['image']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'avg_pace': avgPace,
        'preferred_distance': preferredDistance,
        'preferred_time': preferredTime,
        'latitude': latitude,
        'longitude': longitude,
        'women_only_mode': womenOnlyMode,
        if (image != null) 'image': image,
      };
}

class DirectMatchEntity {
  final String id;
  final String user1Id;
  final UserEntity? user1;
  final String user2Id;
  final UserEntity? user2;
  final String status;
  final String? createdAt;
  final String? matchedAt;

  const DirectMatchEntity({
    required this.id,
    required this.user1Id,
    this.user1,
    required this.user2Id,
    this.user2,
    required this.status,
    this.createdAt,
    this.matchedAt,
  });

  factory DirectMatchEntity.fromJson(Map<String, dynamic> json) {
    return DirectMatchEntity(
      id: (json['id'] ?? '').toString(),
      user1Id: (json['user_1_id'] ?? json['user1_id'] ?? '').toString(),
      user1: json['user_1'] is Map
          ? UserEntity.fromJson(Map<String, dynamic>.from(json['user_1']))
          : null,
      user2Id: (json['user_2_id'] ?? json['user2_id'] ?? '').toString(),
      user2: json['user_2'] is Map
          ? UserEntity.fromJson(Map<String, dynamic>.from(json['user_2']))
          : null,
      status: (json['status'] ?? 'pending').toString(),
      createdAt: json['created_at']?.toString(),
      matchedAt: json['matched_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_1_id': user1Id,
        'user_2_id': user2Id,
        'status': status,
      };
}

class RunGroupEntity {
  final String id;
  final String? name;
  final double avgPace;
  final int preferredDistance;
  final double latitude;
  final double longitude;
  final String? scheduledAt;
  final int maxMember;
  final bool isWomenOnly;
  final String status;
  final String createdBy;
  final UserEntity? creator;
  final int memberCount;
  final String? createdAt;

  const RunGroupEntity({
    required this.id,
    this.name,
    required this.avgPace,
    required this.preferredDistance,
    required this.latitude,
    required this.longitude,
    this.scheduledAt,
    required this.maxMember,
    required this.isWomenOnly,
    required this.status,
    required this.createdBy,
    this.creator,
    this.memberCount = 0,
    this.createdAt,
  });

  factory RunGroupEntity.fromJson(Map<String, dynamic> json) {
    return RunGroupEntity(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString(),
      avgPace: (json['avg_pace'] as num?)?.toDouble() ?? 0,
      preferredDistance: (json['preferred_distance'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      scheduledAt: json['scheduled_at']?.toString(),
      maxMember: (json['max_member'] as num?)?.toInt() ?? 0,
      isWomenOnly: json['is_women_only'] == true,
      status: (json['status'] ?? 'open').toString(),
      createdBy: (json['created_by'] ?? '').toString(),
      creator: json['creator'] is Map
          ? UserEntity.fromJson(Map<String, dynamic>.from(json['creator']))
          : null,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        'avg_pace': avgPace,
        'preferred_distance': preferredDistance,
        'latitude': latitude,
        'longitude': longitude,
        if (scheduledAt != null) 'scheduled_at': scheduledAt,
        'max_member': maxMember,
        'is_women_only': isWomenOnly,
      };
}

class RunGroupMemberEntity {
  final String id;
  final String groupId;
  final String userId;
  final UserEntity? user;
  final String status;
  final String? joinedAt;

  const RunGroupMemberEntity({
    required this.id,
    required this.groupId,
    required this.userId,
    this.user,
    required this.status,
    this.joinedAt,
  });

  factory RunGroupMemberEntity.fromJson(Map<String, dynamic> json) {
    return RunGroupMemberEntity(
      id: (json['id'] ?? '').toString(),
      groupId: (json['group_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      user: json['user'] is Map
          ? UserEntity.fromJson(Map<String, dynamic>.from(json['user']))
          : null,
      status: (json['status'] ?? '').toString(),
      joinedAt: json['joined_at']?.toString(),
    );
  }
}

class RunActivityEntity {
  final String id;
  final String userId;
  final UserEntity? user;
  final double distance;
  final int duration;
  final double avgPace;
  final int calories;
  final String source;
  final String? createdAt;

  const RunActivityEntity({
    required this.id,
    required this.userId,
    this.user,
    required this.distance,
    required this.duration,
    required this.avgPace,
    this.calories = 0,
    this.source = '',
    this.createdAt,
  });

  factory RunActivityEntity.fromJson(Map<String, dynamic> json) {
    return RunActivityEntity(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      user: json['user'] is Map
          ? UserEntity.fromJson(Map<String, dynamic>.from(json['user']))
          : null,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      avgPace: (json['avg_pace'] as num?)?.toDouble() ?? 0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      source: (json['source'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'distance': distance,
        'duration': duration,
        'avg_pace': avgPace,
        'calories': calories,
        'source': source,
      };
}

class DirectChatMessageEntity {
  final String id;
  final String matchId;
  final String senderId;
  final UserEntity? sender;
  final String message;
  final String? createdAt;

  const DirectChatMessageEntity({
    required this.id,
    required this.matchId,
    required this.senderId,
    this.sender,
    required this.message,
    this.createdAt,
  });

  factory DirectChatMessageEntity.fromJson(Map<String, dynamic> json) {
    return DirectChatMessageEntity(
      id: (json['id'] ?? '').toString(),
      matchId: (json['match_id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      sender: json['sender'] is Map
          ? UserEntity.fromJson(Map<String, dynamic>.from(json['sender']))
          : null,
      message: (json['message'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class GroupChatMessageEntity {
  final String id;
  final String groupId;
  final String senderId;
  final UserEntity? sender;
  final String message;
  final String? createdAt;

  const GroupChatMessageEntity({
    required this.id,
    required this.groupId,
    required this.senderId,
    this.sender,
    required this.message,
    this.createdAt,
  });

  factory GroupChatMessageEntity.fromJson(Map<String, dynamic> json) {
    return GroupChatMessageEntity(
      id: (json['id'] ?? '').toString(),
      groupId: (json['group_id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      sender: json['sender'] is Map
          ? UserEntity.fromJson(Map<String, dynamic>.from(json['sender']))
          : null,
      message: (json['message'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class PhotoEntity {
  final String id;
  final String userId;
  final String url;
  final String type;
  final bool isPrimary;
  final String? createdAt;

  const PhotoEntity({
    required this.id,
    required this.userId,
    required this.url,
    required this.type,
    required this.isPrimary,
    this.createdAt,
  });

  factory PhotoEntity.fromJson(Map<String, dynamic> json) {
    return PhotoEntity(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      url: (json['url'] ?? json['image_url'] ?? json['image'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      isPrimary: json['is_primary'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'image': url,
        'type': type,
        'is_primary': isPrimary,
      };
}

class SafetyLogEntity {
  final String id;
  final String userId;
  final UserEntity? user;
  final String matchId;
  final String status;
  final String reason;
  final String? createdAt;

  const SafetyLogEntity({
    required this.id,
    required this.userId,
    this.user,
    required this.matchId,
    required this.status,
    required this.reason,
    this.createdAt,
  });

  factory SafetyLogEntity.fromJson(Map<String, dynamic> json) {
    return SafetyLogEntity(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      user: json['user'] is Map
          ? UserEntity.fromJson(Map<String, dynamic>.from(json['user']))
          : null,
      matchId: (json['match_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'match_id': matchId,
        'status': status,
        'reason': reason,
      };
}

class StravaConnectionEntity {
  final String id;
  final int athleteId;
  final String scope;
  final bool isConnected;
  final String? lastSyncAt;
  final String connectedAt;

  const StravaConnectionEntity({
    required this.id,
    required this.athleteId,
    required this.scope,
    required this.isConnected,
    this.lastSyncAt,
    required this.connectedAt,
  });

  factory StravaConnectionEntity.fromJson(Map<String, dynamic> json) {
    return StravaConnectionEntity(
      id: (json['id'] ?? '').toString(),
      athleteId: (json['athlete_id'] as num?)?.toInt() ?? 0,
      scope: (json['scope'] ?? '').toString(),
      isConnected: json['is_connected'] == true,
      lastSyncAt: json['last_sync_at']?.toString(),
      connectedAt: (json['connected_at'] ?? '').toString(),
    );
  }
}

class StravaActivityEntity {
  final String id;
  final int stravaId;
  final String? runActivityId;
  final String name;
  final String type;
  final double distanceKm;
  final int movingTime;
  final int elapsedTime;
  final double totalElevation;
  final double averagePace;
  final double maxSpeed;
  final double averageHeartrate;
  final double maxHeartrate;
  final double calories;
  final String startDate;
  final String? mapPolyline;
  final String status;
  final String syncedAt;

  const StravaActivityEntity({
    required this.id,
    required this.stravaId,
    this.runActivityId,
    required this.name,
    required this.type,
    required this.distanceKm,
    required this.movingTime,
    required this.elapsedTime,
    this.totalElevation = 0,
    this.averagePace = 0,
    this.maxSpeed = 0,
    this.averageHeartrate = 0,
    this.maxHeartrate = 0,
    this.calories = 0,
    required this.startDate,
    this.mapPolyline,
    required this.status,
    required this.syncedAt,
  });

  factory StravaActivityEntity.fromJson(Map<String, dynamic> json) {
    return StravaActivityEntity(
      id: (json['id'] ?? '').toString(),
      stravaId: (json['strava_id'] as num?)?.toInt() ?? 0,
      runActivityId: json['run_activity_id']?.toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      movingTime: (json['moving_time_seconds'] as num?)?.toInt() ?? 0,
      elapsedTime: (json['elapsed_time_seconds'] as num?)?.toInt() ?? 0,
      totalElevation: (json['total_elevation_m'] as num?)?.toDouble() ?? 0,
      averagePace: (json['average_pace_min_km'] as num?)?.toDouble() ?? 0,
      maxSpeed: (json['max_speed_m_s'] as num?)?.toDouble() ?? 0,
      averageHeartrate: (json['average_heartrate'] as num?)?.toDouble() ?? 0,
      maxHeartrate: (json['max_heartrate'] as num?)?.toDouble() ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      startDate: (json['start_date'] ?? '').toString(),
      mapPolyline: json['map_polyline']?.toString(),
      status: (json['status'] ?? '').toString(),
      syncedAt: (json['synced_at'] ?? '').toString(),
    );
  }
}

class StravaSyncSummaryEntity {
  final int totalSynced;
  final int totalSkipped;
  final int totalFailed;
  final List<StravaActivityEntity> activities;

  const StravaSyncSummaryEntity({
    required this.totalSynced,
    required this.totalSkipped,
    required this.totalFailed,
    required this.activities,
  });

  factory StravaSyncSummaryEntity.fromJson(Map<String, dynamic> json) {
    return StravaSyncSummaryEntity(
      totalSynced: (json['total_synced'] as num?)?.toInt() ?? 0,
      totalSkipped: (json['total_skipped'] as num?)?.toInt() ?? 0,
      totalFailed: (json['total_failed'] as num?)?.toInt() ?? 0,
      activities: (json['activities'] as List?)
              ?.map((a) => StravaActivityEntity.fromJson(
                  a is Map ? Map<String, dynamic>.from(a) : const {}))
              .toList() ??
          [],
    );
  }
}

class StravaStatsEntity {
  final StravaConnectionEntity? connection;
  final int totalActivities;
  final double totalDistanceKm;
  final int totalDuration;
  final double avgPace;
  final double avgHeartrate;
  final int totalCalories;
  final double totalElevation;

  const StravaStatsEntity({
    this.connection,
    required this.totalActivities,
    required this.totalDistanceKm,
    required this.totalDuration,
    required this.avgPace,
    this.avgHeartrate = 0,
    this.totalCalories = 0,
    this.totalElevation = 0,
  });

  factory StravaStatsEntity.fromJson(Map<String, dynamic> json) {
    return StravaStatsEntity(
      connection: json['connection'] is Map
          ? StravaConnectionEntity.fromJson(
              Map<String, dynamic>.from(json['connection']))
          : null,
      totalActivities: (json['total_activities'] as num?)?.toInt() ?? 0,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0,
      totalDuration: (json['total_duration_seconds'] as num?)?.toInt() ?? 0,
      avgPace: (json['avg_pace_min_km'] as num?)?.toDouble() ?? 0,
      avgHeartrate: (json['avg_heartrate'] as num?)?.toDouble() ?? 0,
      totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
      totalElevation: (json['total_elevation_m'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BiometricCredentialEntity {
  final String id;
  final String userId;
  final String credentialId;
  final String deviceName;
  final bool isActive;
  final String? lastUsedAt;
  final String? createdAt;

  const BiometricCredentialEntity({
    required this.id,
    this.userId = '',
    required this.credentialId,
    required this.deviceName,
    this.isActive = true,
    this.lastUsedAt,
    this.createdAt,
  });

  factory BiometricCredentialEntity.fromJson(Map<String, dynamic> json) {
    return BiometricCredentialEntity(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      credentialId: (json['credential_id'] ?? '').toString(),
      deviceName: (json['device_name'] ?? '').toString(),
      isActive: json['is_active'] == true,
      lastUsedAt: json['last_used_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class ExploreRunnerEntity {
  final String userId;
  final String? name;
  final String? gender;
  final double avgPace;
  final int preferredDistance;
  final String preferredTime;
  final String? image;
  final double distanceKm;
  final bool womenOnlyMode;

  const ExploreRunnerEntity({
    required this.userId,
    this.name,
    this.gender,
    required this.avgPace,
    required this.preferredDistance,
    required this.preferredTime,
    this.image,
    this.distanceKm = 0,
    this.womenOnlyMode = false,
  });

  factory ExploreRunnerEntity.fromJson(Map<String, dynamic> json) {
    return ExploreRunnerEntity(
      userId: (json['user_id'] ?? '').toString(),
      name: json['name']?.toString(),
      gender: json['gender']?.toString(),
      avgPace: (json['avg_pace'] as num?)?.toDouble() ?? 0,
      preferredDistance: (json['preferred_distance'] as num?)?.toInt() ?? 0,
      preferredTime: (json['preferred_time'] ?? '').toString(),
      image: json['image']?.toString(),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      womenOnlyMode: json['women_only_mode'] == true,
    );
  }
}

class ExploreGroupEntity {
  final String groupId;
  final String? name;
  final double avgPace;
  final int preferredDistance;
  final String? scheduledAt;
  final int maxMember;
  final int currentMembers;
  final bool isWomenOnly;
  final String status;
  final double distanceKm;
  final String createdBy;

  const ExploreGroupEntity({
    required this.groupId,
    this.name,
    required this.avgPace,
    required this.preferredDistance,
    this.scheduledAt,
    required this.maxMember,
    this.currentMembers = 0,
    required this.isWomenOnly,
    required this.status,
    this.distanceKm = 0,
    required this.createdBy,
  });

  factory ExploreGroupEntity.fromJson(Map<String, dynamic> json) {
    return ExploreGroupEntity(
      groupId: (json['group_id'] ?? '').toString(),
      name: json['name']?.toString(),
      avgPace: (json['avg_pace'] as num?)?.toDouble() ?? 0,
      preferredDistance: (json['preferred_distance'] as num?)?.toInt() ?? 0,
      scheduledAt: json['scheduled_at']?.toString(),
      maxMember: (json['max_member'] as num?)?.toInt() ?? 0,
      currentMembers: (json['current_members'] as num?)?.toInt() ?? 0,
      isWomenOnly: json['is_women_only'] == true,
      status: (json['status'] ?? 'open').toString(),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      createdBy: (json['created_by'] ?? '').toString(),
    );
  }
}

class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final String orderBy;
  final String sortOrder;

  const PaginationMeta({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.orderBy = '',
    this.sortOrder = '',
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      orderBy: (json['order_by'] ?? '').toString(),
      sortOrder: (json['sort_by'] ?? '').toString(),
    );
  }
}

class CursorPaginationMeta {
  final int limit;
  final String sortBy;
  final String orderBy;
  final String nextCursor;
  final bool hasNext;

  const CursorPaginationMeta({
    this.limit = 20,
    this.sortBy = '',
    this.orderBy = '',
    this.nextCursor = '',
    this.hasNext = false,
  });

  factory CursorPaginationMeta.fromJson(Map<String, dynamic> json) {
    return CursorPaginationMeta(
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      sortBy: (json['sort_by'] ?? '').toString(),
      orderBy: (json['order_by'] ?? '').toString(),
      nextCursor: (json['next_cursor'] ?? '').toString(),
      hasNext: json['has_next'] == true,
    );
  }
}