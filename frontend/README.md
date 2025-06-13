# Resellio App - File Structure

This document outlines the project's file structure.

## `lib/`

* **`main.dart`**: App's entry point and core setup.
* **`config/`**: App-wide configuration.
    * `app_theme.dart`: Theme definitions.
    * `app_constants.dart`: Global constants.
    * `app_router.dart`: Navigation setup.
* **`core/`**: Shared utilities and services.
    * `utils/`: Utility functions.
    * `widgets/`: Reusable UI widgets.
    * `services/`: Shared services.
        * `api_service.dart`: API interaction.
* **`data/`**: Data handling.
    * `models/`: Data models.
        * `user_model.dart`, `event_model.dart`, ...: Data structures.
    * `repositories/`: Data fetching logic.
        * `auth_repository.dart`, `event_repository.dart`, ...: Data retrieval.
* **`presentation/`**: UI layer, organized by feature.
    * `common_widgets/`: Shared UI elements.
        * `event_card.dart`: Reusable event card.
    * `auth/`: Authentication UI & logic.
        * `auth_screen.dart`, `auth_provider.dart`: Authentication features.
    * `events/`: Event browsing UI & logic.
        * `event_list_screen.dart`, `event_details_screen.dart`, `event_provider.dart`: Event display.
    * `cart/`: Cart UI & logic.
        * `cart_screen.dart`, `cart_provider.dart`: Shopping cart.
    * `tickets/`: Ticket management UI & logic.
        * `my_tickets_screen.dart`, `resale_market_screen.dart`, `tickets_provider.dart`: Ticket views.
    * `organizer/`: Organizer tools UI & logic.
        * `organizer_dashboard_screen.dart`, `create_edit_event_screen.dart`, `organizer_provider.dart`: Organizer features.
    * `admin/`: Admin tools UI & logic.
        * `admin_dashboard_screen.dart`, `user_management_screen.dart`, `admin_provider.dart`: Admin functions.
    * `profile/`: User profile UI & logic.
        * `profile_screen.dart`, `profile_provider.dart`: User profile.

## `assets/`

* Static assets.
    * `images/`: Images.
    * `fonts/`: Fonts.

## `test/`

* Automated tests.

## `pubspec.yaml`

* Project dependencies and configuration.