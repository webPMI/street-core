/// App Configuration Model
///
/// Contains app version, maintenance mode, and update settings.
class AppConfig {
  AppConfig({
    this.minVersionIos,
    this.minVersionAndroid,
    this.currentVersionIos,
    this.currentVersionAndroid,
    this.appStoreUrl,
    this.playStoreUrl,
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.maintenanceEndTime,
    this.forceUpdate = false,
    this.updateMessage,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      minVersionIos: json['minVersionIos'],
      minVersionAndroid: json['minVersionAndroid'],
      currentVersionIos: json['currentVersionIos'],
      currentVersionAndroid: json['currentVersionAndroid'],
      appStoreUrl: json['appStoreUrl'],
      playStoreUrl: json['playStoreUrl'],
      maintenanceMode: json['maintenanceMode'] ?? false,
      maintenanceMessage: json['maintenanceMessage'],
      maintenanceEndTime: json['maintenanceEndTime'],
      forceUpdate: json['forceUpdate'] ?? false,
      updateMessage: json['updateMessage'],
    );
  }

  factory AppConfig.empty() => AppConfig();

  final String? minVersionIos;
  final String? minVersionAndroid;
  final String? currentVersionIos;
  final String? currentVersionAndroid;
  final String? appStoreUrl;
  final String? playStoreUrl;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final String? maintenanceEndTime;
  final bool forceUpdate;
  final String? updateMessage;

  Map<String, dynamic> toJson() => {
        if (minVersionIos != null) 'minVersionIos': minVersionIos,
        if (minVersionAndroid != null) 'minVersionAndroid': minVersionAndroid,
        if (currentVersionIos != null) 'currentVersionIos': currentVersionIos,
        if (currentVersionAndroid != null)
          'currentVersionAndroid': currentVersionAndroid,
        if (appStoreUrl != null) 'appStoreUrl': appStoreUrl,
        if (playStoreUrl != null) 'playStoreUrl': playStoreUrl,
        'maintenanceMode': maintenanceMode,
        if (maintenanceMessage != null) 'maintenanceMessage': maintenanceMessage,
        if (maintenanceEndTime != null) 'maintenanceEndTime': maintenanceEndTime,
        'forceUpdate': forceUpdate,
        if (updateMessage != null) 'updateMessage': updateMessage,
      };
}
