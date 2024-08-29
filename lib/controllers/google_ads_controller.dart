// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// class GoogleAdsController extends GetxController {
//   final RxBool isAdLoaded = false.obs;
//   late BannerAd bannerAd;

//   @override
//   void onInit() {
//     super.onInit();
//     loadBannerAd();
//   }

//   void loadBannerAd() {
//     bannerAd = BannerAd(
//       adUnitId: 'YOUR_AD_UNIT_ID_HERE', // Replace with your actual ad unit ID
//       size: AdSize.banner,
//       request: const AdRequest(),
//       listener: BannerAdListener(
//         onAdLoaded: (ad) {
//           isAdLoaded.value = true;
//         },
//         onAdFailedToLoad: (ad, error) {
//           ad.dispose();
//           print('Ad failed to load: $error');
//         },
//       ),
//     );

//     bannerAd.load();
//   }

//   Widget getBannerAd() {
//     return SizedBox(
//       height: 50,
//       child: AdWidget(ad: bannerAd),
//     );
//   }

//   @override
//   void onClose() {
//     bannerAd.dispose();
//     super.onClose();
//   }
// }
