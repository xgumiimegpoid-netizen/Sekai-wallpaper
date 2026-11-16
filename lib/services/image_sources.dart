/// Keep GitHub as a direct source when the catalog uses jsDelivr's branch cache.
List<String> imageSources(String url) {
  const cdn =
      'https://cdn.jsdelivr.net/gh/xgumiimegpoid-netizen/Wallpapers@DATA/';
  const raw =
      'https://raw.githubusercontent.com/xgumiimegpoid-netizen/Wallpapers/DATA/';
  if (url.startsWith(cdn)) return [url.replaceFirst(cdn, raw), url];
  return [url];
}
