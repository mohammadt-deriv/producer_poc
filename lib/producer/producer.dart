import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:producer_poc/producer/stream_value.dart';

enum ProducerStatus {
  initial,
  loading,
  success,
  failure,
}

class ProducerState<T> with EquatableMixin {
  ProducerState({required this.status, this.data, this.error});

  ProducerStatus status;
  T? data;
  String? error;

  ProducerState<T> copyWith({
    T? data,
    ProducerStatus? status,
    String? error,
  }) =>
      ProducerState<T>(
        status: status ?? this.status,
        data: data ?? this.data,
        error: error ?? this.error,
      );

  @override
  String toString() => '''
    status: $status,
    state: $data,
    error: $error
    ''';

  @override
  List<Object?> get props => <Object?>[data, status, error];
}

abstract class ProducerIO {}

abstract class Producer<Input extends ProducerIO, Output extends ProducerIO>
    extends Cubit<ProducerState<Output>> {
  Producer(this.dependency, {Output? initialValue, Duration? debouncer})
      : super(ProducerState<Output>(
          status: initialValue == null
              ? ProducerStatus.initial
              : ProducerStatus.success,
          data: initialValue,
        )) {
    _init();
  }

  final Input dependency;

  late final StreamValue<Output> _streamValue;
  StreamValue<Output> get streamValue => _streamValue;

  @protected
  void emitSuccess(Output successOutput) {
    // TODO(mohammad): add debouncer here
    emit(state.copyWith(status: ProducerStatus.success, data: successOutput));
  }

  @protected
  void emitLoading() {
    emit(state.copyWith(status: ProducerStatus.loading));
  }

  @protected
  void emitFailure(String error) {
    emit(state.copyWith(status: ProducerStatus.failure, error: error));
  }

  Future<void> _init() async {
    _streamValue = StreamValue<Output>(
      stream
          .where((ProducerState<Output> event) =>
              event.status == ProducerStatus.success)
          .map((ProducerState<Output> event) => event.data!),
    );

    final List<StreamValue<dynamic>> streamDependencies =
        getStreamDependencies();

    if (streamDependencies.isNotEmpty) {
      await Future.wait<dynamic>(
        streamDependencies
            .map((StreamValue<dynamic> dependency) => dependency.value),
      );

      onAllDependenciesResolved();
      await _emitOutput();

      for (final StreamValue<dynamic> streamDependency in streamDependencies) {
        streamDependency.addCallback((dynamic _) => _emitOutput());
      }
    }
  }

  @protected
  List<StreamValue<Object>> getStreamDependencies();

  @protected
  Future<Output> produce(Input input, Output? currentState);

  @protected
  void onAllDependenciesResolved() {}

  Future<void> _emitOutput() async {
    // TODO(mohammad): add locker for streamValues? can we modify streamValue?
    emitLoading();

    try {
      final Output output = await produce(dependency, state.data);

      emitSuccess(output);
    } on Exception catch (e) {
      emitFailure(e.toString());
    }
  }

  @override
  Future<void> close() {
    for (final StreamValue<Object> dependency in getStreamDependencies()) {
      dependency.dispose();
    }

    return super.close();
  }
}

class EmptyInput extends ProducerIO {}

abstract class IndependentProducer<Output extends ProducerIO>
    extends Producer<EmptyInput, Output> {
  IndependentProducer() : super(EmptyInput());

  @override
  List<StreamValue<Object>> getStreamDependencies() => [];

  // This function will never get called as we have no input.
  @override
  Future<Output> produce(EmptyInput input, Output? currentState) {
    // ignore: null_argument_to_non_null_type
    return Future.value();
  }

  void produceManually(Output output) async => emitSuccess(output);
}
