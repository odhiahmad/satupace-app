class UserEntity {
  final String id;
  final String? name;
  final String? email;
  final String phoneNumber;
  final String? gender;
  final bool isVerified;
  final bool isActive;

  const UserEntity({
    required this.id,
    this.name,
    this.email,
    required this.phoneNumber,
    this.gender,
    required this.isVerified,
    required this.isActive,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: (json['phone_number'] ?? '').toString(),
      gender: json['gender']?.toString(),
      isVerified: json['is_verified'] == true,
      isActive: json['is_active'] == true,
    );
  }
}

class RunnerProfileEntity {
  final String userId;
  final double avgPace;
  final int preferredDistance;
  final String preferredTime;
  final double latitude;
  final double longitude;
  final bool womenOnlyMode;
  final String? image;
  final bool isActive;

  const RunnerProfileEntity({
    required this.userId,
    required this.avgPace,
    required this.preferredDistance,
    required this.preferredTime,
    required this.latitude,
    required this.longitude,
    required this.womenOnlyMode,
    this.image,
    required this.isActive,
  });

  factory RunnerProfileEntity.fromJson(Map<String, dynamic> json) {
    return RunnerProfileEntity(
      userId: (json['user_id'] ?? '').toString(),
      avgPace: (json['avg_pace'] as num?)?.toDouble() ?? 0,
      preferredDistance: (json['preferred_distance'] as num?)?.toInt() ?? 0,
      preferredTime: (json['preferred_time'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      womenOnlyMode: json['women_only_mode'] == true,
      image: json['image']?.toString(),
      isActive: json['is_active'] == true,
    );
  }
}

class DirectMatchEntity {
  final String id;
  final String user1Id;
  final String user2Id;
  final String status;
  final String? message;
  final String? createdAt;
  final String? matchedAt;

  const DirectMatchEntity({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.status,
    this.message,
    this.createdAt,
    this.matchedAt,
  });

  factory DirectMatchEntity.fromJson(Map<String, dynamic> json) {
    return DirectMatchEntity(
      id: (json['id'] ?? '').toString(),
      user1Id: (json['user1_id'] ?? '').toString(),
      user2Id: (json['user2_id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      message: json['message']?.toString(),
      createdAt: json['created_at']?.toString(),
      matchedAt: json['matched_at']?.toString(),
    );
  }
}

class RunGroupEntity {
  final String id;
  final String name;
  final double avgPace;
  final int preferredDistance;
  final double latitude;
  final double longitude;
  final String? scheduledAt;
  final int maxMember;
  final bool isWomenOnly;
  final String status;
  final String createdBy;

  const RunGroupEntity({
    required this.id,
    required this.name,
    required this.avgPace,
    required this.preferredDistance,
    required this.latitude,
    required this.longitude,
    required this.scheduledAt,
    required this.maxMember,
    required this.isWomenOnly,
    required this.status,
    required this.createdBy,
  });

  factory RunGroupEntity.fromJson(Map<String, dynamic> json) {
    return RunGroupEntity(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Run Group').toString(),
      avgPace: (json['avg_pace'] as num?)?.toDouble() ?? 0,
      preferredDistance: (json['preferred_distance'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      scheduledAt: json['scheduled_at']?.toString(),
      maxMember: (json['max_member'] as num?)?.toInt() ?? 0,
      isWomenOnly: json['is_women_only'] == true,
      status: (json['status'] ?? 'open').toString(),
      createdBy: (json['created_by'] ?? '').toString(),
    );
  }
}

class RunActivityEntity {
  final String id;
  final String userId;
  final double distance;
  final int duration;
  final double? avgPace;
  final int? calories;
  final String? routeData;
  final String? startedAt;
  final String? endedAt;

  const RunActivityEntity({
    required this.id,
    required this.userId,
    required this.distance,
    required this.duration,
    this.avgPace,
    this.calories,
    this.routeData,
    this.startedAt,
    this.endedAt,
  });

  factory RunActivityEntity.fromJson(Map<String, dynamic> json) {
    return RunActivityEntity(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      avgPace: (json['avg_pace'] as num?)?.toDouble(),
      calories: (json['calories'] as num?)?.toInt(),
      routeData: json['route_data']?.toString(),
      startedAt: json['started_at']?.toString(),
      endedAt: json['ended_at']?.toString(),
    );
  }
}

class ChatMessageEntity {
  final String id;
  final String senderId;
  final String message;
  final String? createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.senderId,
    required this.message,
    this.createdAt,
  });

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) {
    return ChatMessageEntity(
      id: (json['id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      message: (json['message'] ?? json['content'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class PhotoEntity {
  final String id;
  final String userId;
  final String? imageUrl;
  final String type;
  final bool isPrimary;

  const PhotoEntity({
    required this.id,
    required this.userId,
    this.imageUrl,
    required this.type,
    required this.isPrimary,
  });

  factory PhotoEntity.fromJson(Map<String, dynamic> json) {
    return PhotoEntity(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
      type: (json['type'] ?? '').toString(),
      isPrimary: json['is_primary'] == true,
    );
  }
}

class SafetyReportEntity {
  final String id;
  final String reporterUserId;
  final String reportedUserId;
  final String reason;
  final String? description;
  final String? createdAt;

  const SafetyReportEntity({
    required this.id,
    required this.reporterUserId,
    required this.reportedUserId,
    required this.reason,
    this.description,
    this.createdAt,
  });

  factory SafetyReportEntity.fromJson(Map<String, dynamic> json) {
    return SafetyReportEntity(
      id: (json['id'] ?? '').toString(),
      reporterUserId: (json['reporter_user_id'] ?? '').toString(),
      reportedUserId: (json['reported_user_id'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      description: json['description']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class SmartwatchDeviceEntity {
  final String id;
  final String userId;
  final String deviceName;
  final String deviceType;
  final String deviceId;

  const SmartwatchDeviceEntity({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.deviceType,
    required this.deviceId,
  });

  factory SmartwatchDeviceEntity.fromJson(Map<String, dynamic> json) {
    return SmartwatchDeviceEntity(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      deviceName: (json['device_name'] ?? '').toString(),
      deviceType: (json['device_type'] ?? '').toString(),
      deviceId: (json['device_id'] ?? '').toString(),
    );
  }
}

class BiometricCredentialEntity {
  final String id;
  final String credentialId;
  final String deviceName;
  final String? createdAt;

  const BiometricCredentialEntity({
    required this.id,
    required this.credentialId,
    required this.deviceName,
    this.createdAt,
  });

  factory BiometricCredentialEntity.fromJson(Map<String, dynamic> json) {
    return BiometricCredentialEntity(
      id: (json['id'] ?? '').toString(),
      credentialId: (json['credential_id'] ?? '').toString(),
      deviceName: (json['device_name'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}