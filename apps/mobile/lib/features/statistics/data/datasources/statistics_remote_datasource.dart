import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/sleep_statistics.dart';
import '../models/sleep_statistics_model.dart';

abstract class StatisticsRemoteDataSource {
  Future<SleepStatistics> getSleepStatistics(StatisticsRange range);
}

class StatisticsRemoteDataSourceImpl implements StatisticsRemoteDataSource {
  StatisticsRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<SleepStatistics> getSleepStatistics(StatisticsRange range) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.sleepStatistics,
      queryParameters: {'range': range.wireValue},
    );
    return SleepStatisticsModel.fromJson(res.data!, range);
  }
}
