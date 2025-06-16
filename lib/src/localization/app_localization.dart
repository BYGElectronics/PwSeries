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

      "horn_change_msg": "Cambiando Tono Horn",
      "switch_lights_aux_mode": "Cambiando a modo luces / Auxiliar",
      "sync_lights_with_siren":
          "Sincronizando / Desincronizando Luces con Sirenas",
      "autoajuste_pa_msg": "Esperar 30 segundos para el autoajuste PA",

      "acercaDe": "Acerca De",
      "desarrollado_por": "Desarrollado Por:",
      "version": "Versión",
      "whatsapp_error": "No se pudo abrir WhatsApp",
      "contactanos_button_image": "Contactanos_1.png",

      'config_avanzada': 'Configuración Avanzada',
      'config_teclado': 'Configuración Teclado',
      'conexion_pw': 'Conexión Pw',

      'pw_series': 'PW series',
      'configuracion': 'Configuración',
      'idiomas': 'Idiomas',
      'acerca_de': 'Acerca de',
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

      "horn_change_msg": "Changing Horn Tone",
      "switch_lights_aux_mode": "Switching to lights / auxiliary mode",
      "sync_lights_with_siren": "Syncing / Unsyncing Lights with Sirens",
      "autoajuste_pa_msg": "Waiting 30 seconds for PA auto-adjustment",
      'pw_series': 'PW series',
      "acercaDe": "About",
      "desarrollado_por": "Developed By:",
      "version": "Version",
      "whatsapp_error": "Could not open WhatsApp",
      "contactanos_button_image": "ContactUs_1.png",

      'config_avanzada': 'Advanced Settings',
      'config_teclado': 'Keyboard Setup',
      'conexion_pw': 'Pw Connection',
    },
    'pt': {
      'title': 'Bem-vindo',
      'language': 'Linguagem',
      'settings': 'Configurações',
      'text_size': 'Tamanho do texto',
      'dark_mode': 'Modo escuro / Modo claro',
      'pw_series': 'PW series',
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

      "horn_change_msg": "Trocando Tom da Buzina",
      "switch_lights_aux_mode": "Trocando para Modo de Luzes / Auxiliar",
      "sync_lights_with_siren":
          "Sincronizando / Desincronizando Luzes com Sirenas",
      "autoajuste_pa_msg":
          "Aguardando 30 segundos para o ajuste automático de PA",

      "acercaDe": "Sobre",
      "desarrollado_por": "Desenvolvido por:",
      "version": "Versão",
      "whatsapp_error": "Não foi possível abrir o WhatsApp",
      "contactanos_button_image": "ContacteNos_1.png",

      'config_avanzada': 'Configuração Avançada',
      'config_teclado': 'Configuração do Teclado',
      'conexion_pw': 'Conexão Pw',
    },
    'fr': {
      'title': 'Bienvenue',
      'language': 'Langue',
      'settings': 'Paramètres',
      'text_size': 'Taille du texte',
      'dark_mode': 'Mode sombre / Mode clair',
      'control': 'Contrôle',
      'home': 'Accueil',
      'pw_series': 'PW series',
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

      "horn_change_msg": "Changement de la tonalité du klaxon",
      "switch_lights_aux_mode": "Changement en mode de lumières / auxiliaire",
      "sync_lights_with_siren":
          "Synchronisation / Dé-synchronisation des lumières avec les sirènes",
      "autoajuste_pa_msg":
          "Attente de 30 secondes pour l'ajuste automatique de PA",

      "acercaDe": "À propos",
      "desarrollado_por": "Développé par :",
      "version": "Version",
      "whatsapp_error": "Impossible d'ouvrir WhatsApp",
      "contactanos_button_image": "ContactezNous_1.png",

      'config_avanzada': 'Paramètres Avancés',
      'config_teclado': 'Configuration Clavier',
      'conexion_pw': 'Connexion Pw',
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
