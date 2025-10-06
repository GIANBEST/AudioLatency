# GIANBEST Audio Latency Optimizer 🚀

Un script simple y efectivo diseñado para reducir la latencia de audio en Windows 10 y 11. Ideal para gamers, streamers, productores de música y cualquier usuario que busque una respuesta de sonido más rápida y precisa.

Este proyecto automatiza la instalación de un servicio ligero en el sistema que se encarga de optimizar el procesamiento de audio, minimizando el molesto retraso entre la acción y el sonido.

---

## ✨ Características Principales

* **Instalación Automatizada:** Ejecuta un único archivo `.bat` como administrador y el script se encargará de todo.
* **Servicio Ligero:** El servicio instalado consume recursos mínimos y se ejecuta discretamente en segundo plano.
* **Fácil de Usar:** No se requieren conocimientos técnicos. La interfaz en la consola te guía en cada paso.
* **Incluye Desinstalador:** Se proporciona un script para revertir todos los cambios de forma limpia y segura, eliminando el servicio y los archivos.
* **Compatible:** Diseñado y probado para funcionar en Windows 10 y Windows 11.

---

## 🤔 ¿Cómo Funciona?

El script principal (`instalar.bat`) realiza las siguientes acciones:

1.  **Verifica los permisos** para asegurar que se ejecuta como Administrador.
2.  **Crea una carpeta** en `C:\AudioLatencyReducer`.
3.  **Descarga los componentes necesarios** (`nssm.exe` para gestionar servicios y `REAL.exe`, el optimizador).
4.  **Instala, configura e inicia un nuevo servicio** en Windows llamado `GIANBEST Audio Latency Reducer Service` para que se ejecute automáticamente.

---

## 🔧 Instalación

Sigue estos sencillos pasos para ponerlo en marcha:

1.  Ve a la sección de **[Releases](https://github.com/TuUsuario/TuRepositorio/releases)** de este repositorio.
2.  Descarga el script `GIANBEST_Optimizer.bat` (o el paquete `.zip` completo).
3.  Haz **clic derecho** sobre el archivo descargado y selecciona **"Ejecutar como administrador"**.
4.  Sigue las instrucciones que aparecerán en la pantalla. ¡Y listo!

---

## 🗑️ Desinstalación

Si deseas eliminar el servicio y todos los archivos:

1.  Descarga y ejecuta el script `desinstalar.bat` desde la sección de **[Releases](https://github.com/TuUsuario/TuRepositorio/releases)**.
2.  Asegúrate de ejecutarlo también como **administrador**.
3.  El script detendrá y eliminará el servicio, y borrará la carpeta de instalación.

---

## ⚠️ Descargo de Responsabilidad

Este es un proyecto personal y no oficial. Las herramientas descargadas (`nssm.exe`, `REAL.exe`) pertenecen a sus respectivos creadores. Utiliza este script bajo tu propio riesgo. No me hago responsable de posibles problemas en tu sistema, aunque ha sido diseñado para ser lo más seguro y reversible posible.
