import 'package:watermemo/core/app_config.dart';
import 'package:watermemo/main.dart' as app;
import 'package:watermemo/firebase_options_staging.dart' as stg;

void main() {
  AppConfig.setConfig(
    AppConfig(
      environment: Environment.staging,
      appTitle: 'WaterMemo STG',
      baseUrl: '', // Add staging API if needed
      firebaseDatabaseUrl:
          'https://hydroflow-stg-app-default-rtdb.asia-southeast1.firebasedatabase.app',
      firebaseOptions: stg.DefaultFirebaseOptions.currentPlatform,
    ),
  );
  app.main();
}
