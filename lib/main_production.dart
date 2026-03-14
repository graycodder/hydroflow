import 'package:watermemo/core/app_config.dart';
import 'package:watermemo/main.dart' as app;
import 'package:watermemo/firebase_options.dart';

void main() {
  AppConfig.setConfig(
    AppConfig(
      environment: Environment.production,
      appTitle: 'WaterMemo',
      baseUrl: '', // Add prod API if needed
      firebaseDatabaseUrl:
          'https://hydroflow-1f649-default-rtdb.asia-southeast1.firebasedatabase.app',
      firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    ),
  );
  app.main();
}
