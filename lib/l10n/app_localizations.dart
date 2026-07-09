import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FuelDirect'**
  String get appName;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Get premium quality fuel delivered directly to your vehicle, wherever you are'**
  String get splashTagline;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to '**
  String get onboardingTitle1;

  /// No description provided for @onboardingTitleSpan1.
  ///
  /// In en, this message translates to:
  /// **'FUEL DIRECT'**
  String get onboardingTitleSpan1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Deliver fuel safely and efficiently\nto customers across the city'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Real-time Navigation'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Get turn-by-turn directions and live\ntraffic updates for every delivery'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Safety First'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Complete safety checklists and track all\ndeliveries with precision'**
  String get onboardingDesc3;

  /// No description provided for @onboardingTitle4.
  ///
  /// In en, this message translates to:
  /// **'Earn More'**
  String get onboardingTitle4;

  /// No description provided for @onboardingDesc4.
  ///
  /// In en, this message translates to:
  /// **'Track your earnings, deliveries, and\nperformance in real-time'**
  String get onboardingDesc4;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSignInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSignInToContinue;

  /// No description provided for @loginEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get loginEmailAddress;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'alex@example.com'**
  String get loginEmailHint;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordHint;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignIn;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get loginNoAccount;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get loginSignUp;

  /// No description provided for @loginEmptyFields.
  ///
  /// In en, this message translates to:
  /// **'Please enter email and password'**
  String get loginEmptyFields;

  /// No description provided for @loginFailedVerification.
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code. Please try again.'**
  String get loginFailedVerification;

  /// No description provided for @loginUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get loginUnexpectedError;

  /// No description provided for @signUpCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpCreateAccount;

  /// No description provided for @signUpGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started'**
  String get signUpGetStarted;

  /// No description provided for @signUpFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get signUpFullName;

  /// No description provided for @signUpFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Alexander Pierce'**
  String get signUpFullNameHint;

  /// No description provided for @signUpEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get signUpEmailAddress;

  /// No description provided for @signUpEmailHint.
  ///
  /// In en, this message translates to:
  /// **'alex@example.com'**
  String get signUpEmailHint;

  /// No description provided for @signUpPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get signUpPhoneNumber;

  /// No description provided for @signUpPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+1 (555) 000-0000'**
  String get signUpPhoneHint;

  /// No description provided for @signUpPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signUpPassword;

  /// No description provided for @signUpPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get signUpPasswordHint;

  /// No description provided for @signUpConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signUpConfirmPassword;

  /// No description provided for @signUpConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get signUpConfirmPasswordHint;

  /// No description provided for @signUpAgreeText.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get signUpAgreeText;

  /// No description provided for @signUpTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get signUpTermsOfService;

  /// No description provided for @signUpAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get signUpAnd;

  /// No description provided for @signUpPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get signUpPrivacyPolicy;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpButton;

  /// No description provided for @signUpAlreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get signUpAlreadyAccount;

  /// No description provided for @signUpSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signUpSignIn;

  /// No description provided for @signUpFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get signUpFillAllFields;

  /// No description provided for @signUpPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signUpPasswordMismatch;

  /// No description provided for @signUpAccountCreatedPartial.
  ///
  /// In en, this message translates to:
  /// **'Account created! But failed to send verification code. Please try to log in.'**
  String get signUpAccountCreatedPartial;

  /// No description provided for @signUpUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get signUpUnexpectedError;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordResetTitle;

  /// No description provided for @forgotPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email address and we will send you a link to reset your password.'**
  String get forgotPasswordDesc;

  /// No description provided for @forgotPasswordEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get forgotPasswordEmailAddress;

  /// No description provided for @forgotPasswordEmailHint.
  ///
  /// In en, this message translates to:
  /// **'alex@example.com'**
  String get forgotPasswordEmailHint;

  /// No description provided for @forgotPasswordEmailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get forgotPasswordEmailEmpty;

  /// No description provided for @forgotPasswordEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get forgotPasswordEmailInvalid;

  /// No description provided for @forgotPasswordSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get forgotPasswordSendButton;

  /// No description provided for @forgotPasswordCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your email!'**
  String get forgotPasswordCodeSent;

  /// No description provided for @forgotPasswordUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: '**
  String get forgotPasswordUnexpectedError;

  /// No description provided for @otpVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get otpVerifyEmail;

  /// No description provided for @otpCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We have sent a 6-digit code to\n'**
  String get otpCodeSentTo;

  /// No description provided for @otpVerifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get otpVerifyButton;

  /// No description provided for @otpDidntReceive.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get otpDidntReceive;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String otpResendIn(int seconds);

  /// No description provided for @otpResendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get otpResendOtp;

  /// No description provided for @otpEnterFull.
  ///
  /// In en, this message translates to:
  /// **'Please enter the full 6-digit code'**
  String get otpEnterFull;

  /// No description provided for @otpVerificationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Verification Successful!'**
  String get otpVerificationSuccessful;

  /// No description provided for @otpInvalidExpired.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired OTP. Please try again.'**
  String get otpInvalidExpired;

  /// No description provided for @otpNewSent.
  ///
  /// In en, this message translates to:
  /// **'A new OTP has been sent to your email'**
  String get otpNewSent;

  /// No description provided for @otpResendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP. Please try again later.'**
  String get otpResendFailed;

  /// No description provided for @updatePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePasswordTitle;

  /// No description provided for @updatePasswordCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get updatePasswordCreateNew;

  /// No description provided for @updatePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from previous used passwords.'**
  String get updatePasswordDesc;

  /// No description provided for @updatePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get updatePasswordNewLabel;

  /// No description provided for @updatePasswordNewHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get updatePasswordNewHint;

  /// No description provided for @updatePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get updatePasswordConfirmLabel;

  /// No description provided for @updatePasswordConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get updatePasswordConfirmHint;

  /// No description provided for @updatePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePasswordButton;

  /// No description provided for @updatePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully! Please log in.'**
  String get updatePasswordSuccess;

  /// No description provided for @updatePasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get updatePasswordEmpty;

  /// No description provided for @updatePasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get updatePasswordTooShort;

  /// No description provided for @updatePasswordConfirmEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get updatePasswordConfirmEmpty;

  /// No description provided for @updatePasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get updatePasswordMismatch;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupDesc.
  ///
  /// In en, this message translates to:
  /// **'Review your details and add a profile photo so customers can identify you.'**
  String get profileSetupDesc;

  /// No description provided for @profileSetupTapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add / change profile photo'**
  String get profileSetupTapToAdd;

  /// No description provided for @profileSetupFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileSetupFullName;

  /// No description provided for @profileSetupFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmed Khan'**
  String get profileSetupFullNameHint;

  /// No description provided for @profileSetupPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profileSetupPhoneNumber;

  /// No description provided for @profileSetupPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+92 300 0000000'**
  String get profileSetupPhoneHint;

  /// No description provided for @profileSetupSaveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get profileSetupSaveContinue;

  /// No description provided for @profileSetupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get profileSetupNameRequired;

  /// No description provided for @profileSetupNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get profileSetupNameTooShort;

  /// No description provided for @profileSetupPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get profileSetupPhoneRequired;

  /// No description provided for @profileSetupPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get profileSetupPhoneInvalid;

  /// No description provided for @profileSetupPhotoError.
  ///
  /// In en, this message translates to:
  /// **'Could not select photo: '**
  String get profileSetupPhotoError;

  /// No description provided for @profileSetupSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile: '**
  String get profileSetupSaveError;

  /// No description provided for @profileSetupChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get profileSetupChoosePhoto;

  /// No description provided for @profileSetupTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profileSetupTakePhoto;

  /// No description provided for @profileSetupChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get profileSetupChooseGallery;

  /// No description provided for @vehicleDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details'**
  String get vehicleDetailsTitle;

  /// No description provided for @vehicleDetailsDesc.
  ///
  /// In en, this message translates to:
  /// **'Register your fuel tanker to start receiving\ndelivery requests.'**
  String get vehicleDetailsDesc;

  /// No description provided for @vehicleDetailsMake.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Make'**
  String get vehicleDetailsMake;

  /// No description provided for @vehicleDetailsMakeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ford, Mercedes, Isuzu'**
  String get vehicleDetailsMakeHint;

  /// No description provided for @vehicleDetailsModel.
  ///
  /// In en, this message translates to:
  /// **'Model / Variant'**
  String get vehicleDetailsModel;

  /// No description provided for @vehicleDetailsModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. F-550 Fuel Tanker'**
  String get vehicleDetailsModelHint;

  /// No description provided for @vehicleDetailsYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get vehicleDetailsYear;

  /// No description provided for @vehicleDetailsYearHint.
  ///
  /// In en, this message translates to:
  /// **'2023'**
  String get vehicleDetailsYearHint;

  /// No description provided for @vehicleDetailsLicense.
  ///
  /// In en, this message translates to:
  /// **'License Plate'**
  String get vehicleDetailsLicense;

  /// No description provided for @vehicleDetailsLicenseHint.
  ///
  /// In en, this message translates to:
  /// **'ABC-1234'**
  String get vehicleDetailsLicenseHint;

  /// No description provided for @vehicleDetailsSaveProceed.
  ///
  /// In en, this message translates to:
  /// **'Save & Proceed'**
  String get vehicleDetailsSaveProceed;

  /// No description provided for @vehicleDetailsMakeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter make'**
  String get vehicleDetailsMakeRequired;

  /// No description provided for @vehicleDetailsModelRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter model'**
  String get vehicleDetailsModelRequired;

  /// No description provided for @vehicleDetailsRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get vehicleDetailsRequired;

  /// No description provided for @vehicleDetailsSessionLost.
  ///
  /// In en, this message translates to:
  /// **'Session lost. Please log in again.'**
  String get vehicleDetailsSessionLost;

  /// No description provided for @vehicleDetailsLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get vehicleDetailsLogIn;

  /// No description provided for @vehicleDetailsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save vehicle details: '**
  String get vehicleDetailsSaveError;

  /// No description provided for @docVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Verification'**
  String get docVerificationTitle;

  /// No description provided for @docVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload required documents to complete\nregistration'**
  String get docVerificationDesc;

  /// No description provided for @docVerificationDriversLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License'**
  String get docVerificationDriversLicense;

  /// No description provided for @docVerificationDriversLicenseDesc.
  ///
  /// In en, this message translates to:
  /// **'Valid government-issued ID'**
  String get docVerificationDriversLicenseDesc;

  /// No description provided for @docVerificationCommercialLicense.
  ///
  /// In en, this message translates to:
  /// **'Commercial License'**
  String get docVerificationCommercialLicense;

  /// No description provided for @docVerificationCommercialLicenseDesc.
  ///
  /// In en, this message translates to:
  /// **'CDL or equivalent certification'**
  String get docVerificationCommercialLicenseDesc;

  /// No description provided for @docVerificationVehicleReg.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration'**
  String get docVerificationVehicleReg;

  /// No description provided for @docVerificationVehicleRegDesc.
  ///
  /// In en, this message translates to:
  /// **'Current vehicle registration'**
  String get docVerificationVehicleRegDesc;

  /// No description provided for @docVerificationInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance Certificate'**
  String get docVerificationInsurance;

  /// No description provided for @docVerificationInsuranceDesc.
  ///
  /// In en, this message translates to:
  /// **'Valid commercial insurance'**
  String get docVerificationInsuranceDesc;

  /// No description provided for @docVerificationBackground.
  ///
  /// In en, this message translates to:
  /// **'Background Check'**
  String get docVerificationBackground;

  /// No description provided for @docVerificationBackgroundDesc.
  ///
  /// In en, this message translates to:
  /// **'Consent for background verification'**
  String get docVerificationBackgroundDesc;

  /// No description provided for @docVerificationUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get docVerificationUploaded;

  /// No description provided for @docVerificationUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get docVerificationUploadFile;

  /// No description provided for @docVerificationCompleteReg.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get docVerificationCompleteReg;

  /// No description provided for @docVerificationUploadAll.
  ///
  /// In en, this message translates to:
  /// **'Please upload all required documents to continue'**
  String get docVerificationUploadAll;

  /// No description provided for @docVerificationAttached.
  ///
  /// In en, this message translates to:
  /// **'Document {number} attached successfully!'**
  String docVerificationAttached(int number);

  /// No description provided for @docVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select document: '**
  String get docVerificationFailed;

  /// No description provided for @dashboardDelivers.
  ///
  /// In en, this message translates to:
  /// **'Delivers'**
  String get dashboardDelivers;

  /// No description provided for @dashboardActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dashboardActive;

  /// No description provided for @dashboardOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get dashboardOffline;

  /// No description provided for @dashboardReceivingOrders.
  ///
  /// In en, this message translates to:
  /// **'Receiving Orders'**
  String get dashboardReceivingOrders;

  /// No description provided for @dashboardGoOnline.
  ///
  /// In en, this message translates to:
  /// **'Go Online'**
  String get dashboardGoOnline;

  /// No description provided for @dashboardFuelCapacity.
  ///
  /// In en, this message translates to:
  /// **'Fuel Capacity'**
  String get dashboardFuelCapacity;

  /// No description provided for @dashboardLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get dashboardLoading;

  /// No description provided for @dashboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get dashboardEmpty;

  /// No description provided for @dashboardActiveDelivery.
  ///
  /// In en, this message translates to:
  /// **'Active Delivery'**
  String get dashboardActiveDelivery;

  /// No description provided for @dashboardAvailableStatus.
  ///
  /// In en, this message translates to:
  /// **'Available Status'**
  String get dashboardAvailableStatus;

  /// No description provided for @dashboardNearbyOrders.
  ///
  /// In en, this message translates to:
  /// **'Nearby Orders'**
  String get dashboardNearbyOrders;

  /// No description provided for @dashboardNoActiveOrder.
  ///
  /// In en, this message translates to:
  /// **'No active order'**
  String get dashboardNoActiveOrder;

  /// No description provided for @dashboardReadyToAccept.
  ///
  /// In en, this message translates to:
  /// **'Ready to accept orders'**
  String get dashboardReadyToAccept;

  /// No description provided for @dashboardNavigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get dashboardNavigate;

  /// No description provided for @dashboardAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get dashboardAccept;

  /// No description provided for @dashboardCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get dashboardCustomer;

  /// No description provided for @dashboardOrderNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Order no longer available.'**
  String get dashboardOrderNoLongerAvailable;

  /// No description provided for @dashboardOrderTakenByAnother.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this order was just accepted by another driver.'**
  String get dashboardOrderTakenByAnother;

  /// No description provided for @dashboardOrderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted! Tap \'Navigate\' to start delivery.'**
  String get dashboardOrderAccepted;

  /// No description provided for @dashboardFailedUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status. Please check your connection.'**
  String get dashboardFailedUpdateStatus;

  /// No description provided for @dashboardEmergencyAlert.
  ///
  /// In en, this message translates to:
  /// **'Emergency alert sent! Order moved to Emergency queue.'**
  String get dashboardEmergencyAlert;

  /// No description provided for @dashboardFailedEmergency.
  ///
  /// In en, this message translates to:
  /// **'Failed to trigger emergency: '**
  String get dashboardFailedEmergency;

  /// No description provided for @dashboardFailedAction.
  ///
  /// In en, this message translates to:
  /// **'Failed: '**
  String get dashboardFailedAction;

  /// No description provided for @dashboardCannotDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not launch phone dialer'**
  String get dashboardCannotDialer;

  /// No description provided for @dashboardEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alert'**
  String get dashboardEmergencyTitle;

  /// No description provided for @dashboardEmergencyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to trigger an emergency alert? This will notify dispatch immediately.'**
  String get dashboardEmergencyPrompt;

  /// No description provided for @dashboardEmergencyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send Alert'**
  String get dashboardEmergencyConfirm;

  /// No description provided for @dashboardEmergencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap and hold in case of fuel spill,\nfire, or accident.'**
  String get dashboardEmergencySubtitle;

  /// No description provided for @dashboardScheduledWarning.
  ///
  /// In en, this message translates to:
  /// **'Scheduled order. You can start this delivery 1 hour before the scheduled time (Scheduled for: {time}).'**
  String dashboardScheduledWarning(String time);

  /// No description provided for @dashboardContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get dashboardContact;

  /// No description provided for @dashboardOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get dashboardOpenMaps;

  /// No description provided for @dashboardOpenMapsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps.'**
  String get dashboardOpenMapsError;

  /// No description provided for @dashboardNoGps.
  ///
  /// In en, this message translates to:
  /// **'No GPS coordinates for this order yet.'**
  String get dashboardNoGps;

  /// No description provided for @dashboardSearchingNearby.
  ///
  /// In en, this message translates to:
  /// **'Searching for nearby orders...'**
  String get dashboardSearchingNearby;

  /// No description provided for @dashboardSearchingNearbyDesc.
  ///
  /// In en, this message translates to:
  /// **'New orders within 25 km will appear here automatically.'**
  String get dashboardSearchingNearbyDesc;

  /// No description provided for @dashboardViewAllOrders.
  ///
  /// In en, this message translates to:
  /// **'View All Orders'**
  String get dashboardViewAllOrders;

  /// No description provided for @dashboardViewAllText.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get dashboardViewAllText;

  /// No description provided for @dashboardStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE'**
  String get dashboardStatusAvailable;

  /// No description provided for @dashboardStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED'**
  String get dashboardStatusAssigned;

  /// No description provided for @dashboardAccepting.
  ///
  /// In en, this message translates to:
  /// **'Accepting...'**
  String get dashboardAccepting;

  /// No description provided for @dashboardAcceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get dashboardAcceptOrder;

  /// No description provided for @dashboardOfflineCardTitle.
  ///
  /// In en, this message translates to:
  /// **'You are currently offline'**
  String get dashboardOfflineCardTitle;

  /// No description provided for @dashboardOfflineCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Toggle your status top-right to start receiving deliveries.'**
  String get dashboardOfflineCardDesc;

  /// No description provided for @dashboardNoPhone.
  ///
  /// In en, this message translates to:
  /// **'Customer phone number not available.'**
  String get dashboardNoPhone;

  /// No description provided for @dashboardMilesAway.
  ///
  /// In en, this message translates to:
  /// **'{miles} miles away'**
  String dashboardMilesAway(String miles);

  /// No description provided for @dashboardMetersAway.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String dashboardMetersAway(int meters);

  /// No description provided for @dashboardKmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String dashboardKmAway(String km);

  /// No description provided for @dashboardOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{order} other{orders}} within 25 km'**
  String dashboardOrdersCount(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsFuelDeliveryPartner.
  ///
  /// In en, this message translates to:
  /// **'Fuel Delivery Partner'**
  String get settingsFuelDeliveryPartner;

  /// No description provided for @settingsAppPreferences.
  ///
  /// In en, this message translates to:
  /// **'APP PREFERENCES'**
  String get settingsAppPreferences;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsAccountSupport.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT & SUPPORT'**
  String get settingsAccountSupport;

  /// No description provided for @settingsHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get settingsHelpCenter;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogOut;

  /// No description provided for @settingsLogOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to log out. Please try again.'**
  String get settingsLogOutFailed;

  /// No description provided for @settingsProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully!'**
  String get settingsProfileUpdated;

  /// No description provided for @settingsProfileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: '**
  String get settingsProfileUploadFailed;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English (US)'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @helpCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenterTitle;

  /// No description provided for @helpCenterHowCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get helpCenterHowCanWeHelp;

  /// No description provided for @helpCenterQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I reset my password?'**
  String get helpCenterQ1;

  /// No description provided for @helpCenterA1.
  ///
  /// In en, this message translates to:
  /// **'To reset your password, click on \"Forgot Password\" on the login screen and follow the instructions sent to your email.'**
  String get helpCenterA1;

  /// No description provided for @helpCenterQ2.
  ///
  /// In en, this message translates to:
  /// **'How do I update my profile?'**
  String get helpCenterQ2;

  /// No description provided for @helpCenterA2.
  ///
  /// In en, this message translates to:
  /// **'Go to the Settings screen, tap on your profile picture to upload a new one, and manage your preferences there.'**
  String get helpCenterA2;

  /// No description provided for @helpCenterQ3.
  ///
  /// In en, this message translates to:
  /// **'What to do if an order is delayed?'**
  String get helpCenterQ3;

  /// No description provided for @helpCenterA3.
  ///
  /// In en, this message translates to:
  /// **'If an order is delayed, please use the in-app chat or push notification to alert the dispatch team or customer immediately.'**
  String get helpCenterA3;

  /// No description provided for @helpCenterStillNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Still need help?'**
  String get helpCenterStillNeedHelp;

  /// No description provided for @helpCenterContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get helpCenterContactSupport;

  /// No description provided for @helpCenterContacting.
  ///
  /// In en, this message translates to:
  /// **'Contacting support...'**
  String get helpCenterContacting;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicy1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Overview'**
  String get privacyPolicy1Title;

  /// No description provided for @privacyPolicy1Body.
  ///
  /// In en, this message translates to:
  /// **'Welcome to FuelDirect Driver App! Your privacy is very important to us. This policy outlines how we collect, use, and protect your personal data when you use our application.'**
  String get privacyPolicy1Body;

  /// No description provided for @privacyPolicy2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Information We Collect'**
  String get privacyPolicy2Title;

  /// No description provided for @privacyPolicy2Body.
  ///
  /// In en, this message translates to:
  /// **'• Personal Information: Name, email address, phone number.\n• Location Data: We collect precise location data to coordinate fuel deliveries effectively.\n• Device Information: Device model, operating system, and unique identifiers.'**
  String get privacyPolicy2Body;

  /// No description provided for @privacyPolicy3Title.
  ///
  /// In en, this message translates to:
  /// **'3. How We Use Information'**
  String get privacyPolicy3Title;

  /// No description provided for @privacyPolicy3Body.
  ///
  /// In en, this message translates to:
  /// **'Data collected is used to optimize fuel drop-offs, track active deliveries, providing in-app guidance, and managing payments/earnings summaries in your dashboard.'**
  String get privacyPolicy3Body;

  /// No description provided for @privacyPolicy4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Data Sharing'**
  String get privacyPolicy4Title;

  /// No description provided for @privacyPolicy4Body.
  ///
  /// In en, this message translates to:
  /// **'We do not sell your personal data. We may share it with verified partners to enhance delivery safety or as required by legal authorities.'**
  String get privacyPolicy4Body;

  /// No description provided for @privacyPolicy5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Contact Us'**
  String get privacyPolicy5Title;

  /// No description provided for @privacyPolicy5Body.
  ///
  /// In en, this message translates to:
  /// **'For inquiries regarding our privacy policy, please contact us at support@fueldirect.com or through the Help Center in your settings.'**
  String get privacyPolicy5Body;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatMessageHint;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Start the conversation!'**
  String get chatNoMessages;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see your order updates and alerts here'**
  String get notificationsEmptyDesc;

  /// No description provided for @orderHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistoryTitle;

  /// No description provided for @orderHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed orders yet'**
  String get orderHistoryEmpty;

  /// No description provided for @orderHistoryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orderHistoryCompleted;

  /// No description provided for @orderHistoryDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderHistoryDelivered;

  /// No description provided for @earningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earningsTitle;

  /// No description provided for @earningsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get earningsToday;

  /// No description provided for @earningsWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get earningsWeek;

  /// No description provided for @earningsMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get earningsMonth;

  /// No description provided for @earningsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get earningsTotal;

  /// No description provided for @earningsDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get earningsDeliveries;

  /// No description provided for @earningsRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get earningsRating;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get common_submit;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
