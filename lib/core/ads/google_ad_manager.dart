import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoogleAdManager {
  static final GoogleAdManager _instance = GoogleAdManager._internal();
  factory GoogleAdManager() => _instance;
  GoogleAdManager._internal();

  // 구글 AdMob 공식 테스트 보상형 광고 ID
  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// 보상형 광고 로드 및 노출 시도
  /// [onUserEarnedReward]는 보상 획득 시 콜백 함수입니다.
  /// 광고 재생 완료 및 보상 획득 성공 시 true 반환, 실패 시 false 반환.
  Future<bool> showRewardedAd({required VoidCallback onUserEarnedReward}) async {
    // 웹이나 지원하지 않는 플랫폼에서는 즉시 실패 처리하여 Fallback 시뮬레이션 동작하도록 유도
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }

    final completer = Completer<bool>();

    try {
      RewardedAd? loadedAd;
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            loadedAd = ad;
            
            loadedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!completer.isCompleted) {
                  completer.complete(false); // 보상을 받지 않고 닫은 경우
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                if (!completer.isCompleted) {
                  completer.complete(false); // 표시 실패
                }
              },
            );

            // 광고 재생 실행
            loadedAd!.show(
              onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
                onUserEarnedReward();
                if (!completer.isCompleted) {
                  completer.complete(true); // 보상 획득 성공
                }
              },
            );
          },
          onAdFailedToLoad: (error) {
            if (!completer.isCompleted) {
              completer.complete(false); // 광고 로드 실패
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('AdMob Load Error: $e');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }
}
