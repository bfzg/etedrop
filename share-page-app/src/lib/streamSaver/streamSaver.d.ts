import type streamSaverDefault from "streamsaver";

declare const streamSaver: typeof streamSaverDefault & {
  resetMitmTransporter: () => void;
};

export default streamSaver;
