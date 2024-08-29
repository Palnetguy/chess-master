import 'package:get/get.dart';
import 'package:startapp_sdk/startapp.dart';

class StartAppAdsController extends GetxController {
  var startAppSdk = StartAppSdk();
  Rxn<StartAppBannerAd> bannerAd = Rxn<StartAppBannerAd>();
  Rxn<StartAppInterstitialAd> interstitialAd = Rxn<StartAppInterstitialAd>();
  Rxn<StartAppRewardedVideoAd> rewardedVideoAd = Rxn<StartAppRewardedVideoAd>();

  @override
  void onInit() {
    super.onInit();
    initAds();
  }

  void initAds() {
    startAppSdk.setTestAdsEnabled(true);
    loadBannerAd();
    loadInterstitialAd();
    loadRewardedVideoAd();
  }

  void loadBannerAd() {
    startAppSdk
        .loadBannerAd(StartAppBannerType.BANNER,
            prefs: const StartAppAdPreferences(adTag: 'game_screen'))
        .then((ad) {
      bannerAd.value = ad;
      print("Successfully Loaded Banner AD");
    }).onError((error, stackTrace) {
      print("Error loading Banner ad: $error");
    });
  }

  void loadInterstitialAd() {
    startAppSdk
        .loadInterstitialAd(
            prefs: const StartAppAdPreferences(adTag: 'game_over'))
        .then((ad) {
      interstitialAd.value = ad;
      print("Successfully Loaded iNTERSTITIAL AD");
    }).onError((error, stackTrace) {
      print("Error loading Interstitial ad: $error");
    });
  }

  void loadRewardedVideoAd() {
    startAppSdk
        .loadRewardedVideoAd(
      prefs: const StartAppAdPreferences(adTag: 'reward'),
      onAdNotDisplayed: () {
        print('onAdNotDisplayed: rewarded video');
        rewardedVideoAd.value?.dispose();
        rewardedVideoAd.value = null;
      },
      onAdHidden: () {
        print('onAdHidden: rewarded video');
        rewardedVideoAd.value?.dispose();
        rewardedVideoAd.value = null;
      },
      onVideoCompleted: () {
        print('onVideoCompleted: rewarded video completed, user gain a reward');
        // TODO: Implement reward logic
      },
    )
        .then((ad) {
      rewardedVideoAd.value = ad;
    }).onError((error, stackTrace) {
      print("Error loading Rewarded Video ad: $error");
    });
  }

  void showInterstitialAd() {
    if (interstitialAd.value != null) {
      interstitialAd.value!.show().then((shown) {
        if (shown) {
          interstitialAd.value = null;
          loadInterstitialAd();
        }
      }).onError((error, stackTrace) {
        print("Error showing Interstitial ad: $error");
      });
    }
  }

  void showRewardedVideoAd() {
    if (rewardedVideoAd.value != null) {
      rewardedVideoAd.value!.show().onError((error, stackTrace) {
        print("Error showing Rewarded Video ad: $error");
        return false;
      });
    }
  }
}
