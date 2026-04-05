/**
 * Vendored streamSaver（含 resetMitmTransporter）；与 `streamSaver.js` 配对。
 */
declare const streamSaver: {
  createWriteStream(
    filename: string,
    options?: { size?: number },
  ): WritableStream<Uint8Array>;
  resetMitmTransporter: () => void;
  mitm?: string;
  WritableStream: typeof WritableStream;
  TransformStream: typeof TransformStream;
};

export default streamSaver;
