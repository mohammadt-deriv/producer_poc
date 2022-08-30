import 'dart:async';

import 'package:producer_poc/counter_producer/counter_logic_producer.dart';
import 'package:producer_poc/producer/producer.dart';
import 'package:producer_poc/producer/stream_value.dart';

class CounterProducerInput extends ProducerIO {
  StreamValue<CounterLogic> logic;

  CounterProducerInput({
    required this.logic,
  });
}

class CounterProducerOutput extends ProducerIO {
  int result;

  CounterProducerOutput({
    required this.result,
  });
}

class CounterProducer
    extends Producer<CounterProducerInput, CounterProducerOutput> {
  CounterProducer(CounterProducerInput dependency)
      : super(
          dependency,
          initialValue: CounterProducerOutput(result: 0),
        );

  //TODO(mohammad): produce function should provide the non-stream value of inputs as we're sure we have all of them here + we can capture all inputs an be sure they will nnot change untill end of the function.
  // what if we only pass StreamValue<InputModel> to producer? this will solve the above issue. other non-stream dependecies can be manually added to constrcutor.
  @override
  Future<CounterProducerOutput> produce(
    CounterProducerInput input,
    CounterProducerOutput? currentState,
  ) async {
    // await Future.delayed(const Duration(milliseconds: 1000));

    final int currentResult = currentState?.result ?? 0;
    final int Function(int) logic = await input.logic.value;

    final int newResult = logic(currentResult);

    if (newResult > 10) {
      throw Exception('Value is more than 10');
    }

    return CounterProducerOutput(result: newResult);
  }

  @override
  List<StreamValue<Object>> getStreamDependencies() => [dependency.logic];
}
