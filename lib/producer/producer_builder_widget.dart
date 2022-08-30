import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:producer_poc/producer/producer.dart';

typedef ProducerLoadingBuilder<T> = Widget Function(
    BuildContext context, T? previousState);
typedef ProducerSuccessBuilder<T> = Widget Function(
    BuildContext context, T state);
typedef ProducerErrorBuilder<T> = Widget Function(
    BuildContext context, String error, T? previousState);

class ProducerBuilder<ProducerType extends Producer<ProducerIO, T>,
    T extends ProducerIO> extends StatelessWidget {
  final ProducerType producer;

  final ProducerLoadingBuilder<T> loadingBuilder;
  final ProducerSuccessBuilder<T> successBuilder;
  final ProducerErrorBuilder<T>? errorBuilder;

  const ProducerBuilder({
    Key? key,
    required this.producer,
    required this.loadingBuilder,
    required this.successBuilder,
    required this.errorBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProducerType, ProducerState<T>>(
        builder: (BuildContext context, ProducerState<T> state) {
      switch (state.status) {
        case ProducerStatus.initial:
          return loadingBuilder(context, state.data);
        case ProducerStatus.loading:
          return loadingBuilder(context, state.data);
        case ProducerStatus.success:
          return successBuilder(context, state.data!);
        case ProducerStatus.failure:
          if (errorBuilder != null) {
            return errorBuilder!.call(context, state.error ?? '', state.data);
          }

          // In case of failure(+ not passing `errorBuilder`), show previous data if there is any.
          return state.data != null
              ? successBuilder(context, state.data!)
              : loadingBuilder(context, state.data);
      }
    });
  }
}
