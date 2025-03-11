import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_localizations_delegate.dart';

// Clase que maneja los textos en diferentes idiomas
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const Map<String, Map<String, String>> _localizedStrings = {
    'es': {
      'title': 'Bienvenido',
      'language': 'Idioma',
      'settings': 'Configuración',
      'text_size': 'Tamaño del texto',
      'dark_mode': 'Modo oscuro / Modo claro',
      'control': 'Control',
      'home': 'Inicio',
      'connect': 'Conectar',
      'disconnect': 'Desconectar',
      'access_control': 'Acceder al Control',
      'detection_mode': 'Modo detección',
      'connected_to': 'Conectado a',
      'no_devices_found': 'No se encontraron dispositivos Pw',
      'unknown_device': 'Dispositivo Desconocido',

      'spanish': 'Español (Latinoamérica)',
      'english': 'English (United States)',
      'portuguese': 'Português (Brasil)',

      'siren': 'Sirena',
      'auxiliary': 'Auxiliar',
      'horn': 'Bocina',
      'wail': 'Wail',
      'intercom': 'Intercomunicador',
      'ptt': 'PTT',
      'system_status': 'Estado del Sistema',
    },
    'en': {
      'title': 'Welcome',
      'language': 'Language',
      'settings': 'Settings',
      'text_size': 'Text Size',
      'dark_mode': 'Dark Mode / Light Mode',
      'control': 'Control',
      'home': 'Home',
      'connect': 'Connect',
      'disconnect': 'Disconnect',
      'access_control': 'Access Control',
      'detection_mode': 'Detection Mode',
      'connected_to': 'Connected to',
      'no_devices_found': 'No Pw devices found',
      'unknown_device': 'Unknown Device',

      'spanish': 'Spanish (Latin America)',
      'english': 'English (United States)',
      'portuguese': 'Portuguese (Brazil)',

      'siren': 'Siren',
      'auxiliary': 'Auxiliary',
      'horn': 'Horn',
      'wail': 'Wail',
      'intercom': 'intercom',
      'ptt': 'PTT',
      'system_status': 'System status',
    },
    'pt': {
      'title': 'Bem-vindo',
      'language': 'Linguagem',
      'settings': 'Configurações',
      'text_size': 'Tamanho do texto',
      'dark_mode': 'Modo escuro / Modo claro',
      'control': 'Controle',
      'home': 'Início',
      'connect': 'Conectar',
      'disconnect': 'Desconectar',
      'access_control': 'Acessar Controle',
      'detection_mode': 'Modo de detecção',
      'connected_to': 'Conectado a',
      'no_devices_found': 'Nenhum dispositivo Pw encontrado',
      'unknown_device': 'Dispositivo desconhecido',

      'spanish': 'Espanhol (América Latina)',
      'english': 'Inglês (Estados Unidos)',
      'portuguese': 'Português (Brasil)',

      'siren': 'Sirene',
      'auxiliary': 'Auxiliar',
      'horn': 'Buzina',
      'wail': 'Wail',
      'intercom': 'interfone',
      'ptt': 'PTT',
      'system_status': 'Status do sistema',
    },
  };

  String translate(String key) {
    return _localizedStrings[locale.languageCode]?[key] ?? key;
  }

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('es'), // Español
    Locale('en'), // Inglés
    Locale('pt'), // Portugués
  ];
}
