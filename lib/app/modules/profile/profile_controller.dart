import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_snackbar.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/settings_service.dart';
import '../home/home_controller.dart';

class ProfileController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final SettingsService settings = Get.find<SettingsService>();
  final ImagePicker _picker = ImagePicker();

  final formKey = GlobalKey<FormState>();
  late final TextEditingController firstNameCtrl;
  late final TextEditingController lastNameCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController currentAddressCtrl;

  /// 'male' | 'female' | null.
  final gender = RxnString();

  /// Selected date of birth, null when unset.
  final dateOfBirth = Rxn<DateTime>();

  final isSaving = false.obs;

  /// Whether the inline edit form is expanded.
  final isEditing = false.obs;

  /// Local path of a newly picked photo, before it's uploaded. Drives the
  /// preview + the "Save photo" button.
  final pickedPhotoPath = RxnString();
  final isUploadingPhoto = false.obs;

  AuthUser? get user => _auth.currentUser.value;

  /// Full name, falling back to first + last when the API `name` is empty.
  String get displayName {
    final u = user;
    return u?.displayName ?? '—';
  }

  @override
  void onInit() {
    super.onInit();
    final u = user;
    firstNameCtrl = TextEditingController(text: u?.firstName ?? '');
    lastNameCtrl = TextEditingController(text: u?.lastName ?? '');
    phoneCtrl = TextEditingController(text: u?.phone ?? '');
    emailCtrl = TextEditingController(text: u?.email ?? '');
    currentAddressCtrl = TextEditingController(text: u?.currentAddress ?? '');
    _resetExtraFields();
  }

  void startEdit() => isEditing.value = true;

  /// Restore gender + date-of-birth from the saved user.
  void _resetExtraFields() {
    final u = user;
    gender.value = u?.gender;
    dateOfBirth.value = _parseDate(u?.dateOfBirth);
  }

  static DateTime? _parseDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    return DateTime.tryParse(iso.trim());
  }

  void setGender(String value) => gender.value = value;

  /// Open a calendar to choose the date of birth (drivers are 18+).
  Future<void> pickDateOfBirth(BuildContext context) async {
    final now = DateTime.now();
    final initial = dateOfBirth.value ?? DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'date_of_birth'.tr,
    );
    if (picked != null) dateOfBirth.value = picked;
  }

  /// Collapse the form and restore fields to the saved values.
  void cancelEdit() {
    final u = user;
    firstNameCtrl.text = u?.firstName ?? '';
    lastNameCtrl.text = u?.lastName ?? '';
    phoneCtrl.text = u?.phone ?? '';
    emailCtrl.text = u?.email ?? '';
    currentAddressCtrl.text = u?.currentAddress ?? '';
    _resetExtraFields();
    isEditing.value = false;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isSaving.value = true;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final dob = dateOfBirth.value;
      await _auth.updateProfile(
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        gender: gender.value,
        dateOfBirth: dob == null ? null : DateFormat('yyyy-MM-dd').format(dob),
        currentAddress: currentAddressCtrl.text.trim(),
      );
      isEditing.value = false;
      AppSnackbar.success('profile_updated'.tr);
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('error_generic'.tr);
    } finally {
      isSaving.value = false;
    }
  }

  // ---- Photo ---------------------------------------------------------------

  Future<void> pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked != null) pickedPhotoPath.value = picked.path;
  }

  void discardPhoto() => pickedPhotoPath.value = null;

  Future<void> savePhoto() async {
    final path = pickedPhotoPath.value;
    if (path == null || isUploadingPhoto.value) return;

    isUploadingPhoto.value = true;
    try {
      await _auth.uploadAvatar(path);
      pickedPhotoPath.value = null;
      AppSnackbar.success('photo_updated'.tr);
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('error_generic'.tr);
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  void openDocuments() => Get.toNamed(Routes.documents);

  /// Jump to the Guide tab.
  void openGuide() => Get.find<HomeController>().changeTab(2);

  Future<void> logout() async {
    await _auth.logout();
    Get.offAllNamed(Routes.login);
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    currentAddressCtrl.dispose();
    super.onClose();
  }
}
