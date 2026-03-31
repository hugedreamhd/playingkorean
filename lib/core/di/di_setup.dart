import 'package:get_it/get_it.dart';
import 'package:playingkorean/core/audio/audio_manager.dart';
import 'package:playingkorean/data/quiz/local_quiz_repository_impl.dart';
// import 'package:playingkorean/data/quiz/mock_quiz_repository_impl.dart';
import 'package:playingkorean/domain/quiz/get_quiz_use_case.dart';
import 'package:playingkorean/domain/quiz/quiz_repository.dart';
import 'package:playingkorean/presentation/quiz_game/game_view_model.dart';

final getIt = GetIt.instance;

void setupDI() {
  // Audio
  getIt.registerSingleton<AudioManager>(AudioManager());

  // Repository
  getIt.registerSingleton<QuizRepository>(LocalQuizRepositoryImpl());
  // getIt.registerSingleton<QuizRepository>(MockQuizRepositoryImpl());

  // UseCase
  getIt.registerSingleton<GetQuizUseCase>(
    GetQuizUseCase(getIt<QuizRepository>()),
  );

  // ViewModel
  getIt.registerFactory<GameViewModel>(
    () => GameViewModel(getIt<GetQuizUseCase>(), getIt<AudioManager>()),
  );
}
