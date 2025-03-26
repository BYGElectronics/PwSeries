import 'dart:async'; // Proporciona herramientas para trabajar con programación asíncrona, como Future y Stream.
import 'package:flutter/material.dart'; // Framework principal de Flutter para construir interfaces de usuario.
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as Ble;
import 'package:permission_handler/permission_handler.dart'; // Maneja permisos en tiempo de ejecución para acceder a hardware y funciones del dispositivo.
import 'package:flutter_sound/flutter_sound.dart'; // Biblioteca para grabación y reproducción de audio.
import 'dart:typed_data'; // Proporciona listas de bytes eficientes para manipulación de datos binarios.
import 'package:path_provider/path_provider.dart'; // Permite acceder a directorios específicos del sistema de archivos, como caché y documentos.
import 'dart:io'; // Proporciona herramientas para manipulación de archivos y operaciones en el sistema de archivos.
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Maneja la comunicación con dispositivos Bluetooth Low Energy (BLE).
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as btClassic; // Biblioteca para manejar Bluetooth Classic, utilizado para conexiones seriales.

class ControlController {
  BluetoothDevice?
  connectedDevice; //Dispositivo BLE actualmente conectado. | Se usará para realizar operaciones de comunicación con el hardware.
  btClassic.BluetoothConnection?
  classicConnection; //Conexión Bluetooth Classic. | Se usará para realizar operaciones de comunicación serial.
  BluetoothCharacteristic?
  targetCharacteristic; //Característica BLE de escritura. | Se usa para enviar comandos al dispositivo BLE.
  final FlutterSoundRecorder _recorder =
      FlutterSoundRecorder(); //Grabador de audio para manejar la funcionalidad de PTT (Push-to-Talk). | Permite iniciar y detener la grabación de audio.
  bool isPTTActive =
      false; //Estado del botón PTT. | Indica si el PTT está activado o desactivado.

  ///===CONFIGURAR DISPOSITIVO CONECTADO===
  /*
  * Configura el dispositivo BLE actualmente conectado.
  * Guarda la referencia del dispositivo y luego busca los servicios disponibles.
  *
  * @param device - El dispositivo Bluetooth LE que se conectará.
  */
  void setDevice(BluetoothDevice device) async {
    // Guarda el dispositivo BLE seleccionado
    connectedDevice = device;

    // Descubre los servicios y características del dispositivo conectado
    await _discoverServices();
  } //FIN setDevice

  ///===DESCUBRIR SERVICIOS Y CARACTERÍSTICAS BLE===
  /*
   * Descubre los servicios del dispositivo BLE actualmente conectado.
   * - Primero verifica si hay un dispositivo almacenado en `connectedDevice`.
   * - Obtiene la lista de servicios disponibles en ese dispositivo.
   * - Dentro de cada servicio, analiza las características buscando la que sea de tipo 'write'.
   * - Si la encuentra, la asigna a 'targetCharacteristic' para uso posterior.
   * - Si no se encuentra ninguna característica de escritura, se reporta en el log.
   */
  Future<void> _discoverServices() async {
    // Si no hay un dispositivo conectado, no hace nada.
    if (connectedDevice == null) return;

    // Obtiene la lista de servicios BLE disponibles en el dispositivo.
    List<BluetoothService> services = await connectedDevice!.discoverServices();

    // Recorre cada servicio encontrado.
    for (var service in services) {
      // Dentro de cada servicio, revisa sus características.
      for (var characteristic in service.characteristics) {
        debugPrint("Característica encontrada: ${characteristic.uuid}");

        // Verifica si la característica actual tiene propiedad de escritura.
        if (characteristic.properties.write) {
          targetCharacteristic = characteristic;
          debugPrint(
            "Característica de escritura seleccionada: ${characteristic.uuid}",
          );
          // Retorna inmediatamente luego de encontrar la primera característica de escritura.
          return;
        }
      }
    }

    // Si no se encontró ninguna característica de escritura en todos los servicios, se informa por consola.
    debugPrint(
      "No se encontró característica de escritura en los servicios BLE.",
    );
  } //FIN _discoverServices

