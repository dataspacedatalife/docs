# Tutorial básico: Acceso al clúster, carga de módulos y pruebas interactivas

## 1. Acceder al clúster:
### 1. Acceder al clúster mediante llave (no recomendado):

mediante SSH con llave  (sin VPN)

Para conectarte al clúster no es necesario utilizar VPN. El acceso se realiza directamente mediante SSH utilizando tu clave privada.

Abre una terminal en tu ordenador y ejecuta el siguiente comando:

```bash
ssh -i key usuario@ip
```

Donde:

- `key` es el archivo de tu clave privada SSH.
- `usuario` es tu nombre de usuario en el clúster.
- `ip` es la dirección IP o nombre del servidor. En nuestro caso será hpc-pps-1.dataspace.cesga.es
```

Por ejemplo:

```bash
ssh -i ~/.ssh/id_rsa juan@192.168.1.25
```

Si la conexión es correcta, el sistema te pedirá la *passphrase* de tu clave (si está protegida) y accederás al entorno del clúster.



### 1.1 Acceder al clúster mediante usuario y contraseña (recomendado)

Es posible la conexión con usuario y contraseña, mediante solicutud previa. En este caso se usará la misma que en el resto de servicios del CESGA.


Para conectarte al clúster no es necesario utilizar VPN. El acceso se realiza directamente mediante SSH.

Abre una terminal en tu ordenador y ejecuta el siguiente comando:

```bash
ssh usuario@hpc-pps-1.dataspace.cesga.es
```

Donde:

- `usuario` es tu nombre de usuario en el clúster.
- `ip` es hpc-pps-1.dataspace.cesga.es


Si la conexión es correcta, el sistema te pedirá la password  y accederás al entorno del clúster.

## 2. Entorno inicial tras el login

Una vez conectado, verás una terminal similar a esta:

```bash
[usuario@login01 ~]$
```

Esto indica que ya estás dentro del nodo de acceso (*login node*) del clúster.

Desde aquí podrás:

- Preparar tus trabajos.
- Cargar software.
- Enviar tareas al sistema de colas.
- Realizar pruebas ligeras.

> **Importante:** El nodo de acceso está destinado únicamente a tareas ligeras (compilación, edición de scripts, envío de trabajos y transferencia de datos). No debe utilizarse para ejecutar cálculos intensivos, ya que esto puede afectar al resto de usuarios.

## 3. Cargar módulos de software

El software en el clúster se gestiona mediante el sistema de módulos. Antes de utilizar un programa, es necesario inicializar el entorno de módulos adecuado.

En este clúster, el software se distribuye mediante EESSI (*European Environment for Scientific Software Installations*).

### 3.1 Inicializar los módulos EESSI

Debes cargar una de las versiones disponibles de EESSI:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
```

o

```bash
source /cvmfs/software.eessi.io/versions/2023.06/init/lmod/bash
```

Esto inicializa el entorno de módulos (Lmod) y habilita el acceso al software instalado.

### 3.2 Comprobar los módulos disponibles

Una vez inicializado el entorno, puedes explorar el software disponible con:

```bash
module spider
```

Este comando permite buscar programas y versiones disponibles dentro del entorno cargado.

Por ejemplo:

```bash
module spider gromacs
```

Si el programa aparece en la lista, significa que está disponible en esa versión de EESSI.

## 4. Selección de la versión de EESSI adecuada

Es necesario verificar qué versión de EESSI funciona correctamente para cada programa, ya que no todos los paquetes están disponibles o son compatibles en todas las versiones.

Procedimiento recomendado:

1. Cargar una versión de EESSI.
2. Ejecutar `module spider`.
3. Verificar que el programa deseado aparece.
4. Si no aparece o no funciona correctamente, cambiar de versión.

Ejemplos observados:

- WRF no funciona con EESSI 2023.06.
- GROMACS funciona con ambas versiones.

## 5. Realizar pruebas interactivas en nodos de cálculo (SLURM)

Para realizar pruebas o testeo sencillo, es recomendable utilizar un nodo de cálculo en modo interactivo en lugar del nodo de login.

### 5.1 Comprobar el estado de los nodos

Primero, consulta el estado de los nodos disponibles con:

```bash
sinfo
```

Busca nodos en estado:

- `idle`
- `mix`

Estos nodos tienen recursos disponibles.

### 5.2 Acceder a un nodo en modo interactivo

Para entrar en un nodo específico en modo interactivo, ejecuta:

```bash
srun --pty -w nombre_nodo /bin/bash
```

Donde:

- `nombre_nodo` es el identificador del nodo que deseas utilizar (por ejemplo: `node01`).

Ejemplo:

```bash
srun --pty -w node01 /bin/bash
```

Tras ejecutar el comando, verás un prompt similar a:

```bash
[usuario@node01 ~]$
```

Esto indica que ya estás trabajando directamente en un nodo de cálculo.

> **Nota:** Si quieres trabajar en MPI, el comando de `srun` es ligeramente distinto:

```bash
srun --pty -n numero_nodos -w nombre_nodo1,nombre_nodo2 /bin/bash
```

### 5.3 Cargar el entorno y ejecutar programas

Una vez dentro del nodo de cálculo, debes:

1. Inicializar el entorno de módulos.
2. Cargar los programas necesarios.
3. Ejecutar las pruebas.

Ejemplo típico:

```bash
source /cvmfs/software.eessi.io/versions/2025.06/init/lmod/bash
