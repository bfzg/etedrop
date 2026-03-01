import 'package:flutter/material.dart';

class FocusInput extends StatefulWidget {
  final String placeholder;
  final String type; // "text" or "password"
  final String value;
  final ValueChanged<String> onChanged;

  const FocusInput({
    super.key,
    required this.placeholder,
    this.type = "text",
    required this.value,
    required this.onChanged,
  });

  @override
  State<FocusInput> createState() => _FocusInputState();
}

class _FocusInputState extends State<FocusInput> {
  final FocusNode _focusNode = FocusNode();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.type == "password";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            focusNode: _focusNode,
            obscureText: isPassword && !_showPassword,
            controller: TextEditingController(text: widget.value)
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: widget.value.length),
              ),
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: const TextStyle(color: Color(0xFF9199A4)),
              filled: true,
              fillColor: const Color(0xFFF1F4F9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF1C98F8),
                  width: 2,
                ),
              ),
            ),
          ),
          if (isPassword)
            Positioned(
              right: 16,
              child: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
