import { IncomingMessage, Server as HttpServer } from 'node:http';
import { Socket } from 'node:net';

import { WebSocket, WebSocketServer } from 'ws';

interface UpgradeRoute {
  path: string;
  server: WebSocketServer;
}

export function createWsServer(
  onConnection: (ws: WebSocket) => void,
): WebSocketServer {
  const server = new WebSocketServer({ noServer: true });
  server.on('connection', onConnection);
  return server;
}

export function attachWsUpgradeHandler(
  httpServer: HttpServer,
  routes: UpgradeRoute[],
): void {
  httpServer.on(
    'upgrade',
    (request: IncomingMessage, socket: Socket, head: Buffer) => {
      const pathname = getPathname(request);

      for (const route of routes) {
        if (pathname !== route.path) {
          continue;
        }

        route.server.handleUpgrade(request, socket, head, (ws) => {
          route.server.emit('connection', ws, request);
        });
        return;
      }

      socket.destroy();
    },
  );
}

export function closeWsServer(server: WebSocketServer | undefined): void {
  if (!server) {
    return;
  }

  server.clients.forEach((socket) => socket.close());
  server.close();
}

function getPathname(request: IncomingMessage): string {
  const rawUrl = request.url ?? '/';
  return new URL(rawUrl, 'http://localhost').pathname;
}
