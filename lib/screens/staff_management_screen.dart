import 'dart:math';

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

// --- 1. EDIT / RESET PASSWORD MODAL ---
  void _showEditStaffDialog(dynamic staff) {
    final nameCtrl = TextEditingController(text: staff['name'] ?? '');
    final emailCtrl = TextEditingController(text: staff['email'] ?? '');
    final phoneCtrl = TextEditingController(text: staff['phone'] ?? '');
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Staff / Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Invalid email' : null,
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'New Password (Optional)',
                    hintText: 'Leave empty to keep existing',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: burgundy),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);

              setState(() => _isLoading = true);

              final result = await RestApi.updateStaffUser(
                id: staff['id'],
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                newPassword: passwordCtrl.text.trim().isNotEmpty
                    ? passwordCtrl.text.trim()
                    : null,
              );

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
            child: const Text('Save Changes',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 2. CONFIRM DELETE DIALOG ---
  Future<void> _confirmDeleteStaff(dynamic staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Staff Member'),
        content: Text(
            'Are you sure you want to remove "${staff['name']}"? They will no longer have access to the POS backend.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
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

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Staff User',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Invalid email' : null,
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: passwordCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Temporary Password'),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Min 6 characters' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: burgundy),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              // 1. Create staff in Firebase Auth so they can log in via AuthScreen
              try {
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailCtrl.text.trim(),
                  password: passwordCtrl.text.trim(),
                );
              } catch (e) {
                // If account exists in Firebase, continue to Laravel sync
                debugPrint('Firebase registration note: $e');
              }

              // 2. Persist staff record with 'staff' role in Laravel MySQL
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
            child:
                const Text('Add Staff', style: TextStyle(color: Colors.white)),
          ),
        ],
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
                      padding: EdgeInsets.only(bottom: 12),
                      child: Slidable(
                        key: ValueKey(staff['id']),
                        // Swipe left to reveal Edit & Delete
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
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: burgundy.withValues(alpha: 0.1),
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
