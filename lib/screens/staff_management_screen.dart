import 'package:flutter/material.dart';
import '../services/rest_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  static const Color burgundy = Color(0xFF7A1C1C);
  List<dynamic> _staffList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    final data = await RestApi.fetchStaffMembers();
    if (mounted) {
      setState(() {
        _staffList = data;
        _isLoading = false;
      });
    }
  }

  // --- REUSABLE DIALOG BASE TEMPLATE ---
  Widget _buildStaffDialogLayout({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData headerIcon,
    required Widget formContent,
    required String confirmText,
    required VoidCallback onConfirm,
    Color confirmColor = burgundy,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Icon Badge & Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: confirmColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(headerIcon, color: confirmColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.grey, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // Form Inputs Body
            Flexible(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: formContent,
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onConfirm,
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE MODERN TEXT FIELD ---
  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isHidden = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword && isHidden,
            validator: validator,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon:
                  Icon(prefixIcon, size: 20, color: Colors.grey.shade500),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: Colors.grey.shade500,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: burgundy, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. EDIT / RESET PASSWORD MODAL ---
  void _showEditStaffDialog(dynamic staff) {
    final nameCtrl = TextEditingController(text: staff['name'] ?? '');
    final emailCtrl = TextEditingController(text: staff['email'] ?? '');
    final phoneCtrl = TextEditingController(text: staff['phone'] ?? '');
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool hidePassword = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _buildStaffDialogLayout(
            context: context,
            title: 'Edit Staff Member',
            subtitle:
                'Update details or reset password for ${staff['name'] ?? "Staff"}',
            headerIcon: Icons.badge_outlined,
            confirmText: 'Save Changes',
            onConfirm: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              final newPassword = passwordCtrl.text.trim();
              final result = await RestApi.updateStaffUser(
                id: staff['id'],
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                newPassword: newPassword.isNotEmpty ? newPassword : null,
              );

              if (newPassword.isNotEmpty) {
                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null &&
                      currentUser.email == emailCtrl.text.trim()) {
                    await currentUser.updatePassword(newPassword);
                  }
                } catch (e) {
                  debugPrint('Firebase password update note: $e');
                }
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor:
                        result['success'] ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _loadStaff();
              }
            },
            formContent: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField(
                    controller: nameCtrl,
                    label: 'Full Name',
                    hint: 'e.g. John Doe',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  _buildDialogField(
                    controller: emailCtrl,
                    label: 'Email Address',
                    hint: 'e.g. staff@gmail.com',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Invalid email' : null,
                  ),
                  _buildDialogField(
                    controller: phoneCtrl,
                    label: 'Phone Number',
                    hint: 'e.g. 089384534',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildDialogField(
                    controller: passwordCtrl,
                    label: 'New Password (Optional)',
                    hint: 'Leave empty to keep existing',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    isHidden: hidePassword,
                    onToggleVisibility: () =>
                        setDialogState(() => hidePassword = !hidePassword),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 2. CONFIRM DELETE DIALOG ---
  Future<void> _confirmDeleteStaff(dynamic staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildStaffDialogLayout(
        context: context,
        title: 'Remove Staff Member',
        subtitle: 'Revoke access permissions',
        headerIcon: Icons.delete_outline_rounded,
        confirmColor: Colors.red.shade700,
        confirmText: 'Remove Staff',
        onConfirm: () => Navigator.pop(ctx, true),
        formContent: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Are you sure you want to remove "${staff['name']}"? They will no longer have access to the POS backend.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await RestApi.deleteStaffUser(staff['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? 'Staff member removed' : 'Failed to remove staff'),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadStaff();
      }
    }
  }

  // --- 3. ADD NEW STAFF DIALOG ---
  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool hidePassword = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _buildStaffDialogLayout(
            context: context,
            title: 'Add New Staff User',
            subtitle: 'Create login access for kitchen and catalog',
            headerIcon: Icons.person_add_alt_1_rounded,
            confirmText: 'Add Staff',
            onConfirm: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailCtrl.text.trim(),
                  password: passwordCtrl.text.trim(),
                );
              } catch (e) {
                debugPrint('Firebase registration note: $e');
              }

              final result = await RestApi.createStaffUser(
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                password: passwordCtrl.text.trim(),
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor:
                        result['success'] == true ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _loadStaff();
              }
            },
            formContent: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField(
                    controller: nameCtrl,
                    label: 'Full Name',
                    hint: 'e.g. John Doe',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  _buildDialogField(
                    controller: emailCtrl,
                    label: 'Email Address',
                    hint: 'e.g. user@gmail.com',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Invalid email' : null,
                  ),
                  _buildDialogField(
                    controller: phoneCtrl,
                    label: 'Phone Number',
                    hint: 'e.g. 089384534',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildDialogField(
                    controller: passwordCtrl,
                    label: 'Temporary Password',
                    hint: 'At least 6 characters',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    isHidden: hidePassword,
                    onToggleVisibility: () =>
                        setDialogState(() => hidePassword = !hidePassword),
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: burgundy,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: burgundy))
          : _staffList.isEmpty
              ? const Center(child: Text('No staff members registered yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _staffList.length,
                  itemBuilder: (context, index) {
                    final staff = _staffList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Slidable(
                        key: ValueKey(staff['id']),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _showEditStaffDialog(staff),
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: 'Edit',
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(16)),
                            ),
                            SlidableAction(
                              onPressed: (_) => _confirmDeleteStaff(staff),
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Delete',
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(16)),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: burgundy.withOpacity(0.1),
                              child: const Icon(Icons.badge_outlined,
                                  color: burgundy),
                            ),
                            title: Text(staff['name'] ?? 'Staff',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '${staff['email']}\n${staff['phone'] ?? "No phone"}'),
                            isThreeLine: true,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('STAFF',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: burgundy,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Staff',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showAddStaffDialog,
      ),
    );
  }
}
