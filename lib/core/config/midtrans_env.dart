import 'package:flutter_dotenv/flutter_dotenv.dart';

class MidtransEnv {
  const MidtransEnv._();

  static String get clientKey => dotenv.env['MIDTRANS_CLIENT_KEY'] ?? '';

  static bool get hasClientKey => clientKey.isNotEmpty;
}
