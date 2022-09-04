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

abstract class ProducerWith1Stream<A, Output> extends Producer<Output> {
  ProducerWith1Stream(this.stream1,
      {Output? initialOutput, Duration? debouncer})
      : super(
          [stream1],
          initialOutput: initialOutput,
          debouncer: debouncer,
        );

  final StreamValue<A> stream1;

  Future<Output> produce(
    A firstStreamValue,
    Output? latestProduced,
  );

  @override
  Future<Output> mainProduce(
    List<dynamic> inputs,
    Output? latestOutput,
    int changedStreamIndex,
  ) =>
      produce(
        inputs[0] as A,
        latestOutput,
      );
}

abstract class ProducerWith2Stream<A, B, Output> extends Producer<Output> {
  ProducerWith2Stream(this.stream1, this.stream2,
      {Output? initialOutput, Duration? debouncer})
      : super([stream1, stream2],
            initialOutput: initialOutput, debouncer: debouncer);

  final Map<int, Type> _indexTypeMap = {0: A, 1: B};

  final StreamValue<A> stream1;
  final StreamValue<B> stream2;

  Future<Output> produce(
    A firstStreamValue,
    B secondStreamValue,
    Output? latestProduced,
    Type changedStream,
  );

  @override
  Future<Output> mainProduce(
    List<dynamic> inputs,
    Output? latestOutput,
    int changedStreamIndex,
  ) =>
      produce(
        inputs[0] as A,
        inputs[1] as B,
        latestOutput,
        _indexTypeMap[changedStreamIndex]!,
      );
}

abstract class Producer<Output> extends Cubit<ProducerState<Output>> {
  Producer(this._streams, {Output? initialOutput, Duration? debouncer})
      : super(ProducerState<Output>(
          status: initialOutput == null
              ? ProducerStatus.initial
              : ProducerStatus.success,
          data: initialOutput,
        )) {
    _init();
  }

  final List<StreamValue<dynamic>> _streams;

  Stream<Output> get outputStream => stream
      .where((ProducerState<Output> event) =>
          event.status == ProducerStatus.success)
      .map((ProducerState<Output> event) => event.data!);

  Future<void> _init() async {
    if (_streams.isNotEmpty) {
      late int latestChangedStreamIndex;

      for (var i = 0; i < _streams.length; i++) {
        final StreamValue<dynamic> streamDependency = _streams[i];
        streamDependency
            .addCallback((dynamic _) => latestChangedStreamIndex = i);
      }

      await Future.wait<dynamic>(
        _streams.map((StreamValue<dynamic> stream) => stream.value),
      );

      onAllDependenciesResolved();
      await _emitOutput(changedStreamIndex: latestChangedStreamIndex);

      for (var i = 0; i < _streams.length; i++) {
        final StreamValue<dynamic> streamDependency = _streams[i];

        streamDependency.clearCallbacks();
        streamDependency
            .addCallback((dynamic _) => _emitOutput(changedStreamIndex: i));
      }
    }
  }

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

  @protected
  Future<Output> mainProduce(
      List<dynamic> inputs, Output? latestOutput, int changedStreamIndex);

  @protected
  void onAllDependenciesResolved() {}

  Future<void> _emitOutput({required int changedStreamIndex}) async {
    emitLoading();

    final inputs = await Future.wait(_streams.map((e) => e.value));

    try {
      final Output output =
          await mainProduce(inputs, state.data, changedStreamIndex);

      emitSuccess(output);
    } on Exception catch (e) {
      emitFailure(e.toString());
    }
  }

  @override
  Future<void> close() {
    for (final StreamValue<dynamic> dependency in _streams) {
      dependency.dispose();
    }

    return super.close();
  }
}

class EmptyInput extends ProducerIO {}

abstract class IndependentProducer<Output extends ProducerIO>
    extends Producer<Output> {
  IndependentProducer() : super([]);

  // This function will never get called, so
  @override
  Future<Output> mainProduce(
      List inputs, Output? latestOutput, int changedStreamIndex) async {
    return latestOutput!;
  }

  void produceManually(Output output) async => emitSuccess(output);
}
