/// A lightweight Flutter package for showing customizable progress dialogs.
///
/// This library provides a simple way to display progress dialogs with two main types:
/// - Normal: Shows a simple loading message with a progress indicator
/// - Download: Shows progress percentage along with the loading message
///
/// The dialog is highly customizable and supports dynamic updates while being shown.
library;

import 'package:material_ui/material_ui.dart';

/// Defines the type of progress dialog to be displayed.
///
/// - [normal]: A simple dialog showing a loading message with progress indicator
/// - [download]: A dialog that displays progress percentage (e.g., "50/100")
enum ProgressDialogType { normal, download }

// ===== Global Configuration Variables =====
// These variables store the current state and styling configuration
// for the progress dialog. They are shared across all instances.

/// The message text displayed in the dialog
String _dialogMessage = "Loading...";

/// Current progress value and maximum progress value for download type dialogs
double _progress = 0.0, _maxProgress = 96.0;

/// Custom widget to replace the entire dialog body
Widget? _customBody;

/// Optional widget to display above the main dialog content
Widget? _widgetAboveTheDialog;

/// Text alignment for the message text
TextAlign _textAlign = TextAlign.start;

/// Alignment for the progress indicator widget
Alignment _progressWidgetAlignment = Alignment.centerLeft;

/// Text direction for RTL/LTR language support
TextDirection _direction = TextDirection.ltr;

// ===== Dialog State Variables =====

/// Whether the dialog is currently being shown (set synchronously by show()).
bool _isShowing = false;

/// Set when hide() is called before the dialog route has been built.
bool _hideRequested = false;

/// Incremented on every show(), so a late-completing old dialog future
/// can never reset the state of a newer dialog.
int _showId = 0;

/// Build contexts for showing and dismissing the dialog
BuildContext? _context, _dismissingContext;

/// The type of progress dialog (normal or download)
ProgressDialogType? _progressDialogType;

/// Whether the dialog can be dismissed by tapping outside or pressing back button.
/// Defaults to false: a loading dialog should not close on a stray tap.
bool _barrierDismissible = false;

/// Whether to show debug logs
bool _showLogs = false;

// ===== Styling Configuration =====

/// Text style for progress percentage text (used in download type)
TextStyle _progressTextStyle = const TextStyle(
  color: Colors.black,
  fontSize: 12.0,
  fontWeight: FontWeight.w400,
);

/// Text style for the main message text
TextStyle _messageStyle = const TextStyle(
  color: Colors.black,
  fontSize: 18.0,
  fontWeight: FontWeight.w600,
);

/// Dialog elevation and border radius values
double _dialogElevation = 8.0, _borderRadius = 8.0;

/// Background color of the dialog
Color _backgroundColor = Colors.white;

/// Animation curve for dialog appearance
Curve _insetAnimCurve = Curves.easeInOut;

/// Internal padding of the dialog content
EdgeInsets _dialogPadding = const EdgeInsets.all(8.0);

/// Path to the default loading animation asset
String assetPath = 'assets/double_ring_loading_io.gif';

/// Default progress indicator widget (animated loading GIF)
Widget _progressWidget = Image.asset(
  assetPath,
  package: 'progress_dialog_null_safe',
);

/// Global key for accessing the dialog body state
final GlobalKey<_DialogBodyState> _dialogBodyKey =
GlobalKey<_DialogBodyState>();

/// The main class for creating and managing progress dialogs.
///
/// This class provides a simple interface to show customizable progress dialogs
/// with support for two types: normal loading dialogs and download progress dialogs.
///
/// Example usage:
/// ```dart
/// final ProgressDialog pr = ProgressDialog(context);
/// pr.style(message: 'Loading...');
/// await pr.show();
/// // Update the dialog
/// pr.update(message: 'Almost done...');
/// await pr.hide();
/// ```
class ProgressDialog {
  // Internal reference to the dialog body widget
  _DialogBody? _dialog;

  /// Creates a new ProgressDialog instance.
  ///
  /// [context] is required and should be the build context where the dialog will be shown.
  ///
  /// Optional parameters:
  /// - [type]: The type of dialog (normal or download). Defaults to normal.
  /// - [isDismissible]: Whether the dialog can be dismissed by tapping outside or back button. Defaults to false.
  /// - [showLogs]: Whether to print debug logs. Defaults to false.
  /// - [textDirection]: Text direction for RTL/LTR support. Defaults to LTR.
  /// - [customBody]: Custom widget to replace the entire dialog body. Defaults to null.
  ProgressDialog(
      BuildContext context, {
        ProgressDialogType? type,
        bool? isDismissible,
        bool? showLogs,
        TextDirection? textDirection,
        Widget? customBody,
      }) {
    _context = context;
    _progressDialogType = type ?? ProgressDialogType.normal;
    _barrierDismissible = isDismissible ?? false;
    _showLogs = showLogs ?? false;
    _direction = textDirection ?? TextDirection.ltr;
    _customBody = customBody;
  }

