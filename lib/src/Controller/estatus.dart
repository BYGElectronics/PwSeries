import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Controller encargado de preguntar periódicamente
/// y de parsear todos los estados del módulo, imprimiéndolos
/// en consola.
class EstadoSistemaController extends ChangeNotifier {
  Timer? _pollingTimer;

  // --- Funciones / estados (códigos 1–17) ---
  bool sirenaT04 = false;
  bool auxT04 = false;
  bool hornT04 = false;
  bool wailT04 = false;
  bool pttT04 = false;
  bool interT04 = false;
  bool sirenaApp = false;
  bool auxApp = false;
  bool hornApp = false;
  bool wailApp = false;
  bool pttApp = false;
  bool interApp = false;
  bool luzActiva = false;
  bool noFuncionesActivas = false;

  // --- Batería (códigos 14–16) ---
  int batteryPercent = 0;
  bool carroEncendido = false;
  bool bateriaMedia = false;
  bool bateriaBaja = false;

  /// Llama a este método justo después de conectar al módulo
  /// Arranca el sondeo periódico con el intervalo que tú quieras.
  void startPolling([Duration interval = const Duration(seconds: 10)]) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) {
      _querySystemState();
    });
  }


  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Envía la trama de “consulta estado del sistema” (código 18)
  void _querySystemState() {
    final cmd = Uint8List.fromList([
      0xAA, // header
      0x18, // código de consulta de estado
      0x00, // longitud payload
      0x00, // CRC placeholder (si lo calculas, cámbialo)
      0xAB, // footer
    ]);
    _sendToModule(cmd);
    debugPrint('[EstadoSistema] <– enviando consulta estado (0x18)');
  }

  /// Sustituye esto por tu lógica de escritura BLE/Serial/Socket
  void _sendToModule(Uint8List bytes) {
    // ej: miCaracteristica.write(bytes);
  }

  /// Conecta esto al listener de tus datos entrantes
  void onDataReceived(Uint8List data) {
    if (data.length < 5) return;
    final ack = data[1];
    if (ack != 0x55) return; // solo aceptamos ACK=0x55

    final functionCode = data[2];
    final battCode     = data[3];

    _parseFunctionCode(functionCode);
    _parseBatteryCode(battCode);
  }

  void _parseFunctionCode(int code) {
    // Reseteamos todos
    sirenaT04 = auxT04 = hornT04 = wailT04 = pttT04 = interT04 = false;
    sirenaApp = auxApp = hornApp = wailApp = pttApp = interApp = false;
    luzActiva = noFuncionesActivas = false;

    switch (code) {
      case  1: sirenaT04          = true; break;
      case  2: auxT04             = true; break;
      case  3: hornT04            = true; break;
      case  4: wailT04            = true; break;
      case  5: pttT04             = true; break;
      case  6: interT04           = true; break;
      case  7: sirenaApp          = true; break;
      case  8: auxApp             = true; break;
      case  9: hornApp            = true; break;
      case 10: wailApp            = true; break;
      case 11: pttApp             = true; break;
      case 12: interApp           = true; break;
      case 13: luzActiva          = true; break;
      case 17: noFuncionesActivas = true; break;
      default:
        debugPrint('[EstadoSistema] Código función desconocido: $code');
    }

    debugPrint('[EstadoSistema] Función (0x${code.toRadixString(16)}) → '
        'T04: {sirena:$sirenaT04,aux:$auxT04,horn:$hornT04,wail:$wailT04,ptt:$pttT04,inter:$interT04}, '
        'App: {sirena:$sirenaApp,aux:$auxApp,horn:$hornApp,wail:$wailApp,ptt:$pttApp,inter:$interApp}, '
        'luz:$luzActiva, none:$noFuncionesActivas'
    );
    notifyListeners();
  }

  void _parseBatteryCode(int code) {
    carroEncendido = bateriaMedia = bateriaBaja = false;

    switch (code) {
      case 14:
        carroEncendido = true;
        batteryPercent = 100;
        break;
      case 15:
        bateriaMedia   = true;
        batteryPercent = 50;
        break;
      case 16:
        bateriaBaja    = true;
        batteryPercent = 15;
        break;
      default:
        debugPrint('[EstadoSistema] Código batería desconocido: $code');
    }

    debugPrint('[EstadoSistema] Batería (0x${code.toRadixString(16)}) → '
        'percent: $batteryPercent%, on:$carroEncendido, mid:$bateriaMedia, low:$bateriaBaja'
    );
    notifyListeners();
  }
}
