// dart:async fornece StreamSubscription, o objeto que representa a
// inscrição em um Stream e permite cancelá-la depois.
import 'dart:async';

// Biblioteca de widgets Material do Flutter
import 'package:flutter/material.dart';

// Plugin sensors_plus. Expõe os streams de sensores e as classes de evento
// (AccelerometerEvent, SensorInterval). Por baixo, usa platform channels
// para obter os dados do código nativo de cada sistema operacional.
import 'package:sensors_plus/sensors_plus.dart';

// Ponto de entrada do programa Dart. runApp() define o widget raiz do app.
void main() => runApp(const SensoresApp());

// Widget raiz. É um StatelessWidget: não guarda estado que mude ao longo do
// tempo. Sua função é configurar o aplicativo (título, tema, tela inicial).
class SensoresApp extends StatelessWidget {
    const SensoresApp({super.key});

    // build() descreve a interface deste widget. O Flutter o chama sempre que
    // precisa (re)desenhar o widget.
    @override
    Widget build(BuildContext context) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Sensores Demo',
            // colorSchemeSeed gera uma paleta de cores a partir de uma cor base.
            // useMaterial3 ativa o visual do Material Design 3.
            theme: ThemeData(colorSchemeSeed: Colors.purple, useMaterial3: true),
            // Tela exibida ao abrir o app.
            home: const AcelerometroPage(),
        );
    }
}

// A tela é um StatefulWidget porque o conteúdo muda a cada leitura do
// sensor. Esse tipo de widget separa duas classes: o widget (imutável) e o
// State (guarda os dados mutáveis e o ciclo de vida).
class AcelerometroPage extends StatefulWidget {
    const AcelerometroPage({super.key});

    // Cria o objeto State associado a este widget.
    @override
    State<AcelerometroPage> createState() => _AcelerometroPageState();
}

class _AcelerometroPageState extends State<AcelerometroPage> {
    // Referência à inscrição no stream do acelerômetro. É necessária para
    // poder cancelá-la em dispose(). Pode ser nula antes de initState() rodar,
    // por isso o tipo termina com "?".
    StreamSubscription<AccelerometerEvent>? _assinatura;

    // Última leitura recebida (campos x, y e z, em m/s²). Nula até a primeira
    // leitura chegar.
    AccelerometerEvent? _ultimaLeitura;

    // Mensagem de erro exibida se o stream emitir um erro (por exemplo,
    // aparelho sem acelerômetro). Nula enquanto não houver erro.
    String? _erro;

    // initState() é executado uma vez, quando o State é criado e antes do
    // primeiro build(). É o local adequado para iniciar a inscrição no stream.
    @override
    void initState() {
        super.initState();

        // accelerometerEventStream() retorna um Stream<AccelerometerEvent>, uma
        // sequência de eventos entregues ao longo do tempo. As leituras incluem
        // o efeito da gravidade (valor bruto do sensor, em m/s²).
        //
        // samplingPeriod define o intervalo desejado entre leituras.
        // SensorInterval.normalInterval é o valor padrão do pacote. No Android,
        // a documentação do plugin informa que a taxa especificada não é
        // garantida: é uma solicitação, não uma exigência.
        _assinatura = accelerometerEventStream(
            samplingPeriod: SensorInterval.normalInterval,
        ).listen(
            // Função executada a cada evento recebido do stream.
                    (evento) {
                // mounted indica se este State ainda está ligado à árvore de
                // widgets. Chamar setState() depois que a tela foi removida gera erro.
                if (!mounted) return;

                // setState() altera o dado e agenda uma nova chamada de build(),
                // fazendo a tela exibir o valor atualizado.
                setState(() => _ultimaLeitura = evento);
            },

            // Função executada se o stream emitir um erro. A documentação do
            // plugin recomenda tratá-lo, pois alguns aparelhos não têm todos os
            // sensores.
            onError: (Object erro) {
                if (!mounted) return;
                setState(() => _erro = 'Sensor indisponível neste aparelho.');
            },

            // Cancela a inscrição automaticamente após o primeiro erro, evitando
            // ficar escutando um stream que falhou.
            cancelOnError: true,
        );
    }

    // dispose() é executado quando o State é descartado (a tela é fechada).
    @override
    void dispose() {
        // cancel() encerra a inscrição. Sem isso, o listener continuaria ativo
        // após a saída da tela, mantendo o sensor em uso e consumindo bateria.
        // O operador ?. só chama cancel() se _assinatura não for nula.
        _assinatura?.cancel();
        super.dispose();
    }

    // build() é chamado na primeira exibição e depois de cada setState().
    // Ele escolhe o que mostrar conforme o estado atual dos dados.
    @override
    Widget build(BuildContext context) {
        // Copia o campo para uma variável local. Isso permite ao compilador
        // garantir que o valor não é nulo dentro do ramo em que é usado.
        final leitura = _ultimaLeitura;

        return Scaffold(
            // Barra superior com o título da tela.
            appBar: AppBar(title: const Text('Acelerômetro')),
            body: Center(
                // Três estados possíveis da tela:
                // 1) erro; 2) ainda sem leitura; 3) leitura disponível.
                child: _erro != null
                        ? Text(_erro!)
                        : leitura == null
                        ? const Text('Aguardando leituras...')
                        : Column(
                    // Faz a coluna ocupar só o espaço necessário na vertical.
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        _linha('x', leitura.x),
                        _linha('y', leitura.y),
                        _linha('z', leitura.z),
                        const SizedBox(height: 16),
                        const Text('Unidade: m/s² (inclui gravidade)'),
                    ],
                ),
            ),
        );
    }

    // metodo auxiliar que monta uma linha de texto "eixo = valor".
    // Evita repetir o mesmo código para x, y e z.
    Widget _linha(String eixo, double valor) {
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
                // toStringAsFixed(2) arredonda para 2 casas decimais na exibição.
                // O valor original não é alterado.
                '$eixo = ${valor.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium,
            ),
        );
    }
}