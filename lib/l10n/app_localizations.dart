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

  /// No description provided for @loginCustomerAccountError.
  ///
  /// In en, this message translates to:
  /// **'This is a customer account. Please use the Customer App.'**
  String get loginCustomerAccountError;

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
  /// **'New orders within 15 miles will appear here automatically.'**
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
  /// **'{count} {count, plural, =1{order} other{orders}} within 15 miles'**
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

  /// No description provided for @chatSendError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send: {error}'**
  String chatSendError(String error);

  /// No description provided for @chatError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String chatError(String error);

  /// No description provided for @chatToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatToday;

  /// No description provided for @chatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatYesterday;

  /// No description provided for @chatCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get chatCustomer;

  /// No description provided for @chatNoMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessagesTitle;

  /// No description provided for @chatNoMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation below'**
  String get chatNoMessagesSubtitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
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

  /// No description provided for @assignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Assigned Orders'**
  String get assignedTitle;

  /// No description provided for @assignedTabAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get assignedTabAvailable;

  /// No description provided for @assignedTabAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assignedTabAssigned;

  /// No description provided for @assignedTabScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get assignedTabScheduled;

  /// No description provided for @assignedTabEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get assignedTabEmergency;

  /// No description provided for @assignedTabDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get assignedTabDelivered;

  /// No description provided for @assignedOrderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted! Tap it to start delivery.'**
  String get assignedOrderAccepted;

  /// No description provided for @assignedFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders'**
  String get assignedFailedLoad;

  /// No description provided for @assignedGoOnlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Go online from the Dashboard to see available orders.'**
  String get assignedGoOnlineDesc;

  /// No description provided for @assignedNoNearby.
  ///
  /// In en, this message translates to:
  /// **'No nearby orders found'**
  String get assignedNoNearby;

  /// No description provided for @assignedNoAssignedOrders.
  ///
  /// In en, this message translates to:
  /// **'No assigned orders yet.'**
  String get assignedNoAssignedOrders;

  /// No description provided for @assignedNoScheduledOrders.
  ///
  /// In en, this message translates to:
  /// **'No scheduled orders yet.'**
  String get assignedNoScheduledOrders;

  /// No description provided for @assignedNoEmergencyOrders.
  ///
  /// In en, this message translates to:
  /// **'No emergency orders yet.'**
  String get assignedNoEmergencyOrders;

  /// No description provided for @assignedNoDeliveredOrders.
  ///
  /// In en, this message translates to:
  /// **'No delivered orders yet.'**
  String get assignedNoDeliveredOrders;

  /// No description provided for @assignedWaitingGps.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS location…'**
  String get assignedWaitingGps;

  /// No description provided for @assignedShowingNearbyFallback.
  ///
  /// In en, this message translates to:
  /// **'Showing orders within 15 miles of your location (fallback).'**
  String get assignedShowingNearbyFallback;

  /// No description provided for @assignedShowingNearbyConfigured.
  ///
  /// In en, this message translates to:
  /// **'Showing orders within {count} configured service area(s).'**
  String assignedShowingNearbyConfigured(int count);

  /// No description provided for @assignedSchedTime.
  ///
  /// In en, this message translates to:
  /// **'SCHED: {time}'**
  String assignedSchedTime(String time);

  /// No description provided for @assignedSched.
  ///
  /// In en, this message translates to:
  /// **'SCHED'**
  String get assignedSched;

  /// No description provided for @assignedNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get assignedNew;

  /// No description provided for @assignedFuelTypeFormat.
  ///
  /// In en, this message translates to:
  /// **'{qty} Gal {type}'**
  String assignedFuelTypeFormat(String qty, String type);

  /// No description provided for @assignedTagAvailable.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE'**
  String get assignedTagAvailable;

  /// No description provided for @assignedTagEmergency.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY'**
  String get assignedTagEmergency;

  /// No description provided for @assignedTagAssigned.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED'**
  String get assignedTagAssigned;

  /// No description provided for @assignedTagDelivered.
  ///
  /// In en, this message translates to:
  /// **'DELIVERED'**
  String get assignedTagDelivered;

  /// No description provided for @assignedTagCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get assignedTagCompleted;

  /// No description provided for @assignedFuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel Type'**
  String get assignedFuelType;

  /// No description provided for @assignedGo.
  ///
  /// In en, this message translates to:
  /// **'GO'**
  String get assignedGo;

  /// No description provided for @assignedDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get assignedDetails;

  /// No description provided for @navGpsDisabled.
  ///
  /// In en, this message translates to:
  /// **'GPS is Disabled'**
  String get navGpsDisabled;

  /// No description provided for @navGpsDisabledDesc.
  ///
  /// In en, this message translates to:
  /// **'Please turn on Location Services in your device settings.'**
  String get navGpsDisabledDesc;

  /// No description provided for @navPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Denied'**
  String get navPermissionDenied;

  /// No description provided for @navPermissionDeniedDesc.
  ///
  /// In en, this message translates to:
  /// **'FuelDirect needs location access to navigate.'**
  String get navPermissionDeniedDesc;

  /// No description provided for @navOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get navOpenSettings;

  /// No description provided for @navCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calc...'**
  String get navCalculating;

  /// No description provided for @navMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String navMinutes(String minutes);

  /// No description provided for @navMiles.
  ///
  /// In en, this message translates to:
  /// **'{miles} mi'**
  String navMiles(String miles);

  /// No description provided for @common_na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get common_na;

  /// No description provided for @navCustomerNotes.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER NOTES'**
  String get navCustomerNotes;

  /// No description provided for @navNoInstructions.
  ///
  /// In en, this message translates to:
  /// **'No special instructions provided.'**
  String get navNoInstructions;

  /// No description provided for @navArrivedAtSource.
  ///
  /// In en, this message translates to:
  /// **'Arrived at Source'**
  String get navArrivedAtSource;

  /// No description provided for @navReleaseOrder.
  ///
  /// In en, this message translates to:
  /// **'Release Order'**
  String get navReleaseOrder;

  /// No description provided for @navReleasing.
  ///
  /// In en, this message translates to:
  /// **'Releasing…'**
  String get navReleasing;

  /// No description provided for @navReleasePromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Release Order?'**
  String get navReleasePromptTitle;

  /// No description provided for @navReleasePromptDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to release this order?\n\nIt will be returned to the available pool and reassigned to another driver.'**
  String get navReleasePromptDesc;

  /// No description provided for @navRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get navRelease;

  /// No description provided for @navReleaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order released. It will be reassigned.'**
  String get navReleaseSuccess;

  /// No description provided for @navReleaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to release order: {error}'**
  String navReleaseFailed(String error);

  /// No description provided for @common_goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get common_goBack;

  /// No description provided for @proofPhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded successfully ✅'**
  String get proofPhotoUploaded;

  /// No description provided for @proofUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String proofUploadFailed(String error);

  /// No description provided for @proofTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery Proof'**
  String get proofTitle;

  /// No description provided for @proofDispensingComplete.
  ///
  /// In en, this message translates to:
  /// **'Dispensing Complete'**
  String get proofDispensingComplete;

  /// No description provided for @proofDispensingCompleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Capture the fuel meter and enter the delivered gallons to complete the order.'**
  String get proofDispensingCompleteDesc;

  /// No description provided for @proofMeterGaugePhoto.
  ///
  /// In en, this message translates to:
  /// **'METER GAUGE PHOTO'**
  String get proofMeterGaugePhoto;

  /// No description provided for @proofRetakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get proofRetakePhoto;

  /// No description provided for @proofManualEntry.
  ///
  /// In en, this message translates to:
  /// **'MANUAL ENTRY'**
  String get proofManualEntry;

  /// No description provided for @proofGallons.
  ///
  /// In en, this message translates to:
  /// **'GALLONS'**
  String get proofGallons;

  /// No description provided for @proofEstimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Estimated Total'**
  String get proofEstimatedTotal;

  /// No description provided for @proofPricePerGal.
  ///
  /// In en, this message translates to:
  /// **'at {price} / gal'**
  String proofPricePerGal(String price);

  /// No description provided for @proofMeterPhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Meter photo uploaded'**
  String get proofMeterPhotoUploaded;

  /// No description provided for @proofUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get proofUploadingPhoto;

  /// No description provided for @proofTakeMeterPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take meter gauge photo (required)'**
  String get proofTakeMeterPhoto;

  /// No description provided for @proofGallonsEntered.
  ///
  /// In en, this message translates to:
  /// **'Gallons entered: {qty}'**
  String proofGallonsEntered(String qty);

  /// No description provided for @proofEnterGallons.
  ///
  /// In en, this message translates to:
  /// **'Enter delivered gallons (required)'**
  String get proofEnterGallons;

  /// No description provided for @proofSupervisorReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Manual entries are flagged for supervisor review. Ensure the photo clearly shows the meter digits matching the entered quantity.'**
  String get proofSupervisorReviewDesc;

  /// No description provided for @proofWaitUpload.
  ///
  /// In en, this message translates to:
  /// **'Please wait for the photo to finish uploading.'**
  String get proofWaitUpload;

  /// No description provided for @proofTakePhotoFirst.
  ///
  /// In en, this message translates to:
  /// **'Please take a photo of the fuel meter first.'**
  String get proofTakePhotoFirst;

  /// No description provided for @proofEnterGallonsFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter the delivered gallons.'**
  String get proofEnterGallonsFirst;

  /// No description provided for @proofCompleteOrder.
  ///
  /// In en, this message translates to:
  /// **'Complete Order'**
  String get proofCompleteOrder;

  /// No description provided for @proofWaitingImage.
  ///
  /// In en, this message translates to:
  /// **'Waiting for image...'**
  String get proofWaitingImage;

  /// No description provided for @proofPhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo Saved'**
  String get proofPhotoSaved;

  /// No description provided for @proofTapToTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to take meter photo'**
  String get proofTapToTakePhoto;

  /// No description provided for @proofDigitsVisible.
  ///
  /// In en, this message translates to:
  /// **'Ensure the final digits are clearly visible'**
  String get proofDigitsVisible;

  /// No description provided for @proofCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Capture failed. Try again.'**
  String get proofCaptureFailed;

  /// No description provided for @proofDebugCamera.
  ///
  /// In en, this message translates to:
  /// **'DEBUG CAMERA'**
  String get proofDebugCamera;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery History'**
  String get historyTitle;

  /// No description provided for @historyNoDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No completed deliveries yet.'**
  String get historyNoDeliveries;

  /// No description provided for @historyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get historyCompleted;

  /// No description provided for @historyError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String historyError(String error);

  /// No description provided for @historyFuelQty.
  ///
  /// In en, this message translates to:
  /// **'{fuelType} ({qty} Gal)'**
  String historyFuelQty(String fuelType, String qty);

  /// No description provided for @earningsYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get earningsYesterday;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @pickupTitle.
  ///
  /// In en, this message translates to:
  /// **'Fuel Pickup'**
  String get pickupTitle;

  /// No description provided for @pickupDepotVerification.
  ///
  /// In en, this message translates to:
  /// **'Depot Verification'**
  String get pickupDepotVerification;

  /// No description provided for @pickupInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get pickupInProgress;

  /// No description provided for @pickupArrivedAt.
  ///
  /// In en, this message translates to:
  /// **'Arrived at Source: {time}'**
  String pickupArrivedAt(String time);

  /// No description provided for @pickupOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'ORDER DETAILS'**
  String get pickupOrderDetails;

  /// No description provided for @pickupOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String pickupOrderNumber(String id);

  /// No description provided for @pickupNoAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address not available'**
  String get pickupNoAddress;

  /// No description provided for @pickupGeofenceConfirmed.
  ///
  /// In en, this message translates to:
  /// **'GEOFENCE CONFIRMED'**
  String get pickupGeofenceConfirmed;

  /// No description provided for @pickupSealTitle.
  ///
  /// In en, this message translates to:
  /// **'Tank Seal Check Number'**
  String get pickupSealTitle;

  /// No description provided for @pickupSealHint.
  ///
  /// In en, this message translates to:
  /// **'Enter numbers only — no letters or special characters.'**
  String get pickupSealHint;

  /// No description provided for @pickupSealEg.
  ///
  /// In en, this message translates to:
  /// **'e.g. 12345678'**
  String get pickupSealEg;

  /// No description provided for @pickupSealVerificationNote.
  ///
  /// In en, this message translates to:
  /// **'Verification ensures the integrity of the fuel cargo during transport.'**
  String get pickupSealVerificationNote;

  /// No description provided for @pickupFuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel Type'**
  String get pickupFuelType;

  /// No description provided for @pickupExpectedVolume.
  ///
  /// In en, this message translates to:
  /// **'Expected Volume'**
  String get pickupExpectedVolume;

  /// No description provided for @pickupTolerance.
  ///
  /// In en, this message translates to:
  /// **'TOLERANCE: ±0.5%'**
  String get pickupTolerance;

  /// No description provided for @pickupVolumeGal.
  ///
  /// In en, this message translates to:
  /// **'{volume} GAL'**
  String pickupVolumeGal(String volume);

  /// No description provided for @pickupConfirmNote.
  ///
  /// In en, this message translates to:
  /// **'By clicking confirm, you verify that you have inspected the safety valves and recorded the correct volume.'**
  String get pickupConfirmNote;

  /// No description provided for @pickupConfirmStartTrip.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Start Trip'**
  String get pickupConfirmStartTrip;

  /// No description provided for @pickupEnterSeal.
  ///
  /// In en, this message translates to:
  /// **'Please enter the tank seal number'**
  String get pickupEnterSeal;

  /// No description provided for @pickupSealMinLength.
  ///
  /// In en, this message translates to:
  /// **'Seal number must be at least 4 digits'**
  String get pickupSealMinLength;

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

  /// No description provided for @rtdLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating delivery address…'**
  String get rtdLocating;

  /// No description provided for @rtdDestMissing.
  ///
  /// In en, this message translates to:
  /// **'Delivery location not available'**
  String get rtdDestMissing;

  /// No description provided for @rtdAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address: {address}'**
  String rtdAddressLabel(String address);

  /// No description provided for @rtdNoAddress.
  ///
  /// In en, this message translates to:
  /// **'No address on record for this order.'**
  String get rtdNoAddress;

  /// No description provided for @rtdRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get rtdRetry;

  /// No description provided for @rtdDeliveringTo.
  ///
  /// In en, this message translates to:
  /// **'Delivering to'**
  String get rtdDeliveringTo;

  /// No description provided for @rtdEtaLabel.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get rtdEtaLabel;

  /// No description provided for @rtdTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get rtdTimeLabel;

  /// No description provided for @rtdDistLabel.
  ///
  /// In en, this message translates to:
  /// **'DIST'**
  String get rtdDistLabel;

  /// No description provided for @rtdMin.
  ///
  /// In en, this message translates to:
  /// **'{mins} min'**
  String rtdMin(String mins);

  /// No description provided for @rtdMiles.
  ///
  /// In en, this message translates to:
  /// **'{dist} miles'**
  String rtdMiles(String dist);

  /// No description provided for @rtdCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get rtdCustomerLabel;

  /// No description provided for @rtdArrivedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Arrived! Confirm Arrival'**
  String get rtdArrivedConfirm;

  /// No description provided for @rtdArrivedAt.
  ///
  /// In en, this message translates to:
  /// **'Arrived at Customer'**
  String get rtdArrivedAt;

  /// No description provided for @rtdNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone number available.'**
  String get rtdNoPhone;

  /// No description provided for @rtdCallError.
  ///
  /// In en, this message translates to:
  /// **'Could not launch phone dialer. Please check permissions.'**
  String get rtdCallError;

  /// No description provided for @rtdArrivalFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update arrival: {error}'**
  String rtdArrivalFailed(String error);

  /// No description provided for @rtdGpsDisabled.
  ///
  /// In en, this message translates to:
  /// **'GPS is disabled'**
  String get rtdGpsDisabled;

  /// No description provided for @rtdGpsDisabledDesc.
  ///
  /// In en, this message translates to:
  /// **'Please turn on Location Services in your device settings.'**
  String get rtdGpsDisabledDesc;

  /// No description provided for @rtdOpenGps.
  ///
  /// In en, this message translates to:
  /// **'Open GPS Settings'**
  String get rtdOpenGps;

  /// No description provided for @rtdPermDenied.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Denied'**
  String get rtdPermDenied;

  /// No description provided for @rtdPermDeniedDesc.
  ///
  /// In en, this message translates to:
  /// **'FuelDirect needs location access to navigate. Tap below to open Settings.'**
  String get rtdPermDeniedDesc;

  /// No description provided for @rtdOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get rtdOpenSettings;

  /// No description provided for @rtdGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get rtdGoBack;

  /// No description provided for @orderSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummaryTitle;

  /// No description provided for @orderSummaryDeliveryDetails.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY DETAILS'**
  String get orderSummaryDeliveryDetails;

  /// No description provided for @orderSummaryOrderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderSummaryOrderId;

  /// No description provided for @orderSummaryFuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel Type'**
  String get orderSummaryFuelType;

  /// No description provided for @orderSummaryQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get orderSummaryQuantity;

  /// No description provided for @orderSummaryQuantityVal.
  ///
  /// In en, this message translates to:
  /// **'{qty} gallons'**
  String orderSummaryQuantityVal(String qty);

  /// No description provided for @orderSummaryDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get orderSummaryDeliveryAddress;

  /// No description provided for @orderSummaryScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get orderSummaryScheduled;

  /// No description provided for @orderSummaryPricingBreakdown.
  ///
  /// In en, this message translates to:
  /// **'PRICING BREAKDOWN'**
  String get orderSummaryPricingBreakdown;

  /// No description provided for @orderSummaryFuelCost.
  ///
  /// In en, this message translates to:
  /// **'Fuel Cost'**
  String get orderSummaryFuelCost;

  /// No description provided for @orderSummaryDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get orderSummaryDeliveryFee;

  /// No description provided for @orderSummaryServiceFee.
  ///
  /// In en, this message translates to:
  /// **'Service Fee'**
  String get orderSummaryServiceFee;

  /// No description provided for @orderSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get orderSummaryTotal;

  /// No description provided for @orderSummaryStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get orderSummaryStatus;

  /// No description provided for @orderSummaryCurrentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get orderSummaryCurrentStatus;

  /// No description provided for @orderSummaryPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get orderSummaryPaymentMethod;

  /// No description provided for @orderSummarySpecialInstructions.
  ///
  /// In en, this message translates to:
  /// **'SPECIAL INSTRUCTIONS'**
  String get orderSummarySpecialInstructions;

  /// No description provided for @orderSummaryNoInstructions.
  ///
  /// In en, this message translates to:
  /// **'No special instructions provided.'**
  String get orderSummaryNoInstructions;

  /// No description provided for @orderSummaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get orderSummaryUnavailable;

  /// No description provided for @orderSummaryNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get orderSummaryNotSet;

  /// No description provided for @orderSummaryFuelDetails.
  ///
  /// In en, this message translates to:
  /// **'Fuel Details'**
  String get orderSummaryFuelDetails;

  /// No description provided for @orderSummaryPricePerGallon.
  ///
  /// In en, this message translates to:
  /// **'Price per Gallon'**
  String get orderSummaryPricePerGallon;

  /// No description provided for @orderSummaryPriceVal.
  ///
  /// In en, this message translates to:
  /// **'{price}'**
  String orderSummaryPriceVal(String price);

  /// No description provided for @orderSummaryFuelTotal.
  ///
  /// In en, this message translates to:
  /// **'Fuel Total'**
  String get orderSummaryFuelTotal;

  /// No description provided for @orderSummaryFuelTotalVal.
  ///
  /// In en, this message translates to:
  /// **'{total}'**
  String orderSummaryFuelTotalVal(String total);

  /// No description provided for @orderSummaryVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get orderSummaryVehicle;

  /// No description provided for @orderSummaryAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get orderSummaryAddress;

  /// No description provided for @orderSummaryScheduledTime.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Time'**
  String get orderSummaryScheduledTime;

  /// No description provided for @orderSummaryNotScheduled.
  ///
  /// In en, this message translates to:
  /// **'Not Scheduled'**
  String get orderSummaryNotScheduled;

  /// No description provided for @orderSummaryPaymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get orderSummaryPaymentSummary;

  /// No description provided for @orderSummaryTotalDueToday.
  ///
  /// In en, this message translates to:
  /// **'Total Due Today'**
  String get orderSummaryTotalDueToday;

  /// No description provided for @orderSummaryDefaultPayment.
  ///
  /// In en, this message translates to:
  /// **'Default payment'**
  String get orderSummaryDefaultPayment;

  /// No description provided for @orderSummaryChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get orderSummaryChange;

  /// No description provided for @orderSummaryLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to place an order'**
  String get orderSummaryLoginRequired;

  /// No description provided for @orderSummaryPlaceError.
  ///
  /// In en, this message translates to:
  /// **'Error placing order: {error}'**
  String orderSummaryPlaceError(String error);

  /// No description provided for @orderSummaryPlaceOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Place Order - {total}'**
  String orderSummaryPlaceOrderButton(String total);

  /// No description provided for @orderSummaryRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get orderSummaryRegular;

  /// No description provided for @orderSummaryPlaceholderVehicle.
  ///
  /// In en, this message translates to:
  /// **'Tesla Model 3'**
  String get orderSummaryPlaceholderVehicle;

  /// No description provided for @orderSummaryPlaceholderVehicleSub.
  ///
  /// In en, this message translates to:
  /// **'ABC 1234'**
  String get orderSummaryPlaceholderVehicleSub;

  /// No description provided for @orderSummaryPlaceholderAddress.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get orderSummaryPlaceholderAddress;

  /// No description provided for @orderSummaryPlaceholderAddressSub.
  ///
  /// In en, this message translates to:
  /// **'123 Main Street, San Francisco, CA 94102'**
  String get orderSummaryPlaceholderAddressSub;

  /// No description provided for @orderHistoryNoOrders.
  ///
  /// In en, this message translates to:
  /// **'No completed orders found.'**
  String get orderHistoryNoOrders;

  /// No description provided for @orderHistoryError.
  ///
  /// In en, this message translates to:
  /// **'Error loading history: {error}'**
  String orderHistoryError(String error);

  /// No description provided for @orderHistoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get orderHistoryLoading;

  /// No description provided for @orderHistorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by location...'**
  String get orderHistorySearchHint;

  /// No description provided for @orderHistoryPlaceholderFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get orderHistoryPlaceholderFuel;

  /// No description provided for @orderHistoryCardQty.
  ///
  /// In en, this message translates to:
  /// **'{fuelType} • {qty} Gal'**
  String orderHistoryCardQty(String fuelType, String qty);

  /// No description provided for @orderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetailsTitle;

  /// No description provided for @orderDetailsOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderDetailsOrderNumber(String id);

  /// No description provided for @orderDetailsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderDetailsStatus;

  /// No description provided for @orderDetailsFuelType.
  ///
  /// In en, this message translates to:
  /// **'Fuel Type'**
  String get orderDetailsFuelType;

  /// No description provided for @orderDetailsQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get orderDetailsQuantity;

  /// No description provided for @orderDetailsAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get orderDetailsAddress;

  /// No description provided for @orderDetailsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get orderDetailsTotal;

  /// No description provided for @orderDetailsScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get orderDetailsScheduled;

  /// No description provided for @orderDetailsPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get orderDetailsPaymentMethod;

  /// No description provided for @orderDetailsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get orderDetailsCustomer;

  /// No description provided for @orderDetailsSpecialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions'**
  String get orderDetailsSpecialInstructions;

  /// No description provided for @orderDetailsNoInstructions.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get orderDetailsNoInstructions;

  /// No description provided for @orderDetailsGallons.
  ///
  /// In en, this message translates to:
  /// **'{qty} Gal'**
  String orderDetailsGallons(String qty);

  /// No description provided for @orderDetailsNoContactInfo.
  ///
  /// In en, this message translates to:
  /// **'No contact info'**
  String get orderDetailsNoContactInfo;

  /// No description provided for @orderDetailsChatUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Customer information not available for chat.'**
  String get orderDetailsChatUnavailable;

  /// No description provided for @orderDetailsOrderTotal.
  ///
  /// In en, this message translates to:
  /// **'ORDER TOTAL'**
  String get orderDetailsOrderTotal;

  /// No description provided for @orderDetailsCompletedCheck.
  ///
  /// In en, this message translates to:
  /// **'Completed ✓'**
  String get orderDetailsCompletedCheck;

  /// No description provided for @orderDetailsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderDetailsPending;

  /// No description provided for @orderDetailsScheduledDeliveryHeader.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULED DELIVERY'**
  String get orderDetailsScheduledDeliveryHeader;

  /// No description provided for @orderDetailsCustomerNotesHeader.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER NOTES'**
  String get orderDetailsCustomerNotesHeader;

  /// No description provided for @orderDetailsNoInstructionsDesc.
  ///
  /// In en, this message translates to:
  /// **'No special instructions provided.'**
  String get orderDetailsNoInstructionsDesc;

  /// No description provided for @orderDetailsDeliveryLocationHeader.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY LOCATION'**
  String get orderDetailsDeliveryLocationHeader;

  /// No description provided for @orderDetailsNavigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get orderDetailsNavigate;

  /// No description provided for @orderDetailsOrderTimelineHeader.
  ///
  /// In en, this message translates to:
  /// **'ORDER TIMELINE'**
  String get orderDetailsOrderTimelineHeader;

  /// No description provided for @orderDetailsTimelinePlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get orderDetailsTimelinePlaced;

  /// No description provided for @orderDetailsTimelineAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order Accepted'**
  String get orderDetailsTimelineAccepted;

  /// No description provided for @orderDetailsTimelineArrived.
  ///
  /// In en, this message translates to:
  /// **'Driver Arrived'**
  String get orderDetailsTimelineArrived;

  /// No description provided for @orderDetailsTimelineCompleted.
  ///
  /// In en, this message translates to:
  /// **'Order Completed'**
  String get orderDetailsTimelineCompleted;

  /// No description provided for @orderDetailsScheduledError.
  ///
  /// In en, this message translates to:
  /// **'This order is scheduled for later. You can only start it 1 hour before the scheduled time.'**
  String get orderDetailsScheduledError;

  /// No description provided for @orderDetailsJourneyStarted.
  ///
  /// In en, this message translates to:
  /// **'Delivery Journey Started! 🚀'**
  String get orderDetailsJourneyStarted;

  /// No description provided for @orderDetailsJourneyStartedBody.
  ///
  /// In en, this message translates to:
  /// **'Heading to source location for pickup.'**
  String get orderDetailsJourneyStartedBody;

  /// No description provided for @orderDetailsStartJourney.
  ///
  /// In en, this message translates to:
  /// **'Start Delivery Journey'**
  String get orderDetailsStartJourney;

  /// No description provided for @orderDetailsEmergencyFlagged.
  ///
  /// In en, this message translates to:
  /// **'Order flagged as Emergency! 🚨'**
  String get orderDetailsEmergencyFlagged;

  /// No description provided for @orderDetailsAssignedFlagged.
  ///
  /// In en, this message translates to:
  /// **'Order moved back to Assigned.'**
  String get orderDetailsAssignedFlagged;

  /// No description provided for @orderDetailsEmergencyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Flag as Emergency'**
  String get orderDetailsEmergencyTooltip;

  /// No description provided for @notificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkRead;

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety Compliance'**
  String get safetyTitle;

  /// No description provided for @safetyCheckAll.
  ///
  /// In en, this message translates to:
  /// **'Check All Items'**
  String get safetyCheckAll;

  /// No description provided for @safetyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Safety Check'**
  String get safetyConfirm;

  /// No description provided for @safetyItem1.
  ///
  /// In en, this message translates to:
  /// **'Check fuel tank pressure'**
  String get safetyItem1;

  /// No description provided for @safetyItem2.
  ///
  /// In en, this message translates to:
  /// **'Inspect hose connections'**
  String get safetyItem2;

  /// No description provided for @safetyItem3.
  ///
  /// In en, this message translates to:
  /// **'Verify fuel type matches order'**
  String get safetyItem3;

  /// No description provided for @safetyItem4.
  ///
  /// In en, this message translates to:
  /// **'Check emergency shutoff valve'**
  String get safetyItem4;

  /// No description provided for @safetyItem5.
  ///
  /// In en, this message translates to:
  /// **'Confirm PPE is on'**
  String get safetyItem5;

  /// No description provided for @safetyAllRequired.
  ///
  /// In en, this message translates to:
  /// **'Please complete all safety checks before confirming.'**
  String get safetyAllRequired;

  /// No description provided for @selectLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get selectLocationTitle;

  /// No description provided for @selectLocationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a different location..'**
  String get selectLocationSearchHint;

  /// No description provided for @selectLocationCurrentSelection.
  ///
  /// In en, this message translates to:
  /// **'CURRENT SELECTION'**
  String get selectLocationCurrentSelection;

  /// No description provided for @selectLocationEstimatedWait.
  ///
  /// In en, this message translates to:
  /// **'ESTIMATED WAIT'**
  String get selectLocationEstimatedWait;

  /// No description provided for @selectLocationServiceFee.
  ///
  /// In en, this message translates to:
  /// **'SERVICE FEE'**
  String get selectLocationServiceFee;

  /// No description provided for @selectLocationConfirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get selectLocationConfirmOrder;

  /// No description provided for @selectLocationPlaceholderAddress.
  ///
  /// In en, this message translates to:
  /// **'123 Innovation Drive'**
  String get selectLocationPlaceholderAddress;

  /// No description provided for @selectLocationPlaceholderCity.
  ///
  /// In en, this message translates to:
  /// **'San Francisco, CA 94105'**
  String get selectLocationPlaceholderCity;

  /// No description provided for @selectLocationPlaceholderWait.
  ///
  /// In en, this message translates to:
  /// **'15-20 mins'**
  String get selectLocationPlaceholderWait;

  /// No description provided for @selectLocationPlaceholderFee.
  ///
  /// In en, this message translates to:
  /// **'\$4.99'**
  String get selectLocationPlaceholderFee;

  /// No description provided for @selectLocationPlaceholderFullAddress.
  ///
  /// In en, this message translates to:
  /// **'123 Innovation Drive, San Francisco, CA 94105'**
  String get selectLocationPlaceholderFullAddress;

  /// No description provided for @deliveryCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery Complete'**
  String get deliveryCompleteTitle;

  /// No description provided for @deliveryCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order successfully delivered!'**
  String get deliveryCompleteSubtitle;

  /// No description provided for @deliveryCompleteBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get deliveryCompleteBackHome;

  /// No description provided for @deliveryCompleteRating.
  ///
  /// In en, this message translates to:
  /// **'Rate this delivery'**
  String get deliveryCompleteRating;

  /// No description provided for @scheduleDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Delivery'**
  String get scheduleDeliveryTitle;

  /// No description provided for @scheduleDeliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get scheduleDeliveryDate;

  /// No description provided for @scheduleDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get scheduleDeliveryTime;

  /// No description provided for @scheduleDeliveryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Schedule'**
  String get scheduleDeliveryConfirm;

  /// No description provided for @scheduleDeliveryNoSlots.
  ///
  /// In en, this message translates to:
  /// **'No available time slots.'**
  String get scheduleDeliveryNoSlots;

  /// No description provided for @notificationsMarkAllReadSuccess.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notificationsMarkAllReadSuccess;

  /// No description provided for @notificationsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsFilterAll;

  /// No description provided for @notificationsFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsFilterUnread;

  /// No description provided for @notificationsFilterOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get notificationsFilterOrder;

  /// No description provided for @notificationsNoFilterNotifications.
  ///
  /// In en, this message translates to:
  /// **'No {filter} notifications'**
  String notificationsNoFilterNotifications(String filter);

  /// No description provided for @notificationsDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationsDefaultTitle;

  /// No description provided for @earningsOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Earnings Overview'**
  String get earningsOverviewTitle;

  /// No description provided for @earningsWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'WALLET BALANCE'**
  String get earningsWalletBalance;

  /// No description provided for @earningsTodayCaps.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get earningsTodayCaps;

  /// No description provided for @earningsActionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get earningsActionRequired;

  /// No description provided for @earningsStripeLinkBankDesc.
  ///
  /// In en, this message translates to:
  /// **'Please link your bank account via Stripe to enable payouts.'**
  String get earningsStripeLinkBankDesc;

  /// No description provided for @earningsLinkBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Link Bank Account'**
  String get earningsLinkBankAccount;

  /// No description provided for @earningsWeeklyPerformance.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY PERFORMANCE'**
  String get earningsWeeklyPerformance;

  /// No description provided for @earningsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get earningsThisWeek;

  /// No description provided for @earningsTotalDeliveriesCaps.
  ///
  /// In en, this message translates to:
  /// **'TOTAL DELIVERIES'**
  String get earningsTotalDeliveriesCaps;

  /// No description provided for @earningsRecentDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Recent Deliveries'**
  String get earningsRecentDeliveries;

  /// No description provided for @earningsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get earningsSeeAll;

  /// No description provided for @earningsNoDeliveriesToday.
  ///
  /// In en, this message translates to:
  /// **'No deliveries today yet.'**
  String get earningsNoDeliveriesToday;

  /// No description provided for @earningsCashOutNow.
  ///
  /// In en, this message translates to:
  /// **'Cash Out Now'**
  String get earningsCashOutNow;

  /// No description provided for @earningsCashOut.
  ///
  /// In en, this message translates to:
  /// **'Cash Out'**
  String get earningsCashOut;

  /// No description provided for @earningsAvailableAmount.
  ///
  /// In en, this message translates to:
  /// **'Available: {amount}'**
  String earningsAvailableAmount(String amount);

  /// No description provided for @earningsAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get earningsAmountHint;

  /// No description provided for @earningsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get earningsConfirm;

  /// No description provided for @earningsEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get earningsEnterValidAmount;

  /// No description provided for @earningsInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get earningsInsufficientBalance;

  /// No description provided for @earningsStripeErrorInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Stripe Error: Insufficient available funds in your account.'**
  String get earningsStripeErrorInsufficient;

  /// No description provided for @earningsOnboardingLinkError.
  ///
  /// In en, this message translates to:
  /// **'Could not open onboarding link.'**
  String get earningsOnboardingLinkError;

  /// No description provided for @earningsGeneratingLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Generating onboarding link failed.'**
  String get earningsGeneratingLinkFailed;

  /// No description provided for @fuelTitle.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get fuelTitle;

  /// No description provided for @fuelTypes.
  ///
  /// In en, this message translates to:
  /// **'Fuel Types'**
  String get fuelTypes;

  /// No description provided for @fuelPetrol.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get fuelPetrol;

  /// No description provided for @fuelDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelDiesel;

  /// No description provided for @fuelOctanePremium.
  ///
  /// In en, this message translates to:
  /// **'Octane 95 Premium'**
  String get fuelOctanePremium;

  /// No description provided for @fuelUltraLowSulfur.
  ///
  /// In en, this message translates to:
  /// **'Ultra-Low Sulfur'**
  String get fuelUltraLowSulfur;

  /// No description provided for @fuelQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get fuelQuantity;

  /// No description provided for @fuelApproxRange.
  ///
  /// In en, this message translates to:
  /// **'Approx. range: 400 miles'**
  String get fuelApproxRange;

  /// No description provided for @fuelFullTank.
  ///
  /// In en, this message translates to:
  /// **'Full Tank'**
  String get fuelFullTank;

  /// No description provided for @fuelConfirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get fuelConfirmOrder;

  /// No description provided for @deliveryProofCameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera error: {error}'**
  String deliveryProofCameraError(String error);

  /// No description provided for @deliveryProofInitError.
  ///
  /// In en, this message translates to:
  /// **'Init error: {error}'**
  String deliveryProofInitError(String error);

  /// No description provided for @meterPreviewUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String meterPreviewUploadFailed(String error);

  /// No description provided for @meterVerificationCameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera error: {error}'**
  String meterVerificationCameraError(String error);

  /// No description provided for @meterVerificationCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to take photo. Please try again.'**
  String get meterVerificationCaptureFailed;

  /// No description provided for @orderDetailsError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String orderDetailsError(String error);

  /// No description provided for @orderTrackingGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get orderTrackingGoBack;

  /// No description provided for @paymentCouponHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Coupon Code'**
  String get paymentCouponHint;

  /// No description provided for @paymentAddNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get paymentAddNoteHint;

  /// No description provided for @paymentButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get paymentButtonLabel;

  /// No description provided for @paymentHaveCoupon.
  ///
  /// In en, this message translates to:
  /// **'Have a Coupon?'**
  String get paymentHaveCoupon;

  /// No description provided for @rtdCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get rtdCustomer;

  /// No description provided for @safetyNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone number available.'**
  String get safetyNoPhone;

  /// No description provided for @safetyCallError.
  ///
  /// In en, this message translates to:
  /// **'Could not launch phone dialer.'**
  String get safetyCallError;

  /// No description provided for @safetySaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get safetySaving;

  /// No description provided for @safetyError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String safetyError(String error);
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
