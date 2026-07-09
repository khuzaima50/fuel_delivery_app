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
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsEmpty => 'Sin notificaciones aún';

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
}
