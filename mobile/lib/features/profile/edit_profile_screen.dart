import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user, required this.token});
  final Map<String, dynamic> user;
  final String token;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: widget.user['name'] as String? ?? '');
  late final _email = TextEditingController(text: widget.user['email'] as String? ?? '');
  late final _phone = TextEditingController(text: widget.user['phone'] as String? ?? '');
  final _current = TextEditingController();
  final _new = TextEditingController();
  XFile? _image;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _current, _new]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery, maxWidth: 800, imageQuality: 80,
    );
    if (f != null) setState(() => _image = f);
  }

  Future<void> _save() async {
    final oldEmail = widget.user['email'] as String? ?? '';
    final emailChanged = _email.text.trim().toLowerCase() != oldEmail.toLowerCase();
    setState(() => _saving = true);
    try {
      final updated = await ProfileService.update(
        token: widget.token,
        name: _name.text.trim(),
        email: emailChanged ? _email.text.trim() : null,
        phone: _phone.text.trim(),
        currentPassword: _current.text.isEmpty ? null : _current.text,
        newPassword: _new.text.isEmpty ? null : _new.text,
        image: _image,
      );
      if (mounted) Navigator.pop(context, updated);
    } on ProfileException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Network error. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.user['profile_picture'] as String?;
    final ImageProvider? avatar = _image != null
        ? FileImage(File(_image!.path))
        : (url != null ? NetworkImage(url) : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pick,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: avatar,
                child: avatar == null ? const Icon(Icons.camera_alt, size: 32) : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile number (optional)'),
          ),
          const SizedBox(height: 20),
          const Text('Change password (optional)'),
          TextField(
            controller: _new,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          TextField(
            controller: _current,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Current password',
              helperText: 'Required when changing email or password',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}