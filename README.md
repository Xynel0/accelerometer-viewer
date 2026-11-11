# accelerometer-viewer

Aplicativo simples em Flutter que mostra, em tempo real, os valores do acelerômetro do aparelho (eixos x, y e z). Foi criado como exemplo para uma apresentação.

O objetivo é demonstrar como um plugin resolve o problema de ler sensores em um cenário cross-platform: o código do app é escrito uma vez, em Dart, e o plugin cuida da comunicação com o código nativo de cada sistema.

## O problema

Cada sistema operacional expõe seus sensores por uma API própria e em uma linguagem própria:

| Sistema | API de sensores | Linguagem nativa |
|---------|-----------------|------------------|
| Android | `SensorManager` | Kotlin / Java |
| iOS | Core Motion (`CMMotionManager`) | Swift / Objective-C |

O Dart não chama diretamente essas APIs nativas. Para manter um único código, o Flutter oferece os platform channels, mecanismo que troca mensagens entre o código Dart e o código da plataforma. Plugins empacotam esse mecanismo e o código nativo, e expõem ao desenvolvedor uma API única em Dart.

## Como o app resolve

O app usa o plugin [`sensors_plus`](https://pub.dev/packages/sensors_plus) (versão 7.1.1). O fluxo é:

1. O app chama `accelerometerEventStream()` e recebe um `Stream` de leituras.
2. O plugin, por meio de platform channels, aciona o código nativo da plataforma em que o app está rodando.
3. O código nativo lê o sensor e devolve os valores.
4. A cada leitura, o app atualiza a tela com `setState`.
5. Ao fechar a tela, o app cancela a inscrição no stream em `dispose()`.

Pontos de implementação:

- `StatefulWidget`, porque o conteúdo da tela muda a cada leitura.
- `listen()` com `onError` e `cancelOnError`, para tratar aparelhos sem o sensor.
- `StreamSubscription.cancel()` no `dispose()`, para não manter o sensor em uso depois que a tela é fechada.
- `samplingPeriod: SensorInterval.normalInterval`. No Android, a documentação do plugin informa que a taxa de amostragem não é garantida.

O código principal está em `lib/main.dart`.

## O que o app mostra

Os valores são do acelerômetro bruto, em m/s², e incluem o efeito da gravidade. Com o aparelho parado, a gravidade (cerca de 9,8 m/s²) aparece no eixo que aponta para baixo.

Pequenos desvios em x e y são normais e podem vir de inclinação do aparelho e de imprecisão do sensor. O sinal dos valores pode variar conforme a posição.
