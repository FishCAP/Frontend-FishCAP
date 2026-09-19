import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

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
    Locale('km'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FishCAP'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Precision Aquaculture Management'**
  String get appTagline;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter your credentials to continue monitoring'**
  String get loginSubtitle;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start monitoring your marine environment today'**
  String get createAccountSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get agreeTerms;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @waterQuality.
  ///
  /// In en, this message translates to:
  /// **'Water Quality'**
  String get waterQuality;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @phLevel.
  ///
  /// In en, this message translates to:
  /// **'pH Level'**
  String get phLevel;

  /// No description provided for @oxygenLevel.
  ///
  /// In en, this message translates to:
  /// **'Oxygen Level'**
  String get oxygenLevel;

  /// No description provided for @salinity.
  ///
  /// In en, this message translates to:
  /// **'Salinity'**
  String get salinity;

  /// No description provided for @turbidity.
  ///
  /// In en, this message translates to:
  /// **'Turbidity'**
  String get turbidity;

  /// No description provided for @ammonia.
  ///
  /// In en, this message translates to:
  /// **'Ammonia'**
  String get ammonia;

  /// No description provided for @nitrite.
  ///
  /// In en, this message translates to:
  /// **'Nitrite'**
  String get nitrite;

  /// No description provided for @nitrate.
  ///
  /// In en, this message translates to:
  /// **'Nitrate'**
  String get nitrate;

  /// No description provided for @alkalinity.
  ///
  /// In en, this message translates to:
  /// **'Alkalinity'**
  String get alkalinity;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @todaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get todaySchedule;

  /// No description provided for @upcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Tasks'**
  String get upcomingTasks;

  /// No description provided for @feedingTime.
  ///
  /// In en, this message translates to:
  /// **'Feeding Time'**
  String get feedingTime;

  /// No description provided for @waterChange.
  ///
  /// In en, this message translates to:
  /// **'Water Change'**
  String get waterChange;

  /// No description provided for @healthCheck.
  ///
  /// In en, this message translates to:
  /// **'Health Check'**
  String get healthCheck;

  /// No description provided for @harvesting.
  ///
  /// In en, this message translates to:
  /// **'Harvesting'**
  String get harvesting;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @recentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recentActivities;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @notificationsSettings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSettings;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @createNewSchedule.
  ///
  /// In en, this message translates to:
  /// **'Create New Schedule'**
  String get createNewSchedule;

  /// No description provided for @pondSelection.
  ///
  /// In en, this message translates to:
  /// **'Pond Selection'**
  String get pondSelection;

  /// No description provided for @siteLocation.
  ///
  /// In en, this message translates to:
  /// **'Site Location'**
  String get siteLocation;

  /// No description provided for @batchInfo.
  ///
  /// In en, this message translates to:
  /// **'Batch Info'**
  String get batchInfo;

  /// No description provided for @currentSpecies.
  ///
  /// In en, this message translates to:
  /// **'Current Species'**
  String get currentSpecies;

  /// No description provided for @estCount.
  ///
  /// In en, this message translates to:
  /// **'Est. Count'**
  String get estCount;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @scheduleSettings.
  ///
  /// In en, this message translates to:
  /// **'Schedule Settings'**
  String get scheduleSettings;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @hardware.
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get hardware;

  /// No description provided for @hardwareProductId.
  ///
  /// In en, this message translates to:
  /// **'Hardware Product ID'**
  String get hardwareProductId;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add Time'**
  String get addTime;

  /// No description provided for @precisionFeedingTip.
  ///
  /// In en, this message translates to:
  /// **'Precision Feeding Tip'**
  String get precisionFeedingTip;

  /// No description provided for @feedingTipDescription.
  ///
  /// In en, this message translates to:
  /// **'Optimal feeding occurs when water oxygen levels are above 5.0 mg/L. Sensors will auto-verify conditions before dispensing.'**
  String get feedingTipDescription;

  /// No description provided for @configureAutomatedFeeding.
  ///
  /// In en, this message translates to:
  /// **'Configure automated feeding'**
  String get configureAutomatedFeeding;

  /// No description provided for @operationalMode.
  ///
  /// In en, this message translates to:
  /// **'OPERATIONAL MODE'**
  String get operationalMode;

  /// No description provided for @totalFeedWeek.
  ///
  /// In en, this message translates to:
  /// **'TOTAL FEED (WEEK)'**
  String get totalFeedWeek;

  /// No description provided for @avgDailyDose.
  ///
  /// In en, this message translates to:
  /// **'AVG DAILY DOSE'**
  String get avgDailyDose;

  /// No description provided for @feedType.
  ///
  /// In en, this message translates to:
  /// **'FEED TYPE'**
  String get feedType;

  /// No description provided for @initialCount.
  ///
  /// In en, this message translates to:
  /// **'INITIAL COUNT'**
  String get initialCount;

  /// No description provided for @stockingPeriod.
  ///
  /// In en, this message translates to:
  /// **'STOCKING PERIOD'**
  String get stockingPeriod;

  /// No description provided for @feedingEvents.
  ///
  /// In en, this message translates to:
  /// **'Feeding Events'**
  String get feedingEvents;

  /// No description provided for @morningFeeding.
  ///
  /// In en, this message translates to:
  /// **'Morning Feeding'**
  String get morningFeeding;

  /// No description provided for @afternoonFeeding.
  ///
  /// In en, this message translates to:
  /// **'Afternoon Feeding'**
  String get afternoonFeeding;

  /// No description provided for @automatedDispenser.
  ///
  /// In en, this message translates to:
  /// **'Automated Dispenser'**
  String get automatedDispenser;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get units;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get today;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get selectDateRange;

  /// No description provided for @tanks.
  ///
  /// In en, this message translates to:
  /// **'Tanks'**
  String get tanks;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs & Support center'**
  String get helpSubtitle;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @appPreferences.
  ///
  /// In en, this message translates to:
  /// **'App & notification preferences'**
  String get appPreferences;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications'**
  String get notificationsEmpty;

  /// No description provided for @readNotification.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get readNotification;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessful;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the terms and conditions'**
  String get pleaseAgreeToTerms;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @createAccountError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create account'**
  String get createAccountError;

  /// No description provided for @accountVerified.
  ///
  /// In en, this message translates to:
  /// **'Account verified successfully!'**
  String get accountVerified;

  /// No description provided for @otpVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'OTP verification failed'**
  String get otpVerificationFailed;

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'OTP resent successfully'**
  String get otpResent;

  /// No description provided for @failedToResendOtp.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP'**
  String get failedToResendOtp;

  /// No description provided for @enterOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP Code'**
  String get enterOtpCode;

  /// No description provided for @pleaseEnterOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the OTP code'**
  String get pleaseEnterOtpCode;

  /// No description provided for @otpMustBe6Digits.
  ///
  /// In en, this message translates to:
  /// **'OTP must be 6 digits'**
  String get otpMustBe6Digits;

  /// No description provided for @otpMustBeDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'OTP must contain only digits'**
  String get otpMustBeDigitsOnly;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resending.
  ///
  /// In en, this message translates to:
  /// **'Resending...'**
  String get resending;

  /// No description provided for @resendOtpIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {count} s'**
  String resendOtpIn(Object count);

  /// No description provided for @alreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'Already verified?'**
  String get alreadyVerified;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @chooseSiteToMonitor.
  ///
  /// In en, this message translates to:
  /// **'Choose a site to monitor real-time data'**
  String get chooseSiteToMonitor;

  /// No description provided for @searchByNameOrSpecies.
  ///
  /// In en, this message translates to:
  /// **'Search by name or species...'**
  String get searchByNameOrSpecies;

  /// No description provided for @completedPonds.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED PONDS'**
  String get completedPonds;

  /// No description provided for @completedSpecies.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED SPECIES'**
  String get completedSpecies;

  /// No description provided for @viewDashboard.
  ///
  /// In en, this message translates to:
  /// **'View Dashboard'**
  String get viewDashboard;

  /// No description provided for @fishCount.
  ///
  /// In en, this message translates to:
  /// **'Fish Count'**
  String get fishCount;

  /// No description provided for @oxygenO2.
  ///
  /// In en, this message translates to:
  /// **'Oxygen (O2)'**
  String get oxygenO2;

  /// No description provided for @tempLabel.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get tempLabel;

  /// No description provided for @tank.
  ///
  /// In en, this message translates to:
  /// **'Tank'**
  String get tank;

  /// No description provided for @tankNumber.
  ///
  /// In en, this message translates to:
  /// **'Tank #01'**
  String get tankNumber;

  /// No description provided for @activeMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Active Monitoring'**
  String get activeMonitoring;

  /// No description provided for @waterQualityStatus.
  ///
  /// In en, this message translates to:
  /// **'Water Quality Status'**
  String get waterQualityStatus;

  /// No description provided for @feedSchedule.
  ///
  /// In en, this message translates to:
  /// **'Feed Schedule'**
  String get feedSchedule;

  /// No description provided for @noFeedSchedule.
  ///
  /// In en, this message translates to:
  /// **'No Feeding Schedule'**
  String get noFeedSchedule;

  /// No description provided for @viewAllFeedingEvents.
  ///
  /// In en, this message translates to:
  /// **'View all feeding events'**
  String get viewAllFeedingEvents;

  /// No description provided for @optimalStatus.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get optimalStatus;

  /// No description provided for @criticalStatus.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get criticalStatus;

  /// No description provided for @waitingForSensorData.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sensor data...'**
  String get waitingForSensorData;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'min ago'**
  String get minutesAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'h ago'**
  String get hoursAgo;

  /// No description provided for @updatedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedPrefix;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @stockOk.
  ///
  /// In en, this message translates to:
  /// **'Stock OK'**
  String get stockOk;

  /// No description provided for @feedStockSensor.
  ///
  /// In en, this message translates to:
  /// **'Feed Stock (Sensor)'**
  String get feedStockSensor;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @sensorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Sensor Dashboard'**
  String get sensorDashboard;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noSensorData.
  ///
  /// In en, this message translates to:
  /// **'No sensor data available'**
  String get noSensorData;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @createPond.
  ///
  /// In en, this message translates to:
  /// **'Create Pond'**
  String get createPond;

  /// No description provided for @editPond.
  ///
  /// In en, this message translates to:
  /// **'Edit Pond'**
  String get editPond;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @deletePond.
  ///
  /// In en, this message translates to:
  /// **'Delete Pond'**
  String get deletePond;

  /// No description provided for @deletePondConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this pond?'**
  String get deletePondConfirm;

  /// No description provided for @pondDeleted.
  ///
  /// In en, this message translates to:
  /// **'Pond deleted successfully'**
  String get pondDeleted;

  /// No description provided for @failedToDeletePond.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete pond'**
  String get failedToDeletePond;

  /// No description provided for @failedToLoadPonds.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ponds'**
  String get failedToLoadPonds;

  /// No description provided for @errorLoadingPonds.
  ///
  /// In en, this message translates to:
  /// **'Error loading ponds'**
  String get errorLoadingPonds;

  /// No description provided for @activePonds.
  ///
  /// In en, this message translates to:
  /// **'Active Ponds'**
  String get activePonds;

  /// No description provided for @addNewTime.
  ///
  /// In en, this message translates to:
  /// **'Add New Time'**
  String get addNewTime;

  /// No description provided for @feedTime.
  ///
  /// In en, this message translates to:
  /// **'Feed Time'**
  String get feedTime;

  /// No description provided for @amountKg.
  ///
  /// In en, this message translates to:
  /// **'Amount (kg)'**
  String get amountKg;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @actionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @typeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search (Kh/En)'**
  String get typeToSearch;

  /// No description provided for @enterNumberOfFish.
  ///
  /// In en, this message translates to:
  /// **'Enter number of fish'**
  String get enterNumberOfFish;

  /// No description provided for @eg50.
  ///
  /// In en, this message translates to:
  /// **'e.g. 50'**
  String get eg50;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @totalDailyFeed.
  ///
  /// In en, this message translates to:
  /// **'Total daily feed'**
  String get totalDailyFeed;

  /// No description provided for @perFeed3x.
  ///
  /// In en, this message translates to:
  /// **'Per feed (3x)'**
  String get perFeed3x;

  /// No description provided for @monthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget (30 days)'**
  String get monthlyBudget;

  /// No description provided for @recommendedSchedule.
  ///
  /// In en, this message translates to:
  /// **'Recommended schedule'**
  String get recommendedSchedule;

  /// No description provided for @morningSchedule.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morningSchedule;

  /// No description provided for @middaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Midday'**
  String get middaySchedule;

  /// No description provided for @eveningSchedule.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get eveningSchedule;

  /// No description provided for @stockingDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Stocking date (optional)'**
  String get stockingDateOptional;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @avgWeightPerFish.
  ///
  /// In en, this message translates to:
  /// **'Or enter current average weight per fish (g)'**
  String get avgWeightPerFish;

  /// No description provided for @searchSpecies.
  ///
  /// In en, this message translates to:
  /// **'Search species'**
  String get searchSpecies;

  /// No description provided for @noPonds.
  ///
  /// In en, this message translates to:
  /// **'No ponds available'**
  String get noPonds;

  /// No description provided for @sensorDataUpdated.
  ///
  /// In en, this message translates to:
  /// **'Sensor data updated'**
  String get sensorDataUpdated;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @noScheduleForToday.
  ///
  /// In en, this message translates to:
  /// **'No schedule for today'**
  String get noScheduleForToday;

  /// No description provided for @feedCount.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feedCount;

  /// No description provided for @noSensorDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No sensor data available'**
  String get noSensorDataAvailable;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to'**
  String get otpSentTo;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'ALERTS'**
  String get alerts;

  /// No description provided for @noCompletedPonds.
  ///
  /// In en, this message translates to:
  /// **'No completed ponds yet'**
  String get noCompletedPonds;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @enterSiteLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter site location'**
  String get enterSiteLocation;

  /// No description provided for @pleaseEnterSiteLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter site location'**
  String get pleaseEnterSiteLocation;

  /// No description provided for @speciesExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., Tilapia'**
  String get speciesExample;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @pleaseSelectStartDate.
  ///
  /// In en, this message translates to:
  /// **'Please select start date'**
  String get pleaseSelectStartDate;

  /// No description provided for @pleaseSelectEndDate.
  ///
  /// In en, this message translates to:
  /// **'Please select end date'**
  String get pleaseSelectEndDate;

  /// No description provided for @endDateAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End date must be after start date'**
  String get endDateAfterStart;

  /// No description provided for @addFeedingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add Feeding Schedule'**
  String get addFeedingSchedule;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @pleaseSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a time'**
  String get pleaseSelectTime;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @feedingTimeExists.
  ///
  /// In en, this message translates to:
  /// **'This feeding time already exists'**
  String get feedingTimeExists;

  /// No description provided for @pleaseAddFeedingTime.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one feeding time'**
  String get pleaseAddFeedingTime;

  /// No description provided for @recommendedFeeding.
  ///
  /// In en, this message translates to:
  /// **'Recommended Feeding'**
  String get recommendedFeeding;

  /// No description provided for @calculateRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Calculate recommendation'**
  String get calculateRecommendation;

  /// No description provided for @applyRecommendedAmounts.
  ///
  /// In en, this message translates to:
  /// **'Apply recommended amounts'**
  String get applyRecommendedAmounts;

  /// No description provided for @addEstCountFirst.
  ///
  /// In en, this message translates to:
  /// **'Add an estimated fish count first to see a recommendation.'**
  String get addEstCountFirst;

  /// No description provided for @enterCountForRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Enter estimated fish count to calculate a recommendation.'**
  String get enterCountForRecommendation;

  /// No description provided for @recommendedSummary.
  ///
  /// In en, this message translates to:
  /// **'{fish} fish • {biomass} kg biomass • {dayFeed} kg/day • {perFeed} kg/feed • {meals} meals'**
  String recommendedSummary(
    Object biomass,
    Object dayFeed,
    Object fish,
    Object meals,
    Object perFeed,
  );

  /// No description provided for @refreshAmountsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap again to refresh amounts with the latest estimated count and average fish weight.'**
  String get refreshAmountsHint;

  /// No description provided for @feedUptakeTipDescription.
  ///
  /// In en, this message translates to:
  /// **'TDS (water conductivity) and pH affect feed uptake — ensure TDS and pH are within safe ranges before dispensing. Sensors will auto-verify conditions before dispensing.'**
  String get feedUptakeTipDescription;

  /// No description provided for @sensorAlert.
  ///
  /// In en, this message translates to:
  /// **'Sensor Alert'**
  String get sensorAlert;

  /// No description provided for @sensorAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'One or more sensor readings (feed stock, pH, TDS, temperature) indicate attention is needed.'**
  String get sensorAlertMessage;

  /// No description provided for @pondCreated.
  ///
  /// In en, this message translates to:
  /// **'Pond created successfully'**
  String get pondCreated;

  /// No description provided for @pondUpdated.
  ///
  /// In en, this message translates to:
  /// **'Pond updated successfully'**
  String get pondUpdated;

  /// No description provided for @failedToSavePond.
  ///
  /// In en, this message translates to:
  /// **'Failed to save pond'**
  String get failedToSavePond;

  /// No description provided for @pondSavedBindingFailed.
  ///
  /// In en, this message translates to:
  /// **'Pond saved but hardware binding failed — reopen the pond and retry.'**
  String get pondSavedBindingFailed;

  /// No description provided for @hardwareAlreadyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Hardware \"{label}\" is already assigned to another pond. Complete that pond first or choose different hardware.'**
  String hardwareAlreadyAssigned(String label);

  /// No description provided for @failedToRegisterHardware.
  ///
  /// In en, this message translates to:
  /// **'Failed to register hardware \"{label}\"'**
  String failedToRegisterHardware(String label);

  /// No description provided for @speciesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Tilapia'**
  String get speciesHint;

  /// No description provided for @applyRecommended.
  ///
  /// In en, this message translates to:
  /// **'Apply recommended amounts'**
  String get applyRecommended;

  /// No description provided for @tapToRefreshAmounts.
  ///
  /// In en, this message translates to:
  /// **'Tap again to refresh amounts with the latest estimated count and average fish weight.'**
  String get tapToRefreshAmounts;

  /// No description provided for @enterFishCountFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter estimated fish count to calculate a recommendation.'**
  String get enterFishCountFirst;

  /// No description provided for @addFishCountFirst.
  ///
  /// In en, this message translates to:
  /// **'Add an estimated fish count first to see a recommendation.'**
  String get addFishCountFirst;

  /// No description provided for @tapToCreateHardwareId.
  ///
  /// In en, this message translates to:
  /// **'Tap to create or assign a hardware ID'**
  String get tapToCreateHardwareId;

  /// No description provided for @assignHardwareId.
  ///
  /// In en, this message translates to:
  /// **'Assign Hardware ID'**
  String get assignHardwareId;

  /// No description provided for @availableDevices.
  ///
  /// In en, this message translates to:
  /// **'Available Devices'**
  String get availableDevices;

  /// No description provided for @generateNewId.
  ///
  /// In en, this message translates to:
  /// **'Generate new ID'**
  String get generateNewId;

  /// No description provided for @noRegisteredDevices.
  ///
  /// In en, this message translates to:
  /// **'No registered devices. Enter an ID manually below.'**
  String get noRegisteredDevices;

  /// No description provided for @orEnterHardwareId.
  ///
  /// In en, this message translates to:
  /// **'Or enter a hardware ID manually'**
  String get orEnterHardwareId;

  /// No description provided for @hardwareIdHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. FEEDER-09-AX'**
  String get hardwareIdHint;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @failedToCreateDevice.
  ///
  /// In en, this message translates to:
  /// **'Failed to create device: {error}'**
  String failedToCreateDevice(String error);
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
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
