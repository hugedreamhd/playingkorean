import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  // 예제 공개 음원 (역동적인 퀴즈쇼 스타일)
  final String _bgmUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  Future<void> playBgm() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(UrlSource(_bgmUrl));
    await _bgmPlayer.setVolume(0.4); // BGM은 약간 작게
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  Future<void> playSuccess() async {
    await _sfxPlayer.play(AssetSource('sounds/success.mp3'));
    print('Audio: Playing Success Sound');
  }

  Future<void> playFailure() async {
    await _sfxPlayer.play(AssetSource('sounds/failure.mp3'));
    print('Audio: Playing Failure Sound');
  }

  Future<void> playTimerTick() async {
    // 틱 소리는 짧게
    print('Audio: Playing Timer Tick');
  }

  void dispose() {
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