  ///===ENVIAR COMANDO / PROTOCOLO AL DISPOSITIVO PW CONECTADO A BLUETOOTH EN FORMARO ASCII===
  /*
   * Envía un comando al dispositivo BLE conectado a través de la característica de escritura.
   *
   * Pasos:
   * 1. Verifica que tanto `targetCharacteristic` (característica con propiedad de escritura)
   *    como `connectedDevice` (el dispositivo BLE conectado) no sean nulos.
   *    - Si alguno es nulo, muestra un mensaje de error y retorna.
   *
   * 2. Convierte la lista de bytes recibida en su representación ASCII en formato hexadecimal:
   *    - Cada byte se pasa a una cadena hex con dos dígitos (ej. 0x0A -> "0A").
   *    - Todos se concatenan en un solo string, y se convierten a mayúsculas.
   *    - Se obtiene así, por ejemplo, "AA14..." etc.
   *
   * 3. Convierte esa cadena ASCII a un arreglo de bytes (`asciiBytes`).
   *
   * 4. Llama a `targetCharacteristic.write` para enviar esos bytes al dispositivo,
   *    usando `withoutResponse: false` para asegurarse de que se procese la confirmación.
   *
   * 5. En caso de éxito, registra en consola que se ha enviado el comando (con la
   *    representación ASCII del mismo). Si ocurre algún error, lo captura y muestra en el log.
   */
  Future<void> sendCommand(List<int> command) async {
    // Si no tenemos una característica de escritura asignada o no hay dispositivo conectado, se avisa y se sale.
    if (targetCharacteristic == null || connectedDevice == null) {
      debugPrint("No hay dispositivo o característica BLE disponible.");
      return;
    }

    // Convertir la lista de bytes en una cadena de texto hexadecimal ASCII.
    String asciiCommand =
        command
            .map((e) => e.toRadixString(16).padLeft(2, '0'))
            .join('')
            .toUpperCase();

    // Convierte la cadena en un arreglo de bytes ASCII.
    List<int> asciiBytes = asciiCommand.codeUnits;

    try {
      // Escribe esos bytes en la característica BLE.
      await targetCharacteristic!.write(asciiBytes, withoutResponse: false);

      // Log de confirmación.
      debugPrint(
        "Comando ASCII enviado a ${connectedDevice!.platformName}: $asciiCommand",
      );
    } catch (e) {
      // Si algo falla en la escritura, se registra el error.
      debugPrint(
        "Error enviando comando ASCII a ${connectedDevice!.platformName}: $e",
      );
    }
  } //FIN sendCommand

