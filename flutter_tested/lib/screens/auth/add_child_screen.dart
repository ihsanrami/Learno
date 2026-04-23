import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';

const _avatarOptions = [
  ('fox', '🦊'),
  ('bear', '🐻'),
  ('panda', '🐼'),
  ('rabbit', '🐰'),
  ('lion', '🦁'),
  ('tiger', '🐯'),
];

const _gradeOptions = [
  ('kindergarten', 'Kindergarten'),
  ('first', '1st Grade'),
  ('second', '2nd Grade'),
  ('third', '3rd Grade'),
  ('fourth', '4th Grade'),
];

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _controller = AuthController();

  int _selectedAge = 6;
  String _selectedGrade = 'first';
  String _selectedAvatar = 'fox';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addChild() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final ok = await _controller.addChild(
      name: _nameCtrl.text.trim(),
      age: _selectedAge,
      grade: _selectedGrade,
      avatar: _selectedAvatar,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isLoading = false;
        _error = _controller.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child:
                Image.asset('assets/images/background.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Color(0xFF44200B), size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Add Child',
                        style: TextStyle(
                          fontFamily: 'Recoleta',
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          color: Color(0xFF44200B),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSection(
                            title: 'Choose Avatar',
                            child: _buildAvatarSelector(),
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            title: 'Name',
                            child: TextFormField(
                              controller: _nameCtrl,
                              style: const TextStyle(
                                  color: Color(0xFF44200B), fontSize: 16),
                              decoration: _inputDecoration('Child\'s name'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter the child\'s name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            title: 'Age',
                            child: _buildAgePicker(),
                          ),
                          const SizedBox(height: 16),
                          _buildSection(
                            title: 'Grade',
                            child: _buildGradeDropdown(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            _buildErrorBubble(_error!),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _addChild,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8D00),
                                foregroundColor: const Color(0xFF44200B),
                                disabledBackgroundColor:
                                    const Color(0xFFFF8D00).withOpacity(0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                textStyle: const TextStyle(
                                  fontFamily: 'Recoleta',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Color(0xFF44200B),
                                          strokeWidth: 2.5),
                                    )
                                  : const Text('Add Child'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                  color: Color(0xFF76310F), fontSize: 15),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDDC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF44200B).withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Recoleta',
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF44200B),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildAvatarSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _avatarOptions.map((option) {
        final (key, emoji) = option;
        final isSelected = _selectedAvatar == key;
        return GestureDetector(
          onTap: () => setState(() => _selectedAvatar = key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF8D00).withOpacity(0.2)
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF8D00)
                    : const Color(0xFFF7CDA5),
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAgePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final age = i + 4;
        final isSelected = _selectedAge == age;
        return GestureDetector(
          onTap: () => setState(() => _selectedAge = age),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF8D00) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF8D00)
                    : const Color(0xFFF7CDA5),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '$age',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isSelected
                      ? const Color(0xFF44200B)
                      : const Color(0xFF76310F),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGradeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGrade,
      onChanged: (v) => setState(() => _selectedGrade = v!),
      decoration: _inputDecoration('Select grade'),
      dropdownColor: const Color(0xFFFFEDDC),
      style: const TextStyle(color: Color(0xFF44200B), fontSize: 15),
      items: _gradeOptions.map((option) {
        final (value, label) = option;
        return DropdownMenuItem(value: value, child: Text(label));
      }).toList(),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF76310F), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF7CDA5), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF8D00), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

Widget _buildErrorBubble(String message) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0F0),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Color(0xFF76310F), fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
