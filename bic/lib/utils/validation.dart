class Validations {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'ناوی بەکارهێنەر پێویستە';
    final RegExp nameExp = RegExp(r'^[A-Za-z ]+$');
    if (!nameExp.hasMatch(value)) {
      return 'تکایە تەنها پیتی ئینگلیزی بنووسە';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'تکایە ئیمەیڵەکەت بنووسە';
    final RegExp nameExp = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$");
    if (!nameExp.hasMatch(value)) return 'ئیمەیڵ دروست نییە';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty || value.length < 6) {
      return 'وشەی نهێنی لانیکەم دەبێت 6 پیت بێت';
    }
    return null;
  }
}