  /// Configures the styling and appearance of the progress dialog.
  ///
  /// This method allows you to customize various aspects of the dialog appearance.
  /// All parameters are optional and will use default values if not provided.
  ///
  /// **Note:** This method has no effect if the dialog is already showing.
  ///
  /// Parameters:
  /// - [child]: Alternative progress widget (same as progressWidget)
  /// - [widgetAboveTheDialog]: Widget to display above the main dialog content
  /// - [progress]: Current progress value (only used for download type dialogs)
  /// - [maxProgress]: Maximum progress value (only used for download type dialogs)
  /// - [message]: Text message to display in the dialog
  /// - [progressWidget]: Custom widget to use as the progress indicator
  /// - [backgroundColor]: Background color of the dialog
  /// - [progressTextStyle]: Text style for progress percentage text
  /// - [messageTextStyle]: Text style for the main message
  /// - [elevation]: Dialog elevation (shadow depth)
  /// - [textAlign]: Text alignment for the message
  /// - [borderRadius]: Corner radius of the dialog
  /// - [insetAnimCurve]: Animation curve for dialog appearance
  /// - [padding]: Internal padding of the dialog content
  /// - [progressWidgetAlignment]: Alignment of the progress indicator
  void style({
    Widget? child,
    Widget? widgetAboveTheDialog,
    double? progress,
    double? maxProgress,
    String? message,
    Widget? progressWidget,
    Color? backgroundColor,
    TextStyle? progressTextStyle,
    TextStyle? messageTextStyle,
    double? elevation,
    TextAlign? textAlign,
    double? borderRadius,
    Curve? insetAnimCurve,
    EdgeInsets? padding,
    Alignment? progressWidgetAlignment,
  }) {
    // Don't allow styling changes while dialog is visible
    if (_isShowing) return;

    // Update progress only for download type dialogs
    if (_progressDialogType == ProgressDialogType.download) {
      _progress = progress ?? _progress;
    }

    // Apply all styling configurations
    _widgetAboveTheDialog = widgetAboveTheDialog;
    _dialogMessage = message ?? _dialogMessage;
    _maxProgress = maxProgress ?? _maxProgress;
    _progressWidget = progressWidget ?? _progressWidget;
    _backgroundColor = backgroundColor ?? _backgroundColor;
    _messageStyle = messageTextStyle ?? _messageStyle;
    _progressTextStyle = progressTextStyle ?? _progressTextStyle;
    _dialogElevation = elevation ?? _dialogElevation;
    _borderRadius = borderRadius ?? _borderRadius;
    _insetAnimCurve = insetAnimCurve ?? _insetAnimCurve;
    _textAlign = textAlign ?? _textAlign;
    _progressWidget = child ?? _progressWidget;
    _dialogPadding = padding ?? _dialogPadding;
    _progressWidgetAlignment =
        progressWidgetAlignment ?? _progressWidgetAlignment;
  }

  /// Updates the dialog content while it's being displayed.
  ///
  /// This method allows you to dynamically change the dialog's appearance
  /// and content while it's visible to the user. Unlike [style()], this method
  /// works even when the dialog is already shown.
  ///
  /// Parameters:
  /// - [progress]: New progress value (only applies to download type dialogs)
  /// - [maxProgress]: New maximum progress value
  /// - [message]: New message text to display
  /// - [progressWidget]: New progress indicator widget
  /// - [progressTextStyle]: New text style for progress percentage
  /// - [messageTextStyle]: New text style for the main message
  ///
  /// If the dialog is not currently showing, the values will be updated
  /// but no visual changes will occur until the dialog is shown.
  void update({
    double? progress,
    double? maxProgress,
    String? message,
    Widget? progressWidget,
    TextStyle? progressTextStyle,
    TextStyle? messageTextStyle,
  }) {
    // Update progress only for download type dialogs
    if (_progressDialogType == ProgressDialogType.download) {
      _progress = progress ?? _progress;
    }

    // Update all provided values
    _dialogMessage = message ?? _dialogMessage;
    _maxProgress = maxProgress ?? _maxProgress;
    _progressWidget = progressWidget ?? _progressWidget;
    _messageStyle = messageTextStyle ?? _messageStyle;
    _progressTextStyle = progressTextStyle ?? _progressTextStyle;

    // Trigger UI update only if dialog is currently visible
    if (!_isShowing) {
      return;
    } else {
      _dialog?.update();
    }
  }

