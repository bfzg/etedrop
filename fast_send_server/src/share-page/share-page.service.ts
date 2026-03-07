/**
 * 分享页 HTML 模板（最小可用：连接设备并显示在线/离线）
 * WS 使用当前页面的 host，便于同源部署
 */
export class SharePageService {
  renderSharePage(deviceId: string, shareCode: string): string {
    const escapedDeviceId = this.escapeHtml(deviceId);
    const escapedShareCode = this.escapeHtml(shareCode);

    return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>FastSend 分享</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: system-ui, sans-serif; margin: 0; padding: 24px; min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; background: #f5f5f5; }
    .card { background: #fff; border-radius: 12px; padding: 32px; max-width: 420px; width: 100%; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
    h1 { margin: 0 0 8px; font-size: 20px; color: #333; }
    .meta { font-size: 13px; color: #666; margin-bottom: 24px; }
    .status { padding: 12px 16px; border-radius: 8px; font-size: 14px; margin-bottom: 16px; }
    .status.pending { background: #fff8e1; color: #b45309; }
    .status.online { background: #e8f5e9; color: #2e7d32; }
    .status.offline { background: #ffebee; color: #c62828; }
    .status.error { background: #f5f5f5; color: #616161; }
    button { background: #1976d2; color: #fff; border: none; padding: 10px 20px; border-radius: 8px; font-size: 14px; cursor: pointer; }
    button:hover { background: #1565c0; }
    button:disabled { opacity: 0.6; cursor: not-allowed; }
  </style>
</head>
<body>
  <div id="app" class="card" data-device-id="${escapedDeviceId}" data-share-code="${escapedShareCode}">
    <h1>FastSend 分享</h1>
    <p class="meta">分享码：${escapedShareCode}</p>
    <div id="status" class="status pending">正在连接设备…</div>
    <button id="retry" type="button" style="display: none;">重新检测</button>
  </div>
  <script>
    (function() {
      var app = document.getElementById('app');
      var deviceId = app.getAttribute('data-device-id') || '';
      var shareCode = app.getAttribute('data-share-code') || '';
      var statusEl = document.getElementById('status');
      var retryBtn = document.getElementById('retry');

      function setStatus(className, text) {
        statusEl.className = 'status ' + className;
        statusEl.textContent = text;
      }

      function connect() {
        setStatus('pending', '正在连接设备…');
        retryBtn.style.display = 'none';

        var protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
        var wsUrl = protocol + '//' + location.host + '/api/share';
        var ws = new WebSocket(wsUrl);

        ws.onopen = function() {
          ws.send(JSON.stringify({ type: 'connect', deviceId: deviceId }));
        };

        ws.onmessage = function(ev) {
          try {
            var msg = JSON.parse(ev.data);
            if (msg.type === 'device-online') {
              setStatus('online', '设备在线，准备就绪');
              retryBtn.style.display = 'none';
              return;
            }
            if (msg.type === 'err') {
              if (msg.code === 'OFFLINE') {
                setStatus('offline', '分享者设备离线，请稍后再试');
              } else {
                setStatus('error', msg.msg || '连接异常');
              }
              retryBtn.style.display = 'block';
              return;
            }
          } catch (e) {
            setStatus('error', '消息解析失败');
            retryBtn.style.display = 'block';
          }
        };

        ws.onerror = function() {
          setStatus('error', '网络错误');
          retryBtn.style.display = 'block';
        };

        ws.onclose = function() {
          if (statusEl.className.indexOf('pending') !== -1) {
            setStatus('error', '连接已关闭');
            retryBtn.style.display = 'block';
          }
        };
      }

      retryBtn.onclick = connect;
      connect();
    })();
  </script>
</body>
</html>`;
  }

  private escapeHtml(s: string): string {
    const map: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
    };
    return s.replace(/[&<>"']/g, (ch) => map[ch] ?? ch);
  }
}
