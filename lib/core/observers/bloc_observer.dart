import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/logger.dart';

/// Observer برای مانیتورینگ تمام BLoC‌ها در برنامه
/// این کلاس تمام event‌ها، state‌ها، و error‌های BLoC را لاگ می‌کند
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    AppLogger.debug('BLoC Created: ${bloc.runtimeType}', 'BLoC');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    AppLogger.info(
      '${bloc.runtimeType} ← Event: ${event.runtimeType}',
      'BLoC',
    );
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    AppLogger.info(
      '${bloc.runtimeType} → State: ${change.currentState.runtimeType} → ${change.nextState.runtimeType}',
      'BLoC',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    // این اطلاعات بیشتری می‌دهد اما می‌تواند پر حرف باشد
    // فقط در debug mode فعال می‌شود
    if (AppLogger.currentLevel == LogLevel.debug) {
      AppLogger.debug(
        '${bloc.runtimeType}: ${transition.event.runtimeType} → ${transition.currentState.runtimeType} → ${transition.nextState.runtimeType}',
        'BLoC',
      );
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    AppLogger.error(
      '${bloc.runtimeType} Error',
      'BLoC',
      error,
      stackTrace,
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    AppLogger.debug('BLoC Closed: ${bloc.runtimeType}', 'BLoC');
  }
}
