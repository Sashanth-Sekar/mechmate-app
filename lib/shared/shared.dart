/// Top-level barrel for all shared modules.
///
/// Re-exports the three sub-barrels so consumers can import everything
/// shared with a single import:
///
/// ```dart
/// import 'package:mechmate_app/shared/shared.dart';
/// ```
library;

export 'providers/providers.dart';
export 'services/services.dart';
export 'widgets/widgets.dart';
