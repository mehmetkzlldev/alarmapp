/// Centralised, typed API path builders.
///
/// Base path is `/api/v1` (configured as the Dio `baseUrl`, so paths here are
/// RELATIVE to that). Keeping every path in one place avoids string drift
/// against the API contract.
library;

class ApiEndpoints {
  ApiEndpoints._();

  // ---- Missions ----------------------------------------------------------
  static const String missionTypes = '/missions/types';
  static const String mathGenerate = '/missions/math/generate';
  static const String mathVerify = '/missions/math/verify';
  static const String missionHistory = '/missions/history';

  static String alarmMissions(String alarmId) => '/alarms/$alarmId/missions';
  static String alarmMission(String alarmId, String missionId) =>
      '/alarms/$alarmId/missions/$missionId';

  // ---- Object detection ---------------------------------------------------
  static const String objectDetectionUploadUrl =
      '/object-detection/upload-url';
  static const String objectDetectionVerify = '/object-detection/verify';
  static const String objectDetectionVerifyImage =
      '/object-detection/verify-image';

  // ---- AI missions (premium) ---------------------------------------------
  static const String aiMissionToday = '/ai-missions/today';
  static const String aiMissionCustom = '/ai-missions/custom';
  static String aiMissionComplete(String id) => '/ai-missions/$id/complete';

  // ---- Statistics (premium) ----------------------------------------------
  static const String sleepStatistics = '/sleep/statistics';

  // ---- Users / settings ---------------------------------------------------
  static const String usersMe = '/users/me';

  // ---- Subscriptions ------------------------------------------------------
  static const String subscriptionMe = '/subscriptions/me';
  static const String subscriptionPlans = '/subscriptions/plans';

  // ---- Auth ---------------------------------------------------------------
  static const String authLogout = '/auth/logout';
}
