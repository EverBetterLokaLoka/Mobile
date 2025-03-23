import 'package:flutter/material.dart';
import 'package:lokaloka/core/styles/colors.dart';
import 'package:lokaloka/features/auth/models/user.dart';
import 'package:lokaloka/features/profile/services/profile_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../globals.dart';

// Widget thông báo tùy chỉnh
class CustomNotification extends StatelessWidget {
  final String message;
  final bool isError;

  const CustomNotification({
    Key? key,
    required this.message,
    this.isError = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF2196F3), // Brand blue color
      ),
      child: SafeArea(
        child: Row(
          children: [
            Image.asset(
              'assets/images/logo.png', // Thay bằng logo của bạn
              width: 24,
              height: 24,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountTab extends StatefulWidget {
  final UserNormal user;
  final Function() onProfileUpdated;

  AccountTab({required this.user, required this.onProfileUpdated});

  @override
  _AccountTabState createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  bool isEditing = false;
  bool isLoading = false;
  bool hasChanges = false;
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  late Map<String, String> originalValues;

  late TextEditingController fullNameController;
  late TextEditingController dobController;
  late TextEditingController genderController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController emergencyController;

  final FocusNode fullNameFocus = FocusNode();
  final FocusNode dobFocus = FocusNode();
  final FocusNode genderFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode addressFocus = FocusNode();
  final FocusNode emergencyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    fullNameController = TextEditingController(text: widget.user.full_name);
    dobController = TextEditingController(text: widget.user.dob ?? '');
    genderController = TextEditingController(text: widget.user.gender ?? '');
    emailController = TextEditingController(text: widget.user.email);
    phoneController = TextEditingController(text: widget.user.phone);
    addressController = TextEditingController(text: widget.user.address);
    emergencyController =
        TextEditingController(text: widget.user.emergency_numbers);

    _addChangeListeners();
  }

  void _clearValidationErrors() {
    _formKey.currentState?.reset(); // Dọn dẹp tất cả các trạng thái lỗi
    fullNameController.clear(); // Xóa nội dung của từng trường
    dobController.clear();
    genderController.clear();
    emailController.clear();
    phoneController.clear();
    addressController.clear();
    emergencyController.clear();

    // reset giá trị ban đầu nếu cần
    fullNameController.text = widget.user.full_name;
    dobController.text = widget.user.dob ?? '';
    genderController.text = widget.user.gender ?? '';
    emailController.text = widget.user.email;
    phoneController.text = widget.user.phone!;
    addressController.text = widget.user.address!;
    emergencyController.text = widget.user.emergency_numbers!;

    // Reset focus nếu cần
    FocusScope.of(context).unfocus();
  }
  void _saveOriginalValues() {
    originalValues = {
      'fullName': widget.user.full_name ?? '',
      'dob': widget.user.dob ?? '',
      'gender': widget.user.gender ?? '',
      'phone': widget.user.phone ?? '',
      'address': widget.user.address ?? '',
      'emergency': widget.user.emergency_numbers ?? '',
    };
  }

  void _addChangeListeners() {
    fullNameController.removeListener(_checkForChanges);
    dobController.removeListener(_checkForChanges);
    genderController.removeListener(_checkForChanges);
    phoneController.removeListener(_checkForChanges);
    addressController.removeListener(_checkForChanges);
    emergencyController.removeListener(_checkForChanges);

    fullNameController.addListener(_checkForChanges);
    dobController.addListener(_checkForChanges);
    genderController.addListener(_checkForChanges);
    phoneController.addListener(_checkForChanges);
    addressController.addListener(_checkForChanges);
    emergencyController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    if (!isEditing) return;

    // Trim whitespace from text fields before comparison
    String trimmedPhone = phoneController.text.trim();
    String trimmedAddress = addressController.text.trim();
    String trimmedEmergency = emergencyController.text.trim();
    String trimmedFullName = fullNameController.text.trim();

    bool changed =
        trimmedFullName != originalValues['fullName']?.trim() ||
            dobController.text != originalValues['dob'] ||
            genderController.text != originalValues['gender'] ||
            (trimmedPhone != originalValues['phone']?.trim() && trimmedPhone.isNotEmpty) ||
            (trimmedAddress != originalValues['address']?.trim() && trimmedAddress.isNotEmpty) ||
            (trimmedEmergency != originalValues['emergency']?.trim() && trimmedEmergency.isNotEmpty);

    if (changed != hasChanges) {
      setState(() {
        hasChanges = changed;
      });
    }
  }

  void showCustomNotification({
    required BuildContext context,
    required Widget notification,
    Duration duration = const Duration(seconds: 3),
  }) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: notification,
        ),
      ),
    );

    Overlay.of(context).insert(entry);

    Future.delayed(duration, () {
      entry?.remove();
    });
  }



