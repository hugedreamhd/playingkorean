import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  // 예제 공개 음원 (역동적인 퀴즈쇼 스타일)
  final String _bgmUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  Future<void> playBgm() async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(UrlSource(_bgmUrl));
      await _bgmPlayer.setVolume(0.4); // BGM은 약간 작게
    } catch (e) {
      print('Audio: error playing BGM: $e');
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      print('Audio: error stopping BGM: $e');
    }
  }

  Future<void> playSuccess() async {
    try {
      // 온라인 정답 효과음 연동
      await _sfxPlayer.play(UrlSource('https://github.com/rafael-puebla/flutter-audio-players-sample/raw/master/assets/success.mp3'));
    } catch (e) {
      debugPrint('Audio: Error playing success sound: $e');
    }
  }

  Future<void> playFailure() async {
    try {
      // 온라인 오답 효과음 연동
      await _sfxPlayer.play(UrlSource('https://github.com/rafael-puebla/flutter-audio-players-sample/raw/master/assets/failure.mp3'));
    } catch (e) {
      debugPrint('Audio: Error playing failure sound: $e');
    }
  }

  Future<void> playTimerTick() async {
    try {
      // 틱(Tick) 소리 로직 (현재는 로그만 남김)
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
