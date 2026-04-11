/**
 * Vendored streamSaver（含 resetMitmTransporter）；与 `streamSaver.js` 配对。
 */
declare const streamSaver: {
  createWriteStream(
    filename: string,
    options?: {
      size?: number;
      /** WritableStream backpressure strategy for the internal TransformStream writable side. */
      writableStrategy?: QueuingStrategy<Uint8Array>;
      /** ReadableStream backpressure strategy for the internal TransformStream readable side. */
      readableStrategy?: QueuingStrategy<Uint8Array>;
    },
  ): WritableStream<Uint8Array>;
  resetMitmTransporter: () => void;
  mitm?: string;
  WritableStream: typeof WritableStream;
  TransformStream: typeof TransformStream;
};

export default streamSaver;
