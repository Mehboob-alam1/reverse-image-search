import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_af.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('af'),
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('pt'),
    Locale('tr'),
    Locale('ur'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Deep Image Search'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Search the web using any image.'**
  String get appTagline;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

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

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied;

  /// No description provided for @allowPermissions.
  ///
  /// In en, this message translates to:
  /// **'Allow Permissions'**
  String get allowPermissions;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello 👋'**
  String get hello;

  /// No description provided for @chooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseLanguageTitle;

  /// No description provided for @chooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language to continue.'**
  String get chooseLanguageSubtitle;

  /// No description provided for @languageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get languageSearchHint;

  /// No description provided for @proTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Reverse Image Search Pro'**
  String get proTitle;

  /// No description provided for @proSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get more powerful image search features and an ad-free experience.'**
  String get proSubtitle;

  /// No description provided for @proBenefitVisual.
  ///
  /// In en, this message translates to:
  /// **'Advanced Visual Search'**
  String get proBenefitVisual;

  /// No description provided for @proBenefitExact.
  ///
  /// In en, this message translates to:
  /// **'Exact Match Results'**
  String get proBenefitExact;

  /// No description provided for @proBenefitProducts.
  ///
  /// In en, this message translates to:
  /// **'Product Search'**
  String get proBenefitProducts;

  /// No description provided for @proBenefitFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get proBenefitFilters;

  /// No description provided for @proBenefitHistory.
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get proBenefitHistory;

  /// No description provided for @proBenefitFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get proBenefitFavorites;

  /// No description provided for @proBenefitAdFree.
  ///
  /// In en, this message translates to:
  /// **'Ad-Free Experience'**
  String get proBenefitAdFree;

  /// No description provided for @proBenefitFaster.
  ///
  /// In en, this message translates to:
  /// **'Faster Search Experience'**
  String get proBenefitFaster;

  /// No description provided for @proMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get proMonthly;

  /// No description provided for @proYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get proYearly;

  /// No description provided for @proBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best Value'**
  String get proBestValue;

  /// No description provided for @proSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial / Subscribe'**
  String get proSubscribe;

  /// No description provided for @proContinueFree.
  ///
  /// In en, this message translates to:
  /// **'Continue with Free'**
  String get proContinueFree;

  /// No description provided for @proRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get proRestore;

  /// No description provided for @proTrialInfo.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. You can cancel anytime in your store account settings.'**
  String get proTrialInfo;

  /// No description provided for @proPriceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Prices will appear after store products are configured.'**
  String get proPriceUnavailable;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Search Any Image'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Description.
  ///
  /// In en, this message translates to:
  /// **'Upload or capture an image and discover where it appears online.'**
  String get onboarding1Description;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Find Similar Images'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Description.
  ///
  /// In en, this message translates to:
  /// **'Discover visually similar images from across the web.'**
  String get onboarding2Description;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Discover Products'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Description.
  ///
  /// In en, this message translates to:
  /// **'Use images to find similar products and shopping results.'**
  String get onboarding3Description;

  /// No description provided for @onboarding4Title.
  ///
  /// In en, this message translates to:
  /// **'Save Your Searches'**
  String get onboarding4Title;

  /// No description provided for @onboarding4Description.
  ///
  /// In en, this message translates to:
  /// **'Keep your search history and favorite useful results.'**
  String get onboarding4Description;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'App Permissions'**
  String get permissionsTitle;

  /// No description provided for @permissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These permissions help you search images from your camera or gallery.'**
  String get permissionsSubtitle;

  /// No description provided for @permissionCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permissionCameraTitle;

  /// No description provided for @permissionCameraDescription.
  ///
  /// In en, this message translates to:
  /// **'Take a photo and search it.'**
  String get permissionCameraDescription;

  /// No description provided for @permissionPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get permissionPhotosTitle;

  /// No description provided for @permissionPhotosDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose an existing image.'**
  String get permissionPhotosDescription;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'This feature needs access. You can enable it in Settings.'**
  String get permissionDeniedBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @searchUsingImage.
  ///
  /// In en, this message translates to:
  /// **'Search using an image'**
  String get searchUsingImage;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @searchFromUrl.
  ///
  /// In en, this message translates to:
  /// **'Search from Image URL'**
  String get searchFromUrl;

  /// No description provided for @searchImage.
  ///
  /// In en, this message translates to:
  /// **'Search Image'**
  String get searchImage;

  /// No description provided for @imageUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/image.jpg'**
  String get imageUrlHint;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid image URL.'**
  String get invalidUrl;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @editImage.
  ///
  /// In en, this message translates to:
  /// **'Edit Image'**
  String get editImage;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @flip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get flip;

  /// No description provided for @flipHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Flip horizontally'**
  String get flipHorizontal;

  /// No description provided for @flipVertical.
  ///
  /// In en, this message translates to:
  /// **'Flip vertically'**
  String get flipVertical;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @zoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get zoom;

  /// No description provided for @useThisImage.
  ///
  /// In en, this message translates to:
  /// **'Use This Image'**
  String get useThisImage;

  /// No description provided for @capturedImage.
  ///
  /// In en, this message translates to:
  /// **'Captured Image'**
  String get capturedImage;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @confirmPhoto.
  ///
  /// In en, this message translates to:
  /// **'Confirm Photo'**
  String get confirmPhoto;

  /// No description provided for @flash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get flash;

  /// No description provided for @switchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get switchCamera;

  /// No description provided for @searchOptions.
  ///
  /// In en, this message translates to:
  /// **'Search Options'**
  String get searchOptions;

  /// No description provided for @searchNow.
  ///
  /// In en, this message translates to:
  /// **'Search Now'**
  String get searchNow;

  /// No description provided for @searchTypeAll.
  ///
  /// In en, this message translates to:
  /// **'All Results'**
  String get searchTypeAll;

  /// No description provided for @searchTypeAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Search everything.'**
  String get searchTypeAllDesc;

  /// No description provided for @searchTypeVisual.
  ///
  /// In en, this message translates to:
  /// **'Visual Matches'**
  String get searchTypeVisual;

  /// No description provided for @searchTypeVisualDesc.
  ///
  /// In en, this message translates to:
  /// **'Find visually similar images.'**
  String get searchTypeVisualDesc;

  /// No description provided for @searchTypeExact.
  ///
  /// In en, this message translates to:
  /// **'Exact Matches'**
  String get searchTypeExact;

  /// No description provided for @searchTypeExactDesc.
  ///
  /// In en, this message translates to:
  /// **'Find pages and images that match the uploaded image.'**
  String get searchTypeExactDesc;

  /// No description provided for @searchTypeProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get searchTypeProducts;

  /// No description provided for @searchTypeProductsDesc.
  ///
  /// In en, this message translates to:
  /// **'Find visually related products.'**
  String get searchTypeProductsDesc;

  /// No description provided for @searchTypeAbout.
  ///
  /// In en, this message translates to:
  /// **'About This Image'**
  String get searchTypeAbout;

  /// No description provided for @searchTypeAboutDesc.
  ///
  /// In en, this message translates to:
  /// **'Find information and context about the image.'**
  String get searchTypeAboutDesc;

  /// No description provided for @analyzingImage.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image...'**
  String get analyzingImage;

  /// No description provided for @searchingWeb.
  ///
  /// In en, this message translates to:
  /// **'Searching the web...'**
  String get searchingWeb;

  /// No description provided for @findingVisualMatches.
  ///
  /// In en, this message translates to:
  /// **'Finding visual matches...'**
  String get findingVisualMatches;

  /// No description provided for @findingRelatedResults.
  ///
  /// In en, this message translates to:
  /// **'Finding related results...'**
  String get findingRelatedResults;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabVisual.
  ///
  /// In en, this message translates to:
  /// **'Visual'**
  String get tabVisual;

  /// No description provided for @tabExact.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get tabExact;

  /// No description provided for @tabProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get tabProducts;

  /// No description provided for @tabAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get tabAbout;

  /// No description provided for @openWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open Website'**
  String get openWebsite;

  /// No description provided for @viewProduct.
  ///
  /// In en, this message translates to:
  /// **'View Product'**
  String get viewProduct;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove favorite'**
  String get unfavorite;

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source: {domain}'**
  String sourceLabel(String domain);

  /// No description provided for @noExactMatches.
  ///
  /// In en, this message translates to:
  /// **'No exact matches found.\nTry Visual Matches instead.'**
  String get noExactMatches;

  /// No description provided for @aboutUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No additional information is available for this image.'**
  String get aboutUnavailable;

  /// No description provided for @relatedWebsites.
  ///
  /// In en, this message translates to:
  /// **'Related websites'**
  String get relatedWebsites;

  /// No description provided for @imageContext.
  ///
  /// In en, this message translates to:
  /// **'Image context'**
  String get imageContext;

  /// No description provided for @possibleSource.
  ///
  /// In en, this message translates to:
  /// **'Possible source'**
  String get possibleSource;

  /// No description provided for @relatedSearches.
  ///
  /// In en, this message translates to:
  /// **'Related searches'**
  String get relatedSearches;

  /// No description provided for @imageMetadata.
  ///
  /// In en, this message translates to:
  /// **'Image metadata'**
  String get imageMetadata;

  /// No description provided for @copyrightNotice.
  ///
  /// In en, this message translates to:
  /// **'Search results come from third-party websites and may be subject to their copyright and terms. This app does not claim ownership of third-party images.'**
  String get copyrightNotice;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get historyTitle;

  /// No description provided for @clearAllHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear All History'**
  String get clearAllHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all search history? This cannot be undone.'**
  String get clearHistoryConfirm;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @noFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Favorites Yet'**
  String get noFavoritesTitle;

  /// No description provided for @noFavoritesBody.
  ///
  /// In en, this message translates to:
  /// **'Save useful search results and they will appear here.'**
  String get noFavoritesBody;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get freePlan;

  /// No description provided for @proMember.
  ///
  /// In en, this message translates to:
  /// **'Pro Member'**
  String get proMember;

  /// No description provided for @advancedFeaturesEnabled.
  ///
  /// In en, this message translates to:
  /// **'Advanced features enabled'**
  String get advancedFeaturesEnabled;

  /// No description provided for @searchesUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} / {limit} searches used'**
  String searchesUsed(int used, int limit);

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

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

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @searchSettings.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchSettings;

  /// No description provided for @defaultSearchMode.
  ///
  /// In en, this message translates to:
  /// **'Default search mode'**
  String get defaultSearchMode;

  /// No description provided for @openResultsExternally.
  ///
  /// In en, this message translates to:
  /// **'Open results externally'**
  String get openResultsExternally;

  /// No description provided for @saveHistoryAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Save history automatically'**
  String get saveHistoryAutomatically;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will delete your account and associated data. Continue?'**
  String get deleteAccountConfirm;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a Problem'**
  String get reportProblem;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetTitle;

  /// No description provided for @noInternetBody.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get noInternetBody;

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Results Found'**
  String get noResultsTitle;

  /// No description provided for @noResultsBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find matching results for this image.\nTry another image.'**
  String get noResultsBody;

  /// No description provided for @searchFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Failed'**
  String get searchFailedTitle;

  /// No description provided for @searchFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while searching.\nPlease try again.'**
  String get searchFailedBody;

  /// No description provided for @serviceUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Search service is temporarily unavailable.'**
  String get serviceUnavailableTitle;

  /// No description provided for @serviceUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again later.'**
  String get serviceUnavailableBody;

  /// No description provided for @unsupportedImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsupported Image'**
  String get unsupportedImageTitle;

  /// No description provided for @unsupportedImageBody.
  ///
  /// In en, this message translates to:
  /// **'Please select a JPG, PNG, or WEBP image.'**
  String get unsupportedImageBody;

  /// No description provided for @rateLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Limit Reached'**
  String get rateLimitTitle;

  /// No description provided for @rateLimitBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your current search limit.\nUpgrade to Pro or try again later.'**
  String get rateLimitBody;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This image is too large. Please choose a smaller file.'**
  String get fileTooLarge;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @guestContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get guestContinue;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get googleSignIn;

  /// No description provided for @loggedOut.
  ///
  /// In en, this message translates to:
  /// **'You have been signed out.'**
  String get loggedOut;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @proRequired.
  ///
  /// In en, this message translates to:
  /// **'This feature is available on Pro.'**
  String get proRequired;

  /// No description provided for @emptyHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No search history yet'**
  String get emptyHistoryTitle;

  /// No description provided for @emptyHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'Your recent reverse image searches will appear here.'**
  String get emptyHistoryBody;

  /// No description provided for @resultDetails.
  ///
  /// In en, this message translates to:
  /// **'Result Details'**
  String get resultDetails;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out this image result:\n{url}'**
  String shareMessage(String url);

  /// No description provided for @languageNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEnglish;

  /// No description provided for @languageNameUrdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get languageNameUrdu;

  /// No description provided for @languageNameArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageNameArabic;

  /// No description provided for @languageNameHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageNameHindi;

  /// No description provided for @languageNameSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageNameSpanish;

  /// No description provided for @languageNameFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageNameFrench;

  /// No description provided for @languageNameGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageNameGerman;

  /// No description provided for @languageNamePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languageNamePortuguese;

  /// No description provided for @languageNameTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageNameTurkish;

  /// No description provided for @languageNameIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get languageNameIndonesian;

  /// No description provided for @languageNameItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get languageNameItalian;

  /// No description provided for @languageNameAfrikaans.
  ///
  /// In en, this message translates to:
  /// **'Afrikaans'**
  String get languageNameAfrikaans;

  /// No description provided for @splashAdNotice.
  ///
  /// In en, this message translates to:
  /// **'This action may perform an ad'**
  String get splashAdNotice;

  /// No description provided for @selectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguageTitle;

  /// No description provided for @languageDefault.
  ///
  /// In en, this message translates to:
  /// **'(Default)'**
  String get languageDefault;

  /// No description provided for @whoAreYouLookingFor.
  ///
  /// In en, this message translates to:
  /// **'Who are you\nlooking for?'**
  String get whoAreYouLookingFor;

  /// No description provided for @typeFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Type full name...'**
  String get typeFullNameHint;

  /// No description provided for @modeFaceTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Face Analysis'**
  String get modeFaceTitle;

  /// No description provided for @modeFaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use camera or select from gallery for analyzation.'**
  String get modeFaceSubtitle;

  /// No description provided for @modeSocialTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Media Deep Search'**
  String get modeSocialTitle;

  /// No description provided for @modeSocialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use social platforms for analyzation.'**
  String get modeSocialSubtitle;

  /// No description provided for @modeObjectTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Object & Landmark'**
  String get modeObjectTitle;

  /// No description provided for @modeObjectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use camera or select from gallery for recognition.'**
  String get modeObjectSubtitle;

  /// No description provided for @modeSimilarTitle.
  ///
  /// In en, this message translates to:
  /// **'Similar Faces from gallery'**
  String get modeSimilarTitle;

  /// No description provided for @modeSimilarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Gallery to detect Face.'**
  String get modeSimilarSubtitle;

  /// No description provided for @modeWebTitle.
  ///
  /// In en, this message translates to:
  /// **'Search from Web'**
  String get modeWebTitle;

  /// No description provided for @modeWebSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use camera or select from gallery to search from Web.'**
  String get modeWebSubtitle;

  /// No description provided for @modeDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Images'**
  String get modeDuplicateTitle;

  /// No description provided for @modeDuplicateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clean up your gallery delete duplicate images'**
  String get modeDuplicateSubtitle;

  /// No description provided for @badgeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get badgeNew;

  /// No description provided for @badgePro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get badgePro;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @moreApps.
  ///
  /// In en, this message translates to:
  /// **'More Apps'**
  String get moreApps;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @communityGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Community Guidelines'**
  String get communityGuidelines;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @adBadge.
  ///
  /// In en, this message translates to:
  /// **'Ad'**
  String get adBadge;

  /// No description provided for @analyzeImageThroughAi.
  ///
  /// In en, this message translates to:
  /// **'Analyze your image through AI.'**
  String get analyzeImageThroughAi;

  /// No description provided for @instagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagram;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @linkedin.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get linkedin;

  /// No description provided for @twitter.
  ///
  /// In en, this message translates to:
  /// **'Twitter'**
  String get twitter;

  /// No description provided for @loadingAd.
  ///
  /// In en, this message translates to:
  /// **'Loading Ad'**
  String get loadingAd;

  /// No description provided for @unlockAllFeatures.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK ALL FEATURES'**
  String get unlockAllFeatures;

  /// No description provided for @whatsIncluded.
  ///
  /// In en, this message translates to:
  /// **'What\'s Included'**
  String get whatsIncluded;

  /// No description provided for @featureWebSearching.
  ///
  /// In en, this message translates to:
  /// **'Web searching'**
  String get featureWebSearching;

  /// No description provided for @featureDuplicateImages.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Images'**
  String get featureDuplicateImages;

  /// No description provided for @featureFaceDetection.
  ///
  /// In en, this message translates to:
  /// **'High quality face detection'**
  String get featureFaceDetection;

  /// No description provided for @featureUnlimitedAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlimited access'**
  String get featureUnlimitedAccess;

  /// No description provided for @featureRemoveAds.
  ///
  /// In en, this message translates to:
  /// **'Remove ADS'**
  String get featureRemoveAds;

  /// No description provided for @featureVipSupport.
  ///
  /// In en, this message translates to:
  /// **'VIP Support'**
  String get featureVipSupport;

  /// No description provided for @proTrialWeekly.
  ///
  /// In en, this message translates to:
  /// **'3-day free trial includes 12 searches on the weekly plan. After the trial, billing continues at the weekly price unless you cancel at least 24 hours before renewal in Google Play or App Store settings.'**
  String get proTrialWeekly;

  /// No description provided for @subscriptionFreeTierNote.
  ///
  /// In en, this message translates to:
  /// **'Free: 5 lifetime searches on all modes.'**
  String get subscriptionFreeTierNote;

  /// No description provided for @subscriptionMonthlyNote.
  ///
  /// In en, this message translates to:
  /// **'Monthly: 120 searches every 30 days, billed through the store.'**
  String get subscriptionMonthlyNote;

  /// No description provided for @continueForFree.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE FOR FREE  →'**
  String get continueForFree;

  /// No description provided for @noPaymentNow.
  ///
  /// In en, this message translates to:
  /// **'No payment Now'**
  String get noPaymentNow;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select image'**
  String get selectImage;

  /// No description provided for @uploadingSerpApi.
  ///
  /// In en, this message translates to:
  /// **'Uploading image and searching with SerpApi'**
  String get uploadingSerpApi;

  /// No description provided for @communityGuidelinesBody.
  ///
  /// In en, this message translates to:
  /// **'Use Deep Image Search for lawful image lookup only.\n\nDo not use this app to harass, stalk, impersonate, or exploit anyone. Do not search for or share sexual content involving minors.\n\nRespect other people\'s privacy and the copyright of images you find. Results come from third-party websites and remain under those sites\' terms.\n\nWe may limit or refuse searches that abuse the service.'**
  String get communityGuidelinesBody;

  /// No description provided for @privacyPolicyBody.
  ///
  /// In en, this message translates to:
  /// **'Deep Image Search processes images you pick, capture, or provide by URL so we can perform reverse image searches through SerpApi Google Lens.\n\nLocal photos are uploaded to a temporary file host so the search provider can read them. We do not keep uploaded images on a custom server.\n\nSearch results are retrieved from third-party websites. Those websites remain the source of the images and may have their own copyright and terms.\n\nHistory and favorites stay on this device. Analytics events such as app opens, search started, and search completed may be collected. We do not collect image contents in analytics.\n\nSubscriptions are processed by Apple or Google. We do not store payment card details.\n\nYou can delete local history and remove favorites from the app.'**
  String get privacyPolicyBody;

  /// No description provided for @allowPhotoAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow photo access to search from gallery.'**
  String get allowPhotoAccess;

  /// No description provided for @allowCameraAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access to take a photo.'**
  String get allowCameraAccess;

  /// No description provided for @emptyImage.
  ///
  /// In en, this message translates to:
  /// **'The selected image is empty.'**
  String get emptyImage;

  /// No description provided for @shareAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Try Deep Image Search: {url}'**
  String shareAppMessage(String url);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'af',
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'it',
    'pt',
    'tr',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af':
      return AppLocalizationsAf();
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