  /// Checks whether the progress dialog is currently visible.
  ///
  /// Returns `true` if the dialog is currently being shown, `false` otherwise.
  /// This can be useful for preventing multiple dialogs from being shown
  /// simultaneously or for conditional logic based on dialog state.
  bool isShowing() => _isShowing;

  /// Hides the progress dialog if it's currently visible.
  ///
  /// Returns a [Future<bool>] that completes with:
  /// - `true` if a hide was performed (or scheduled, when the dialog route
  ///   has not been built yet)
  /// - `false` if the dialog was not showing
  ///
  /// It is safe to call this immediately after [show], even if the work
  /// between them finished instantly: the hide is queued and executed as soon
  /// as the dialog route exists.
  Future<bool> hide() async {
    if (!_isShowing) {
      if (_showLogs) debugPrint('ProgressDialog already dismissed');
      return false;
    }

    // show() was called but the route hasn't been built yet:
    // remember the request and close as soon as it exists.
    if (_dismissingContext == null) {
      _hideRequested = true;
      return true;
    }

    _closeDialog();
    if (_showLogs) debugPrint('ProgressDialog dismissed');
    return true;
  }

  /// Pops the dialog route and resets the internal state.
  void _closeDialog() {
    final ctx = _dismissingContext;
    _dismissingContext = null;
    _hideRequested = false;
    _isShowing = false;
    if (ctx != null && ctx.mounted) {
      Navigator.of(ctx, rootNavigator: true).pop();
    }
  }

  /// Displays the progress dialog with the current configuration.
  ///
  /// This method creates and shows the dialog using Flutter's [showDialog] function.
  /// The dialog appearance and behavior are determined by the current configuration
  /// set through the constructor and [style] method.
  ///
  /// Returns a [Future<bool>] that completes with:
  /// - `true` if the dialog was successfully shown
  /// - `false` if the dialog was already visible or the context is unmounted
  ///
  /// Call this from an event handler or after an `await`, not directly
  /// inside `build()`.
  Future<bool> show() async {
    // Prevent showing multiple dialogs simultaneously
    if (_isShowing) {
      if (_showLogs) debugPrint('ProgressDialog already shown');
      return false;
    }

    final ctx = _context;
    if (ctx == null || !ctx.mounted) {
      debugPrint('ProgressDialog: context is no longer mounted');
      return false;
    }

    // Set synchronously so show()/hide() calls right after each other are safe.
    _isShowing = true;
    _hideRequested = false;
    _dismissingContext = null;
    final int id = ++_showId;
    _dialog = _DialogBody(key: _dialogBodyKey);

    // Defer to after the current frame so show() is safe to call from
    // initState() or build(), where showDialog would otherwise fail.
    WidgetsBinding.instance.addPostFrameCallback((_) => _present(id));
    WidgetsBinding.instance.ensureVisualUpdate();

    if (_showLogs) debugPrint('ProgressDialog shown');
    return true;
  }

  /// Actually pushes the dialog route. Runs after the current frame.
  void _present(int id) {
    // A newer show() superseded this one.
    if (id != _showId) return;

    // hide() was called before the route was ever pushed: just cancel.
    if (_hideRequested) {
      _hideRequested = false;
      _isShowing = false;
      return;
    }

    final ctx = _context;
    if (ctx == null || !ctx.mounted) {
      _isShowing = false;
      debugPrint('ProgressDialog: context is no longer mounted');
      return;
    }

    showDialog<void>(
      context: ctx,
      barrierDismissible: _barrierDismissible,
      builder: (BuildContext buildContext) {
        // Store context for dismissing the dialog later
        _dismissingContext = buildContext;

        // hide() was called before we were built.
        if (_hideRequested) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _closeDialog());
        }

        return PopScope(
          canPop: _barrierDismissible,
          child: Dialog(
            backgroundColor: _backgroundColor,
            insetAnimationCurve: _insetAnimCurve,
            insetAnimationDuration: const Duration(milliseconds: 100),
            elevation: _dialogElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(_borderRadius)),
            ),
            child: Builder(builder: (_) => _dialog!),
          ),
        );
      },
    ).then((_) {
      // Runs when the route is gone for ANY reason (hide, barrier tap, back).
      // Ignore if a newer dialog has been shown in the meantime.
      if (id != _showId) return;
      _isShowing = false;
      _dismissingContext = null;
      _hideRequested = false;
      if (_showLogs) debugPrint('ProgressDialog closed');
    });
  }
}

