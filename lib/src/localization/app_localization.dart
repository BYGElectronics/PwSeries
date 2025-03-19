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
      'control': 'Teclado',
      'home': 'Inicio',
      'connect': 'Conectar',
      'disconnect': 'Desconectar',
      'access_control': 'Acceder al Teclado',
      'detection_mode': 'Modo detección',
      'connected_to': 'Conectado a',
      'no_devices_found': 'No se encontraron dispositivos Pw',
      'unknown_device': 'Dispositivo Desconocido',
      'enable_dark_mode': 'Activar modo oscuro',
      'spanish': 'Español (Latinoamérica)',
      'english': 'English (United States)',
      'portuguese': 'Português (Brasil)',
      'french': 'Français (France)',
      'siren': 'Sirena',
      'auxiliary': 'Auxiliar',
      'horn': 'Bocina',
      'wail': 'Wail',
      'intercom': 'Intercomunicador',
      'ptt': 'PTT',
      'system_status': 'Estado del Sistema',
      'adjust_text_size': 'Ajusta el tamaño del texto',
      'preview_text': 'Texto de ejemplo',
    },
    'en': {
      'title': 'Welcome',
      'language': 'Language',
      'settings': 'Settings',
      'text_size': 'Text Size',
      'dark_mode': 'Dark Mode / Light Mode',
      'control': 'Teclado',
      'home': 'Home',
      'connect': 'Connect',
      'disconnect': 'Disconnect',
      'access_control': 'Access Teclado',
      'detection_mode': 'Detection Mode',
      'connected_to': 'Connected to',
      'no_devices_found': 'No Pw devices found',
      'unknown_device': 'Unknown Device',
      'enable_dark_mode': 'Enable Dark Mode',
      'spanish': 'Spanish (Latin America)',
      'english': 'English (United States)',
      'portuguese': 'Portuguese (Brazil)',
      'french': 'French (France)',
      'siren': 'Siren',
      'auxiliary': 'Auxiliary',
      'horn': 'Horn',
      'wail': 'Wail',
      'intercom': 'Intercom',
      'ptt': 'PTT',
      'system_status': 'System Status',
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
      'enable_dark_mode': 'Ativar modo escuro',
      'spanish': 'Espanhol (América Latina)',
      'english': 'Inglês (Estados Unidos)',
      'portuguese': 'Português (Brasil)',
      'french': 'Francês (França)',
      'siren': 'Sirene',
      'auxiliary': 'Auxiliar',
      'horn': 'Buzina',
      'wail': 'Wail',
      'intercom': 'Interfone',
      'ptt': 'PTT',
      'system_status': 'Status do sistema',
    },
    'fr': {
      'title': 'Bienvenue',
      'language': 'Langue',
      'settings': 'Paramètres',
      'text_size': 'Taille du texte',
      'dark_mode': 'Mode sombre / Mode clair',
      'control': 'Contrôle',
      'home': 'Accueil',
      'connect': 'Se connecter',
      'disconnect': 'Se déconnecter',
      'access_control': 'Accéder au contrôle',
      'detection_mode': 'Mode détection',
      'connected_to': 'Connecté à',
      'no_devices_found': 'Aucun appareil Pw trouvé',
      'unknown_device': 'Appareil inconnu',
      'enable_dark_mode': 'Activer le mode sombre',
      'spanish': 'Espagnol (Amérique Latine)',
      'english': 'Anglais (États-Unis)',
      'portuguese': 'Portugais (Brésil)',
      'french': 'Français (France)',
      'siren': 'Sirène',
      'auxiliary': 'Auxiliaire',
      'horn': 'Klaxon',
      'wail': 'Wail',
      'intercom': 'Interphone',
      'ptt': 'PTT',
      'system_status': 'État du système',
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
    Locale('fr'), // Francés
  ];
}