  ///===CALCULO DEL CRC MODBUS===
  /*
   * Calcula el CRC (Cyclic Redundancy Check) de tipo ModBus para un arreglo de bytes.
   *
   * Pasos:
   * 1. Se inicia la variable `crc` con el valor 0xFFFF.
   * 2. Para cada byte en la lista `data`:
   *    - Se hace XOR entre `crc` y el byte actual.
   *    - Luego se itera 8 veces:
   *       - Si el bit menos significativo (LSB) de `crc` es 1,
   *         se realiza un desplazamiento a la derecha de `crc` y se hace XOR con 0xA001.
   *       - De lo contrario, simplemente se realiza un desplazamiento a la derecha de `crc`.
   * 3. Una vez procesados todos los bytes, ModBus espera que
   *    el resultado final del CRC se divida en dos bytes (low y high).
   *    Sin embargo, a menudo se envían en orden inverso: primero el low y luego el high.
   * 4. Esta función devuelve el CRC reordenado, tomando el byte bajo como high y el byte alto como low.
   */
  int calculateCRC(List<int> data) {
    int crc = 0xFFFF;
    // Recorre cada byte y actualiza el CRC en base al algoritmo ModBus
    for (var byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        // Si el bit menos significativo de crc es 1, se desplaza y se aplica XOR con 0xA001
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          // De lo contrario, simplemente se desplaza a la derecha.
          crc >>= 1;
        }
      }
    }
    // Se reordenan los bytes del resultado final antes de retornarlo.
    return ((crc & 0xFF) << 8) | ((crc >> 8) & 0xFF);
  } //FIN calculateCRC

  ///===TEST CRC===
  /*
   * Función de prueba para verificar el correcto funcionamiento de `calculateCRC`.
   *
   * Pasos:
   * 1. Se define un arreglo de bytes `testData` con valores `[0xAA, 0x14, 0x07, 0x44]`.
   * 2. Se obtiene el valor de CRC calculado para este arreglo.
   * 3. Se muestra por consola el resultado en formato hexadecimal,
   *    comparándolo con el CRC esperado (`CFC8`) para validar la implementación.
   */
  void testCRC() {
    // Datos de prueba para verificar el CRC.
    List<int> testData = [0xAA, 0x14, 0x07, 0x44];
    // Se calcula el CRC para los datos de prueba.
    int crc = calculateCRC(testData);
    // Se muestra el resultado comparando el CRC esperado con el calculado.
    debugPrint(
      "CRC esperado: CFC8, CRC calculado: ${crc.toRadixString(16).toUpperCase()}",
    );
  } //FIN testCRC

  ///FUNCIONES DE CONTROL CON PROTOCOLOS CORRECTOS
  /*
   * Método para activar la Sirena a través de BLE.
   *
   * Pasos:
   * 1. Se construye un frame específico para la sirena:
   *    [0xAA, 0x14, 0x07, 0x44, 0xCF, 0xC8, 0xFF]
   *    - 0xAA  : Inicio de trama
   *    - 0x14  : Dirección o comando base
   *    - 0x07  : Código del comando "Sirena"
   *    - 0x44  : Dato para activar
   *    - 0xCF, 0xC8 : CRC forzado para este comando
   *    - 0xFF  : Fin de trama
   * 2. Se llama a `sendCommand(frame)` para enviar estos bytes al dispositivo.
   * 3. Se imprime un mensaje de confirmación en la consola.
   */
  void activateSiren() {
    // Enviar el protocolo para activar Sirena
    List<int> frame = [0xAA, 0x14, 0x07, 0x44, 0xCF, 0xC8, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Sirena activada.");
  } //FIN activateSiren

  /*
   * Método para activar la Auxiliar a través de BLE.
   *
   * Pasos:
   * 1. Se construye un frame específico para el auxiliar:
   *    [0xAA, 0x14, 0x08, 0x44, 0xCC, 0xF8, 0xFF]
   *    - 0xAA  : Inicio de trama
   *    - 0x14  : Dirección o comando base
   *    - 0x08  : Código del comando "Auxiliar"
   *    - 0x44  : Dato para activar
   *    - 0xCC, 0xF8 : CRC forzado para este comando
   *    - 0xFF  : Fin de trama
   * 2. Se llama a `sendCommand(frame)` para enviar estos bytes al dispositivo.
   * 3. Se imprime un mensaje de confirmación en la consola.
   */
  void activateAux() {
    // Enviar el protocolo para activar Auxiliar
    List<int> frame = [0xAA, 0x14, 0x08, 0x44, 0xCC, 0xF8, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Auxiliar activado.");
  } //FIN activateAux

  /*
   * Método para activar el Intercomunicador a través de BLE.
   *
   * Pasos:
   * 1. Se construye el frame específico para el intercom:
   *    [0xAA, 0x14, 0x12, 0x44, 0x32, 0xD9, 0xFF]
   *    - 0xAA  : Inicio de trama
   *    - 0x14  : Dirección o comando base
   *    - 0x12  : Código del comando "Intercom"
   *    - 0x44  : Dato para activar
   *    - 0x32, 0xD9 : CRC forzado para este comando
   *    - 0xFF  : Fin de trama
   * 2. Se llama a `sendCommand(frame)` para enviar estos bytes al dispositivo.
   * 3. Se imprime un mensaje de confirmación en la consola.
   */
  void activateInter() {
    // Enviar el protocolo para activar Intercom
    List<int> frame = [0xAA, 0x14, 0x12, 0x44, 0x32, 0xD9, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Intercom activado.");
  } //FIN activateInter

  /*
   * Método para alternar (encender/restablecer) la bocina (Horn).
   *
   * Pasos:
   * 1. Se envía primero un frame "resetFrame" con valores neutrales:
   *    [0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF]
   *    Esto permite restablecer cualquier estado previo.
   * 2. Luego se construye el frame principal:
   *    [0xAA, 0x14, 0x09, 0x44, 0x0C, 0xA9, 0xFF]
   *    - 0x09  : Código del comando "Horn"
   *    - 0x44  : Indica activación
   *    - 0x0C, 0xA9 : CRC forzado para Horn
   * 3. Ambos frames se envían con `sendCommand(...)`.
   * 4. Se imprime en consola un mensaje que confirma la acción.
   */
  void toggleHorn() {
    // Enviar un comando neutro para restablecer el estado
    List<int> resetFrame = [0xAA, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF];
    sendCommand(resetFrame);

    // Luego enviar el comando deseado
    List<int> frame = [0xAA, 0x14, 0x09, 0x44, 0x0C, 0xA9, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Horn alternado después de reset.");
  } //FIN toggleHorn

  /*
   * Método para alternar (encender) el Wail a través de BLE.
   *
   * Pasos:
   * 1. Se construye el frame específico para Wail:
   *    [0xAA, 0x14, 0x10, 0x44, 0xF2, 0x78, 0xFF]
   *    - 0x10  : Código del comando "Wail"
   *    - 0x44  : Activación
   *    - 0xF2, 0x78 : CRC forzado para Wail
   * 2. Se llama a `sendCommand(frame)` para enviar estos bytes al dispositivo.
   * 3. Se imprime un mensaje de confirmación en la consola.
   */
  void toggleWail() {
    // Enviar el protocolo del Wail
    List<int> frame = [0xAA, 0x14, 0x10, 0x44, 0xF2, 0x78, 0xFF];
    sendCommand(frame);
    debugPrint("✅ Wail alternado.");
  } //FIN toggleWail

  /*
   * Función para alternar el estado del PTT (Push to Talk).
   * - Activa el modo Bluetooth Classic solo mientras se mantiene el PTT activo
   * - Desactiva el micrófono y el Bluetooth Classic al terminar
   * - Reconecta BLE automáticamente al finalizar el uso de PTT
   */
  Future<void> togglePTT() async {
    // Verifica si el PTT está desactivado
    if (!isPTTActive) {
      // 1. Desconecta primero el dispositivo BLE, si existe
      if (connectedDevice != null) {
        await connectedDevice!.disconnect();
        debugPrint('🔴 BLE desconectado temporalmente para usar Classic');
      }

      // 2. Realiza la conexión Bluetooth Classic de manera dinámica usando la dirección MAC

      // 3. Solicita permiso de micrófono para enviar audio por Classic
      if (await _requestMicrophonePermission()) {
        // 3.1 Inicia la grabación (micrófono)
        await _startMicrophone();
      } else {
        debugPrint(
          "❌ Permiso de micrófono denegado, no se puede grabar audio.",
        );
        return;
      }

      // 4. Envía el protocolo o frame correspondiente al comando de PTT en el hardware
      List<int> frame = [0xAA, 0x14, 0x11, 0x44, 0x32, 0x29, 0xFF];
      await sendCommand(frame);

      // 5. Marca el estado del PTT como activo
      isPTTActive = true;
      debugPrint("✅ PTT activado correctamente.");
    } else {
      // Caso contrario: el PTT está activo y se desea desactivar

      // 1. Detener y cerrar el micrófono
      await _stopMicrophone();

      // 2. Desconectar el Bluetooth Classic
      await _deactivateBluetoothClassic();

      // 3. Reconectar Bluetooth BLE, en caso de que haya un dispositivo previamente guardado
      if (connectedDevice != null) {
        await connectedDevice!.connect();
        debugPrint('🔵 BLE reconectado correctamente');
        // Redescubre los servicios BLE para restablecer la característica de escritura
        await _discoverServices();
      }

      // 4. Envía el mismo protocolo PTT para desactivarlo en el hardware
      List<int> frame = [0xAA, 0x14, 0x11, 0x44, 0x32, 0x29, 0XFF];
      await sendCommand(frame);

      // 5. Marca el estado del PTT como inactivo
      isPTTActive = false;
      debugPrint("⛔ PTT desactivado correctamente.");
    }
  } //FIN togglePTT

  ///FUNCIONES PARA FUNCION DE PTT
  /*
   * Solicita el permiso de micrófono al usuario.
   * Devuelve `true` si el permiso fue concedido; de lo contrario, `false`.
   */
  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      debugPrint("🎤 Permiso de micrófono concedido.");
      return true;
    } else {
      debugPrint("❌ Permiso de micrófono denegado.");
      return false;
    }
  } //FIN _requestMicrophonePermission

  /*
   * Inicia la grabación de audio a través del micrófono.
   * - Verifica si no se está grabando ya.
   * - Abre el 'recorder' de Flutter Sound.
   * - Genera un archivo temporal (audio_ptt.aac) en el directorio temporal.
   * - Comienza la grabación con el codec AAC ADTS.
   */
  Future<void> _startMicrophone() async {
    try {
      if (!_recorder.isRecording) {
        // Abre el grabador de audio
        await _recorder.openRecorder();

        // Obtiene un directorio temporal en el dispositivo
        final tempDir = await getTemporaryDirectory();
        // Construye la ruta completa del archivo de audio temporal
        final tempPath = '${tempDir.path}/audio_ptt.aac';

        // Inicia la grabación y especifica el archivo de salida y el códec
        await _recorder.startRecorder(toFile: tempPath, codec: Codec.aacADTS);

        debugPrint("🎤 Micrófono activado y grabando audio...");
      }
    } catch (e) {
      debugPrint("❌ Error al activar el micrófono: $e");
    }
  } //FIN _startMicrophone

  /*
   * Detiene la grabación de audio a través del micrófono.
   * - Verifica si el grabador está en uso.
   * - Detiene la grabación, cierra el grabador y notifica por consola.
   */
  Future<void> _stopMicrophone() async {
    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
        await _recorder.closeRecorder();
        debugPrint("⛔ Micrófono detenido correctamente.");
      }
    } catch (e) {
      debugPrint("❌ Error al detener el micrófono: $e");
    }
  } //FIN _stopMicrophone

  /*
   * Activa (conecta) el Bluetooth Classic a una dirección MAC específica.
   * - Recibe como parámetro la dirección MAC del dispositivo Classic.
   * - Verifica que no esté vacío el address.
   * - Si no hay conexión previa o esta no está activa, intenta conectar.
   */
  Future<void> _activateBluetoothClassic(String address) async {
    debugPrint("🔄 Intentando conectar Bluetooth Classic a $address...");
    try {
      if (address.isEmpty) {
        debugPrint('❌ Dirección MAC no disponible.');
        return;
      }

      // Si no está conectado aún, intenta la conexión usando la librería
      if (classicConnection == null || !classicConnection!.isConnected) {
        classicConnection = await btClassic.BluetoothConnection.toAddress(
          address,
        );
        debugPrint('✅ Bluetooth Classic conectado a $address');
      } else {
        debugPrint('🔵 Bluetooth Classic ya está activo.');
      }
    } catch (e) {
      debugPrint('❌ Error activando Bluetooth Classic: $e');
    }
  } //FIN _activateBluetoothClassic

  /*
   * Desactiva (cierra) la conexión Bluetooth Classic, si existe.
   * - Verifica la conexión actual.
   * - Cierra la conexión si está activa.
   * - Finalmente, restablece classicConnection a null.
   */
  Future<void> _deactivateBluetoothClassic() async {
    try {
      if (classicConnection != null && classicConnection!.isConnected) {
        await classicConnection!.close();
        debugPrint('⛔ Bluetooth Classic desconectado.');
      } else {
        debugPrint(
          '🔴 Bluetooth Classic ya está desactivado o nunca se conectó.',
        );
      }
    } catch (e) {
      debugPrint('❌ Error desactivando Bluetooth Classic: $e');
    } finally {
      // Asegura que la referencia se limpie siempre, incluso tras un error
      classicConnection = null;
    }
  } //FIN _deactivateBluetoothClassic

  /*
   * Envío de trama PTT específica según el documento.
   * - Construye y envía el comando correspondiente para el Push To Talk.
   */

  ///==SOLICITAR ESTADOS DEL SISTEMA===
  /*
   * Método para solicitar el estado actual del sistema al hardware.
   *
   * Pasos:
   * 1. Se construye el frame con los bytes base:
   *    [0xAA, 0x14, 0x18, 0x44]
   *    - 0xAA : Inicio de trama
   *    - 0x14 : Dirección o comando base
   *    - 0x18 : Código de comando para “Estado del Sistema”
   *    - 0x44 : Dato para indicar solicitud
   *
   * 2. Se agrega el CRC forzado para la “solicitud de estado del sistema”:
   *    [0x30, 0xF9]
   *
   * 3. Se agrega el byte de fin de trama (0xFF).
   *
   * 4. Se llama a `sendCommand(frame)` para enviar el comando por BLE.
   */

  void requestSystemStatus() {
    List<int> frame = [0xAA, 0x14, 0x18, 0x44];

    // FORZAR EL CRC A `30F9` SOLO PARA SOLicitud DE ESTADO DEL SISTEMA
    frame.addAll([0x30, 0xF9]);
    frame.add(0xFF); // Fin de trama

    sendCommand(frame);
  } //FIN requestSystemStatus

  ///===ESCUCHAR RESPUESTAS DEL HARDWARE EN ASCII
  /*
   * Escucha de notificaciones/respuestas provenientes del hardware BLE.
   * - Comprueba si hay una característica de notificación disponible.
   * - Activa la notificación (setNotifyValue(true)).
   * - Se suscribe a los cambios de valor (value.listen(...)).
   * - Convierte la respuesta recibida a hexadecimal legible.
   * - Extrae el comando y el CRC para evaluar el estado reportado por el dispositivo.
   */

  // ================================
  // NUEVAS FUNCIONES IMPLEMENTADAS
  // ================================

  /// **Cambiar Aux a Luces / Luces a Aux**
  void switchAuxLights() {
    List<int> frame = [0xAA, 0x14, 0x24, 0x44];
    frame.addAll([0x77, 0x39]); // CRC FORZADO
    frame.add(0xFF);
    sendCommand(frame);
  }

  /// **Cambiar Tono de Horn**
  void changeHornTone() {
    List<int> frame = [0xAA, 0x14, 0x25, 0x44];
    frame.addAll([0xB7, 0x68]); // CRC FORZADO
    frame.add(0xFF);
    sendCommand(frame);
  }

  /// **Sincronizar / Desincronizar luces con sirena**
  void syncLightsWithSiren() {
    List<int> frame = [0xAA, 0x14, 0x26, 0x44];
    frame.addAll([0xB7, 0x98]); // CRC FORZADO
    frame.add(0xFF);
    sendCommand(frame);
  }

  /// **Autoajuste PA**
  void autoAdjustPA() {
    List<int> frame = [0xAA, 0x14, 0x27, 0x44];
    frame.addAll([0x77, 0xC9]); // CRC FORZADO
    frame.add(0xFF);
    sendCommand(frame);
    debugPrint("⏳ Esperar 30 segundos para el autoajuste PA.");
  }

  /// **Escuchar respuestas del hardware**
  void listenForResponses(Ble.BluetoothCharacteristic characteristic) {
    characteristic.setNotifyValue(true);
    characteristic.value.listen((response) {
      String hexResponse =
          response
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(' ')
              .toUpperCase();
      debugPrint("📩 Respuesta recibida: $hexResponse");

      if (response.length >= 6) {
        String command = hexResponse.substring(3, 5);
        String crc = hexResponse.substring(hexResponse.length - 4);

        switch (command) {
          case "18":
            if (crc == "3733") debugPrint("✅ Estado del sistema: DataOK");
            break;
          case "22":
            if (crc == "D45A") debugPrint("⚠️ Estado del sistema: DataFail");
            break;
          case "33":
            if (crc == "B8CA") debugPrint("❌ Estado del sistema: CRC error");
            break;
          case "24":
            debugPrint("🔁 Cambio Aux/Luces recibido");
            break;
          case "25":
            debugPrint("🔊 Cambio Tono Horn recibido");
            break;
          case "26":
            debugPrint("💡 Sincronización luces/sirena recibida");
            break;
          case "27":
            debugPrint("🔄 Autoajuste PA recibido");
            break;
          case "13":
            debugPrint("💡 Función Luz Activa");
            break;
          case "14":
            debugPrint("🔋 Batería Completa / Carro encendido");
            break;
          case "15":
            debugPrint("🔋 Batería Media / Carro apagado");
            break;
          case "16":
            debugPrint("⚠️ Batería Baja");
            break;
          default:
            debugPrint("❓ Estado desconocido: $command");
        }
      }
    });
  }

  /// **Desconectar Dispositivo**
  void disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      debugPrint("🔴 Dispositivo desconectado.");
      connectedDevice = null;
    }
  }
}

//FIN ControlController
