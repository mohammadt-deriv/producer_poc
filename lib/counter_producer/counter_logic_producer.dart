import 'package:producer_poc/producer/producer.dart';

typedef CounterLogic = int Function(int);

class CounterLogicProducerOutput extends ProducerIO {
  CounterLogic logic;

  CounterLogicProducerOutput({
    required this.logic,
  });
}

class CounterLogicProducer
    extends IndependentProducer<CounterLogicProducerOutput> {}
