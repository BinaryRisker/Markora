import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Markora'**
  String get appTitle;

  /// Welcome message title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Markora'**
  String get welcomeTitle;

  /// Welcome message description
  ///
  /// In en, this message translates to:
  /// **'A lightweight and elegant Markdown editor.'**
  String get welcomeDescription;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Core features section title
  ///
  /// In en, this message translates to:
  /// **'Core Features'**
  String get coreFeatures;

  /// Real-time preview feature
  ///
  /// In en, this message translates to:
  /// **'Real-time Preview'**
  String get realtimePreview;

  /// Real-time preview description
  ///
  /// In en, this message translates to:
  /// **'WYSIWYG editing experience'**
  String get realtimePreviewDesc;

  /// Syntax highlighting feature
  ///
  /// In en, this message translates to:
  /// **'Syntax Highlighting'**
  String get syntaxHighlighting;

  /// Syntax highlighting description
  ///
  /// In en, this message translates to:
  /// **'Support for multiple programming languages'**
  String get syntaxHighlightingDesc;

  /// Math formulas feature
  ///
  /// In en, this message translates to:
  /// **'Math Formulas'**
  String get mathFormulas;

  /// Math formulas description
  ///
  /// In en, this message translates to:
  /// **'Support for LaTeX math formulas'**
  String get mathFormulasDesc;

  /// Chart support feature
  ///
  /// In en, this message translates to:
  /// **'Chart Support'**
  String get chartSupport;

  /// Chart support description
  ///
  /// In en, this message translates to:
  /// **'Integrated Mermaid charts'**
  String get chartSupportDesc;

  /// Quick start section title
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get quickStart;

  /// Quick start step 1
  ///
  /// In en, this message translates to:
  /// **'Enter Markdown content in the left editor'**
  String get quickStartStep1;

  /// Quick start step 2
  ///
  /// In en, this message translates to:
  /// **'The right side will show real-time preview'**
  String get quickStartStep2;

  /// Quick start step 3
  ///
  /// In en, this message translates to:
  /// **'Use the toolbar to quickly insert formats'**
  String get quickStartStep3;

  /// Code example section title
  ///
  /// In en, this message translates to:
  /// **'Code Example'**
  String get codeExample;

  /// Inline formula label
  ///
  /// In en, this message translates to:
  /// **'Inline formula'**
  String get inlineFormula;

  /// Block formula label
  ///
  /// In en, this message translates to:
  /// **'Block formula'**
  String get blockFormula;

  /// Feature column header
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get feature;

  /// Status column header
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Description column header
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Editor view mode
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// Preview view mode
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// Completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Start journey message
  ///
  /// In en, this message translates to:
  /// **'Start your Markdown creation journey!'**
  String get startJourney;

  /// New document button tooltip
  ///
  /// In en, this message translates to:
  /// **'New Document'**
  String get newDocument;

  /// Open document button tooltip
  ///
  /// In en, this message translates to:
  /// **'Open Document'**
  String get openDocument;

  /// Save document button tooltip
  ///
  /// In en, this message translates to:
  /// **'Save Document'**
  String get saveDocument;

  /// Save as button tooltip
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get saveAs;

  /// Export document button tooltip
  ///
  /// In en, this message translates to:
  /// **'Export Document'**
  String get exportDocument;

  /// Undo button tooltip
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Redo button tooltip
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// Plugin management page title
  ///
  /// In en, this message translates to:
  /// **'Plugin Management'**
  String get pluginManagement;

  /// Settings button tooltip
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Source mode option
  ///
  /// In en, this message translates to:
  /// **'Source mode'**
  String get sourceMode;

  /// Split mode option
  ///
  /// In en, this message translates to:
  /// **'Split mode'**
  String get splitMode;

  /// Preview mode option
  ///
  /// In en, this message translates to:
  /// **'Preview mode'**
  String get previewMode;

  /// Characters count label
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get characters;

  /// Words count label
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get words;

  /// Lines count label
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get lines;

  /// Line position label
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get line;

  /// Column position label
  ///
  /// In en, this message translates to:
  /// **'Column'**
  String get column;

  /// Cursor position label
  ///
  /// In en, this message translates to:
  /// **'Cursor Position'**
  String get cursorPosition;

  /// Start creating placeholder text
  ///
  /// In en, this message translates to:
  /// **'Start your creation...'**
  String get startCreating;

  /// Document created success message
  ///
  /// In en, this message translates to:
  /// **'Document created'**
  String get documentCreated;

  /// Create document failed error message
  ///
  /// In en, this message translates to:
  /// **'Failed to create document'**
  String get createDocumentFailed;

  /// Open markdown file dialog title
  ///
  /// In en, this message translates to:
  /// **'Open Markdown File'**
  String get openMarkdownFile;

  /// Document opened success message
  ///
  /// In en, this message translates to:
  /// **'Document opened'**
  String get documentOpened;

  /// Open document failed error message
  ///
  /// In en, this message translates to:
  /// **'Failed to open document'**
  String get openDocumentFailed;

  /// Document saved success message
  ///
  /// In en, this message translates to:
  /// **'Document saved'**
  String get documentSaved;

  /// Save failed error message
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// Document saved as success message
  ///
  /// In en, this message translates to:
  /// **'Document saved as {path}'**
  String documentSavedAs(String path);

  /// Save as error message
  ///
  /// In en, this message translates to:
  /// **'Save As Error'**
  String get saveAsError;

  /// Untitled document default name
  ///
  /// In en, this message translates to:
  /// **'Untitled Document'**
  String get untitledDocument;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Chinese language option
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// Appearance settings section title
  ///
  /// In en, this message translates to:
  /// **'Appearance Settings'**
  String get appearanceSettings;

  /// Editor settings section title
  ///
  /// In en, this message translates to:
  /// **'Editor Settings'**
  String get editorSettings;

  /// Behavior settings section title
  ///
  /// In en, this message translates to:
  /// **'Behavior Settings'**
  String get behaviorSettings;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Theme mode setting label
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// Follow system theme option
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get followSystem;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Editor theme setting
  ///
  /// In en, this message translates to:
  /// **'Editor Theme'**
  String get editorTheme;

  /// Font size setting label
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// Font family setting label
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamily;

  /// Show line numbers setting label
  ///
  /// In en, this message translates to:
  /// **'Show Line Numbers'**
  String get showLineNumbers;

  /// Enabled status
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// Disabled status
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// Word wrap setting
  ///
  /// In en, this message translates to:
  /// **'Word Wrap'**
  String get wordWrap;

  /// Default view mode setting
  ///
  /// In en, this message translates to:
  /// **'Default View Mode'**
  String get defaultViewMode;

  /// Auto save setting label
  ///
  /// In en, this message translates to:
  /// **'Auto Save'**
  String get autoSave;

  /// Auto save interval setting
  ///
  /// In en, this message translates to:
  /// **'Auto Save Interval'**
  String get autoSaveInterval;

  /// Seconds unit
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get seconds;

  /// Live preview setting
  ///
  /// In en, this message translates to:
  /// **'Live Preview'**
  String get livePreview;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Install plugin button tooltip
  ///
  /// In en, this message translates to:
  /// **'Install Plugin'**
  String get installPlugin;

  /// Refresh button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// All plugins tab label
  ///
  /// In en, this message translates to:
  /// **'All Plugins'**
  String get allPlugins;

  /// Enabled plugins tab label
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabledPlugins;

  /// Plugin store tab label
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get pluginStore;

  /// No plugins message
  ///
  /// In en, this message translates to:
  /// **'No plugins'**
  String get noPlugins;

  /// Install plugins instruction
  ///
  /// In en, this message translates to:
  /// **'Click the + button in the top right to install plugins'**
  String get clickToInstallPlugins;

  /// No enabled plugins message
  ///
  /// In en, this message translates to:
  /// **'No enabled plugins'**
  String get noEnabledPlugins;

  /// Enable plugins instruction
  ///
  /// In en, this message translates to:
  /// **'Enable plugins in the All Plugins tab'**
  String get enablePluginsInAllTab;

  /// Coming soon message
  ///
  /// In en, this message translates to:
  /// **'Coming soon...'**
  String get comingSoon;

  /// Install from file option
  ///
  /// In en, this message translates to:
  /// **'Install from File'**
  String get installFromFile;

  /// Select plugin file description
  ///
  /// In en, this message translates to:
  /// **'Select plugin file (.zip)'**
  String get selectPluginFile;

  /// Install from URL option
  ///
  /// In en, this message translates to:
  /// **'Install from URL'**
  String get installFromUrl;

  /// Enter plugin URL description
  ///
  /// In en, this message translates to:
  /// **'Enter plugin download link'**
  String get enterPluginUrl;

  /// Install from store option
  ///
  /// In en, this message translates to:
  /// **'Install from Store'**
  String get installFromStore;

  /// Browse plugin store description
  ///
  /// In en, this message translates to:
  /// **'Browse plugin store'**
  String get browsePluginStore;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Install button
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// Insert button
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get insert;

  /// Plugin URL input label
  ///
  /// In en, this message translates to:
  /// **'Plugin URL'**
  String get pluginUrl;

  /// Select plugin file prompt
  ///
  /// In en, this message translates to:
  /// **'Please select plugin file'**
  String get pleaseSelectPluginFile;

  /// Installation failed message
  ///
  /// In en, this message translates to:
  /// **'Installation failed'**
  String get installFailed;

  /// Downloading plugin message
  ///
  /// In en, this message translates to:
  /// **'Downloading plugin...'**
  String get downloadingPlugin;

  /// URL install development message
  ///
  /// In en, this message translates to:
  /// **'URL installation feature is under development'**
  String get urlInstallInDevelopment;

  /// Refresh complete message
  ///
  /// In en, this message translates to:
  /// **'Refresh complete'**
  String get refreshComplete;

  /// Refresh failed message
  ///
  /// In en, this message translates to:
  /// **'Refresh failed'**
  String get refreshFailed;

  /// Author label
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// Type label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Homepage label
  ///
  /// In en, this message translates to:
  /// **'Homepage'**
  String get homepage;

  /// Tags field label
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// Disable button
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// Enable button
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// Uninstall button
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Confirm uninstall dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Uninstall'**
  String get confirmUninstall;

  /// Uninstall confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to uninstall plugin \"{pluginName}\"? This action cannot be undone.'**
  String uninstallConfirmation(String pluginName);

  /// Plugin disabled success message
  ///
  /// In en, this message translates to:
  /// **'Plugin disabled'**
  String get pluginDisabled;

  /// Disable plugin failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to disable plugin'**
  String get disablePluginFailed;

  /// Plugin enabled success message
  ///
  /// In en, this message translates to:
  /// **'Plugin enabled'**
  String get pluginEnabled;

  /// Enable plugin failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to enable plugin'**
  String get enablePluginFailed;

  /// Plugin uninstalled success message
  ///
  /// In en, this message translates to:
  /// **'Plugin uninstalled'**
  String get pluginUninstalled;

  /// Uninstall plugin failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to uninstall plugin'**
  String get uninstallPluginFailed;

  /// Initialize plugin manager failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize plugin manager'**
  String get initializePluginManagerFailed;

  /// Split view mode
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// Editor placeholder text
  ///
  /// In en, this message translates to:
  /// **'Enter Markdown content here...'**
  String get enterMarkdownContent;

  /// Math formula dialog title
  ///
  /// In en, this message translates to:
  /// **'Insert Math Formula'**
  String get insertMathFormula;

  /// Formula type label
  ///
  /// In en, this message translates to:
  /// **'Formula type: '**
  String get formulaType;

  /// Inline formula option
  ///
  /// In en, this message translates to:
  /// **'Inline formula'**
  String get inlineFormulaOption;

  /// Block formula option
  ///
  /// In en, this message translates to:
  /// **'Block formula'**
  String get blockFormulaOption;

  /// LaTeX formula input label
  ///
  /// In en, this message translates to:
  /// **'LaTeX Formula'**
  String get latexFormula;

  /// Formula example hint
  ///
  /// In en, this message translates to:
  /// **'e.g.: E = mc^2'**
  String get formulaExample;

  /// Common formulas label
  ///
  /// In en, this message translates to:
  /// **'Common formulas:'**
  String get commonFormulas;

  /// Preview placeholder text
  ///
  /// In en, this message translates to:
  /// **'Preview will be shown here'**
  String get previewWillBeShownHere;

  /// Preview empty state message
  ///
  /// In en, this message translates to:
  /// **'Enter Markdown content in the left editor'**
  String get enterMarkdownContentInLeftEditor;

  /// Preview empty state description
  ///
  /// In en, this message translates to:
  /// **'Preview will be displayed here'**
  String get previewWillBeDisplayedHere;

  /// Export as PDF tooltip
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportAsPdf;

  /// Export as HTML tooltip
  ///
  /// In en, this message translates to:
  /// **'Export as HTML'**
  String get exportAsHtml;

  /// Refresh preview tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh Preview'**
  String get refreshPreview;

  /// No open documents message
  ///
  /// In en, this message translates to:
  /// **'No open documents'**
  String get noOpenDocuments;

  /// Instructions for creating new document
  ///
  /// In en, this message translates to:
  /// **'Click the + button above to create a new document, or open an existing document from the file menu'**
  String get clickPlusButtonToCreate;

  /// Select language option
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Configure button
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configure;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Failed to load configuration error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load configuration'**
  String get failedToLoadConfiguration;

  /// Light theme mode option
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// Dark mode theme option
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPage;

  /// Configuration title
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No configurable options message
  ///
  /// In en, this message translates to:
  /// **'No configurable options available for this plugin.'**
  String get noConfigurableOptions;

  /// Welcome document title
  ///
  /// In en, this message translates to:
  /// **'Welcome Document'**
  String get welcomeDocument;

  /// Heading toolbar button tooltip
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get heading;

  /// Link toolbar button tooltip
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// Image toolbar button tooltip
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// Code block toolbar button tooltip
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get codeBlock;

  /// Math formula toolbar button tooltip
  ///
  /// In en, this message translates to:
  /// **'Math formula'**
  String get mathFormula;

  /// Quote toolbar button tooltip
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get quote;

  /// Unordered list toolbar button tooltip
  ///
  /// In en, this message translates to:
  /// **'Unordered list'**
  String get unorderedList;

  /// Ordered list toolbar button tooltip
  ///
  /// In en, this message translates to:
  /// **'Ordered list'**
  String get orderedList;

  /// Plugin statistics card title
  ///
  /// In en, this message translates to:
  /// **'Plugin Statistics'**
  String get pluginStatistics;

  /// Total plugins count label
  ///
  /// In en, this message translates to:
  /// **'Total Plugins'**
  String get totalPlugins;

  /// Plugin distribution by type section title
  ///
  /// In en, this message translates to:
  /// **'Distribution by Type'**
  String get distributionByType;

  /// Error status
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// Syntax plugin type
  ///
  /// In en, this message translates to:
  /// **'Syntax Plugin'**
  String get syntaxPlugin;

  /// Renderer plugin type
  ///
  /// In en, this message translates to:
  /// **'Renderer Plugin'**
  String get rendererPlugin;

  /// Theme plugin type
  ///
  /// In en, this message translates to:
  /// **'Theme Plugin'**
  String get themePlugin;

  /// Export plugin type
  ///
  /// In en, this message translates to:
  /// **'Export Plugin'**
  String get exportPlugin;

  /// Exporter plugin type
  ///
  /// In en, this message translates to:
  /// **'Exporter Plugin'**
  String get exporterPlugin;

  /// Import plugin type
  ///
  /// In en, this message translates to:
  /// **'Import Plugin'**
  String get importPlugin;

  /// Tool plugin type
  ///
  /// In en, this message translates to:
  /// **'Tool Plugin'**
  String get toolPlugin;

  /// Widget plugin type
  ///
  /// In en, this message translates to:
  /// **'Widget Plugin'**
  String get widgetPlugin;

  /// Component plugin type
  ///
  /// In en, this message translates to:
  /// **'Component Plugin'**
  String get componentPlugin;

  /// Integration plugin type
  ///
  /// In en, this message translates to:
  /// **'Integration Plugin'**
  String get integrationPlugin;

  /// Other plugin type
  ///
  /// In en, this message translates to:
  /// **'Other Plugin'**
  String get otherPlugin;

  /// Enabled plugin status
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabledStatus;

  /// Disabled plugin status
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabledStatus;

  /// Installed plugin status
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installedStatus;

  /// Error plugin status
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorStatus;

  /// Loading plugin status
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingStatus;

  /// All status filter option
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get allStatus;

  /// Filter and sort section title
  ///
  /// In en, this message translates to:
  /// **'Filter and Sort'**
  String get filterAndSort;

  /// Plugin type filter label
  ///
  /// In en, this message translates to:
  /// **'Plugin Type'**
  String get pluginType;

  /// All types filter option
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// All filter option
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Ascending sort order
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// Descending sort order
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// Plugin search input hint text
  ///
  /// In en, this message translates to:
  /// **'Search plugin name, description or tags...'**
  String get searchPluginHint;

  /// Clear search button tooltip
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// Advanced search button tooltip and dialog title
  ///
  /// In en, this message translates to:
  /// **'Advanced search'**
  String get advancedSearch;

  /// Plugin name
  ///
  /// In en, this message translates to:
  /// **'Plugin Name'**
  String get pluginName;

  /// Description keywords field label
  ///
  /// In en, this message translates to:
  /// **'Description Keywords'**
  String get descriptionKeywords;

  /// Tags field hint text
  ///
  /// In en, this message translates to:
  /// **'e.g: markdown, editor, syntax'**
  String get tagsHint;

  /// Tags field label with comma separated note
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get tagsCommaSeparated;

  /// Advanced search tip message
  ///
  /// In en, this message translates to:
  /// **'Tip: Advanced search feature coming soon, currently only basic search is supported'**
  String get advancedSearchTip;

  /// Clear button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Search button text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Sort by label
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// More filters button tooltip
  ///
  /// In en, this message translates to:
  /// **'More Filters'**
  String get moreFilters;

  /// Advanced filters dialog title
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get advancedFilters;

  /// All statuses option
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// Reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Install date
  ///
  /// In en, this message translates to:
  /// **'Install Date'**
  String get installDate;

  /// Last updated label
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// Name label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Pandoc export feature name
  ///
  /// In en, this message translates to:
  /// **'Pandoc Export'**
  String get pandocExport;

  /// Pandoc import feature name
  ///
  /// In en, this message translates to:
  /// **'Pandoc Import'**
  String get pandocImport;

  /// Pandoc export dialog title
  ///
  /// In en, this message translates to:
  /// **'Export with Pandoc'**
  String get exportWithPandoc;

  /// Pandoc import dialog title
  ///
  /// In en, this message translates to:
  /// **'Import with Pandoc'**
  String get importWithPandoc;

  /// Export format selection label
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportFormat;

  /// Import format selection label
  ///
  /// In en, this message translates to:
  /// **'Import Format'**
  String get importFormat;

  /// Output path selection label
  ///
  /// In en, this message translates to:
  /// **'Output Path'**
  String get outputPath;

  /// Input file selection label
  ///
  /// In en, this message translates to:
  /// **'Input File'**
  String get inputFile;

  /// Select output file prompt
  ///
  /// In en, this message translates to:
  /// **'Select output file'**
  String get selectOutputFile;

  /// Select import file prompt
  ///
  /// In en, this message translates to:
  /// **'Select file to import'**
  String get selectFileToImport;

  /// Pandoc not installed error title
  ///
  /// In en, this message translates to:
  /// **'Pandoc not installed'**
  String get pandocNotInstalled;

  /// Pandoc installation requirement description
  ///
  /// In en, this message translates to:
  /// **'Pandoc is required for this feature. Please install Pandoc from https://pandoc.org/installing.html'**
  String get pandocRequired;

  /// Pandoc available status
  ///
  /// In en, this message translates to:
  /// **'Pandoc available'**
  String get pandocAvailable;

  /// Platform not supported prompt
  ///
  /// In en, this message translates to:
  /// **'This feature is only available on desktop platforms (Windows, macOS, Linux)'**
  String get platformNotSupported;

  /// Export successful message
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get exportSuccessful;

  /// Export failed message
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// Import successful message
  ///
  /// In en, this message translates to:
  /// **'Import successful'**
  String get importSuccessful;

  /// Import failed message
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// Browse button text
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// Export button text
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Import button text
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
