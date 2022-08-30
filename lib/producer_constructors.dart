// Helper functions for providing systems with already passed dependencies.
import 'package:producer_poc/counter_producer/counter_logic_producer.dart';
import 'package:producer_poc/counter_producer/counter_producer.dart';
import 'package:producer_poc/producer/producer.dart';
import 'package:producer_poc/producer/stream_value.dart';


// TODO(mohammad): Can we eliminate this class?
class ProducerConstructors {
  static CounterLogicProducer buildCounterLogicSystem() =>
      CounterLogicProducer();

  static CounterProducer buildCounterSystem(
    CounterLogicProducer counterLogicSystem,
  ) {
    late final _counterLogicSystemStream =
        counterLogicSystem.streamValue.stream.map((event) => event.logic);

    return CounterProducer(CounterProducerInput(
      logic: StreamValue(_counterLogicSystemStream),
    ));
  }
}
