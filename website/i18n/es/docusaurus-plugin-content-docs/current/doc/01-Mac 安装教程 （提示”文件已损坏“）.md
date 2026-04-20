---
slug: mac-install-damaged
---

# Guía de instalación en Mac (mensaje "La app está dañada")

Si la aplicación no está firmada y notarizada con **Developer ID** de Apple, macOS puede mostrar un aviso de app dañada al abrirla por primera vez después de descargarla desde el navegador. Sigue estos pasos.

## 1. Aviso que puede aparecer

Al hacer doble clic en la app, podrías ver un aviso similar (normalmente indicando que fue descargada con Chrome / Safari):

![Aviso de app dañada](/img/mac-install-damaged-dialog.png)

## 2. Quitar el atributo de cuarentena en Terminal

Ejecuta este comando en **Terminal** (reemplaza la ruta por la ubicación real de **EteDrop.app** en tu Mac; si está en Aplicaciones, usa la ruta siguiente):

```bash
xattr -cr "/Applications/EteDrop.app"
```

Si no quieres escribir la ruta manualmente, primero escribe `xattr -cr ` (dejando un espacio al final), luego arrastra el **icono de la app desde Finder** a la ventana de Terminal para autocompletar la ruta y presiona Enter:

![Arrastrar la app a Terminal para completar la ruta](/img/mac-install-xattr-drag-to-terminal.png)

Cuando termine, vuelve a Finder y abre la app de nuevo.

---

:::tip

Si la app no está en **Aplicaciones**, ejecuta el comando sobre la **ruta real del archivo .app**.

:::

## 3. "Cerca" sigue buscando / no aparece el permiso de Red local

Desde **macOS Sequoia (15)**, el acceso a Red local se controla de forma más estricta. Si la app se distribuye sin firma y notarización con **Developer ID**, puede ocurrir lo siguiente:

- El sistema **no muestra** el aviso para permitir acceso a red local;
- O la app **no aparece** en **Configuración del sistema → Privacidad y seguridad → Red local**, por lo que el descubrimiento LAN (multicast UDP) puede bloquearse en silencio y la lista de dispositivos cercanos queda vacía.

**Revísalo manualmente:**

1. Abre **Configuración del sistema → Privacidad y seguridad → Red local**.
2. Busca **EteDrop** (o el nombre actual de la app) y activa el interruptor.
3. Si la app no aparece: ciérrala completamente y ábrela otra vez; espera unos segundos y vuelve a revisar. Si sigue sin aparecer, puede deberse a limitaciones de distribución sin firma. Se recomienda usar una **cuenta de desarrollador de Apple** para firma y notarización con Developer ID.

**Nota:** La lista "Cerca" **no muestra este dispositivo**; solo muestra **otros dispositivos en la misma LAN**. Para pruebas locales, usa dos dispositivos o una máquina virtual.

En macOS, la página "Cerca" dentro de la app también muestra un breve texto de ayuda.
