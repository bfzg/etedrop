import { Injectable } from '@nestjs/common';

@Injectable()
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
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);min-height:100vh;display:flex;align-items:center;justify-content:center;padding:20px}
    .card{background:#fff;border-radius:16px;padding:32px;max-width:440px;width:100%;box-shadow:0 20px 60px rgba(0,0,0,.15)}
    .logo{font-size:24px;font-weight:700;color:#333;margin-bottom:4px}
    .meta{font-size:13px;color:#999;margin-bottom:24px}
    .status{padding:12px 16px;border-radius:10px;font-size:14px;margin-bottom:16px;display:flex;align-items:center;gap:8px}
    .dot{width:8px;height:8px;border-radius:50%;flex-shrink:0}
    .status.pending{background:#fff8e1;color:#b45309}
    .status.pending .dot{background:#f59e0b;animation:pulse 1.5s infinite}
    .status.online{background:#ecfdf5;color:#059669}
    .status.online .dot{background:#10b981}
    .status.error{background:#fef2f2;color:#dc2626}
    .status.error .dot{background:#ef4444}
    @keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
    .file-card{background:#f8fafc;border:1px solid #e2e8f0;border-radius:12px;padding:20px;margin-bottom:16px;display:none}
    .file-icon{font-size:40px;margin-bottom:12px}
    .file-name{font-size:16px;font-weight:600;color:#1e293b;word-break:break-all;margin-bottom:4px}
    .file-size{font-size:13px;color:#64748b}
    .pwd-section{margin-bottom:16px;display:none}
    .pwd-section label{display:block;font-size:13px;color:#475569;margin-bottom:6px;font-weight:500}
    .pwd-row{display:flex;gap:8px}
    .pwd-row input{flex:1;padding:10px 14px;border:1px solid #d1d5db;border-radius:8px;font-size:14px;outline:none;transition:border .2s}
    .pwd-row input:focus{border-color:#6366f1}
    .pwd-row input.err{border-color:#ef4444}
    .pwd-err{font-size:12px;color:#ef4444;margin-top:4px;display:none}
    .btn{display:inline-flex;align-items:center;justify-content:center;gap:6px;padding:12px 24px;border-radius:10px;font-size:15px;font-weight:500;border:none;cursor:pointer;transition:all .2s;width:100%}
    .btn-p{background:linear-gradient(135deg,#6366f1 0%,#8b5cf6 100%);color:#fff}
    .btn-p:hover{opacity:.9;transform:translateY(-1px)}
    .btn-p:disabled{opacity:.5;cursor:not-allowed;transform:none}
    .btn-s{background:#f1f5f9;color:#475569;margin-top:12px}
    .btn-s:hover{background:#e2e8f0}
    .progress{margin-top:16px;display:none}
    .progress-bar{height:6px;background:#e2e8f0;border-radius:3px;overflow:hidden;margin-bottom:8px}
    .progress-fill{height:100%;background:linear-gradient(90deg,#6366f1,#8b5cf6);border-radius:3px;transition:width .15s;width:0%}
    .progress-text{font-size:12px;color:#64748b;text-align:center}
    .done{text-align:center;padding:20px 0;display:none}
    .done .icon{font-size:48px;margin-bottom:8px}
    .done p{color:#059669;font-weight:500}
  </style>
</head>
<body>
  <div class="card" id="app" data-device-id="${escapedDeviceId}" data-share-code="${escapedShareCode}">
    <div class="logo">FastSend</div>
    <p class="meta">分享码: ${escapedShareCode}</p>
    <div id="status" class="status pending"><span class="dot"></span><span id="stxt">正在连接设备…</span></div>
    <div id="fcard" class="file-card">
      <div id="ficon" class="file-icon"></div>
      <div id="fname" class="file-name"></div>
      <div id="fsize" class="file-size"></div>
    </div>
    <div id="pwds" class="pwd-section">
      <label>此文件需要访问密码</label>
      <div class="pwd-row">
        <input type="password" id="pwdi" placeholder="请输入密码" />
        <button class="btn btn-p" id="vbtn" style="width:auto;padding:10px 20px">验证</button>
      </div>
      <div id="perr" class="pwd-err"></div>
    </div>
    <button id="dbtn" class="btn btn-p" style="display:none">下载文件</button>
    <div id="prog" class="progress">
      <div class="progress-bar"><div id="pfill" class="progress-fill"></div></div>
      <div id="ptxt" class="progress-text">准备下载…</div>
    </div>
    <div id="done" class="done"><div class="icon">✅</div><p>下载完成</p></div>
    <button id="rbtn" class="btn btn-s" style="display:none">重新连接</button>
  </div>
<script>
(function(){
  var el=document.getElementById,a=document.getElementById('app');
  var did=a.dataset.deviceId,sc=a.dataset.shareCode;
  var $=function(id){return document.getElementById(id)};
  var sEl=$('status'),stxt=$('stxt'),fcard=$('fcard'),ficon=$('ficon'),fname=$('fname'),fsize=$('fsize');
  var pwds=$('pwds'),pwdi=$('pwdi'),vbtn=$('vbtn'),perr=$('perr');
  var dbtn=$('dbtn'),prog=$('prog'),pfill=$('pfill'),ptxt=$('ptxt'),done=$('done'),rbtn=$('rbtn');
  var ws,pc,dc,fi=null,chunks=[],rcvd=0,total=0;

  function ss(c,t){sEl.className='status '+c;stxt.textContent=t;sEl.style.display=''}
  function fmt(b){if(b<1024)return b+' B';if(b<1048576)return(b/1024).toFixed(1)+' KB';if(b<1073741824)return(b/1048576).toFixed(1)+' MB';return(b/1073741824).toFixed(2)+' GB'}
  function icon(n){var e=(n.split('.').pop()||'').toLowerCase();var m={pdf:'\\ud83d\\udcd5',doc:'\\ud83d\\udcd8',docx:'\\ud83d\\udcd8',xls:'\\ud83d\\udcd7',xlsx:'\\ud83d\\udcd7',ppt:'\\ud83d\\udcd9',pptx:'\\ud83d\\udcd9',zip:'\\ud83d\\uddc4',rar:'\\ud83d\\uddc4',jpg:'\\ud83d\\uddbc',jpeg:'\\ud83d\\uddbc',png:'\\ud83d\\uddbc',gif:'\\ud83d\\uddbc',svg:'\\ud83d\\uddbc',webp:'\\ud83d\\uddbc',mp4:'\\ud83c\\udfac',mov:'\\ud83c\\udfac',mp3:'\\ud83c\\udfb5',wav:'\\ud83c\\udfb5',txt:'\\ud83d\\udcdd',md:'\\ud83d\\udcdd',json:'\\ud83d\\udcdd',js:'\\ud83d\\udcbb',ts:'\\ud83d\\udcbb',py:'\\ud83d\\udcbb',dart:'\\ud83d\\udcbb'};return m[e]||'\\ud83d\\udcc4'}

  function reset(){fcard.style.display='none';pwds.style.display='none';dbtn.style.display='none';prog.style.display='none';done.style.display='none';rbtn.style.display='none';fi=null;chunks=[];rcvd=0;total=0}

  function connect(){
    reset();ss('pending','正在连接设备…');
    var proto=location.protocol==='https:'?'wss:':'ws:';
    ws=new WebSocket(proto+'//'+location.host+'/api/share');
    ws.onopen=function(){ws.send(JSON.stringify({type:'connect',deviceId:did}))};
    ws.onmessage=function(ev){try{onWs(JSON.parse(ev.data))}catch(e){ss('error','消息解析失败');rbtn.style.display=''}};
    ws.onerror=function(){ss('error','网络连接失败');rbtn.style.display=''};
    ws.onclose=function(){if(sEl.className.indexOf('pending')!==-1){ss('error','连接已关闭');rbtn.style.display=''}};
  }

  function onWs(m){
    switch(m.type){
      case'device-online':ss('online','设备在线，正在建立 P2P 连接…');startRTC();break;
      case'answer':if(pc&&m.data)pc.setRemoteDescription(new RTCSessionDescription(m.data));break;
      case'ice-candidate':if(pc&&m.data)pc.addIceCandidate(new RTCIceCandidate(m.data)).catch(function(){});break;
      case'err':ss('error',m.code==='OFFLINE'?'分享者设备离线，请稍后再试':(m.msg||'连接异常'));rbtn.style.display='';break;
    }
  }

  function startRTC(){
    if(dc){try{dc.close()}catch(e){} dc=null}
    if(pc){try{pc.close()}catch(e){} pc=null}
    pc=new RTCPeerConnection({iceServers:[{urls:'stun:stun.l.google.com:19302'}]});
    dc=pc.createDataChannel('share',{ordered:true});
    dc.binaryType='arraybuffer';
    dc.onopen=function(){ss('online','P2P 已连接，获取文件信息…');dc.send(JSON.stringify({type:'share-request',shareCode:sc}))};
    dc.onmessage=function(ev){if(typeof ev.data==='string'){try{onDc(JSON.parse(ev.data))}catch(e){}}else{onChunk(ev.data)}};
    dc.onclose=function(){if(done.style.display==='none'||!done.style.display){ss('error','P2P 连接已断开');rbtn.style.display=''}};
    pc.onicecandidate=function(ev){if(ev.candidate&&ws&&ws.readyState===1)ws.send(JSON.stringify({type:'ice-candidate',data:{candidate:ev.candidate.candidate,sdpMid:ev.candidate.sdpMid,sdpMLineIndex:ev.candidate.sdpMLineIndex}}))};
    pc.oniceconnectionstatechange=function(){if(pc.iceConnectionState==='failed'){ss('error','P2P 连接失败，请重试');rbtn.style.display=''}};
    pc.createOffer().then(function(o){return pc.setLocalDescription(o)}).then(function(){ws.send(JSON.stringify({type:'offer',data:{sdp:pc.localDescription.sdp,type:pc.localDescription.type}}))}).catch(function(){ss('error','创建连接失败');rbtn.style.display=''});
  }

  function onDc(m){
    switch(m.type){
      case'share-info':fi=m;showFile(m);break;
      case'error':ss('error',m.message||'未知错误');rbtn.style.display='';break;
      case'verify-result':onVerify(m);break;
      case'file-meta':startRecv(m);break;
      case'file-done':finishDl();break;
    }
  }

  function showFile(i){
    ficon.textContent=icon(i.fileName);fname.textContent=i.fileName;fsize.textContent=fmt(i.fileSize);
    fcard.style.display='';sEl.style.display='none';
    if(i.hasPassword){pwds.style.display='';dbtn.style.display='none'}
    else{pwds.style.display='none';dbtn.style.display=''}
  }

  function onVerify(m){
    if(m.success){pwds.style.display='none';perr.style.display='none';dbtn.style.display=''}
    else{pwdi.classList.add('err');perr.textContent=m.error||'密码错误';perr.style.display='';vbtn.disabled=false}
  }

  function startRecv(m){chunks=[];rcvd=0;total=m.fileSize;dbtn.style.display='none';prog.style.display='';updProg()}
  function onChunk(d){chunks.push(d);rcvd+=d.byteLength;updProg()}
  function updProg(){var p=total>0?Math.min(100,rcvd/total*100):0;pfill.style.width=p.toFixed(1)+'%';ptxt.textContent=fmt(rcvd)+' / '+fmt(total)+' ('+p.toFixed(1)+'%)'}

  function finishDl(){
    prog.style.display='none';done.style.display='';
    var blob=new Blob(chunks);var url=URL.createObjectURL(blob);
    var a=document.createElement('a');a.href=url;a.download=fi?fi.fileName:'download';
    document.body.appendChild(a);a.click();document.body.removeChild(a);
    setTimeout(function(){URL.revokeObjectURL(url)},5000);
    chunks=[];
  }

  vbtn.onclick=function(){
    var p=pwdi.value.trim();
    if(!p){pwdi.classList.add('err');perr.textContent='请输入密码';perr.style.display='';return}
    pwdi.classList.remove('err');perr.style.display='none';vbtn.disabled=true;
    dc.send(JSON.stringify({type:'share-verify',password:p}));
  };
  dbtn.onclick=function(){dbtn.disabled=true;dc.send(JSON.stringify({type:'download-start'}))};
  rbtn.onclick=function(){
    if(dc){try{dc.close()}catch(e){} dc=null}
    if(pc){try{pc.close()}catch(e){} pc=null}
    if(ws){try{ws.close()}catch(e){} ws=null}
    connect();
  };
  pwdi.onkeydown=function(ev){if(ev.key==='Enter')vbtn.click()};
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