  String? validatePhone(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return null;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'The phone number can only contain digits.';
    }

    if (!RegExp(r'^(?!0+$)[0-9]{10,11}$').hasMatch(value)) {
      return 'Invalid phone number.';
    }
    return null;
  }


  String? validateFullName(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Please enter your full name.';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? validateDob(String? value) {
    if (value != null && value.isNotEmpty) {
      try {
        final date = DateFormat('yyyy-MM-dd').parse(value);
        final now = DateTime.now();

        if (date.isAfter(now)) {
          return 'Date of birth cannot be in the future';
        }
      } catch (e) {
        return 'Enter a valid date (YYYY-MM-DD)';
      }
    }
    return null; // Trả về null nếu không có lỗi
  }

  String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Gender is required';
    }
    return null;
  }

  String? validateAddress(String? value) {
    if (value != null && value.isNotEmpty && value.length < 5) {
      return 'Address must be at least 5 characters';
    }
    return null;
  }

  String? validateEmergencyNumber(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return null;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'The emergency number can only contain digits.';
    }

    if (!RegExp(r'^(?!0+$)[0-9]{10,11}$').hasMatch(value)) {
      return 'Invalid emergency number.';
    }

    return null;
  }

  Future<void> _selectDate(BuildContext context, TextEditingController dobController) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Mặc định chọn 18 tuổi trước
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);

      // Kiểm tra hợp lệ
      String? validationError = validateDob(formattedDate);
      if (validationError != null) {
        showCustomNotification(
          context: context,
          notification: CustomNotification(
            message: validationError,
            isError: true,
          ),
        );
      } else {
        dobController.text = formattedDate;
      }
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      showCustomNotification(
        context: context,
        notification: CustomNotification(
          message: 'Please check the form for errors and try again.',
          isError: true,
        ),
      );
      return;
    }

    if (!hasChanges) {
      showCustomNotification(
        context: context,
        notification: CustomNotification(
          message: 'No changes detected to save.',
          isError: true,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final updatedUser = UserNormal(
        id: widget.user.id,
        full_name: fullNameController.text,
        dob: dobController.text,
        gender: genderController.text,
        email: emailController.text,
        phone: phoneController.text,
        address: addressController.text,
        emergency_numbers: emergencyController.text,
        name: widget.user.name,
        avatar: widget.user.avatar,
      );

      final result = await _profileService.updateUserProfile(updatedUser);

      if (result is bool && result) {
        showCustomNotification(
          context: context,
          notification: CustomNotification(
            message: 'Your profile has been updated successfully.',
          ),
        );

        widget.onProfileUpdated();
        setState(() {
          isEditing = false;
          hasChanges = false;
        });
      } else {
        String errorMessage =
            'An error occurred while updating your profile. Please try again later.';
        showCustomNotification(
          context: context,
          notification: CustomNotification(
            message: errorMessage,
            isError: true,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      showCustomNotification(
        context: context,
        notification: CustomNotification(
          message:
              'An error occurred while updating your profile. Please try again later.',
          isError: true,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildFormField(
                    "Full Name",
                    fullNameController,
                    isEditing,
                    true,
                    validator: validateFullName,
                    focusNode: fullNameFocus,
                  ),
                  _buildDateAndGenderRow(),
                  _buildFormField("Email", emailController, false, false),
                  _buildFormField(
                    "Phone",
                    phoneController,
                    isEditing,
                    false, // Không yêu cầu
                    validator: validatePhone,
                    focusNode: phoneFocus,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildFormField(
                    "Address",
                    addressController,
                    isEditing,
                    false, // Không yêu cầu
                    focusNode: addressFocus,
                  ),
                  _buildFormField(
                    "Emergency Number",
                    emergencyController,
                    isEditing,
                    false,
                    validator: validateEmergencyNumber,
                    focusNode: emergencyFocus,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 20),
                  _buildActionButtons(),
                  SizedBox(height: 16),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateAndGenderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child:
                  _buildDateField('Date of Birth', dobController, isEditing)),
          SizedBox(width: 16), // Space between date and gender fields
          Expanded(child: _buildGenderField()),
        ],
      ),
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 50,
          child: DropdownButtonFormField<String>(
            value: genderController.text.isNotEmpty ? genderController.text : null,
            items: ['Male', 'Female', 'Other'].map((gender) {
              return DropdownMenuItem(value: gender, child: Text(gender));
            }).toList(),
            onChanged: isEditing
                ? (value) {
                    setState(() => genderController.text = value ?? '');
                  }
                : null,
            validator: validateGender,
            focusNode: genderFocus,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              errorStyle: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
      String label, TextEditingController controller, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 50,
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            validator: (value) => validateDob(value),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              suffixIcon: enabled
                  ? IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context, controller), // Đúng cách gọi callback
              )
                  : null,
              errorStyle: TextStyle(color: Colors.red),
              hintText: "YYYY-MM-DD",
            ),
            readOnly: true, // Không cho phép nhập tay
            onTap: enabled ? () => _selectDate(context, controller) : null, // Đúng cách gọi callback
          ),
        ),
      ],
    );
  }


  Widget _buildFormField(String label, TextEditingController controller,
      bool enabled, bool isRequired,
      {bool isPassword = false,
      String? Function(String?)? validator,
      FocusNode? focusNode,
      TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 50,
            child: TextFormField(
              controller: controller,
              enabled: enabled,
              obscureText: isPassword,
              validator: validator,
              focusNode: focusNode,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                errorStyle: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: 350,
        height: 50,
        child: ElevatedButton(
          key: Key("logout_button"),
          onPressed: _handleLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orangeColor,
            textStyle: TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(width: 0, color: Colors.white),
            ),
          ),
          child: Text("Sign out",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Are you sure you want to Sign out?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          contentPadding: EdgeInsets.zero,
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: Key("cancel_logout_button"),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(false); // Return false when No is pressed
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF78909C), // Gray color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(0, 45), // Height 45
                    ),
                    child: Text(
                      'No',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: Key("confirm_logout_button"),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(true); // Return true when Yes is pressed
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00BCD4), // Turquoise color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(0, 45), // Height 45
                    ),
                    child: Text(
                      'Yes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    // Proceed with logout only if user confirmed
    if (confirmLogout == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove("auth_token");
      travelDays = 0;
      cityName = "";
      trustPhone = "";
      cityTrip = null;
      images.clear();
      userGlobal = UserNormal(
          id: 1, name: "", email: "", full_name: "", address: "", avatar: "");
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/login");
      }
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 25, 30, 4),
      child: isEditing
          ? Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  isEditing = false;
                  hasChanges = false;
                  _initializeControllers();
                  _clearValidationErrors();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(width: 0, color: Colors.white),
                ),
                minimumSize: Size(130, 50),
              ),
              child: Text("Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: hasChanges ? _handleUpdate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                disabledBackgroundColor: Colors.teal.withAlpha(120),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(width: 0, color: Colors.white),
                ),
                minimumSize: Size(130, 50),
              ),
              child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      )
          : SizedBox(
              width: 350,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isEditing = true;
                    hasChanges = false;
                    _saveOriginalValues();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text("Update",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
    );
  }

  @override
  void dispose() {
    fullNameController.removeListener(_checkForChanges);
    dobController.removeListener(_checkForChanges);
    genderController.removeListener(_checkForChanges);
    phoneController.removeListener(_checkForChanges);
    addressController.removeListener(_checkForChanges);
    emergencyController.removeListener(_checkForChanges);

    fullNameController.dispose();
    dobController.dispose();
    genderController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    emergencyController.dispose();

    fullNameFocus.dispose();
    dobFocus.dispose();
    genderFocus.dispose();
    phoneFocus.dispose();
    addressFocus.dispose();
    emergencyFocus.dispose();

    super.dispose();
  }
}
