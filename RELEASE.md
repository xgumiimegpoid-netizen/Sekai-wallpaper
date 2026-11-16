# Publicar una actualización de Android

La app consulta `version.json` en `xgumiimegpoid-netizen/Sekai-wallpaper`, rama `main`, al abrirse. También permite buscar desde el menú lateral. El diálogo muestra las notas y abre el enlace HTTPS de descarga; Android gestiona la instalación con la confirmación del usuario.

Para publicar 1.5.3 (compilación 8):

1. Publicar una release `v1.5.3` en ese repositorio, adjuntando el APK compilado con el nombre `app-release.apk`.
2. Comprobar que el archivo puede descargarse.
3. Publicar el `version.json` preparado en la raíz del proyecto en `main`. Hacerlo después de adjuntar el APK evita anunciar una descarga inexistente.

La configuración local está preparada, pero no publica automáticamente la release ni modifica el manifiesto remoto. Los APK anteriores con el comprobador ya integrado podrán detectar la nueva versión cuando se publique el manifiesto.

Para versiones futuras, incrementar el número de compilación en `pubspec.yaml`, ajustar las constantes de respaldo de `UpdateChecker` y preparar el manifiesto correspondiente. En Android se consulta la versión instalada desde PackageManager. No se ofrece una compilación igual o inferior a la instalada.
