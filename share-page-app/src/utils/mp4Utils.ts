export function concatU8(a: Uint8Array, b: Uint8Array): Uint8Array {
  if (a.byteLength === 0) return b;
  if (b.byteLength === 0) return a;
  const out = new Uint8Array(a.byteLength + b.byteLength);
  out.set(a, 0);
  out.set(b, a.byteLength);
  return out;
}

export interface Mp4Box {
  type: string;
  data: Uint8Array;
}

export function splitMp4Boxes(buf: Uint8Array): {
  boxes: Mp4Box[];
  rest: Uint8Array;
} {
  const out: Mp4Box[] = [];
  let off = 0;
  while (buf.byteLength - off >= 8) {
    const dv = new DataView(
      buf.buffer,
      buf.byteOffset + off,
      buf.byteLength - off,
    );
    const size32 = dv.getUint32(0, false);
    const type = String.fromCharCode(
      dv.getUint8(4),
      dv.getUint8(5),
      dv.getUint8(6),
      dv.getUint8(7),
    );
    let boxSize: number | null = null;
    let headerSize = 8;

    if (size32 === 0) {
      break;
    } else if (size32 === 1) {
      if (buf.byteLength - off < 16) break;
      const size64 = dv.getBigUint64(8, false);
      if (size64 > BigInt(Number.MAX_SAFE_INTEGER)) break;
      boxSize = Number(size64);
      headerSize = 16;
    } else {
      boxSize = size32;
    }

    if (!boxSize || boxSize < headerSize) break;
    if (buf.byteLength - off < boxSize) break;

    out.push({ type, data: buf.subarray(off, off + boxSize) });
    off += boxSize;
  }
  return { boxes: out, rest: buf.subarray(off) };
}
