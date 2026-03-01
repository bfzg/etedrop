export interface WsMessage {
  type: string;
  [key: string]: unknown;
}
