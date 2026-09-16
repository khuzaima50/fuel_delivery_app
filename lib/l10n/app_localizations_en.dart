// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FuelDirect';

  @override
  String get splashTagline =>
      'Get premium quality fuel delivered directly to your vehicle, wherever you are';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingTitle1 => 'Welcome to ';

  @override
  String get onboardingTitleSpan1 => 'FUEL DIRECT';

  @override
  String get onboardingDesc1 =>
      'Deliver fuel safely and efficiently\nto customers across the city';

  @override
  String get onboardingTitle2 => 'Real-time Navigation';

  @override
  String get onboardingDesc2 =>
      'Get turn-by-turn directions and live\ntraffic updates for every delivery';

  @override
  String get onboardingTitle3 => 'Safety First';

  @override
  String get onboardingDesc3 =>
      'Complete safety checklists and track all\ndeliveries with precision';

  @override
  String get onboardingTitle4 => 'Earn More';

  @override
  String get onboardingDesc4 =>
      'Track your earnings, deliveries, and\nperformance in real-time';

  @override
  String get loginWelcomeBack => 'Welcome Back';

  @override
  String get loginSignInToContinue => 'Sign in to continue';

  @override
  String get loginEmailAddress => 'Email Address';

  @override
  String get loginEmailHint => 'alex@example.com';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginPasswordHint => 'Enter your password';

  @override
  String get loginForgotPassword => 'Forgot Password?';

  @override
  String get loginSignIn => 'Sign In';

  @override
  String get loginNoAccount => 'Don\'t have an account? ';

  @override
  String get loginSignUp => 'Sign Up';

  @override
  String get loginEmptyFields => 'Please enter email and password';

  @override
  String get loginCustomerAccountError =>
      'This is a customer account. Please use the Customer App.';

  @override
  String get loginFailedVerification =>
      'Failed to send verification code. Please try again.';

  @override
  String get loginUnexpectedError => 'An unexpected error occurred';

  @override
  String get signUpCreateAccount => 'Create Account';

  @override
  String get signUpGetStarted => 'Sign up to get started';

  @override
  String get signUpFullName => 'Full Name';

  @override
  String get signUpFullNameHint => 'Alexander Pierce';

  @override
  String get signUpEmailAddress => 'Email Address';

  @override
  String get signUpEmailHint => 'alex@example.com';

  @override
  String get signUpPhoneNumber => 'Phone Number';

  @override
  String get signUpPhoneHint => '+1 (555) 000-0000';

  @override
  String get signUpPassword => 'Password';

  @override
  String get signUpPasswordHint => 'Create a password';

  @override
  String get signUpConfirmPassword => 'Confirm Password';

  @override
  String get signUpConfirmPasswordHint => 'Confirm your password';

  @override
  String get signUpAgreeText => 'I agree to the ';

  @override
  String get signUpTermsOfService => 'Terms of Service';

  @override
  String get signUpAnd => ' and ';

  @override
  String get signUpPrivacyPolicy => 'Privacy Policy';

  @override
  String get signUpButton => 'Create Account';

  @override
  String get signUpAlreadyAccount => 'Already have an account? ';

  @override
  String get signUpSignIn => 'Sign In';

  @override
  String get signUpFillAllFields => 'Please fill all fields';

  @override
  String get signUpPasswordMismatch => 'Passwords do not match';

  @override
  String get signUpAccountCreatedPartial =>
      'Account created! But failed to send verification code. Please try to log in.';

  @override
  String get signUpUnexpectedError => 'An unexpected error occurred';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordResetTitle => 'Reset Password';

  @override
  String get forgotPasswordDesc =>
      'Enter your registered email address and we will send you a link to reset your password.';

  @override
  String get forgotPasswordEmailAddress => 'Email Address';

  @override
  String get forgotPasswordEmailHint => 'alex@example.com';

  @override
  String get forgotPasswordEmailEmpty => 'Please enter your email';

  @override
  String get forgotPasswordEmailInvalid => 'Please enter a valid email address';

  @override
  String get forgotPasswordSendButton => 'Send Reset Link';

  @override
  String get forgotPasswordCodeSent => 'Verification code sent to your email!';

  @override
  String get forgotPasswordUnexpectedError => 'An unexpected error occurred: ';

  @override
  String get otpVerifyEmail => 'Verify Email';

  @override
  String get otpCodeSentTo => 'We have sent a 6-digit code to\n';

  @override
  String get otpVerifyButton => 'Verify Code';

  @override
  String get otpDidntReceive => 'Didn\'t receive the code?';

  @override
  String otpResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get otpResendOtp => 'Resend OTP';

  @override
  String get otpEnterFull => 'Please enter the full 6-digit code';

  @override
  String get otpVerificationSuccessful => 'Verification Successful!';

  @override
  String get otpInvalidExpired => 'Invalid or expired OTP. Please try again.';

  @override
  String get otpNewSent => 'A new OTP has been sent to your email';

  @override
  String get otpResendFailed => 'Failed to resend OTP. Please try again later.';

  @override
  String get updatePasswordTitle => 'Update Password';

  @override
  String get updatePasswordCreateNew => 'Create New Password';

  @override
  String get updatePasswordDesc =>
      'Your new password must be different from previous used passwords.';

  @override
  String get updatePasswordNewLabel => 'New Password';

  @override
  String get updatePasswordNewHint => 'Enter new password';

  @override
  String get updatePasswordConfirmLabel => 'Confirm New Password';

  @override
  String get updatePasswordConfirmHint => 'Confirm new password';

  @override
  String get updatePasswordButton => 'Update Password';

  @override
  String get updatePasswordSuccess =>
      'Password updated successfully! Please log in.';

  @override
  String get updatePasswordEmpty => 'Please enter a new password';

  @override
  String get updatePasswordTooShort =>
      'Password must be at least 6 characters long';

  @override
  String get updatePasswordConfirmEmpty => 'Please confirm your new password';

  @override
  String get updatePasswordMismatch => 'Passwords do not match';

  @override
  String get profileSetupTitle => 'Complete Your Profile';

  @override
  String get profileSetupDesc =>
      'Review your details and add a profile photo so customers can identify you.';

  @override
  String get profileSetupTapToAdd => 'Tap to add / change profile photo';

  @override
  String get profileSetupFullName => 'Full Name';

  @override
  String get profileSetupFullNameHint => 'e.g. Ahmed Khan';

  @override
  String get profileSetupPhoneNumber => 'Phone Number';

  @override
  String get profileSetupPhoneHint => '+92 300 0000000';

  @override
  String get profileSetupSaveContinue => 'Save & Continue';

  @override
  String get profileSetupNameRequired => 'Please enter your full name';

  @override
  String get profileSetupNameTooShort => 'Name must be at least 3 characters';

  @override
  String get profileSetupPhoneRequired => 'Please enter your phone number';

  @override
  String get profileSetupPhoneInvalid => 'Enter a valid phone number';

  @override
  String get profileSetupPhotoError => 'Could not select photo: ';

  @override
  String get profileSetupSaveError => 'Failed to save profile: ';

  @override
  String get profileSetupChoosePhoto => 'Choose Photo';

  @override
  String get profileSetupTakePhoto => 'Take a photo';

  @override
  String get profileSetupChooseGallery => 'Choose from gallery';

  @override
  String get vehicleDetailsTitle => 'Vehicle Details';

  @override
  String get vehicleDetailsDesc =>
      'Register your fuel tanker to start receiving\ndelivery requests.';

  @override
  String get vehicleDetailsMake => 'Vehicle Make';

  @override
  String get vehicleDetailsMakeHint => 'e.g. Ford, Mercedes, Isuzu';

  @override
  String get vehicleDetailsModel => 'Model / Variant';

  @override
  String get vehicleDetailsModelHint => 'e.g. F-550 Fuel Tanker';

  @override
  String get vehicleDetailsYear => 'Year';

  @override
  String get vehicleDetailsYearHint => '2023';

  @override
  String get vehicleDetailsLicense => 'License Plate';

  @override
  String get vehicleDetailsLicenseHint => 'ABC-1234';

  @override
  String get vehicleDetailsSaveProceed => 'Save & Proceed';

  @override
  String get vehicleDetailsMakeRequired => 'Please enter make';

  @override
  String get vehicleDetailsModelRequired => 'Please enter model';

  @override
  String get vehicleDetailsRequired => 'Required';

  @override
  String get vehicleDetailsSessionLost => 'Session lost. Please log in again.';

  @override
  String get vehicleDetailsLogIn => 'Log In';

  @override
  String get vehicleDetailsSaveError => 'Failed to save vehicle details: ';

  @override
  String get docVerificationTitle => 'Document Verification';

  @override
  String get docVerificationDesc =>
      'Upload required documents to complete\nregistration';

  @override
  String get docVerificationDriversLicense => 'Driver\'s License';

  @override
  String get docVerificationDriversLicenseDesc => 'Valid government-issued ID';

  @override
  String get docVerificationCommercialLicense => 'Commercial License';

  @override
  String get docVerificationCommercialLicenseDesc =>
      'CDL or equivalent certification';

  @override
  String get docVerificationVehicleReg => 'Vehicle Registration';

  @override
  String get docVerificationVehicleRegDesc => 'Current vehicle registration';

  @override
  String get docVerificationInsurance => 'Insurance Certificate';

  @override
  String get docVerificationInsuranceDesc => 'Valid commercial insurance';

  @override
  String get docVerificationBackground => 'Background Check';

  @override
  String get docVerificationBackgroundDesc =>
      'Consent for background verification';

  @override
  String get docVerificationUploaded => 'Uploaded';

  @override
  String get docVerificationUploadFile => 'Upload File';

  @override
  String get docVerificationCompleteReg => 'Complete Registration';

  @override
  String get docVerificationUploadAll =>
      'Please upload all required documents to continue';

  @override
  String docVerificationAttached(int number) {
    return 'Document $number attached successfully!';
  }

  @override
  String get docVerificationFailed => 'Failed to select document: ';

  @override
  String get dashboardDelivers => 'Delivers';

  @override
  String get dashboardActive => 'Active';

  @override
  String get dashboardOffline => 'Offline';

  @override
  String get dashboardReceivingOrders => 'Receiving Orders';

  @override
  String get dashboardGoOnline => 'Go Online';

  @override
  String get dashboardFuelCapacity => 'Fuel Capacity';

  @override
  String get dashboardLoading => 'Loading...';

  @override
  String get dashboardEmpty => 'Empty';

  @override
  String get dashboardActiveDelivery => 'Active Delivery';

  @override
  String get dashboardAvailableStatus => 'Available Status';

  @override
  String get dashboardNearbyOrders => 'Nearby Orders';

  @override
  String get dashboardNoActiveOrder => 'No active order';

  @override
  String get dashboardReadyToAccept => 'Ready to accept orders';

  @override
  String get dashboardNavigate => 'Navigate';

  @override
  String get dashboardAccept => 'Accept';

  @override
  String get dashboardCustomer => 'Customer';

  @override
  String get dashboardOrderNoLongerAvailable => 'Order no longer available.';

  @override
  String get dashboardOrderTakenByAnother =>
      'Sorry, this order was just accepted by another driver.';

  @override
  String get dashboardOrderAccepted =>
      'Order accepted! Tap \'Navigate\' to start delivery.';

  @override
  String get dashboardFailedUpdateStatus =>
      'Failed to update status. Please check your connection.';

  @override
  String get dashboardEmergencyAlert =>
      'Emergency alert sent! Order moved to Emergency queue.';

  @override
  String get dashboardFailedEmergency => 'Failed to trigger emergency: ';

  @override
  String get dashboardFailedAction => 'Failed: ';

  @override
  String get dashboardCannotDialer => 'Could not launch phone dialer';

  @override
  String get dashboardEmergencyTitle => 'Emergency Alert';

  @override
  String get dashboardEmergencyPrompt =>
      'Are you sure you want to trigger an emergency alert? This will notify dispatch immediately.';

  @override
  String get dashboardEmergencyConfirm => 'Send Alert';

  @override
  String get dashboardEmergencySubtitle =>
      'Tap and hold in case of fuel spill,\nfire, or accident.';

  @override
  String dashboardScheduledWarning(String time) {
    return 'Scheduled order. You can start this delivery 1 hour before the scheduled time (Scheduled for: $time).';
  }

  @override
  String get dashboardContact => 'Contact';

  @override
  String get dashboardOpenMaps => 'Open in Google Maps';

  @override
  String get dashboardOpenMapsError => 'Could not open Google Maps.';

  @override
  String get dashboardNoGps => 'No GPS coordinates for this order yet.';

  @override
  String get dashboardSearchingNearby => 'Searching for nearby orders...';

  @override
  String get dashboardSearchingNearbyDesc =>
      'New orders within 15 miles will appear here automatically.';

  @override
  String get dashboardViewAllOrders => 'View All Orders';

  @override
  String get dashboardViewAllText => 'View All';

  @override
  String get dashboardStatusAvailable => 'AVAILABLE';

  @override
  String get dashboardStatusAssigned => 'ASSIGNED';

  @override
  String get dashboardAccepting => 'Accepting...';

  @override
  String get dashboardAcceptOrder => 'Accept Order';

  @override
  String get dashboardOfflineCardTitle => 'You are currently offline';

  @override
  String get dashboardOfflineCardDesc =>
      'Toggle your status top-right to start receiving deliveries.';

  @override
  String get dashboardNoPhone => 'Customer phone number not available.';

  @override
  String dashboardMilesAway(String miles) {
    return '$miles miles away';
  }

  @override
  String dashboardMetersAway(int meters) {
    return '$meters m away';
  }

  @override
  String dashboardKmAway(String km) {
    return '$km km away';
  }

  @override
  String dashboardOrdersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'orders',
      one: 'order',
    );
    return '$count $_temp0 within 15 miles';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsFuelDeliveryPartner => 'Fuel Delivery Partner';

  @override
  String get settingsAppPreferences => 'APP PREFERENCES';

  @override
  String get settingsAppLanguage => 'App Language';

  @override
  String get settingsPushNotifications => 'Push Notifications';

  @override
  String get settingsAccountSupport => 'ACCOUNT & SUPPORT';

  @override
  String get settingsHelpCenter => 'Help Center';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsLogOut => 'Log Out';

  @override
  String get settingsLogOutFailed => 'Failed to log out. Please try again.';

  @override
  String get settingsProfileUpdated => 'Profile picture updated successfully!';

  @override
  String get settingsProfileUploadFailed => 'Failed to upload image: ';

  @override
  String get languageTitle => 'App Language';

  @override
  String get languageEnglish => 'English (US)';

  @override
  String get languageSpanish => 'Español';

  @override
  String get helpCenterTitle => 'Help Center';

  @override
  String get helpCenterHowCanWeHelp => 'How can we help you?';

  @override
  String get helpCenterQ1 => 'How do I reset my password?';

  @override
  String get helpCenterA1 =>
      'To reset your password, click on \"Forgot Password\" on the login screen and follow the instructions sent to your email.';

  @override
  String get helpCenterQ2 => 'How do I update my profile?';

  @override
  String get helpCenterA2 =>
      'Go to the Settings screen, tap on your profile picture to upload a new one, and manage your preferences there.';

  @override
  String get helpCenterQ3 => 'What to do if an order is delayed?';

  @override
  String get helpCenterA3 =>
      'If an order is delayed, please use the in-app chat or push notification to alert the dispatch team or customer immediately.';

  @override
  String get helpCenterStillNeedHelp => 'Still need help?';

  @override
  String get helpCenterContactSupport => 'Contact Support';

  @override
  String get helpCenterContacting => 'Contacting support...';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicy1Title => '1. Overview';

  @override
  String get privacyPolicy1Body =>
      'Welcome to FuelDirect Driver App! Your privacy is very important to us. This policy outlines how we collect, use, and protect your personal data when you use our application.';

  @override
  String get privacyPolicy2Title => '2. Information We Collect';

  @override
  String get privacyPolicy2Body =>
      '• Personal Information: Name, email address, phone number.\n• Location Data: We collect precise location data to coordinate fuel deliveries effectively.\n• Device Information: Device model, operating system, and unique identifiers.';

  @override
  String get privacyPolicy3Title => '3. How We Use Information';

  @override
  String get privacyPolicy3Body =>
      'Data collected is used to optimize fuel drop-offs, track active deliveries, providing in-app guidance, and managing payments/earnings summaries in your dashboard.';

  @override
  String get privacyPolicy4Title => '4. Data Sharing';

  @override
  String get privacyPolicy4Body =>
      'We do not sell your personal data. We may share it with verified partners to enhance delivery safety or as required by legal authorities.';

  @override
  String get privacyPolicy5Title => '5. Contact Us';

  @override
  String get privacyPolicy5Body =>
      'For inquiries regarding our privacy policy, please contact us at support@fueldirect.com or through the Help Center in your settings.';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatMessageHint => 'Type a message...';

  @override
  String get chatSend => 'Send';

  @override
  String get chatNoMessages => 'No messages yet. Start the conversation!';

  @override
  String chatSendError(String error) {
    return 'Failed to send: $error';
  }

  @override
  String chatError(String error) {
    return 'Error: $error';
  }

  @override
  String get chatToday => 'Today';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatCustomer => 'Customer';

  @override
  String get chatNoMessagesTitle => 'No messages yet';

  @override
  String get chatNoMessagesSubtitle => 'Start the conversation below';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationsEmptyDesc =>
      'You\'ll see your order updates and alerts here';

  @override
  String get orderHistoryTitle => 'Order History';

  @override
  String get orderHistoryEmpty => 'No completed orders yet';

  @override
  String get orderHistoryCompleted => 'Completed';

  @override
  String get orderHistoryDelivered => 'Delivered';

  @override
  String get earningsTitle => 'Earnings';

  @override
  String get earningsToday => 'Today';

  @override
  String get earningsWeek => 'This Week';

  @override
  String get earningsMonth => 'This Month';

  @override
  String get earningsTotal => 'Total Earned';

  @override
  String get earningsDeliveries => 'Deliveries';

  @override
  String get earningsRating => 'Rating';

  @override
  String get assignedTitle => 'Assigned Orders';

  @override
  String get assignedTabAvailable => 'Available';

  @override
  String get assignedTabAssigned => 'Assigned';

  @override
  String get assignedTabScheduled => 'Scheduled';

  @override
  String get assignedTabEmergency => 'Emergency';

  @override
  String get assignedTabDelivered => 'Delivered';

  @override
  String get assignedOrderAccepted =>
      'Order accepted! Tap it to start delivery.';

  @override
  String get assignedFailedLoad => 'Failed to load orders';

  @override
  String get assignedGoOnlineDesc =>
      'Go online from the Dashboard to see available orders.';

  @override
  String get assignedNoNearby => 'No nearby orders found';

  @override
  String get assignedNoAssignedOrders => 'No assigned orders yet.';

  @override
  String get assignedNoScheduledOrders => 'No scheduled orders yet.';

  @override
  String get assignedNoEmergencyOrders => 'No emergency orders yet.';

  @override
  String get assignedNoDeliveredOrders => 'No delivered orders yet.';

  @override
  String get assignedWaitingGps => 'Waiting for GPS location…';

  @override
  String get assignedShowingNearbyFallback =>
      'Showing orders within 15 miles of your location (fallback).';

  @override
  String assignedShowingNearbyConfigured(int count) {
    return 'Showing orders within $count configured service area(s).';
  }

  @override
  String assignedSchedTime(String time) {
    return 'SCHED: $time';
  }

  @override
  String get assignedSched => 'SCHED';

  @override
  String get assignedNew => 'NEW';

  @override
  String assignedFuelTypeFormat(String qty, String type) {
    return '$qty Gal $type';
  }

  @override
  String get assignedTagAvailable => 'AVAILABLE';

  @override
  String get assignedTagEmergency => 'EMERGENCY';

  @override
  String get assignedTagAssigned => 'ASSIGNED';

  @override
  String get assignedTagDelivered => 'DELIVERED';

  @override
  String get assignedTagCompleted => 'COMPLETED';

  @override
  String get assignedFuelType => 'Fuel Type';

  @override
  String get assignedGo => 'GO';

  @override
  String get assignedDetails => 'Details';

  @override
  String get navGpsDisabled => 'GPS is Disabled';

  @override
  String get navGpsDisabledDesc =>
      'Please turn on Location Services in your device settings.';

  @override
  String get navPermissionDenied => 'Location Permission Denied';

  @override
  String get navPermissionDeniedDesc =>
      'FuelDirect needs location access to navigate.';

  @override
  String get navOpenSettings => 'Open Settings';

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
  String get common_na => 'N/A';

  @override
  String get navCustomerNotes => 'CUSTOMER NOTES';

  @override
  String get navNoInstructions => 'No special instructions provided.';

  @override
  String get navArrivedAtSource => 'Arrived at Source';

  @override
  String get navReleaseOrder => 'Release Order';

  @override
  String get navReleasing => 'Releasing…';

  @override
  String get navReleasePromptTitle => 'Release Order?';

  @override
  String get navReleasePromptDesc =>
      'Are you sure you want to release this order?\n\nIt will be returned to the available pool and reassigned to another driver.';

  @override
  String get navRelease => 'Release';

  @override
  String get navReleaseSuccess => 'Order released. It will be reassigned.';

  @override
  String navReleaseFailed(String error) {
    return 'Failed to release order: $error';
  }

  @override
  String get common_goBack => 'Go Back';

  @override
  String get proofPhotoUploaded => 'Photo uploaded successfully ✅';

  @override
  String proofUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get proofTitle => 'Delivery Proof';

  @override
  String get proofDispensingComplete => 'Dispensing Complete';

  @override
  String get proofDispensingCompleteDesc =>
      'Capture the fuel meter and enter the delivered gallons to complete the order.';

  @override
  String get proofMeterGaugePhoto => 'METER GAUGE PHOTO';

  @override
  String get proofRetakePhoto => 'Retake Photo';

  @override
  String get proofManualEntry => 'MANUAL ENTRY';

  @override
  String get proofGallons => 'GALLONS';

  @override
  String get proofEstimatedTotal => 'Estimated Total';

  @override
  String proofPricePerGal(String price) {
    return 'at $price / gal';
  }

  @override
  String get proofMeterPhotoUploaded => 'Meter photo uploaded';

  @override
  String get proofUploadingPhoto => 'Uploading photo…';

  @override
  String get proofTakeMeterPhoto => 'Take meter gauge photo (required)';

  @override
  String proofGallonsEntered(String qty) {
    return 'Gallons entered: $qty';
  }

  @override
  String get proofEnterGallons => 'Enter delivered gallons (required)';

  @override
  String get proofSupervisorReviewDesc =>
      'Manual entries are flagged for supervisor review. Ensure the photo clearly shows the meter digits matching the entered quantity.';

  @override
  String get proofWaitUpload =>
      'Please wait for the photo to finish uploading.';

  @override
  String get proofTakePhotoFirst =>
      'Please take a photo of the fuel meter first.';

  @override
  String get proofEnterGallonsFirst => 'Please enter the delivered gallons.';

  @override
  String get proofCompleteOrder => 'Complete Order';

  @override
  String get proofWaitingImage => 'Waiting for image...';

  @override
  String get proofPhotoSaved => 'Photo Saved';

  @override
  String get proofTapToTakePhoto => 'Tap to take meter photo';

  @override
  String get proofDigitsVisible =>
      'Ensure the final digits are clearly visible';

  @override
  String get proofCaptureFailed => 'Capture failed. Try again.';

  @override
  String get proofDebugCamera => 'DEBUG CAMERA';

  @override
  String get historyTitle => 'Delivery History';

  @override
  String get historyNoDeliveries => 'No completed deliveries yet.';

  @override
  String get historyCompleted => 'Completed';

  @override
  String historyError(String error) {
    return 'Error: $error';
  }

  @override
  String historyFuelQty(String fuelType, String qty) {
    return '$fuelType ($qty Gal)';
  }

  @override
  String get earningsYesterday => 'Yesterday';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get pickupTitle => 'Fuel Pickup';

  @override
  String get pickupDepotVerification => 'Depot Verification';

  @override
  String get pickupInProgress => 'In Progress';

  @override
  String pickupArrivedAt(String time) {
    return 'Arrived at Source: $time';
  }

  @override
  String get pickupOrderDetails => 'ORDER DETAILS';

  @override
  String pickupOrderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String get pickupNoAddress => 'Delivery address not available';

  @override
  String get pickupGeofenceConfirmed => 'GEOFENCE CONFIRMED';

  @override
  String get pickupSealTitle => 'Tank Seal Check Number';

  @override
  String get pickupSealHint =>
      'Enter numbers only — no letters or special characters.';

  @override
  String get pickupSealEg => 'e.g. 12345678';

  @override
  String get pickupSealVerificationNote =>
      'Verification ensures the integrity of the fuel cargo during transport.';

  @override
  String get pickupFuelType => 'Fuel Type';

  @override
  String get pickupExpectedVolume => 'Expected Volume';

  @override
  String get pickupTolerance => 'TOLERANCE: ±0.5%';

  @override
  String pickupVolumeGal(String volume) {
    return '$volume GAL';
  }

  @override
  String get pickupConfirmNote =>
      'By clicking confirm, you verify that you have inspected the safety valves and recorded the correct volume.';

  @override
  String get pickupConfirmStartTrip => 'Confirm & Start Trip';

  @override
  String get pickupEnterSeal => 'Please enter the tank seal number';

  @override
  String get pickupSealMinLength => 'Seal number must be at least 4 digits';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_save => 'Save';

  @override
  String get common_close => 'Close';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_ok => 'OK';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_error => 'An error occurred';

  @override
  String get common_success => 'Success';

  @override
  String get common_back => 'Back';

  @override
  String get common_next => 'Next';

  @override
  String get common_submit => 'Submit';

  @override
  String get common_done => 'Done';

  @override
  String get rtdLocating => 'Locating delivery address…';

  @override
  String get rtdDestMissing => 'Delivery location not available';

  @override
  String rtdAddressLabel(String address) {
    return 'Address: $address';
  }

  @override
  String get rtdNoAddress => 'No address on record for this order.';

  @override
  String get rtdRetry => 'Retry';

  @override
  String get rtdDeliveringTo => 'Delivering to';

  @override
  String get rtdEtaLabel => 'ETA';

  @override
  String get rtdTimeLabel => 'TIME';

  @override
  String get rtdDistLabel => 'DIST';

  @override
  String rtdMin(String mins) {
    return '$mins min';
  }

  @override
  String rtdMiles(String dist) {
    return '$dist miles';
  }

  @override
  String get rtdCustomerLabel => 'Customer';

  @override
  String get rtdArrivedConfirm => 'Arrived! Confirm Arrival';

  @override
  String get rtdArrivedAt => 'Arrived at Customer';

  @override
  String get rtdNoPhone => 'No phone number available.';

  @override
  String get rtdCallError =>
      'Could not launch phone dialer. Please check permissions.';

  @override
  String rtdArrivalFailed(String error) {
    return 'Failed to update arrival: $error';
  }

  @override
  String get rtdGpsDisabled => 'GPS is disabled';

  @override
  String get rtdGpsDisabledDesc =>
      'Please turn on Location Services in your device settings.';

  @override
  String get rtdOpenGps => 'Open GPS Settings';

  @override
  String get rtdPermDenied => 'Location Permission Denied';

  @override
  String get rtdPermDeniedDesc =>
      'FuelDirect needs location access to navigate. Tap below to open Settings.';

  @override
  String get rtdOpenSettings => 'Open Settings';

  @override
  String get rtdGoBack => 'Go Back';

  @override
  String get orderSummaryTitle => 'Order Summary';

  @override
  String get orderSummaryDeliveryDetails => 'DELIVERY DETAILS';

  @override
  String get orderSummaryOrderId => 'Order ID';

  @override
  String get orderSummaryFuelType => 'Fuel Type';

  @override
  String get orderSummaryQuantity => 'Quantity';

  @override
  String orderSummaryQuantityVal(String qty) {
    return '$qty gallons';
  }

  @override
  String get orderSummaryDeliveryAddress => 'Delivery Address';

  @override
  String get orderSummaryScheduled => 'Scheduled';

  @override
  String get orderSummaryPricingBreakdown => 'PRICING BREAKDOWN';

  @override
  String get orderSummaryFuelCost => 'Fuel Cost';

  @override
  String get orderSummaryDeliveryFee => 'Delivery Fee';

  @override
  String get orderSummaryServiceFee => 'Service Fee';

  @override
  String get orderSummaryTotal => 'Total';

  @override
  String get orderSummaryStatus => 'STATUS';

  @override
  String get orderSummaryCurrentStatus => 'Current Status';

  @override
  String get orderSummaryPaymentMethod => 'Payment Method';

  @override
  String get orderSummarySpecialInstructions => 'SPECIAL INSTRUCTIONS';

  @override
  String get orderSummaryNoInstructions => 'No special instructions provided.';

  @override
  String get orderSummaryUnavailable => 'N/A';

  @override
  String get orderSummaryNotSet => 'Not set';

  @override
  String get orderSummaryFuelDetails => 'Fuel Details';

  @override
  String get orderSummaryPricePerGallon => 'Price per Gallon';

  @override
  String orderSummaryPriceVal(String price) {
    return '$price';
  }

  @override
  String get orderSummaryFuelTotal => 'Fuel Total';

  @override
  String orderSummaryFuelTotalVal(String total) {
    return '$total';
  }

  @override
  String get orderSummaryVehicle => 'Vehicle';

  @override
  String get orderSummaryAddress => 'Address';

  @override
  String get orderSummaryScheduledTime => 'Scheduled Time';

  @override
  String get orderSummaryNotScheduled => 'Not Scheduled';

  @override
  String get orderSummaryPaymentSummary => 'Payment Summary';

  @override
  String get orderSummaryTotalDueToday => 'Total Due Today';

  @override
  String get orderSummaryDefaultPayment => 'Default payment';

  @override
  String get orderSummaryChange => 'Change';

  @override
  String get orderSummaryLoginRequired => 'Please log in to place an order';

  @override
  String orderSummaryPlaceError(String error) {
    return 'Error placing order: $error';
  }

  @override
  String orderSummaryPlaceOrderButton(String total) {
    return 'Place Order - $total';
  }

  @override
  String get orderSummaryRegular => 'Regular';

  @override
  String get orderSummaryPlaceholderVehicle => 'Tesla Model 3';

  @override
  String get orderSummaryPlaceholderVehicleSub => 'ABC 1234';

  @override
  String get orderSummaryPlaceholderAddress => 'Home';

  @override
  String get orderSummaryPlaceholderAddressSub =>
      '123 Main Street, San Francisco, CA 94102';

  @override
  String get orderHistoryNoOrders => 'No completed orders found.';

  @override
  String orderHistoryError(String error) {
    return 'Error loading history: $error';
  }

  @override
  String get orderHistoryLoading => 'Loading...';

  @override
  String get orderHistorySearchHint => 'Search by location...';

  @override
  String get orderHistoryPlaceholderFuel => 'Fuel';

  @override
  String orderHistoryCardQty(String fuelType, String qty) {
    return '$fuelType • $qty Gal';
  }

  @override
  String get orderDetailsTitle => 'Order Details';

  @override
  String orderDetailsOrderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String get orderDetailsStatus => 'Status';

  @override
  String get orderDetailsFuelType => 'Fuel Type';

  @override
  String get orderDetailsQuantity => 'Quantity';

  @override
  String get orderDetailsAddress => 'Delivery Address';

  @override
  String get orderDetailsTotal => 'Total';

  @override
  String get orderDetailsScheduled => 'Scheduled';

  @override
  String get orderDetailsPaymentMethod => 'Payment Method';

  @override
  String get orderDetailsCustomer => 'Customer';

  @override
  String get orderDetailsSpecialInstructions => 'Special Instructions';

  @override
  String get orderDetailsNoInstructions => 'None';

  @override
  String orderDetailsGallons(String qty) {
    return '$qty Gal';
  }

  @override
  String get orderDetailsNoContactInfo => 'No contact info';

  @override
  String get orderDetailsChatUnavailable =>
      'Customer information not available for chat.';

  @override
  String get orderDetailsOrderTotal => 'ORDER TOTAL';

  @override
  String get orderDetailsCompletedCheck => 'Completed ✓';

  @override
  String get orderDetailsPending => 'Pending';

  @override
  String get orderDetailsScheduledDeliveryHeader => 'SCHEDULED DELIVERY';

  @override
  String get orderDetailsCustomerNotesHeader => 'CUSTOMER NOTES';

  @override
  String get orderDetailsNoInstructionsDesc =>
      'No special instructions provided.';

  @override
  String get orderDetailsDeliveryLocationHeader => 'DELIVERY LOCATION';

  @override
  String get orderDetailsNavigate => 'Navigate';

  @override
  String get orderDetailsOrderTimelineHeader => 'ORDER TIMELINE';

  @override
  String get orderDetailsTimelinePlaced => 'Order Placed';

  @override
  String get orderDetailsTimelineAccepted => 'Order Accepted';

  @override
  String get orderDetailsTimelineArrived => 'Driver Arrived';

  @override
  String get orderDetailsTimelineCompleted => 'Order Completed';

  @override
  String get orderDetailsScheduledError =>
      'This order is scheduled for later. You can only start it 1 hour before the scheduled time.';

  @override
  String get orderDetailsJourneyStarted => 'Delivery Journey Started! 🚀';

  @override
  String get orderDetailsJourneyStartedBody =>
      'Heading to source location for pickup.';

  @override
  String get orderDetailsStartJourney => 'Start Delivery Journey';

  @override
  String get orderDetailsEmergencyFlagged => 'Order flagged as Emergency! 🚨';

  @override
  String get orderDetailsAssignedFlagged => 'Order moved back to Assigned.';

  @override
  String get orderDetailsEmergencyTooltip => 'Flag as Emergency';

  @override
  String get notificationsMarkRead => 'Mark all as read';

  @override
  String get safetyTitle => 'Safety Compliance';

  @override
  String get safetyCheckAll => 'Check All Items';

  @override
  String get safetyConfirm => 'Confirm Safety Check';

  @override
  String get safetyItem1 => 'Check fuel tank pressure';

  @override
  String get safetyItem2 => 'Inspect hose connections';

  @override
  String get safetyItem3 => 'Verify fuel type matches order';

  @override
  String get safetyItem4 => 'Check emergency shutoff valve';

  @override
  String get safetyItem5 => 'Confirm PPE is on';

  @override
  String get safetyAllRequired =>
      'Please complete all safety checks before confirming.';

  @override
  String get selectLocationTitle => 'Confirm Location';

  @override
  String get selectLocationSearchHint => 'Search for a different location..';

  @override
  String get selectLocationCurrentSelection => 'CURRENT SELECTION';

  @override
  String get selectLocationEstimatedWait => 'ESTIMATED WAIT';

  @override
  String get selectLocationServiceFee => 'SERVICE FEE';

  @override
  String get selectLocationConfirmOrder => 'Confirm Order';

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
  String get deliveryCompleteTitle => 'Delivery Complete';

  @override
  String get deliveryCompleteSubtitle => 'Order successfully delivered!';

  @override
  String get deliveryCompleteBackHome => 'Back to Home';

  @override
  String get deliveryCompleteRating => 'Rate this delivery';

  @override
  String get scheduleDeliveryTitle => 'Schedule Delivery';

  @override
  String get scheduleDeliveryDate => 'Select Date';

  @override
  String get scheduleDeliveryTime => 'Select Time';

  @override
  String get scheduleDeliveryConfirm => 'Confirm Schedule';

  @override
  String get scheduleDeliveryNoSlots => 'No available time slots.';

  @override
  String get notificationsMarkAllReadSuccess =>
      'All notifications marked as read';

  @override
  String get notificationsFilterAll => 'All';

  @override
  String get notificationsFilterUnread => 'Unread';

  @override
  String get notificationsFilterOrder => 'Order';

  @override
  String notificationsNoFilterNotifications(String filter) {
    return 'No $filter notifications';
  }

  @override
  String get notificationsDefaultTitle => 'Notification';

  @override
  String get earningsOverviewTitle => 'Earnings Overview';

  @override
  String get earningsWalletBalance => 'WALLET BALANCE';

  @override
  String get earningsTodayCaps => 'TODAY';

  @override
  String get earningsActionRequired => 'Action Required';

  @override
  String get earningsStripeLinkBankDesc =>
      'Please link your bank account via Stripe to enable payouts.';

  @override
  String get earningsLinkBankAccount => 'Link Bank Account';

  @override
  String get earningsWeeklyPerformance => 'WEEKLY PERFORMANCE';

  @override
  String get earningsThisWeek => 'This week';

  @override
  String get earningsTotalDeliveriesCaps => 'TOTAL DELIVERIES';

  @override
  String get earningsRecentDeliveries => 'Recent Deliveries';

  @override
  String get earningsSeeAll => 'See all';

  @override
  String get earningsNoDeliveriesToday => 'No deliveries today yet.';

  @override
  String get earningsCashOutNow => 'Cash Out Now';

  @override
  String get earningsCashOut => 'Cash Out';

  @override
  String earningsAvailableAmount(String amount) {
    return 'Available: $amount';
  }

  @override
  String get earningsAmountHint => 'Enter amount';

  @override
  String get earningsConfirm => 'Confirm';

  @override
  String get earningsEnterValidAmount => 'Please enter a valid amount';

  @override
  String get earningsInsufficientBalance => 'Insufficient balance';

  @override
  String get earningsStripeErrorInsufficient =>
      'Stripe Error: Insufficient available funds in your account.';

  @override
  String get earningsOnboardingLinkError => 'Could not open onboarding link.';

  @override
  String get earningsGeneratingLinkFailed =>
      'Generating onboarding link failed.';

  @override
  String get fuelTitle => 'Fuel';

  @override
  String get fuelTypes => 'Fuel Types';

  @override
  String get fuelPetrol => 'Petrol';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelOctanePremium => 'Octane 95 Premium';

  @override
  String get fuelUltraLowSulfur => 'Ultra-Low Sulfur';

  @override
  String get fuelQuantity => 'Quantity';

  @override
  String get fuelApproxRange => 'Approx. range: 400 miles';

  @override
  String get fuelFullTank => 'Full Tank';

  @override
  String get fuelConfirmOrder => 'Confirm Order';

  @override
  String deliveryProofCameraError(String error) {
    return 'Camera error: $error';
  }

  @override
  String deliveryProofInitError(String error) {
    return 'Init error: $error';
  }

  @override
  String meterPreviewUploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String meterVerificationCameraError(String error) {
    return 'Camera error: $error';
  }

  @override
  String get meterVerificationCaptureFailed =>
      'Failed to take photo. Please try again.';

  @override
  String orderDetailsError(String error) {
    return 'Error: $error';
  }

  @override
  String get orderTrackingGoBack => 'Go Back';

  @override
  String get paymentCouponHint => 'Enter Coupon Code';

  @override
  String get paymentAddNoteHint => 'Add Note';

  @override
  String get paymentButtonLabel => 'Apply';

  @override
  String get paymentHaveCoupon => 'Have a Coupon?';

  @override
  String get rtdCustomer => 'Customer';

  @override
  String get safetyNoPhone => 'No phone number available.';

  @override
  String get safetyCallError => 'Could not launch phone dialer.';

  @override
  String get safetySaving => 'Saving…';

  @override
  String safetyError(String error) {
    return 'Error: $error';
  }
}
