# Producer

## What is a producer?

Producer is an independent reacticve class which can accept multiple streams as input and produce new output whenever any of input stream gets new value.
Each producer overrides its `produce` pure function to define how the output would be produced.
Producers know nothing about eachother, but they will connect to eachother by whoever instantiating them.

## How to use?
1. Before anything, think about the output you want to produce, what's the type of it. as an example, we want a counter which produce a single `int` at any possible time. but its not like other counters which only adds to previous value. it can also multiply the value!
2. Then think about the required dependencies/inputs in order to produce that output. in our example, we can't say we need a single int, cause that wouldn't be enough for applying multiplication. instead we need a function which takes our value and do whatever it wants with it, then returning it!
``` dart
typedef CounterLogic = int Function(int);
```
3. Make sure there is a chance that your defined inputs would change in the life cycle of your app, cause otherwise all you need is a simple cubit, not a producer.
4. Create a model for your inputs, call it `FooProducerInput` and extend it from `ProducerIO`. don't forget that the changing dependecies should be type of `StreamValue<T>` (Its same as stream but also holds latest value):

```dart
class CounterProducerInput extends ProducerIO {
  StreamValue<CounterLogic> logic;

  CounterProducerInput({
    required this.logic,
  });
}

```

4. Create a `FooProducer` class and extend it from `Producer`. In our example we also need to pass initial output(state).
```dart
class CounterProducer
    extends Producer<CounterProducerInput, CounterProducerOutput> {
  CounterProducer(CounterProducerInput dependency)
      : super(
          dependency,
          initialOutput: CounterProducerOutput(result: 0),
        );
}
```
5. Override required `getStreamDependencies` function and pass all fields in `FooProducerInput` which was type of `StreamValue`.
```dart
  @override
  List<StreamValue<Object>> getStreamDependencies() => [dependency.logic];
}
```

6. This is the main step. Override `produce` function and define how the output would be produced based on `inputs` and `latest output`:
```dart
@override
  Future<CounterProducerOutput> produce(
    CounterProducerInput input,
    CounterProducerOutput? latestOutput,
  ) async {
    final int currentResult = currentState?.result ?? 0;
    final int Function(int) logic = await input.logic.value;

    final int newResult = logic(currentResult);

    if (newResult > 10) {
      throw Exception('Value is more than 10');
    }

    return CounterProducerOutput(result: newResult);
  }
```


7. Who can provide me the input?

In this example our input is a logic which comes from user at anygiven time and it can change, so we need to produce that as well!
we need another producer for producing the logic, but should we do all of these steps again? i say it depends. if we need some (changing)dependency in order to produce logic, then yes, but in this case, there is none. so our `CounterLogicProducer` has no changing input. we have anther type of producers called `IndependentProducer` which accepts no input, so lets extend out new producer from this abstract class.
luckily this class has nothing to override, so all you have to do is to create its class and its output model.
since they are independent from any input, we need to produce them manually. thats why we also have a public function called `produceManually(Output)` in any subclass of `IndependentProducer`. so in our example, we can call this function and produce logics from anywhere.

```dart
class CounterLogicProducerOutput extends ProducerIO {
  CounterLogic logic;

  CounterLogicProducerOutput({
    required this.logic,
  });
}

// Empty class
class CounterLogicProducer
    extends IndependentProducer<CounterLogicProducerOutput> {}

```

8. How to connect producers? we can do that by a pure function which can be used anywhere in the app:

```dart
  CounterProducer buildCounterSystem(
    CounterLogicProducer counterLogicSystem,
  ) {
    late final _counterLogicSystemStream =
        counterLogicSystem.streamValue.stream.map((event) => event.logic);

    return CounterProducer(CounterProducerInput(
      logic: StreamValue(_counterLogicSystemStream),
    ));
  }
```


9. Now we should provide these producers to our widget tree. since producers are also cubits, we can provide them using `MultiBlocProvider`:

```dart
class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);
  late final CounterLogicProducer _counterLogicSystem =
      ProducerConstructors.buildCounterLogicSystem();

  late final CounterProducer _counterSystem =
      ProducerConstructors.buildCounterSystem(_counterLogicSystem);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CounterProducer>.value(value: _counterSystem),
        BlocProvider<CounterLogicProducer>.value(value: _counterLogicSystem)
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(
          title: 'Flutter Demo Home Page',
        ),
      ),
    );
  }
}

```

10. It's finaly the time to use them!

```dart

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            SizedBox(
              height: 35,
              child: ProducerBuilder<CounterProducer, CounterProducerOutput>(
                producer: context.read<CounterProducer>(),
                loadingBuilder: (
                  BuildContext context,
                  CounterProducerOutput? previousData,
                ) =>
                    const CircularProgressIndicator(),
                successBuilder: (
                  BuildContext context,
                  CounterProducerOutput data,
                ) =>
                    Text(
                  data.result.toString(),
                  style: Theme.of(context).textTheme.headline4,
                ),
                errorBuilder: (
                  BuildContext context,
                  String error,
                  CounterProducerOutput? previousData,
                ) =>
                    Text(error.toString()),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            FloatingActionButton(
              onPressed: () =>
                  context.read<CounterLogicProducer>().produceManually(
                        CounterLogicProducerOutput(logic: _incrementByOneLogic),
                      ),
              tooltip: 'Increment by 1',
              child: const Icon(Icons.add),
            ),
            FloatingActionButton(
              onPressed: () =>
                  context.read<CounterLogicProducer>().produceManually(
                        CounterLogicProducerOutput(logic: _multiplyByTwoLogic),
                      ),
              tooltip: 'Multiply by 2',
              child: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  int _incrementByOneLogic(int input) => input + 1;
  int _multiplyByTwoLogic(int input) => input * 2;
}

```

