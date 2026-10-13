import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swappia_app/core/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('SupabaseService Singleton instance test', () {
    final instance1 = SupabaseService();
    final instance2 = SupabaseService.instance;
    expect(identical(instance1, instance2), isTrue);
  });

  test('SupabaseService initializes successfully with .env and connects', () async {
    dotenv.loadFromString(
      envString:
          'SUPABASE_URL=https://glzvrdhyqcyeuhpggjkb.supabase.co\nSUPABASE_ANON_KEY=sb_publishable_UKeiGkLM7U7rwJ8OWS3fEQ_Sd22AHrv',
    );

    await SupabaseService.initialize();

    expect(SupabaseService.instance.client, isNotNull);
    expect(SupabaseService.instance.auth, isNotNull);
    expect(SupabaseService.instance.currentUser, isNull);
  });
}
