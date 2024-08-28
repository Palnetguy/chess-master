import 'package:share_plus/share_plus.dart';

class ShareService {
  static void shareApp() {
    Share.share(
      'Check out this awesome Chess app! https://tak-kinship-devs.vercel.app/',
      subject: 'Chess Master App',
    );
  }
}
