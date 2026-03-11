import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/signal.dart';

class SignalState {
  final Map<String, Signal> signals;

  const SignalState({this.signals = const {}});

  SignalState copyWith({Map<String, Signal>? signals}) =>
      SignalState(signals: signals ?? this.signals);

  Signal? getSignal(String symbol) => signals[symbol];
}

class SignalNotifier extends StateNotifier<SignalState> {
  SignalNotifier() : super(const SignalState());

  void updateSignal(Signal signal) {
    final updated = Map<String, Signal>.from(state.signals);
    updated[signal.symbol] = signal;
    state = state.copyWith(signals: updated);
  }

  void updateFromJson(Map<String, dynamic> json) {
    try {
      final signal = Signal.fromJson(json);
      updateSignal(signal);
    } catch (_) {}
  }

  void clearSignals() {
    state = const SignalState();
  }
}
