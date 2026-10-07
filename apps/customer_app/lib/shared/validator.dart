String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Email wajib diisi';
  if (!v.contains('@')) return 'Format email tidak valid';
  return null;
}