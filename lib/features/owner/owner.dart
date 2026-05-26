/// Top-level barrel for the owner feature.
///
/// Re-exports all public owner modules so consumers can import everything
/// owner-related with a single import:
///
/// ```dart
/// import 'package:mechmate_app/features/owner/owner.dart';
/// ```
library;

export 'controllers/map_controller.dart';
export 'map/map_styles.dart';
export 'models/booking_model.dart';
export 'models/shop_model.dart';
export 'models/vehicle_model.dart';
export 'screens/create_booking_screen.dart';
export 'screens/my_bookings_screen.dart';
export 'screens/my_vehicles_screen.dart';
export 'screens/owner_home_screen.dart';
export 'screens/owner_main_screen.dart';
export 'screens/owner_profile_screen.dart';
export 'screens/search_workshops_screen.dart';
export 'services/location_service.dart';
export 'services/workshop_repository.dart';
export 'widgets/booking_details_sheet.dart';
export 'widgets/current_location_button.dart';
export 'widgets/edit_profile_sheet.dart';
export 'widgets/location_status_overlay.dart';
export 'widgets/map_glass_search_bar.dart';
export 'widgets/premium_map_view.dart';
export 'widgets/service_selection_card.dart';
export 'widgets/workshop_details_sheet.dart';
export 'widgets/workshop_list_item.dart';
