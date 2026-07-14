// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'EteDrop';

  @override
  String get home => 'Inicio';

  @override
  String get send => 'Enviar';

  @override
  String get receive => 'Recibir';

  @override
  String get settings => 'Ajustes';

  @override
  String get cloud => 'Nube';

  @override
  String get nearby => 'Cerca';

  @override
  String get messages => 'Mensajes';

  @override
  String get deviceInfo => 'Información del dispositivo';

  @override
  String get storage => 'Almacenamiento';

  @override
  String get desktopIntegration => 'Integración de escritorio';

  @override
  String get appearance => 'Apariencia';

  @override
  String get networkLine => 'Ruta del servidor';

  @override
  String get serverLineAuto => 'Automático';

  @override
  String get serverLineAutoDesc =>
      'Selecciona automáticamente el nodo más cercano.';

  @override
  String get serverLineGlobal => 'Global';

  @override
  String get serverLineGlobalDesc => 'api.etedrop.com';

  @override
  String get serverLineMainland => 'China continental';

  @override
  String get serverLineMainlandDesc => 'api.etedrop.cn';

  @override
  String get about => 'Acerca de';

  @override
  String get checkForUpdates => 'Buscar actualizaciones';

  @override
  String get checkForUpdatesDesc => 'Descarga e instala la última versión';

  @override
  String get updateCheckFailed => 'No se pudo comprobar si hay actualizaciones';

  @override
  String get updateAvailableTitle => 'Actualización disponible';

  @override
  String updateAvailableBody(String current, String latest) {
    return 'Actual: $current\nÚltima: $latest';
  }

  @override
  String updateAlreadyLatest(String version) {
    return 'Ya está actualizado (v$version)';
  }

  @override
  String get updateNow => 'Actualizar';

  @override
  String get later => 'Más tarde';

  @override
  String get openLinkFailed => 'No se pudo abrir el enlace';

  @override
  String get connected => 'Conectado';

  @override
  String get disconnected => 'Desconectado';

  @override
  String get connect => 'Conectar';

  @override
  String get deviceId => 'ID del dispositivo';

  @override
  String get editDeviceName => 'Editar nombre del dispositivo';

  @override
  String get storagePath => 'Ruta de almacenamiento';

  @override
  String get notSet => 'Sin definir';

  @override
  String get launchAtStartup => 'Abrir al iniciar';

  @override
  String get minimizeToTray => 'Minimizar a la bandeja';

  @override
  String get minimizeToTrayDesc => 'Ocultar la ventana en la bandeja al cerrar';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get followSystem => 'Seguir el sistema';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get language => 'Idioma';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get selectTheme => 'Elegir tema';

  @override
  String get inputDeviceName => 'Nombre del dispositivo';

  @override
  String get sendFile => 'Enviar archivo';

  @override
  String get selectFile => 'Seleccionar archivo';

  @override
  String get selectFileToSend => 'Selecciona un archivo para enviar';

  @override
  String get reselect => 'Volver a elegir';

  @override
  String get startSend => 'Empezar envío';

  @override
  String get connecting => 'Conectando...';

  @override
  String get waitingForReceiver => 'Esperando al receptor...';

  @override
  String get waitingForSender => 'Esperando al emisor...';

  @override
  String get pickupCode => 'Código de recogida';

  @override
  String get copied => 'Copiado';

  @override
  String get sending => 'Enviando...';

  @override
  String get sendComplete => '¡Envío completado!';

  @override
  String get sendNewFile => 'Enviar otro archivo';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Reintentar';

  @override
  String get receiveFile => 'Recibir archivo';

  @override
  String get inputPickupCode => 'Introducir código de recogida';

  @override
  String get inputPickupCodeHint => 'Introduce el código para recibir';

  @override
  String get startReceive => 'Empezar a recibir';

  @override
  String get receiving => 'Recibiendo...';

  @override
  String get receiveComplete => '¡Recepción completada!';

  @override
  String get saveFile => 'Guardar archivo';

  @override
  String get receiveNewFile => 'Recibir otro archivo';

  @override
  String fileSaved(String path) {
    return 'Archivo guardado en: $path';
  }

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get langChineseSimplified => 'Chino (simplificado)';

  @override
  String get langEnglish => 'Inglés';

  @override
  String get langJapanese => 'Japonés';

  @override
  String get langKorean => 'Coreano';

  @override
  String get langSpanish => 'Español';

  @override
  String get nearbyDevices => 'Dispositivos cercanos';

  @override
  String selectedCount(int count) {
    return 'Seleccionados: $count';
  }

  @override
  String get findingNearbyUsers => 'Buscando usuarios...';

  @override
  String get lookingForNearbyDevices => 'Buscando dispositivos cercanos...';

  @override
  String get macLanLocalNetworkHint =>
      'Si la lista sigue vacía: Ajustes del sistema → Privacidad y seguridad → Red local → permita esta app. No verá su propio dispositivo; solo otros en la misma LAN.';

  @override
  String get offline => 'Sin conexión';

  @override
  String get weakSignal => 'Señal débil';

  @override
  String get youLabel => 'Tú';

  @override
  String get emptyFolder => 'Carpeta vacía';

  @override
  String get shareAction => 'Compartir';

  @override
  String get deleteAction => 'Eliminar';

  @override
  String get columnName => 'Nombre';

  @override
  String get columnModified => 'Modificado';

  @override
  String get columnSize => 'Tamaño';

  @override
  String get columnActions => 'Acciones';

  @override
  String get shareTooltip => 'Compartir';

  @override
  String get deleteTooltip => 'Eliminar';

  @override
  String get storagePreparingTitle => 'Preparando almacenamiento';

  @override
  String get storagePreparingSubtitle =>
      'Los archivos se guardarán en la carpeta de la app en este dispositivo.';

  @override
  String get storageNotSetTitle => 'Aún no hay carpeta de almacenamiento';

  @override
  String get storageNotSetSubtitle => 'Elige una carpeta para la nube.';

  @override
  String get chooseStorageFolder => 'Elegir carpeta';

  @override
  String get loadFailed => 'Error al cargar';

  @override
  String get openSystemSettingsForAccess =>
      'Abrir Ajustes del sistema para permitir acceso';

  @override
  String get changeStorageDirectory => 'Cambiar carpeta de almacenamiento';

  @override
  String get confirmDelete => 'Confirmar eliminación';

  @override
  String deleteEntryConfirm(String name, String suffix) {
    return '¿Eliminar «$name»?$suffix';
  }

  @override
  String get deleteFolderSuffix =>
      '\nSe eliminará todo el contenido de la carpeta.';

  @override
  String get moveToTrashAction => 'Mover a la papelera';

  @override
  String moveToTrashConfirm(String name, String suffix) {
    return '¿Mover «$name» a la papelera?$suffix';
  }

  @override
  String get moveToTrashFolderSuffix =>
      '\nTodo el contenido de la carpeta se moverá a la papelera.';

  @override
  String get newFolderTooltip => 'Nueva carpeta';

  @override
  String get uploadFileTooltip => 'Subir archivos';

  @override
  String get refreshTooltip => 'Actualizar';

  @override
  String get cloudDirectoryLabel => 'Carpeta de la nube';

  @override
  String get downloadDirectoryLabel => 'Carpeta de descargas';

  @override
  String clipboardImageSaveFailed(String error) {
    return 'No se pudo guardar la imagen del portapapeles: $error';
  }

  @override
  String get enterTextOrAddFiles => 'Escribe texto o añade al menos un archivo';

  @override
  String get selectOnlineReceiversFirst =>
      'Primero selecciona dispositivos receptores en línea arriba';

  @override
  String sendFailed(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get inputHintDesktop =>
      'Escribe texto, ⌘V para pegar capturas o arrastra archivos…';

  @override
  String get inputHintMobile => 'Escribe texto o elige archivos…';

  @override
  String get addFilesTooltip => 'Añadir archivos';

  @override
  String get sendButtonLabel => 'Enviar';

  @override
  String get sendingButton => 'Enviando…';

  @override
  String get removeTooltip => 'Quitar';

  @override
  String get shareScreenTitle => 'Compartir';

  @override
  String get selectAtLeastOneReceiver =>
      'Selecciona al menos un receptor arriba';

  @override
  String get shareInviteSentSnack =>
      'Invitación enviada. La transferencia empezará cuando el otro la acepte en Mensajes.';

  @override
  String get expireNever => 'Sin caducidad';

  @override
  String get expireOneHour => '1 hora';

  @override
  String get expireOneDay => '24 horas';

  @override
  String get expireSevenDays => '7 días';

  @override
  String get expireThirtyDays => '30 días';

  @override
  String get shareLinkCopied => 'Enlace de compartición copiado';

  @override
  String createShareFailed(String error) {
    return 'No se pudo crear el recurso compartido: $error';
  }

  @override
  String get cancelShareTitle => 'Dejar de compartir';

  @override
  String get cancelShareBody =>
      '¿Dejar de compartir este archivo? Ya no se podrá descargar con el enlace actual.';

  @override
  String get backButton => 'Atrás';

  @override
  String get cancelShareButton => 'Dejar de compartir';

  @override
  String get shareCancelled => 'Compartición cancelada';

  @override
  String cancelShareFailed(String error) {
    return 'Error al dejar de compartir: $error';
  }

  @override
  String shareLoadingTitle(String name) {
    return 'Compartir «$name»';
  }

  @override
  String get closeButton => 'Cerrar';

  @override
  String get createShareDialogTitle => 'Crear recurso compartido';

  @override
  String fileColon(String name) {
    return 'Archivo: $name';
  }

  @override
  String get setPassword => 'Proteger con contraseña';

  @override
  String get enterPassword => 'Introducir contraseña';

  @override
  String get shareCreatedTitle => 'Recurso compartido creado';

  @override
  String get shareExistingDescription =>
      'Este archivo ya se está compartiendo. Copia el código o el enlace de abajo.';

  @override
  String get connectForShareLink =>
      'Conéctate al servidor para ver el enlace en Mis compartidos.';

  @override
  String get passwordProtected => 'Contraseña activada';

  @override
  String expiresAt(String when) {
    return 'Caduca: $when';
  }

  @override
  String get doneButton => 'Hecho';

  @override
  String get createShareAction => 'Crear compartición';

  @override
  String get copyShareLinkTooltip => 'Copiar enlace de compartición';

  @override
  String get pickCloudStorageTitle => 'Elegir carpeta de la nube';

  @override
  String get pickDownloadDirTitle => 'Elegir carpeta de descargas';

  @override
  String get messagePageTitle => 'Mensajes';

  @override
  String get clearMessagesTooltip => 'Vaciar';

  @override
  String get noMessagesYet => 'No hay mensajes';

  @override
  String get noMessagesSubtitle =>
      'Cuando un dispositivo te envíe archivos, aparecerán aquí.';

  @override
  String get waitAcceptInMessage =>
      'Esperando que el otro acepte en Mensajes (válido 2 minutos)';

  @override
  String get retrySend => 'Reintentar envío';

  @override
  String get reject => 'Rechazar';

  @override
  String get receiveAction => 'Recibir';

  @override
  String notifySenderFailed(String error) {
    return 'No se pudo notificar al remitente: $error';
  }

  @override
  String get fileNotFoundMaybeMoved =>
      'Archivo local no encontrado; puede haberse movido o eliminado.';

  @override
  String get revealInFolderNotSupported =>
      'Esta plataforma no puede mostrar el archivo en la carpeta.';

  @override
  String get shareRestarted => 'Compartición reiniciada';

  @override
  String get localFileGoneCannotRetry =>
      'Falta el archivo local; no se puede reintentar.';

  @override
  String retryFailed(String error) {
    return 'Error al reintentar: $error';
  }

  @override
  String get statusPending => 'Pendiente';

  @override
  String get statusAccepted => 'Aceptado';

  @override
  String get statusReceiving => 'Recibiendo';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusRejected => 'Rechazado';

  @override
  String get statusFailed => 'Fallido';

  @override
  String get statusExpired => 'Caducado';

  @override
  String get meLabel => 'Yo';

  @override
  String get sendingBadge => 'Enviar';

  @override
  String messageSendToRecipients(String names) {
    return 'Para $names';
  }

  @override
  String messageOutgoingHeaderLine(String names) {
    return 'Para $names';
  }

  @override
  String recipientNDevices(int count) {
    return '$count dispositivos';
  }

  @override
  String recipientTwo(String name1, String name2) {
    return '$name1, $name2';
  }

  @override
  String recipientMany(String name1, String name2, int total) {
    return '$name1, $name2 ($total dispositivos)';
  }

  @override
  String sendingPercent(String percent) {
    return 'Enviando $percent%';
  }

  @override
  String receivingPercent(String percent) {
    return 'Recibiendo $percent%';
  }

  @override
  String approxSpeed(String speed) {
    return '~ $speed';
  }

  @override
  String totalSizeLine(String size) {
    return 'Total $size';
  }

  @override
  String get shareRecordTitle => 'Compartir';

  @override
  String get transferCompleted => 'Completado';

  @override
  String get transferInProgress => 'Transfiriendo';

  @override
  String get transferEnded => 'Finalizado';

  @override
  String timeRemaining(String mm, String ss) {
    return 'Quedan $mm:$ss';
  }

  @override
  String get receiverLabel => 'Destinatarios';

  @override
  String get shareAllReceivedHint =>
      'El destinatario recibió todos los archivos de este recurso compartido.';

  @override
  String get shareTransferringHint =>
      'Transfiriendo al destinatario. Mantén la app abierta y la conexión.';

  @override
  String get shareWaitAcceptHint =>
      'El destinatario debe pulsar Recibir en Mensajes para empezar. Se cancela si nadie acepta en 2 minutos.';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get copyAction => 'Copiar';

  @override
  String get closeAction => 'Cerrar';

  @override
  String get cancelSharingAction => 'Cancelar compartición';

  @override
  String processingPercent(String percent) {
    return 'Procesando… $percent%';
  }

  @override
  String get chooseAvatar => 'Elegir avatar';

  @override
  String get newFolderDialogTitle => 'Nueva carpeta';

  @override
  String get folderNameHint => 'Nombre de la carpeta';

  @override
  String get createFolderButton => 'Crear';

  @override
  String get folderNameEmpty => 'Introduce un nombre de carpeta';

  @override
  String get folderNameInvalidChars => 'El nombre no puede contener / ni \\';

  @override
  String createFolderFailed(String error) {
    return 'No se pudo crear la carpeta: $error';
  }

  @override
  String get rootDirectory => 'Raíz';

  @override
  String get notificationIncomingTitle => 'Nueva solicitud de archivo';

  @override
  String notificationIncomingBody(String sender, String file) {
    return '$sender está enviando: $file';
  }

  @override
  String get notificationCompleteTitle => 'Recepción completada';

  @override
  String notificationCompleteBody(String file, String sender) {
    return '$file (de $sender)';
  }

  @override
  String trayOpenApp(String appName) {
    return 'Abrir $appName';
  }

  @override
  String get trayQuit => 'Salir';

  @override
  String get showInFolder => 'Mostrar en carpeta';

  @override
  String get signalingConnectFailed =>
      'No se pudo conectar al servidor de señalización';

  @override
  String get signalingWaitTimeout => 'Tiempo de espera agotado';

  @override
  String get webSocketError => 'Error de conexión WebSocket';

  @override
  String get invalidPickupCode => 'Código de recogida no válido';

  @override
  String get transferReceiveSection => 'Transferencia';

  @override
  String get transferAutoReceiveTitle => 'Aceptar compartidos automáticamente';

  @override
  String get transferAutoReceiveSubtitle =>
      'Si está activado, los recursos LAN empiezan sin pulsar Recibir en Mensajes. Por defecto desactivado.';

  @override
  String get videoTranscodeTitle => 'Transcodificación de vídeo';

  @override
  String get videoTranscodeSubtitle =>
      'Si está activado, los formatos de vídeo no compatibles se transcodifican automáticamente para reproducción en línea (usa más CPU).';

  @override
  String get transferAutoReceivingHint =>
      'Aceptación automática activada: conectando y recibiendo en segundo plano.';

  @override
  String get webrtcBackgroundKeepaliveSection => 'Background';

  @override
  String get webrtcBackgroundKeepaliveTitle =>
      'Keep transfer alive in background';

  @override
  String get webrtcBackgroundKeepaliveSubtitle =>
      'When on, tries to keep the LAN WebRTC data connection in background (file transfer only, no microphone). Android shows a low-priority foreground notification. iOS uses limited background refresh. System limits still apply.';

  @override
  String get webrtcBackgroundFgNotificationTitle => 'Keeping transfer active';

  @override
  String get webrtcBackgroundFgNotificationBody => 'Tap to return to the app';

  @override
  String get webrtcBackgroundKeepaliveEnableFailed =>
      'Could not enable background keep-alive. Allow notification access, then try again.';
}
