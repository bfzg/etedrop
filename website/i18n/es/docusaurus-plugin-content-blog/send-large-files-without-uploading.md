---
slug: send-large-files-without-uploading
title: "Cómo enviar archivos grandes sin subirlos a la nube"
description: "Aprende a enviar archivos grandes sin subirlos a ningún servidor. P2P directo — sin nube ni límites de tamaño. Prueba EteDrop gratis."
authors: [etedrop]
tags: [large-files, p2p, privacy]
date: 2026-06-01
---

Cada subida a la nube son dos viajes: tu dispositivo → servidor → destinatario. Un archivo de 5 GB puede consumir ~10 GB de ancho de banda en la cadena — y el archivo queda en servidores ajenos.

EteDrop — diseñado para lo directo — lo reduce a un viaje: de dispositivo a dispositivo. Sin servidor en medio.

## El problema de subir

1. Subes al servidor
2. El servidor guarda (temporal o no)
3. Compartes enlace
4. El destinatario descarga del servidor

**Costes reales:** tiempo (dos tramos), privacidad, límites (2 GB gratis en muchos servicios), retención más larga de lo esperado.

## Qué es la transferencia P2P

De igual a igual, sin intermediario. WebRTC en el navegador — sin plugins; receptor sin instalar.

## Tres pasos (sin subir)

**Paso 1:** Abre [EteDrop](/down) en cualquier navegador moderno. Sin registro.

**Paso 2:** Elige archivos → enlace + código de recogida → comparte por SMS, email, Slack, etc.

**Paso 3:** El destinatario abre el enlace, introduce el código, previsualiza (PDF, imágenes, video, audio, código) y descarga.

*Avanzado:* modo LAN en la misma red; varios archivos en una sesión.

## Por qué P2P es más rápido

Nube: dispositivo → nube → dispositivo (dos tramos). P2P: dispositivo → dispositivo (uno). En LAN, velocidad cercana al hardware de red. 5 GB a ~50 Mbps: nube ~14 min vs P2P directo ~7 min (orientativo).

## Privacidad por arquitectura

El archivo no llega a un servidor. El servidor de señalización solo establece la conexión. Nadie más accede salvo el destinatario previsto.

Sin límites artificiales — solo conexión y estabilidad del navegador. 10+ GB: conexión estable; si se corta, reenviar (sin reanudación por ahora). P2P: ambos en línea — no asíncrono.

## Cuándo la nube sigue teniendo sentido

- Destinatario no disponible ahora
- Almacenamiento persistente / varias descargas
- Analítica y auditoría detalladas

## FAQ

**¿El receptor instala algo?** No — solo abre el enlace en el navegador.

**¿Límite de tamaño?** No artificial.

**¿Conexión cortada?** Reiniciar transferencia.

**¿Varios archivos?** Sí — previsualizar y descargar por separado.

**¿De verdad privado?** WebRTC directo; ningún servidor guarda el archivo; metadatos no retenidos tras completar.

**Envía archivos grandes sin subirlos a ningún servidor.** [Prueba EteDrop gratis →](/down)