// Internal StatefulWidget that renders the actual dialog content.
// This class handles the UI construction and state management for the dialog.
class _DialogBody extends StatefulWidget {
  const _DialogBody({super.key});

  /// Triggers a UI update by calling setState on the current state instance.
  /// This method is called when dialog content needs to be refreshed.
  void update() => _dialogBodyKey.currentState?.update();

  @override
  State<StatefulWidget> createState() => _DialogBodyState();
}

// State class for _DialogBody that manages the dialog's UI and lifecycle.
class _DialogBodyState extends State<_DialogBody> {
  /// Triggers a rebuild of the dialog UI.
  /// This method is called internally to refresh the dialog appearance
  /// when content is updated via the update() method.
  void update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Create the progress indicator widget with fixed size and alignment
    final loader = Align(
      alignment: _progressWidgetAlignment,
      child: SizedBox(width: 64.0, height: 64.0, child: _progressWidget),
    );

    // Create the text content widget based on dialog type
    final text = Builder(
      builder: (BuildContext buildContext) {
        if (_progressDialogType == ProgressDialogType.normal) {
          // Normal dialog: just display the message text
          return Text(
            _dialogMessage,
            textAlign: _textAlign,
            style: _messageStyle,
            textDirection: _direction,
          );
        } else {
          // Download dialog: display message with progress percentage
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 8.0),
                // Message text row
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _dialogMessage,
                        style: _messageStyle,
                        textDirection: _direction,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                // Progress percentage display (e.g., "50/100")
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    "$_progress/$_maxProgress",
                    style: _progressTextStyle,
                    textDirection: _direction,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );

    // Return custom body if provided, otherwise use default layout
    if (_customBody != null) {
      return Directionality(textDirection: _direction, child: _customBody!);
    } else {
      // Default dialog layout with progress indicator and text
      return Directionality(
        textDirection: _direction,
        child: Container(
          padding: _dialogPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Optional widget above the main content
              if (_widgetAboveTheDialog != null) _widgetAboveTheDialog!,
              // Main content row with loader and text
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(width: 8.0),
                  loader,
                  const SizedBox(width: 8.0),
                  Expanded(child: text),
                  const SizedBox(width: 8.0),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}

/// Defines the types of exceptions that can occur during dialog operations.
///
/// These exception types help identify specific error conditions:
/// - [alreadyShown]: Attempted to show a dialog that is already visible
/// - [alreadyDismissed]: Attempted to hide a dialog that is already dismissed
enum ProgressDialogExceptionType { alreadyShown, alreadyDismissed }

/// Extension on [ProgressDialogExceptionType] to provide human-readable error messages.
///
/// This extension converts exception types into descriptive error messages
/// that can be displayed to users or logged for debugging purposes.
extension ProgressDialogExceptionTypeExtension on ProgressDialogExceptionType {
  /// Returns a descriptive error message for each exception type.
  String get message {
    switch (this) {
      case ProgressDialogExceptionType.alreadyShown:
        return "ProgressDialog already shown";
      case ProgressDialogExceptionType.alreadyDismissed:
        return "ProgressDialog already dismissed";
    }
  }
}

/// Custom exception class for progress dialog related errors.
///
/// This exception is thrown when invalid operations are attempted on the dialog,
/// such as trying to show a dialog that's already visible or hide one that's
/// already dismissed. The exception includes both a type identifier and an
/// optional custom message.
///
/// Example:
/// ```dart
/// throw ProgressDialogException(
///   ProgressDialogExceptionType.alreadyShown,
///   "Custom error message"
/// );
/// ```
class ProgressDialogException implements Exception {
  /// The type of exception that occurred
  ProgressDialogExceptionType type;

  /// Optional custom message providing additional context
  String? message;

  /// Creates a new ProgressDialogException with the specified type and optional message.
  ///
  /// [type] specifies the category of error that occurred
  /// [message] provides additional context (optional)
  ProgressDialogException(this.type, [this.message]);

  @override
  String toString() {
    if (message == null) return "DialogException";
    return "DialogException: $message";
  }
}