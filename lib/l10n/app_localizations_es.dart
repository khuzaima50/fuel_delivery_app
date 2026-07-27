// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'FuelDirect';

  @override
  String get splashTagline =>
      'Obtén combustible de primera calidad entregado directamente a tu vehículo, donde estés';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingGetStarted => 'Comenzar';

  @override
  String get onboardingTitle1 => 'Bienvenido a ';

  @override
  String get onboardingTitleSpan1 => 'FUEL DIRECT';

  @override
  String get onboardingDesc1 =>
      'Entrega combustible de forma segura y eficiente\na clientes en toda la ciudad';

  @override
  String get onboardingTitle2 => 'Navegación en Tiempo Real';

  @override
  String get onboardingDesc2 =>
      'Obtén direcciones giro a giro y actualizaciones\nde tráfico en vivo para cada entrega';

  @override
  String get onboardingTitle3 => 'La Seguridad Primero';

  @override
  String get onboardingDesc3 =>
      'Completa listas de verificación de seguridad y rastrea\ntodas las entregas con precisión';

  @override
  String get onboardingTitle4 => 'Gana Más';

  @override
  String get onboardingDesc4 =>
      'Rastrea tus ganancias, entregas y\nrendimiento en tiempo real';

  @override
  String get loginWelcomeBack => 'Bienvenido de Nuevo';

  @override
  String get loginSignInToContinue => 'Inicia sesión para continuar';

  @override
  String get loginEmailAddress => 'Correo Electrónico';

  @override
  String get loginEmailHint => 'alex@ejemplo.com';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginPasswordHint => 'Ingresa tu contraseña';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginSignIn => 'Iniciar Sesión';

  @override
  String get loginNoAccount => '¿No tienes una cuenta? ';

  @override
  String get loginSignUp => 'Regístrate';

  @override
  String get loginEmptyFields => 'Por favor ingresa tu correo y contraseña';

  @override
  String get loginFailedVerification =>
      'Error al enviar el código de verificación. Inténtalo de nuevo.';

  @override
  String get loginUnexpectedError => 'Ocurrió un error inesperado';

  @override
  String get signUpCreateAccount => 'Crear Cuenta';

  @override
  String get signUpGetStarted => 'Regístrate para comenzar';

  @override
  String get signUpFullName => 'Nombre Completo';

  @override
  String get signUpFullNameHint => 'Alexander Pierce';

  @override
  String get signUpEmailAddress => 'Correo Electrónico';

  @override
  String get signUpEmailHint => 'alex@ejemplo.com';

  @override
  String get signUpPhoneNumber => 'Número de Teléfono';

  @override
  String get signUpPhoneHint => '+1 (555) 000-0000';

  @override
  String get signUpPassword => 'Contraseña';

  @override
  String get signUpPasswordHint => 'Crea una contraseña';

  @override
  String get signUpConfirmPassword => 'Confirmar Contraseña';

  @override
  String get signUpConfirmPasswordHint => 'Confirma tu contraseña';

  @override
  String get signUpAgreeText => 'Acepto los ';

  @override
  String get signUpTermsOfService => 'Términos de Servicio';

  @override
  String get signUpAnd => ' y la ';

  @override
  String get signUpPrivacyPolicy => 'Política de Privacidad';

  @override
  String get signUpButton => 'Crear Cuenta';

  @override
  String get signUpAlreadyAccount => '¿Ya tienes una cuenta? ';

  @override
  String get signUpSignIn => 'Iniciar Sesión';

  @override
  String get signUpFillAllFields => 'Por favor completa todos los campos';

  @override
  String get signUpPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get signUpAccountCreatedPartial =>
      '¡Cuenta creada! Pero no se pudo enviar el código de verificación. Intenta iniciar sesión.';

  @override
  String get signUpUnexpectedError => 'Ocurrió un error inesperado';

  @override
  String get forgotPasswordTitle => 'Olvidé mi Contraseña';

  @override
  String get forgotPasswordResetTitle => 'Restablecer Contraseña';

  @override
  String get forgotPasswordDesc =>
      'Ingresa tu correo registrado y te enviaremos un enlace para restablecer tu contraseña.';

  @override
  String get forgotPasswordEmailAddress => 'Correo Electrónico';

  @override
  String get forgotPasswordEmailHint => 'alex@ejemplo.com';

  @override
  String get forgotPasswordEmailEmpty => 'Por favor ingresa tu correo';

  @override
  String get forgotPasswordEmailInvalid => 'Por favor ingresa un correo válido';

  @override
  String get forgotPasswordSendButton => 'Enviar Enlace';

  @override
  String get forgotPasswordCodeSent =>
      '¡Código de verificación enviado a tu correo!';

  @override
  String get forgotPasswordUnexpectedError => 'Ocurrió un error inesperado: ';

  @override
  String get otpVerifyEmail => 'Verificar Correo';

  @override
  String get otpCodeSentTo => 'Hemos enviado un código de 6 dígitos a\n';

  @override
  String get otpVerifyButton => 'Verificar Código';

  @override
  String get otpDidntReceive => '¿No recibiste el código?';

  @override
  String otpResendIn(int seconds) {
    return 'Reenviar en ${seconds}s';
  }

  @override
  String get otpResendOtp => 'Reenviar OTP';

  @override
  String get otpEnterFull =>
      'Por favor ingresa el código completo de 6 dígitos';

  @override
  String get otpVerificationSuccessful => '¡Verificación Exitosa!';

  @override
  String get otpInvalidExpired =>
      'OTP inválido o expirado. Inténtalo de nuevo.';

  @override
  String get otpNewSent => 'Se ha enviado un nuevo OTP a tu correo';

  @override
  String get otpResendFailed => 'Error al reenviar OTP. Inténtalo más tarde.';

  @override
  String get updatePasswordTitle => 'Actualizar Contraseña';

  @override
  String get updatePasswordCreateNew => 'Crear Nueva Contraseña';

  @override
  String get updatePasswordDesc =>
      'Tu nueva contraseña debe ser diferente a las contraseñas usadas anteriormente.';

  @override
  String get updatePasswordNewLabel => 'Nueva Contraseña';

  @override
  String get updatePasswordNewHint => 'Ingresa nueva contraseña';

  @override
  String get updatePasswordConfirmLabel => 'Confirmar Nueva Contraseña';

  @override
  String get updatePasswordConfirmHint => 'Confirma la nueva contraseña';

  @override
  String get updatePasswordButton => 'Actualizar Contraseña';

  @override
  String get updatePasswordSuccess =>
      '¡Contraseña actualizada exitosamente! Por favor inicia sesión.';

  @override
  String get updatePasswordEmpty => 'Por favor ingresa una nueva contraseña';

  @override
  String get updatePasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get updatePasswordConfirmEmpty =>
      'Por favor confirma tu nueva contraseña';

  @override
  String get updatePasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get profileSetupTitle => 'Completa tu Perfil';

  @override
  String get profileSetupDesc =>
      'Revisa tus datos y agrega una foto de perfil para que los clientes puedan identificarte.';

  @override
  String get profileSetupTapToAdd =>
      'Toca para agregar / cambiar foto de perfil';

  @override
  String get profileSetupFullName => 'Nombre Completo';

  @override
  String get profileSetupFullNameHint => 'ej. Ahmed Khan';

  @override
  String get profileSetupPhoneNumber => 'Número de Teléfono';

  @override
  String get profileSetupPhoneHint => '+92 300 0000000';

  @override
  String get profileSetupSaveContinue => 'Guardar y Continuar';

  @override
  String get profileSetupNameRequired => 'Por favor ingresa tu nombre completo';

  @override
  String get profileSetupNameTooShort =>
      'El nombre debe tener al menos 3 caracteres';

  @override
  String get profileSetupPhoneRequired =>
      'Por favor ingresa tu número de teléfono';

  @override
  String get profileSetupPhoneInvalid => 'Ingresa un número de teléfono válido';

  @override
  String get profileSetupPhotoError => 'No se pudo seleccionar la foto: ';

  @override
  String get profileSetupSaveError => 'Error al guardar el perfil: ';

  @override
  String get profileSetupChoosePhoto => 'Elegir Foto';

  @override
  String get profileSetupTakePhoto => 'Tomar una foto';

  @override
  String get profileSetupChooseGallery => 'Elegir de la galería';

  @override
  String get vehicleDetailsTitle => 'Datos del Vehículo';

  @override
  String get vehicleDetailsDesc =>
      'Registra tu camión cisterna para empezar a recibir\nsolicitudes de entrega.';

  @override
  String get vehicleDetailsMake => 'Marca del Vehículo';

  @override
  String get vehicleDetailsMakeHint => 'ej. Ford, Mercedes, Isuzu';

  @override
  String get vehicleDetailsModel => 'Modelo / Variante';

  @override
  String get vehicleDetailsModelHint => 'ej. F-550 Cisterna';

  @override
  String get vehicleDetailsYear => 'Año';

  @override
  String get vehicleDetailsYearHint => '2023';

  @override
  String get vehicleDetailsLicense => 'Placa';

  @override
  String get vehicleDetailsLicenseHint => 'ABC-1234';

  @override
  String get vehicleDetailsSaveProceed => 'Guardar y Continuar';

  @override
  String get vehicleDetailsMakeRequired => 'Por favor ingresa la marca';

  @override
  String get vehicleDetailsModelRequired => 'Por favor ingresa el modelo';

  @override
  String get vehicleDetailsRequired => 'Requerido';

  @override
  String get vehicleDetailsSessionLost =>
      'Sesión perdida. Por favor inicia sesión de nuevo.';

  @override
  String get vehicleDetailsLogIn => 'Iniciar Sesión';

  @override
  String get vehicleDetailsSaveError => 'Error al guardar datos del vehículo: ';

  @override
  String get docVerificationTitle => 'Verificación de Documentos';

  @override
  String get docVerificationDesc =>
      'Sube los documentos requeridos para completar\ntu registro';

  @override
  String get docVerificationDriversLicense => 'Licencia de Conducir';

  @override
  String get docVerificationDriversLicenseDesc => 'ID gubernamental válido';

  @override
  String get docVerificationCommercialLicense => 'Licencia Comercial';

  @override
  String get docVerificationCommercialLicenseDesc =>
      'CDL o certificación equivalente';

  @override
  String get docVerificationVehicleReg => 'Registro del Vehículo';

  @override
  String get docVerificationVehicleRegDesc => 'Registro actual del vehículo';

  @override
  String get docVerificationInsurance => 'Certificado de Seguro';

  @override
  String get docVerificationInsuranceDesc => 'Seguro comercial válido';

  @override
  String get docVerificationBackground => 'Verificación de Antecedentes';

  @override
  String get docVerificationBackgroundDesc =>
      'Consentimiento para verificación de antecedentes';

  @override
  String get docVerificationUploaded => 'Subido';

  @override
  String get docVerificationUploadFile => 'Subir Archivo';

  @override
  String get docVerificationCompleteReg => 'Completar Registro';

  @override
  String get docVerificationUploadAll =>
      'Por favor sube todos los documentos requeridos para continuar';

  @override
  String docVerificationAttached(int number) {
    return '¡Documento $number adjuntado exitosamente!';
  }

  @override
  String get docVerificationFailed => 'Error al seleccionar documento: ';

  @override
  String get dashboardDelivers => 'Entregas';

  @override
  String get dashboardActive => 'Activo';

  @override
  String get dashboardOffline => 'Desconectado';

  @override
  String get dashboardReceivingOrders => 'Recibiendo Pedidos';

  @override
  String get dashboardGoOnline => 'Conectarse';

  @override
  String get dashboardFuelCapacity => 'Capacidad de Combustible';

  @override
  String get dashboardLoading => 'Cargando...';

  @override
  String get dashboardEmpty => 'Vacío';

  @override
  String get dashboardActiveDelivery => 'Entrega Activa';

  @override
  String get dashboardAvailableStatus => 'Estado Disponible';

  @override
  String get dashboardNearbyOrders => 'Pedidos Cercanos';

  @override
  String get dashboardNoActiveOrder => 'Sin pedido activo';

  @override
  String get dashboardReadyToAccept => 'Listo para aceptar pedidos';

  @override
  String get dashboardNavigate => 'Navegar';

  @override
  String get dashboardAccept => 'Aceptar';

  @override
  String get dashboardCustomer => 'Cliente';

  @override
  String get dashboardOrderNoLongerAvailable =>
      'El pedido ya no está disponible.';

  @override
  String get dashboardOrderTakenByAnother =>
      'Lo sentimos, este pedido fue aceptado por otro conductor.';

  @override
  String get dashboardOrderAccepted =>
      '¡Pedido aceptado! Toca \'Navegar\' para iniciar la entrega.';

  @override
  String get dashboardFailedUpdateStatus =>
      'Error al actualizar estado. Verifica tu conexión.';

  @override
  String get dashboardEmergencyAlert =>
      '¡Alerta de emergencia enviada! Pedido movido a cola de emergencia.';

  @override
  String get dashboardFailedEmergency => 'Error al activar emergencia: ';

  @override
  String get dashboardFailedAction => 'Error: ';

  @override
  String get dashboardCannotDialer => 'No se pudo abrir el marcador telefónico';

  @override
  String get dashboardEmergencyTitle => 'Alerta de Emergencia';

  @override
  String get dashboardEmergencyPrompt =>
      '¿Estás seguro de que quieres activar una alerta de emergencia? Esto notificará a despacho de inmediato.';

  @override
  String get dashboardEmergencyConfirm => 'Enviar Alerta';

  @override
  String get dashboardEmergencySubtitle =>
      'Mantén pulsado en caso de derrame de combustible,\nincendio o accidente.';

  @override
  String dashboardScheduledWarning(String time) {
    return 'Pedido programado. Puedes iniciar esta entrega 1 hora antes de la hora programada (Programado para: $time).';
  }

  @override
  String get dashboardContact => 'Contacto';

  @override
  String get dashboardOpenMaps => 'Abrir en Google Maps';

  @override
  String get dashboardOpenMapsError => 'No se pudo abrir Google Maps.';

  @override
  String get dashboardNoGps =>
      'No hay coordenadas GPS para este pedido todavía.';

  @override
  String get dashboardSearchingNearby => 'Buscando pedidos cercanos...';

  @override
  String get dashboardSearchingNearbyDesc =>
      'Los nuevos pedidos dentro de 25 km aparecerán aquí automáticamente.';

  @override
  String get dashboardViewAllOrders => 'Ver Todos los Pedidos';

  @override
  String get dashboardViewAllText => 'Ver Todos';

  @override
  String get dashboardStatusAvailable => 'DISPONIBLE';

  @override
  String get dashboardStatusAssigned => 'ASIGNADO';

  @override
  String get dashboardAccepting => 'Aceptando...';

  @override
  String get dashboardAcceptOrder => 'Aceptar Pedido';

  @override
  String get dashboardOfflineCardTitle => 'Actualmente estás desconectado';

  @override
  String get dashboardOfflineCardDesc =>
      'Cambia tu estado arriba a la derecha para comenzar a recibir entregas.';

  @override
  String get dashboardNoPhone =>
      'El número de teléfono del cliente no está disponible.';

  @override
  String dashboardMilesAway(String miles) {
    return 'a $miles millas de distancia';
  }

  @override
  String dashboardMetersAway(int meters) {
    return 'a $meters m de distancia';
  }

  @override
  String dashboardKmAway(String km) {
    return 'a $km km de distancia';
  }

  @override
  String dashboardOrdersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pedidos',
      one: 'pedido',
    );
    return '$count $_temp0 dentro de 25 km';
  }

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsFuelDeliveryPartner => 'Socio de Entrega de Combustible';

  @override
  String get settingsAppPreferences => 'PREFERENCIAS DE APP';

  @override
  String get settingsAppLanguage => 'Idioma de la App';

  @override
  String get settingsPushNotifications => 'Notificaciones Push';

  @override
  String get settingsAccountSupport => 'CUENTA Y SOPORTE';

  @override
  String get settingsHelpCenter => 'Centro de Ayuda';

  @override
  String get settingsPrivacyPolicy => 'Política de Privacidad';

  @override
  String get settingsLogOut => 'Cerrar Sesión';

  @override
  String get settingsLogOutFailed =>
      'Error al cerrar sesión. Inténtalo de nuevo.';

  @override
  String get settingsProfileUpdated =>
      '¡Foto de perfil actualizada exitosamente!';

  @override
  String get settingsProfileUploadFailed => 'Error al subir imagen: ';

  @override
  String get languageTitle => 'Idioma de la App';

  @override
  String get languageEnglish => 'English (US)';

  @override
  String get languageSpanish => 'Español';

  @override
  String get helpCenterTitle => 'Centro de Ayuda';

  @override
  String get helpCenterHowCanWeHelp => '¿Cómo podemos ayudarte?';

  @override
  String get helpCenterQ1 => '¿Cómo restablezco mi contraseña?';

  @override
  String get helpCenterA1 =>
      'Para restablecer tu contraseña, haz clic en \"¿Olvidaste tu contraseña?\" en la pantalla de inicio de sesión y sigue las instrucciones enviadas a tu correo.';

  @override
  String get helpCenterQ2 => '¿Cómo actualizo mi perfil?';

  @override
  String get helpCenterA2 =>
      'Ve a la pantalla de Configuración, toca tu foto de perfil para subir una nueva y gestiona tus preferencias desde allí.';

  @override
  String get helpCenterQ3 => '¿Qué hago si un pedido se retrasa?';

  @override
  String get helpCenterA3 =>
      'Si un pedido se retrasa, usa el chat interno o la notificación push para alertar al equipo de despacho o al cliente de inmediato.';

  @override
  String get helpCenterStillNeedHelp => '¿Aún necesitas ayuda?';

  @override
  String get helpCenterContactSupport => 'Contactar Soporte';

  @override
  String get helpCenterContacting => 'Contactando soporte...';

  @override
  String get privacyPolicyTitle => 'Política de Privacidad';

  @override
  String get privacyPolicy1Title => '1. Descripción General';

  @override
  String get privacyPolicy1Body =>
      '¡Bienvenido a FuelDirect Driver App! Tu privacidad es muy importante para nosotros. Esta política describe cómo recopilamos, usamos y protegemos tus datos personales cuando utilizas nuestra aplicación.';

  @override
  String get privacyPolicy2Title => '2. Información que Recopilamos';

  @override
  String get privacyPolicy2Body =>
      '• Información Personal: Nombre, correo electrónico, número de teléfono.\n• Datos de Ubicación: Recopilamos datos de ubicación precisa para coordinar las entregas de combustible de manera efectiva.\n• Información del Dispositivo: Modelo del dispositivo, sistema operativo e identificadores únicos.';

  @override
  String get privacyPolicy3Title => '3. Cómo Usamos la Información';

  @override
  String get privacyPolicy3Body =>
      'Los datos recopilados se usan para optimizar las entregas de combustible, rastrear entregas activas, proporcionar orientación en la app y gestionar resúmenes de pagos/ganancias en tu panel.';

  @override
  String get privacyPolicy4Title => '4. Compartir Datos';

  @override
  String get privacyPolicy4Body =>
      'No vendemos tus datos personales. Podemos compartirlos con socios verificados para mejorar la seguridad de las entregas o según lo requieran las autoridades legales.';

  @override
  String get privacyPolicy5Title => '5. Contáctanos';

  @override
  String get privacyPolicy5Body =>
      'Para consultas sobre nuestra política de privacidad, contáctanos en support@fueldirect.com o a través del Centro de Ayuda en tu configuración.';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatMessageHint => 'Escribe un mensaje...';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatNoMessages => 'Sin mensajes aún. ¡Inicia la conversación!';

  @override
  String chatSendError(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String chatError(String error) {
    return 'Error: $error';
  }

  @override
  String get chatToday => 'Hoy';

  @override
  String get chatYesterday => 'Ayer';

  @override
  String get chatCustomer => 'Cliente';

  @override
  String get chatNoMessagesTitle => 'Sin mensajes aún';

  @override
  String get chatNoMessagesSubtitle => 'Inicia la conversación abajo';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsEmpty => 'No hay notificaciones aún.';

  @override
  String get notificationsEmptyDesc =>
      'Aquí verás actualizaciones de pedidos y alertas';

  @override
  String get orderHistoryTitle => 'Historial de Pedidos';

  @override
  String get orderHistoryEmpty => 'Sin pedidos completados aún';

  @override
  String get orderHistoryCompleted => 'Completado';

  @override
  String get orderHistoryDelivered => 'Entregado';

  @override
  String get earningsTitle => 'Ganancias';

  @override
  String get earningsToday => 'Hoy';

  @override
  String get earningsWeek => 'Esta Semana';

  @override
  String get earningsMonth => 'Este Mes';

  @override
  String get earningsTotal => 'Total Ganado';

  @override
  String get earningsDeliveries => 'Entregas';

  @override
  String get earningsRating => 'Calificación';

  @override
  String get assignedTitle => 'Pedidos Asignados';

  @override
  String get assignedTabAvailable => 'Disponible';

  @override
  String get assignedTabAssigned => 'Asignado';

  @override
  String get assignedTabScheduled => 'Programado';

  @override
  String get assignedTabEmergency => 'Emergencia';

  @override
  String get assignedTabDelivered => 'Entregado';

  @override
  String get assignedOrderAccepted =>
      '¡Pedido aceptado! Toca para iniciar la entrega.';

  @override
  String get assignedFailedLoad => 'Error al cargar pedidos';

  @override
  String get assignedGoOnlineDesc =>
      'Conéctate desde el Panel para ver los pedidos disponibles.';

  @override
  String get assignedNoNearby => 'No se encontraron pedidos cercanos';

  @override
  String get assignedNoAssignedOrders => 'No hay pedidos asignados todavía.';

  @override
  String get assignedNoScheduledOrders => 'No hay pedidos programados todavía.';

  @override
  String get assignedNoEmergencyOrders =>
      'No hay pedidos de emergencia todavía.';

  @override
  String get assignedNoDeliveredOrders => 'No hay pedidos entregados todavía.';

  @override
  String get assignedWaitingGps => 'Esperando ubicación GPS…';

  @override
  String get assignedShowingNearbyFallback =>
      'Mostrando pedidos dentro de 25 km de tu ubicación (reserva).';

  @override
  String assignedShowingNearbyConfigured(int count) {
    return 'Mostrando pedidos dentro de $count área(s) de servicio configurada(s).';
  }

  @override
  String assignedSchedTime(String time) {
    return 'PROG: $time';
  }

  @override
  String get assignedSched => 'PROG';

  @override
  String get assignedNew => 'NUEVO';

  @override
  String assignedFuelTypeFormat(String qty, String type) {
    return '$qty Gal $type';
  }

  @override
  String get assignedTagAvailable => 'DISPONIBLE';

  @override
  String get assignedTagEmergency => 'EMERGENCIA';

  @override
  String get assignedTagAssigned => 'ASIGNADO';

  @override
  String get assignedTagDelivered => 'ENTREGADO';

  @override
  String get assignedTagCompleted => 'COMPLETADO';

  @override
  String get assignedFuelType => 'Tipo de Combustible';

  @override
  String get assignedGo => 'IR';

  @override
  String get assignedDetails => 'Detalles';

  @override
  String get navGpsDisabled => 'El GPS está Desactivado';

  @override
  String get navGpsDisabledDesc =>
      'Por favor, activa los Servicios de Ubicación en la configuración de tu dispositivo.';

  @override
  String get navPermissionDenied => 'Permiso de Ubicación Denegado';

  @override
  String get navPermissionDeniedDesc =>
      'FuelDirect necesita acceso a la ubicación para navegar.';

  @override
  String get navOpenSettings => 'Abrir Configuración';

  @override
  String get navCalculating => 'Calc...';

  @override
  String navMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String navMiles(String miles) {
    return '$miles mi';
  }

  @override
  String get common_na => 'N/D';

  @override
  String get navCustomerNotes => 'NOTAS DEL CLIENTE';

  @override
  String get navNoInstructions =>
      'No se proporcionaron instrucciones especiales.';

  @override
  String get navArrivedAtSource => 'Llegado al Origen';

  @override
  String get navReleaseOrder => 'Liberar Pedido';

  @override
  String get navReleasing => 'Liberando…';

  @override
  String get navReleasePromptTitle => '¿Liberar Pedido?';

  @override
  String get navReleasePromptDesc =>
      '¿Estás seguro de que deseas liberar este pedido?\n\nSe devolverá al grupo disponible y se reasignará a otro conductor.';

  @override
  String get navRelease => 'Liberar';

  @override
  String get navReleaseSuccess => 'Pedido liberado. Será reasignado.';

  @override
  String navReleaseFailed(String error) {
    return 'Error al liberar el pedido: $error';
  }

  @override
  String get common_goBack => 'Volver';

  @override
  String get proofPhotoUploaded => 'Foto subida correctamente ✅';

  @override
  String proofUploadFailed(String error) {
    return 'Error al subir: $error';
  }

  @override
  String get proofTitle => 'Prueba de Entrega';

  @override
  String get proofDispensingComplete => 'Despacho Completado';

  @override
  String get proofDispensingCompleteDesc =>
      'Captura el medidor de combustible e ingresa los galones entregados para completar el pedido.';

  @override
  String get proofMeterGaugePhoto => 'FOTO DEL MEDIDOR';

  @override
  String get proofRetakePhoto => 'Volver a tomar foto';

  @override
  String get proofManualEntry => 'ENTRADA MANUAL';

  @override
  String get proofGallons => 'GALONES';

  @override
  String get proofEstimatedTotal => 'Total Estimado';

  @override
  String proofPricePerGal(String price) {
    return 'a $price / gal';
  }

  @override
  String get proofMeterPhotoUploaded => 'Foto del medidor subida';

  @override
  String get proofUploadingPhoto => 'Subiendo foto…';

  @override
  String get proofTakeMeterPhoto => 'Tomar foto del medidor (obligatorio)';

  @override
  String proofGallonsEntered(String qty) {
    return 'Galones ingresados: $qty';
  }

  @override
  String get proofEnterGallons => 'Ingresar galones entregados (obligatorio)';

  @override
  String get proofSupervisorReviewDesc =>
      'Las entradas manuales se marcan para la revisión del supervisor. Asegúrate de que la foto muestre claramente los dígitos del medidor que coincidan con la cantidad ingresada.';

  @override
  String get proofWaitUpload =>
      'Por favor, espera a que la foto termine de subirse.';

  @override
  String get proofTakePhotoFirst =>
      'Por favor, toma una foto del medidor de combustible primero.';

  @override
  String get proofEnterGallonsFirst =>
      'Por favor, ingresa los galones entregados.';

  @override
  String get proofCompleteOrder => 'Completar Pedido';

  @override
  String get proofWaitingImage => 'Esperando imagen...';

  @override
  String get proofPhotoSaved => 'Foto Guardada';

  @override
  String get proofTapToTakePhoto => 'Toca para tomar foto del medidor';

  @override
  String get proofDigitsVisible =>
      'Asegúrate de que los dígitos finales sean claramente visibles';

  @override
  String get proofCaptureFailed => 'Error al capturar. Inténtalo de nuevo.';

  @override
  String get proofDebugCamera => 'CÁMARA DE DEPURACIÓN';

  @override
  String get historyTitle => 'Historial de Entregas';

  @override
  String get historyNoDeliveries => 'Aún no hay entregas completadas.';

  @override
  String get historyCompleted => 'Completado';

  @override
  String historyError(String error) {
    return 'Error: $error';
  }

  @override
  String historyFuelQty(String fuelType, String qty) {
    return '$fuelType ($qty Gal)';
  }

  @override
  String get earningsYesterday => 'Ayer';

  @override
  String get monthJan => 'Ene';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Abr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Ago';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dic';

  @override
  String get pickupTitle => 'Recogida de Combustible';

  @override
  String get pickupDepotVerification => 'Verificación del Depósito';

  @override
  String get pickupInProgress => 'En Progreso';

  @override
  String pickupArrivedAt(String time) {
    return 'Llegada al origen: $time';
  }

  @override
  String get pickupOrderDetails => 'DETALLES DEL PEDIDO';

  @override
  String pickupOrderNumber(String id) {
    return 'Pedido #$id';
  }

  @override
  String get pickupNoAddress => 'Dirección de entrega no disponible';

  @override
  String get pickupGeofenceConfirmed => 'GEOCERCA CONFIRMADA';

  @override
  String get pickupSealTitle => 'Número de Verificación del Sello del Tanque';

  @override
  String get pickupSealHint =>
      'Ingrese solo números — sin letras ni caracteres especiales.';

  @override
  String get pickupSealEg => 'ej. 12345678';

  @override
  String get pickupSealVerificationNote =>
      'La verificación garantiza la integridad de la carga de combustible durante el transporte.';

  @override
  String get pickupFuelType => 'Tipo de Combustible';

  @override
  String get pickupExpectedVolume => 'Volumen Esperado';

  @override
  String get pickupTolerance => 'TOLERANCIA: ±0.5%';

  @override
  String pickupVolumeGal(String volume) {
    return '$volume GAL';
  }

  @override
  String get pickupConfirmNote =>
      'Al hacer clic en confirmar, verifica que ha inspeccionado las válvulas de seguridad y registrado el volumen correcto.';

  @override
  String get pickupConfirmStartTrip => 'Confirmar e Iniciar Viaje';

  @override
  String get pickupEnterSeal =>
      'Por favor ingrese el número del sello del tanque';

  @override
  String get pickupSealMinLength =>
      'El número de sello debe tener al menos 4 dígitos';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_confirm => 'Confirmar';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_close => 'Cerrar';

  @override
  String get common_retry => 'Reintentar';

  @override
  String get common_ok => 'Aceptar';

  @override
  String get common_yes => 'Sí';

  @override
  String get common_no => 'No';

  @override
  String get common_loading => 'Cargando...';

  @override
  String get common_error => 'Ocurrió un error';

  @override
  String get common_success => 'Éxito';

  @override
  String get common_back => 'Atrás';

  @override
  String get common_next => 'Siguiente';

  @override
  String get common_submit => 'Enviar';

  @override
  String get common_done => 'Listo';

  @override
  String get rtdLocating => 'Localizando dirección de entrega…';

  @override
  String get rtdDestMissing => 'Ubicación de entrega no disponible';

  @override
  String rtdAddressLabel(String address) {
    return 'Dirección: $address';
  }

  @override
  String get rtdNoAddress => 'No hay dirección registrada para este pedido.';

  @override
  String get rtdRetry => 'Reintentar';

  @override
  String get rtdDeliveringTo => 'Entregando a';

  @override
  String get rtdEtaLabel => 'ETA';

  @override
  String get rtdTimeLabel => 'TIEMPO';

  @override
  String get rtdDistLabel => 'DIST';

  @override
  String rtdMin(String mins) {
    return '$mins min';
  }

  @override
  String rtdMiles(String dist) {
    return '$dist millas';
  }

  @override
  String get rtdCustomerLabel => 'Cliente';

  @override
  String get rtdArrivedConfirm => '¡Llegué! Confirmar llegada';

  @override
  String get rtdArrivedAt => 'Llegó al cliente';

  @override
  String get rtdNoPhone => 'No hay número de teléfono disponible.';

  @override
  String get rtdCallError =>
      'No se pudo iniciar el marcador telefónico. Verifique los permisos.';

  @override
  String rtdArrivalFailed(String error) {
    return 'Error al actualizar la llegada: $error';
  }

  @override
  String get rtdGpsDisabled => 'El GPS está desactivado';

  @override
  String get rtdGpsDisabledDesc =>
      'Por favor, active los Servicios de Ubicación en la configuración de su dispositivo.';

  @override
  String get rtdOpenGps => 'Abrir Configuración de GPS';

  @override
  String get rtdPermDenied => 'Permiso de Ubicación Denegado';

  @override
  String get rtdPermDeniedDesc =>
      'FuelDirect necesita acceso a la ubicación para navegar. Toque abajo para abrir la Configuración.';

  @override
  String get rtdOpenSettings => 'Abrir Configuración';

  @override
  String get rtdGoBack => 'Volver';

  @override
  String get orderSummaryTitle => 'Resumen del Pedido';

  @override
  String get orderSummaryDeliveryDetails => 'DETALLES DE ENTREGA';

  @override
  String get orderSummaryOrderId => 'ID del Pedido';

  @override
  String get orderSummaryFuelType => 'Tipo de Combustible';

  @override
  String get orderSummaryQuantity => 'Cantidad';

  @override
  String orderSummaryQuantityVal(String qty) {
    return '$qty galones';
  }

  @override
  String get orderSummaryDeliveryAddress => 'Dirección de Entrega';

  @override
  String get orderSummaryScheduled => 'Programado';

  @override
  String get orderSummaryPricingBreakdown => 'DESGLOSE DE PRECIOS';

  @override
  String get orderSummaryFuelCost => 'Costo de Combustible';

  @override
  String get orderSummaryDeliveryFee => 'Tarifa de Entrega';

  @override
  String get orderSummaryServiceFee => 'Tarifa de Servicio';

  @override
  String get orderSummaryTotal => 'Total';

  @override
  String get orderSummaryStatus => 'ESTADO';

  @override
  String get orderSummaryCurrentStatus => 'Estado Actual';

  @override
  String get orderSummaryPaymentMethod => 'Método de Pago';

  @override
  String get orderSummarySpecialInstructions => 'INSTRUCCIONES ESPECIALES';

  @override
  String get orderSummaryNoInstructions =>
      'No se proporcionaron instrucciones especiales.';

  @override
  String get orderSummaryUnavailable => 'N/D';

  @override
  String get orderSummaryNotSet => 'No establecido';

  @override
  String get orderSummaryFuelDetails => 'Detalles del Combustible';

  @override
  String get orderSummaryPricePerGallon => 'Precio por Galón';

  @override
  String orderSummaryPriceVal(String price) {
    return '$price';
  }

  @override
  String get orderSummaryFuelTotal => 'Total de Combustible';

  @override
  String orderSummaryFuelTotalVal(String total) {
    return '$total';
  }

  @override
  String get orderSummaryVehicle => 'Vehículo';

  @override
  String get orderSummaryAddress => 'Dirección';

  @override
  String get orderSummaryScheduledTime => 'Hora Programada';

  @override
  String get orderSummaryNotScheduled => 'No Programado';

  @override
  String get orderSummaryPaymentSummary => 'Resumen de Pago';

  @override
  String get orderSummaryTotalDueToday => 'Total a Pagar Hoy';

  @override
  String get orderSummaryDefaultPayment => 'Pago predeterminado';

  @override
  String get orderSummaryChange => 'Cambiar';

  @override
  String get orderSummaryLoginRequired =>
      'Por favor inicie sesión para realizar un pedido';

  @override
  String orderSummaryPlaceError(String error) {
    return 'Error al realizar el pedido: $error';
  }

  @override
  String orderSummaryPlaceOrderButton(String total) {
    return 'Realizar Pedido - $total';
  }

  @override
  String get orderSummaryRegular => 'Regular';

  @override
  String get orderSummaryPlaceholderVehicle => 'Tesla Model 3';

  @override
  String get orderSummaryPlaceholderVehicleSub => 'ABC 1234';

  @override
  String get orderSummaryPlaceholderAddress => 'Inicio';

  @override
  String get orderSummaryPlaceholderAddressSub =>
      '123 Main Street, San Francisco, CA 94102';

  @override
  String get orderHistoryNoOrders => 'No se encontraron pedidos completados.';

  @override
  String orderHistoryError(String error) {
    return 'Error al cargar el historial: $error';
  }

  @override
  String get orderHistoryLoading => 'Cargando...';

  @override
  String get orderHistorySearchHint => 'Buscar por ubicación...';

  @override
  String get orderHistoryPlaceholderFuel => 'Combustible';

  @override
  String orderHistoryCardQty(String fuelType, String qty) {
    return '$fuelType • $qty Gal';
  }

  @override
  String get orderDetailsTitle => 'Detalles del Pedido';

  @override
  String orderDetailsOrderNumber(String id) {
    return 'Pedido #$id';
  }

  @override
  String get orderDetailsStatus => 'Estado';

  @override
  String get orderDetailsFuelType => 'Tipo de Combustible';

  @override
  String get orderDetailsQuantity => 'Cantidad';

  @override
  String get orderDetailsAddress => 'Dirección de Entrega';

  @override
  String get orderDetailsTotal => 'Total';

  @override
  String get orderDetailsScheduled => 'Programado';

  @override
  String get orderDetailsPaymentMethod => 'Método de Pago';

  @override
  String get orderDetailsCustomer => 'Cliente';

  @override
  String get orderDetailsSpecialInstructions => 'Instrucciones Especiales';

  @override
  String get orderDetailsNoInstructions => 'Ninguna';

  @override
  String orderDetailsGallons(String qty) {
    return '$qty Gal';
  }

  @override
  String get orderDetailsNoContactInfo => 'Sin información de contacto';

  @override
  String get orderDetailsChatUnavailable =>
      'Información del cliente no disponible para chat.';

  @override
  String get orderDetailsOrderTotal => 'TOTAL DEL PEDIDO';

  @override
  String get orderDetailsCompletedCheck => 'Completado ✓';

  @override
  String get orderDetailsPending => 'Pendiente';

  @override
  String get orderDetailsScheduledDeliveryHeader => 'ENTREGA PROGRAMADA';

  @override
  String get orderDetailsCustomerNotesHeader => 'NOTAS DEL CLIENTE';

  @override
  String get orderDetailsNoInstructionsDesc =>
      'No se proporcionaron instrucciones especiales.';

  @override
  String get orderDetailsDeliveryLocationHeader => 'UBICACIÓN DE ENTREGA';

  @override
  String get orderDetailsNavigate => 'Navegar';

  @override
  String get orderDetailsOrderTimelineHeader => 'CRONOLOGÍA DEL PEDIDO';

  @override
  String get orderDetailsTimelinePlaced => 'Pedido Realizado';

  @override
  String get orderDetailsTimelineAccepted => 'Pedido Aceptado';

  @override
  String get orderDetailsTimelineArrived => 'Conductor Llegó';

  @override
  String get orderDetailsTimelineCompleted => 'Pedido Completado';

  @override
  String get orderDetailsScheduledError =>
      'Este pedido está programado para más tarde. Solo puede iniciarlo 1 hora antes de la hora programada.';

  @override
  String get orderDetailsJourneyStarted => '¡Viaje de entrega iniciado! 🚀';

  @override
  String get orderDetailsJourneyStartedBody =>
      'Dirigiéndose a la ubicación de origen para la recogida.';

  @override
  String get orderDetailsStartJourney => 'Iniciar viaje de entrega';

  @override
  String get orderDetailsEmergencyFlagged =>
      '¡Pedido marcado como Emergencia! 🚨';

  @override
  String get orderDetailsAssignedFlagged =>
      'Pedido movido de nuevo a Asignado.';

  @override
  String get orderDetailsEmergencyTooltip => 'Marcar como Emergencia';

  @override
  String get notificationsMarkRead => 'Marcar todas como leídas';

  @override
  String get safetyTitle => 'Cumplimiento de Seguridad';

  @override
  String get safetyCheckAll => 'Marcar todos los elementos';

  @override
  String get safetyConfirm => 'Confirmar Control de Seguridad';

  @override
  String get safetyItem1 => 'Verificar la presión del tanque de combustible';

  @override
  String get safetyItem2 => 'Inspeccionar las conexiones de la manguera';

  @override
  String get safetyItem3 =>
      'Verificar que el tipo de combustible coincida con el pedido';

  @override
  String get safetyItem4 => 'Revisar la válvula de cierre de emergencia';

  @override
  String get safetyItem5 => 'Confirmar que el EPP esté colocado';

  @override
  String get safetyAllRequired =>
      'Por favor complete todas las comprobaciones de seguridad antes de confirmar.';

  @override
  String get selectLocationTitle => 'Confirmar Ubicación';

  @override
  String get selectLocationSearchHint => 'Buscar una ubicación diferente..';

  @override
  String get selectLocationCurrentSelection => 'SELECCIÓN ACTUAL';

  @override
  String get selectLocationEstimatedWait => 'ESPERA ESTIMADA';

  @override
  String get selectLocationServiceFee => 'TARIFA DE SERVICIO';

  @override
  String get selectLocationConfirmOrder => 'Confirmar Pedido';

  @override
  String get selectLocationPlaceholderAddress => '123 Innovation Drive';

  @override
  String get selectLocationPlaceholderCity => 'San Francisco, CA 94105';

  @override
  String get selectLocationPlaceholderWait => '15-20 mins';

  @override
  String get selectLocationPlaceholderFee => '\$4.99';

  @override
  String get selectLocationPlaceholderFullAddress =>
      '123 Innovation Drive, San Francisco, CA 94105';

  @override
  String get deliveryCompleteTitle => 'Entrega Completada';

  @override
  String get deliveryCompleteSubtitle => '¡Pedido entregado con éxito!';

  @override
  String get deliveryCompleteBackHome => 'Volver al Inicio';

  @override
  String get deliveryCompleteRating => 'Calificar esta entrega';

  @override
  String get scheduleDeliveryTitle => 'Programar Entrega';

  @override
  String get scheduleDeliveryDate => 'Seleccionar Fecha';

  @override
  String get scheduleDeliveryTime => 'Seleccionar Hora';

  @override
  String get scheduleDeliveryConfirm => 'Confirmar Programación';

  @override
  String get scheduleDeliveryNoSlots => 'No hay horarios disponibles.';

  @override
  String get notificationsMarkAllReadSuccess =>
      'Todas las notificaciones marcadas como leídas';

  @override
  String get notificationsFilterAll => 'Todas';

  @override
  String get notificationsFilterUnread => 'No leídas';

  @override
  String get notificationsFilterOrder => 'Pedidos';

  @override
  String notificationsNoFilterNotifications(String filter) {
    return 'Sin notificaciones de tipo $filter';
  }

  @override
  String get notificationsDefaultTitle => 'Notificación';

  @override
  String get earningsOverviewTitle => 'Resumen de Ganancias';

  @override
  String get earningsWalletBalance => 'SALDO DE BILLETERA';

  @override
  String get earningsTodayCaps => 'HOY';

  @override
  String get earningsActionRequired => 'Acción Requerida';

  @override
  String get earningsStripeLinkBankDesc =>
      'Por favor vincule su cuenta bancaria a través de Stripe para habilitar pagos.';

  @override
  String get earningsLinkBankAccount => 'Vincular Cuenta Bancaria';

  @override
  String get earningsWeeklyPerformance => 'RENDIMIENTO SEMANAL';

  @override
  String get earningsThisWeek => 'Esta semana';

  @override
  String get earningsTotalDeliveriesCaps => 'TOTAL DE ENTREGAS';

  @override
  String get earningsRecentDeliveries => 'Entregas Recientes';

  @override
  String get earningsSeeAll => 'Ver todo';

  @override
  String get earningsNoDeliveriesToday => 'Aún no hay entregas hoy.';

  @override
  String get earningsCashOutNow => 'Cobrar Ahora';

  @override
  String get earningsCashOut => 'Retirar Fondos';

  @override
  String earningsAvailableAmount(String amount) {
    return 'Disponible: $amount';
  }

  @override
  String get earningsAmountHint => 'Ingrese monto';

  @override
  String get earningsConfirm => 'Confirmar';

  @override
  String get earningsEnterValidAmount => 'Por favor ingrese un monto válido';

  @override
  String get earningsInsufficientBalance => 'Saldo insuficiente';

  @override
  String get earningsStripeErrorInsufficient =>
      'Error de Stripe: Fondos disponibles insuficientes en su cuenta.';

  @override
  String get earningsOnboardingLinkError =>
      'No se pudo abrir el enlace de incorporación.';

  @override
  String get earningsGeneratingLinkFailed =>
      'Error al generar el enlace de incorporación.';

  @override
  String get fuelTitle => 'Combustible';

  @override
  String get fuelTypes => 'Tipos de Combustible';

  @override
  String get fuelPetrol => 'Gasolina';

  @override
  String get fuelDiesel => 'Diésel';

  @override
  String get fuelOctanePremium => 'Octano 95 Premium';

  @override
  String get fuelUltraLowSulfur => 'Ultra Bajo Azufre';

  @override
  String get fuelQuantity => 'Cantidad';

  @override
  String get fuelApproxRange => 'Alcance aprox: 400 millas';

  @override
  String get fuelFullTank => 'Tanque Lleno';

  @override
  String get fuelConfirmOrder => 'Confirmar Pedido';

  @override
  String deliveryProofCameraError(String error) {
    return 'Error de cámara: $error';
  }

  @override
  String deliveryProofInitError(String error) {
    return 'Error de inicio: $error';
  }

  @override
  String meterPreviewUploadFailed(String error) {
    return 'Error al subir: $error';
  }

  @override
  String meterVerificationCameraError(String error) {
    return 'Error de cámara: $error';
  }

  @override
  String get meterVerificationCaptureFailed =>
      'Error al tomar la foto. Por favor intente de nuevo.';

  @override
  String orderDetailsError(String error) {
    return 'Error: $error';
  }

  @override
  String get orderTrackingGoBack => 'Volver';

  @override
  String get paymentCouponHint => 'Ingresar código de cupón';

  @override
  String get paymentAddNoteHint => 'Agregar nota';

  @override
  String get paymentButtonLabel => 'Aplicar';

  @override
  String get paymentHaveCoupon => '¿Tiene un cupón?';

  @override
  String get rtdCustomer => 'Cliente';

  @override
  String get safetyNoPhone => 'No hay número de teléfono disponible.';

  @override
  String get safetyCallError => 'No se pudo abrir el marcador telefónico.';

  @override
  String get safetySaving => 'Guardando…';

  @override
  String safetyError(String error) {
    return 'Error: $error';
  }
}
