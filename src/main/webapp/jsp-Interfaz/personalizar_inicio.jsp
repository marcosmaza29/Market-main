<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%@ include file="/WEB-INF/jspf/comun.jspf" %>
<%
String tienda=request.getParameter("tienda");
if(tienda==null || !Arrays.asList("market","juguetes","cosmeticos").contains(tienda)) tienda="market";
String token=(String)session.getAttribute("personalizacionInicialToken");
if(token==null){ token=java.util.UUID.randomUUID().toString(); session.setAttribute("personalizacionInicialToken",token); }
String nombre="market".equals(tienda)?"Minimarket Anais":("juguetes".equals(tienda)?"Juguetería":"Belleza y Cosméticos");
String primario="market".equals(tienda)?"#15803D":("juguetes".equals(tienda)?"#EA580C":"#A21CAF");
String secundario="market".equals(tienda)?"#166534":("juguetes".equals(tienda)?"#C2410C":"#86198F");
%>
<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Personaliza tu tienda</title>
<style>
*{box-sizing:border-box}body{margin:0;padding:24px;background:#f4f5f7;color:#1f2937;font-family:Arial,sans-serif}.panel{max-width:760px;margin:auto;background:white;padding:30px;border-radius:18px;box-shadow:0 12px 40px #00000012}h1{margin-top:0}.sub{color:#64748b}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:16px}.field{margin:18px 0}label{display:block;font-weight:600;margin-bottom:7px}input,select{width:100%;min-height:44px;border:1px solid #cbd5e1;border-radius:9px;padding:9px;background:white}input[type=color]{padding:3px;height:46px}.preview{padding:20px;border-radius:12px;margin:20px 0;border:1px solid #e2e8f0}.preview header{padding:15px;color:white;border-radius:9px}.btn{border:0;padding:12px 18px;border-radius:9px;background:#1d4ed8;color:white;font-weight:bold;cursor:pointer}.hint{font-size:13px;color:#64748b}@media(max-width:540px){body{padding:12px}.panel{padding:20px}}
</style></head><body><main class="panel">
<h1>Personaliza tu tienda antes de ingresar</h1><p class="sub">Configura la apariencia inicial de <strong><%=util.Html.esc(nombre)%></strong>. Podrás cambiarla después desde el panel de administración.</p>
<form method="post" action="<%=ctx%>/jsp-Interfaz/guardar_personalizacion_inicial.jsp">
<input type="hidden" name="tienda" value="<%=tienda%>"><input type="hidden" name="token" value="<%=token%>">
<div class="field"><label for="nombre">Nombre de la tienda</label><input id="nombre" name="nombre" maxlength="100" required value="<%=util.Html.esc(nombre)%>"></div>
<div class="field"><label for="fuente">Tipo de letra</label><select id="fuente" name="fuente"><option value="Inter">Inter</option><option value="'Segoe UI', sans-serif">Segoe UI</option><option value="Georgia, serif">Georgia</option><option value="'Comic Sans MS', cursive">Comic Sans</option></select></div>
<div class="grid"><div class="field"><label for="p">Color principal</label><input id="p" type="color" name="primario" value="<%=primario%>"></div><div class="field"><label for="s">Color secundario</label><input id="s" type="color" name="secundario" value="<%=secundario%>"></div><div class="field"><label for="f">Color de fondo</label><input id="f" type="color" name="fondo" value="#FFFFFF"></div></div>
<div class="field"><label for="logo">URL HTTPS del logo (opcional)</label><input id="logo" type="url" name="logo" maxlength="1000" placeholder="https://..."></div>
<div class="field"><label for="banner">URL HTTPS del banner (opcional)</label><input id="banner" type="url" name="banner" maxlength="1000" placeholder="https://..."></div>
<section class="preview" id="preview"><header id="previewHead"><strong id="previewName"><%=util.Html.esc(nombre)%></strong><div>Vista previa de tu tienda</div></header><p>Así se verá el estilo general de tu catálogo.</p></section>
<p class="hint">La configuración se guarda para esta tienda. Los productos y administradores permanecen separados por tienda.</p><button class="btn" type="submit">Guardar y entrar a la tienda</button>
</form></main>
<script>
const $=id=>document.getElementById(id);function update(){ $('previewName').textContent=$('nombre').value; $('previewHead').style.background=$('p').value; $('preview').style.background=$('f').value; $('preview').style.color=$('s').value; $('previewHead').style.borderBottom='5px solid '+$('s').value; $('preview').style.fontFamily=$('fuente').value; }
['nombre','p','s','f','fuente'].forEach(id=>$(id).addEventListener('input',update));update();
</script></body></html>
