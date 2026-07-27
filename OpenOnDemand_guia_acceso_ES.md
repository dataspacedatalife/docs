# Acceso al portal Open OnDemand

Esta guía explica cómo configurar tu acceso al portal **Open OnDemand** de CESGA y empezar a usarlo. El proceso solo hay que hacerlo una vez: generas tu par de claves SSH con un script y ya puedes entrar al portal desde el navegador.

## Requisitos previos

Antes de empezar necesitas:

- Un **usuario de LDAP** de CESGA (el mismo con el que accedes a los sistemas de CESGA).
- Acceso por terminal a tu directorio personal (`$HOME`).

## Paso 1 — Descargar y subir el script a tu `$HOME`

Primero descarga el script `activar_acceso.sh` en tu ordenador personal. Después tienes que copiarlo a tu directorio personal (`$HOME`) en el clúster de CESGA. Tienes varias formas de hacerlo según tu sistema operativo.

### Opción A — Desde Linux o macOS (comando `scp`)

Abre una terminal en tu ordenador, sitúate en la carpeta donde descargaste el script y cópialo con `scp`. Como el acceso al clúster se hace mediante clave privada, tienes que indicarla con la opción `-i` (la misma clave que ya usas para conectarte por SSH al clúster). Sustituye `RUTA_CLAVE_PRIVADA` por la ruta a tu clave y `TU_USUARIO` por tu usuario de LDAP:

```bash
scp -i RUTA_CLAVE_PRIVADA activar_acceso.sh TU_USUARIO@hpc-compute.dataspace.cesga.es:~/
```

Por ejemplo, si tu clave privada está en `~/.ssh/id_rsa`:

```bash
scp -i ~/.ssh/id_rsa activar_acceso.sh TU_USUARIO@hpc-compute.dataspace.cesga.es:~/
```

El `~/` del final indica que se copiará directamente a tu `$HOME`.

### Opción B — Desde Windows

Puedes usar una de estas herramientas:

- **MobaXterm** o **WinSCP:** conéctate a `hpc-compute.dataspace.cesga.es` con tu usuario de LDAP, indicando tu **clave privada** en los ajustes de la sesión (el mismo fichero que usas para acceder por SSH al clúster). Una vez conectado, arrastra el archivo `activar_acceso.sh` a tu carpeta personal.
- **Línea de comandos (PowerShell o CMD):** si tienes `scp` disponible, usa el mismo comando que en la Opción A, indicando tu clave privada con `-i` y la ruta local del archivo:

  ```bash
  scp -i RUTA_CLAVE_PRIVADA C:\ruta\a\activar_acceso.sh TU_USUARIO@hpc-compute.dataspace.cesga.es:~/
  ```

### Comprobar que el script está en tu `$HOME`

Una vez subido, conéctate al clúster y comprueba que el archivo está en tu carpeta personal:

```bash
cd ~
ls -l activar_acceso.sh
```

Si aparece el archivo en el listado, puedes continuar con el Paso 2.

## Paso 2 — Ejecutar el script

Ejecuta el script para generar tu par de claves SSH:

```bash
./activar_acceso.sh
```

Si aparece un error de permisos (`Permission denied`), dale permiso de ejecución y vuelve a lanzarlo:

```bash
chmod +x activar_acceso.sh
./activar_acceso.sh
```

El script genera automáticamente tu clave pública y privada, guarda la privada con el nombre por defecto en `~/.ssh/` y añade la clave pública a tu archivo `~/.ssh/authorized_keys`. No tienes que hacer nada más de forma manual.

## Paso 3 — Comprobar el acceso al portal

Abre un navegador y accede a:

**https://hpc2.dataspace.cesga.es**

Inicia sesión con tu **usuario de LDAP** de CESGA y tu contraseña. Si las credenciales son correctas, verás el panel principal de Open OnDemand.

## Paso 4 — Probar el acceso

Una vez dentro del portal, ya puedes empezar a trabajar. Dos formas de comprobar que todo funciona:

- **Shell:** abre una terminal en el clúster directamente desde el navegador, a través del menú de acceso *Shell* del portal.
- **Project Manager:** lanza un trabajo en el clúster desde el *Project Manager* de Open OnDemand.

Si cualquiera de las dos opciones funciona, tu acceso está correctamente configurado.

## Resolución de problemas

Algunas incidencias habituales y cómo resolverlas:

- **No puedes subir el script por `scp` (permiso denegado o autenticación fallida):** asegúrate de indicar tu clave privada con la opción `-i` (la misma que usas para conectarte por SSH al clúster), de usar tu usuario de LDAP y de conectarte a `hpc-compute.dataspace.cesga.es`. En Windows, si el comando `scp` no está disponible, usa MobaXterm o WinSCP como se indica en el Paso 1, configurando también tu clave privada en la sesión.
- **El script da error de permisos:** ejecuta `chmod +x activar_acceso.sh` antes de lanzarlo, como se indica en el Paso 2.
- **No puedes iniciar sesión en el portal:** verifica que usas tu usuario de LDAP de CESGA y que la contraseña es correcta.
- **La shell no conecta:** confirma que el Paso 2 se completó sin errores. Si el script no llegó a generar las claves o falló a mitad, vuelve a ejecutarlo.

Si el problema persiste, contacta con el equipo de soporte de CESGA indicando tu nombre de usuario y una descripción del error.