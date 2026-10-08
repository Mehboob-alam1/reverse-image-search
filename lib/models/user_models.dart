class UsageStats {
  const UsageStats({
    required this.used,
    required this.limit,
    required this.remaining,
    required this.isPro,
    this.tier = UsageTier.free,
    this.trialActive = false,
    this.periodEndsAt,
  });

  final int used;
  final int limit;
  final int remaining;
  /// Premium benefits (full results, no ads) — not the same as unlimited searches.
  final bool isPro;
  final UsageTier tier;
  final bool trialActive;
  final DateTime? periodEndsAt;

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      used: int.tryParse(json['used']?.toString() ?? '') ?? 0,
      limit: int.tryParse(json['limit']?.toString() ?? '') ?? 50,
      remaining: int.tryParse(json['remaining']?.toString() ?? '') ?? 0,
      isPro: json['isPro'] == true,
      tier: UsageTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => UsageTier.free,
      ),
      trialActive: json['trialActive'] == true,
      periodEndsAt: DateTime.tryParse(json['periodEndsAt']?.toString() ?? ''),
    );
  }
}

enum UsageTier { free, trial, weekly, monthly, yearly }

class UserProfile {
  const UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isPro = false,
    this.isAnonymous = true,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isPro;
  final bool isAnonymous;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid']?.toString() ?? '',
      email: json['email']?.toString(),
      displayName: json['displayName']?.toString(),
      photoUrl: json['photoUrl']?.toString() ?? json['photoURL']?.toString(),
      isPro: json['isPro'] == true,
      isAnonymous: json['isAnonymous'] == true,
    );
  }
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.isPro,
    this.productId,
    this.status,
    this.expiresAt,
    this.willRenew = false,
    this.trialActive = false,
  });

  final bool isPro;
  final String? productId;
  final String? status;
  final DateTime? expiresAt;
  final bool willRenew;
  final bool trialActive;

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      isPro: json['isPro'] == true,
      productId: json['productId']?.toString(),
      status: json['status']?.toString(),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      willRenew: json['willRenew'] == true,
      trialActive: json['trialActive'] == true,
    );
  }
}

class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  final String code;
  final String name;
  final String nativeName;

  static const supported = [
    LanguageOption(code: 'en', name: 'English', nativeName: 'English'),
    LanguageOption(code: 'ur', name: 'Urdu', nativeName: 'اردو'),
    LanguageOption(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
    LanguageOption(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    LanguageOption(code: 'es', name: 'Spanish', nativeName: 'Español'),
    LanguageOption(code: 'fr', name: 'French', nativeName: 'Français'),
    LanguageOption(code: 'de', name: 'German', nativeName: 'Deutsch'),
    LanguageOption(code: 'pt', name: 'Portuguese', nativeName: 'Português'),
    LanguageOption(code: 'tr', name: 'Turkish', nativeName: 'Türkçe'),
    LanguageOption(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia'),
  ];
}

class PendingImage {
  const PendingImage({
    this.localPath,
    this.remoteUrl,
  });

  final String? localPath;
  final String? remoteUrl;

  bool get hasLocal => localPath != null && localPath!.isNotEmpty;
  bool get hasRemote => remoteUrl != null && remoteUrl!.isNotEmpty;
}
