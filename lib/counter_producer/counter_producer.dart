import 'dart:async';

import 'package:producer_poc/counter_producer/counter_logic_producer.dart';
import 'package:producer_poc/producer/producer.dart';
import 'package:producer_poc/producer/stream_value.dart';

class CounterProducerOutput extends ProducerIO {
  int result;

  CounterProducerOutput({
    required this.result,
  });
}

class CounterProducer
    extends ProducerWith1Stream<CounterLogic, CounterProducerOutput> {
  CounterProducer(StreamValue<CounterLogic> counterLogicStream)
      : super(
          counterLogicStream,
          initialOutput: CounterProducerOutput(result: 0),
        );

  @override
  Future<CounterProducerOutput> produce(
    CounterLogic firstStreamValue,
    CounterProducerOutput? latestProduced,
  ) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final int currentResult = latestProduced?.result ?? 0;

    final int newResult = firstStreamValue(currentResult);

    if (newResult > 10) {
      throw Exception('Value is more than 10');
    }

    return CounterProducerOutput(result: newResult);
  }
}
