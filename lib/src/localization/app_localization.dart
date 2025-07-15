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
      'msg_sincronizacionpw': 'Sincronización iniciada',
      'sincronizar_pw': 'Sincronizar PW',
      'title': 'Bienvenido',
      'language': 'Idioma',
      'settings': 'Configuración',
      'text_size': 'Tamaño del texto',
      'dark_mode': 'Temas',
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

      "conexion_pw": "Conexión PW",
      "olvidar_pw": "Olvidar PW",
      "sin_dispositivos": "No hay ningún dispositivo emparejado",

      'pw_series': 'PW series',
      'configuracion': 'Configuración',
      'idiomas': 'Idiomas',
      'acerca_de': 'Acerca de',
      'tecladoTitulo': 'Configuración Teclado',
      'tecladoAutoajustePA': 'Autoajuste PA',
      'tecladoAutoajusteMsg': 'Esperando 30 segundos para el autoajuste PA',
      'tecladoSyncLuces': 'Sincronizar Luces con Sirenas',
      'tecladoSyncMsg': 'Sincronizando / Desincronizando Luces con Sirenas',
      'tecladoCambioHorn': 'Cambiar Tono Horn',
      'tecladoHornMsg': 'Cambiando Tono Horn',
      'tecladoAuxLuces': 'Cambiar a Modo Luces / Auxiliar',
      "autoajuste_pa": "Autoajuste PA",
      "msg_autoajuste_pa": "Autoajuste PA iniciado",
      "sincronizar_luces": "Sincronizar Luces y Sirenas",
      "msg_sincronizacion": "Sincronización iniciada",
      "cambio_horn": "Cambio Horn",
      "msg_cambio_horn": "Tono Horn cambiado",
      "aux_luces": "Auxiliar / Luces",
      "msg_aux_luces": "Modo Aux/Luces cambiado",
      "dispositivo_no_conectado": "Dispositivo no conectado",

      "idioma": "Idioma",
      "idioma_es": "Español",
      "idioma_en": "Inglés",
      "idioma_fr": "Francés",
      "idioma_pt": "Portugués",

      "theme_title": "Tema App Pw",
      "theme_dark": "Modo Oscuro",
      "theme_light": "Modo Claro",
      "theme_system": "Sistema",
    },
    'en': {
      'msg_sincronizacionpw': 'Synchronize PW',
      'sincronizar_pw': 'Synchronize PW',
      'title': 'Welcome',
      'language': 'Language',
      'settings': 'Settings',
      'text_size': 'Text Size',
      'dark_mode': 'Themes',
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

      'adjust_text_size': 'Adjust Text Size',
      'preview_text': 'Preview Text',

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
      "olvidar_pw": "Forget PW",
      "sin_dispositivos": "No paired devices found",
      'configuracion': 'Configuration',
      'idiomas': 'Languages',
      'acerca_de': 'About',

      "autoajuste_pa": "Auto Adjust PA",
      "msg_autoajuste_pa": "Auto adjust PA started",
      "sincronizar_luces": "Sync Lights and Sirens",
      "msg_sincronizacion": "Synchronization started",
      "cambio_horn": "Change Horn",
      "msg_cambio_horn": "Horn tone changed",
      "aux_luces": "Auxiliary / Lights",
      "msg_aux_luces": "Aux/Lights mode changed",
      "dispositivo_no_conectado": "Device not connected",

      "idioma": "Language",
      "idioma_es": "Spanish",
      "idioma_en": "English",
      "idioma_fr": "French",
      "idioma_pt": "Portuguese",

      "theme_title": "App Theme Pw",
      "theme_dark": "Dark Mode",
      "theme_light": "Light Mode",
      "theme_system": "System Default",
      'conexion_pw': 'PW Connection',
    },
    'pt': {
      'msg_sincronizacionpw': 'Sincronizar PW',
      'sincronizar_pw': 'Sincronizar PW',
      'title': 'Bem-vindo',
      'language': 'Linguagem',
      'settings': 'Configurações',
      'text_size': 'Tamanho do texto',
      'dark_mode': 'Temas',
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

      "acerca_de": "Sobre",
      "desarrollado_por": "Desenvolvido por:",
      "version": "Versão",
      "whatsapp_error": "Não foi possível abrir o WhatsApp",
      "contactanos_button_image": "ContacteNos_1.png",

      'config_avanzada': 'Configuração Avançada',
      'config_teclado': 'Configuração do Teclado',

      "conexion_pw": "Conexão PW",
      "olvidar_pw": "Esquecer PW",
      "sin_dispositivos": "Nenhum dispositivo emparelhado encontrado",

      "autoajuste_pa": "Autoajuste PA",
      "msg_autoajuste_pa": "Autoajuste PA iniciado",
      "sincronizar_luces": "Sincronizar Luzes e Sirenes",
      "msg_sincronizacion": "Sincronização iniciada",
      "cambio_horn": "Mudar Horn",
      "msg_cambio_horn": "Tom da buzina alterado",
      "aux_luces": "Auxiliar / Luzes",
      "msg_aux_luces": "Modo Aux/Luzes alterado",
      "dispositivo_no_conectado": "Dispositivo não conectado",

      'adjust_text_size': 'Ajustar o tamanho do texto',
      'preview_text': 'Texto de exemplo',
      "idioma": "Idioma",
      'idiomas': 'Idiomas',
      "idioma_es": "Espanhol",
      "idioma_en": "Inglês",
      "idioma_fr": "Francês",
      "idioma_pt": "Português",

      "theme_title": "Tema do App Pw",
      "theme_dark": "Modo Escuro",
      "theme_light": "Modo Claro",
      "theme_system": "Sistema",
      'configuracion': 'Configuração',
    },
    'fr': {
      'msg_sincronizacionpw': 'Synchroniser PW',
      'sincronizar_pw': 'Synchroniser PW',
      'title': 'Bienvenue',
      'language': 'Langue',
      'settings': 'Paramètres',
      'text_size': 'Taille du texte',
      'dark_mode': 'thèmes',
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

      "acerca_de": "À propos",
      "desarrollado_por": "Développé par :",
      "version": "Version",
      "whatsapp_error": "Impossible d'ouvrir WhatsApp",
      "contactanos_button_image": "ContactezNous_1.png",

      'config_avanzada': 'Paramètres Avancés',
      'config_teclado': 'Configuration Clavier',

      "autoajuste_pa": "Ajustement auto PA",
      "msg_autoajuste_pa": "Ajustement automatique PA démarré",
      "sincronizar_luces": "Synchroniser Lumières et Sirènes",
      "msg_sincronizacion": "Synchronisation démarrée",
      "cambio_horn": "Changer le Horn",
      "msg_cambio_horn": "Ton du klaxon changé",
      "aux_luces": "Auxiliaire / Lumières",
      "msg_aux_luces": "Mode Aux/Lumières modifié",
      "dispositivo_no_conectado": "Appareil non connecté",

      "idioma": "Langue",
      "idioma_es": "Espagnol",
      "idioma_en": "Anglais",
      "idioma_fr": "Français",
      "idioma_pt": "Portugais",

      'configuracion': 'Configuration',
      'idiomas': 'Langues',

      "theme_title": "Thème de l'app Pw",
      "theme_dark": "Mode Sombre",
      "theme_light": "Mode Clair",
      "theme_system": "Système",

      'adjust_text_size': 'Ajuster la taille du texte',
      'preview_text': 'Exemple de texte',

      "conexion_pw": "Connexion PW",
      "olvidar_pw": "Oublier PW",
      "sin_dispositivos": "Aucun appareil jumelé trouvé",
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
