import 'dart:async';
import 'package:flutter/material.dart';

class AdSimulationDialog extends StatefulWidget {
  final String title;

  const AdSimulationDialog({
    super.key,
    this.title = '조력자(암행어사)의 도움을 요청하는 중...',
  });

  @override
  State<AdSimulationDialog> createState() => _AdSimulationDialogState();
}

class _AdSimulationDialogState extends State<AdSimulationDialog> {
  double _progress = 0.0;
  int _secondsLeft = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    const duration = Duration(milliseconds: 100);
    const totalTicks = 30; // 3초 (3000ms / 100ms)
    int currentTick = 0;

    _timer = Timer.periodic(duration, (timer) {
      currentTick++;
      setState(() {
        _progress = currentTick / totalTicks;
        _secondsLeft = 3 - (currentTick / 10).floor();
      });

      if (currentTick >= totalTicks) {
        _timer?.cancel();
        Navigator.of(context).pop(true); // 광고 성공 완료 반환
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.95), // 딥 네이비 유리
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF5ED8D4).withOpacity(0.3), // 밝은 민트 하이라이트
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5ED8D4).withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 엽전 모양이나 마패 형상처럼 둥근 진행 표시
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5ED8D4)),
                  ),
                ),
                Text(
                  '${_secondsLeft.clamp(1, 3)}초',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '조력자의 지혜를 얻기 위해 잠시 대기합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _timer?.cancel();
                Navigator.of(context).pop(false); // 취소
              },
              child: Text(
                '도움 요청 취소',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
