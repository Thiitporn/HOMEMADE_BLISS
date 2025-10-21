# Styling Quick Reference

Use this sheet when someone asks where to tweak colors, sizes, or wording. Paths are clickable inside VS Code.

## Global Palette & Typography
- `lib/util/constants/colors.dart` – master color palette (`TColors.primary`, `secondary`, gradients, button colors). Change values here to update app-wide colors.
- `lib/util/theme/theme.dart` – light/dark `ThemeData` (app bar background, primary color, default text colors). Adjust to shift global look and feel.
- `lib/util/theme/custom_themes/text_theme.dart` – heading/body font sizes & weights. Update the `copyWith` values to change typography scale.
- `lib/util/constants/sizes.dart` – shared spacing, padding, and icon size tokens.
- `lib/util/constants/enums.dart` – enum labels for text size or payment methods; useful if you need to add new options.

## Reusable Widgets & Services
- `lib/common/widgets/confirmation_dialog.dart` – confirmation modal colors (`0xFF8D6E63` primary) and button text.
- `lib/services/cart_service.dart` – enforces max quantity and uses product/variant names; update status text if copy changes.
- `lib/models/product.dart` / `lib/models/cart_item.dart` – source-of-truth for product labels, default prices, and variant naming.

## Owner/Admin Screens
- `lib/features/owner/views/owner_dashboard_view.dart`
  - App bar title text, bottom navigation labels, quick action card colors, and stat card layout.
  - Floating action button styling for "เพิ่มสินค้า".
- `lib/features/owner/views/orders_management_view.dart`
  - Status chip colors (`pending`, `ready`, etc.), card padding, and type scales for order items.
  - Action button label text (`_getNextStatusText`) and status badge colors (`_getStatusColor`).
- `lib/features/owner/views/sales_report_view.dart`
  - Gradient header background, range filter chip colors, status progress bar palette, and summary tile shadows.
  - Text shown when there are no orders per status (`emptyOrdersMessage`).
- `lib/features/owner/views/coupons_management_view.dart`
  - Button labels, input hints, and tile background colors for coupons.

## Customer-Facing Screens
- `lib/features/authentication/views/home_view.dart`
  - Home banner text, order tab titles, variant bottom sheet colors, and quantity selector labels.
- `lib/features/products/views/product_list_view.dart`
  - Product grid card radius, shadow intensity, badge colors (`0xFFFFF3E0`), font sizes (15 for title, 9 for variants).
- `lib/features/orders/views/checkout_view.dart`
  - Section header text, price highlight color, and button captions.
- `lib/features/orders/views/order_history_view.dart`
  - Timeline chip colors, empty-state messages, and history card typography.
- `lib/features/orders/views/payment_view.dart`
  - PromptPay/Stripe section titles, button colors, and summary text for totals.

## Authentication & Profile
- `lib/features/authentication/views/login_view.dart` / `signup_view.dart`
  - Input labels, hint text, button captions, and accent colors for toggles.
- `lib/features/authentication/views/edit_profile_view.dart`
  - Field label text, save button background, and avatar placeholder colors.

## Chat & Notifications
- `lib/features/chat/chat_view.dart`
  - Message bubble colors, timestamp text size, and "ส่ง" button label.
- `lib/features/chat/chat_inbox_view.dart`
  - Inbox list tile fonts, unread badge colors, and empty-state strings.
- `lib/features/chat/chat_service.dart`
  - Notification body/title copy created when chat events occur.
- `lib/common/notification_service.dart` & `lib/features/notifications/views/notifications_view.dart`
  - In-app notification channel names, banner colors, and action labels.

## Utilities & Misc
- `lib/app.dart` / `lib/main.dart`
  - Root theme injection, MaterialApp title/locale, and route names used for navigation.
- `lib/features/products/controllers/product_controller.dart`
  - Default sample product names/prices used when Firestore is empty.
- `lib/features/orders/controllers/orders_controller.dart`
  - Status display strings and toast/snackbar messages.
- `lib/common/in_app_notification.dart`
  - Snackbar/banner styling (`backgroundColor`, `duration`) when showing toast messages.

Keep this file updated whenever you introduce a new styled widget so that anyone can quickly jump to the right spot during a review.
