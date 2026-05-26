/// Top-level barrel for all core modules.
///
/// Re-exports the three sub-barrels so consumers can import everything
/// core with a single import:
///
/// ```dart
/// import 'package:mechmate_app/core/core.dart';
/// ```
library;

export 'constants/constants.dart';
export 'theme/theme.dart';
export 'utils/utils.dart';
