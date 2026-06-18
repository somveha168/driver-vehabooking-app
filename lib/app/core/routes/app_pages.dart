import 'package:get/get.dart';

import '../../modules/auth/login_binding.dart';
import '../../modules/auth/login_view.dart';
import '../../modules/booking_detail/booking_detail_binding.dart';
import '../../modules/booking_detail/booking_detail_view.dart';
import '../../modules/documents/documents_binding.dart';
import '../../modules/documents/documents_view.dart';
import '../../modules/home/home_binding.dart';
import '../../modules/home/home_view.dart';
import 'app_routes.dart';

/// Route table. Bindings register each screen's controllers lazily.
class AppPages {
  AppPages._();

  static final List<GetPage> pages = [
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.bookingDetail,
      page: () => const BookingDetailView(),
      binding: BookingDetailBinding(),
    ),
    GetPage(
      name: Routes.documents,
      page: () => const DocumentsView(),
      binding: DocumentsBinding(),
    ),
  ];
}
