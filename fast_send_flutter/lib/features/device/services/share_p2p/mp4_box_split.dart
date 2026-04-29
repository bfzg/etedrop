import 'dart:typed_data';

/// ISO BMFF（mp4）顶层 box 切分；不完整尾部留在 [rest]。
({List<Uint8List> boxes, Uint8List rest}) splitIsoBmffBoxes(Uint8List buf) {
  final boxes = <Uint8List>[];
  var off = 0;
  while (buf.length - off >= 8) {
    final bd = ByteData.sublistView(buf, off);
    final size32 = bd.getUint32(0, Endian.big);
    int header = 8;
    int? size;
    if (size32 == 0) break;
    if (size32 == 1) {
      if (buf.length - off < 16) break;
      final size64 = bd.getUint64(8, Endian.big);
      header = 16;
      if (size64 > 0x7fffffff) break;
      size = size64;
    } else {
      size = size32;
    }
    if (size < header) break;
    if (buf.length - off < size) break;
    boxes.add(buf.sublist(off, off + size));
    off += size;
  }
  return (boxes: boxes, rest: buf.sublist(off));
}

bool isoBmffBoxTypeEquals(Uint8List box, String t) {
  if (box.length < 8) return false;
  final s = String.fromCharCodes(box.sublist(4, 8));
  return s == t;
}
