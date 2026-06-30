import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  Future<void> playBgm() async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.2); // 배경음악 소리가 너무 크지 않도록 설정 (0.2)
      await _bgmPlayer.play(AssetSource('data/music/backgroundmusic_01.mp3'));
    } catch (e) {
      debugPrint('Audio: error playing BGM: $e');
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint('Audio: error stopping BGM: $e');
    }
  }

  Future<void> playSuccess() async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('data/effects/correct.wav'));
    } catch (e) {
      debugPrint('Audio: Error playing success sound: $e');
    }
  }

  Future<void> playFailure() async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('data/effects/incorrect.wav'));
    } catch (e) {
      debugPrint('Audio: Error playing failure sound: $e');
    }
  }

  Future<void> playResult(int score) async {
    try {
      await _sfxPlayer.stop();
      if (score >= 8) {
        await _sfxPlayer.play(AssetSource('data/effects/8_10.wav'));
      } else if (score >= 4) {
        await _sfxPlayer.play(AssetSource('data/effects/4_7.wav'));
      } else {
        await _sfxPlayer.play(AssetSource('data/effects/1_3.wav'));
      }
    } catch (e) {
      debugPrint('Audio: Error playing result sound: $e');
    }
  }

  Future<void> playTimerTick() async {
    try {
      // 초(Tick) 소리 로직 (필요시 활성화)
      debugPrint('Audio: Timer Ticking...');
    } catch (e) {
      debugPrint('Audio: Error playing timer tick: $e');
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
