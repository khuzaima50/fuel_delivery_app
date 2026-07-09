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
      'New orders within 25 km will appear here automatically.';

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
    return '$count $_temp0 within 25 km';
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
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

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
}
