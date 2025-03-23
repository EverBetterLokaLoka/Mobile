String formatTitle(String text) {
  String title = text.replaceAll(RegExp(r'_\d+$'), '');
  return title;
}
