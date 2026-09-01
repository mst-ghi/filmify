import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

/// Opens the app's single sembast database (pure-Dart, file-backed).
///
/// Lives in the application-support directory on all three platforms.
Future<Database> openAppDatabase() async {  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  return databaseFactoryIo.openDatabase(p.join(dir.path, 'filmify.db'));
}

