
### GitHub
https://github.com/aws/aws-parallelcluster/wiki/Migrate-SLURM-accounting-data-when-upgrading-to-a-newer-ParallelCluster-version

# Migración de la base de datos de SLURM

## — Backup del CLUSTER V2 — en caliente
```bash
mysqldump cluster_ohio_v2 \
  -h slurm-accounting-db.cluster-c928g2qkw62o.us-east-2.rds.amazonaws.com \
  -u clusteradmin -p \
  --ssl \
  --single-transaction \
  --routines --triggers --events > backup_cluster_ohio_v2_$(date +%Y%m%d_%H%M).sql
```

## — Backup del CLUSTER V3 —
```bash
mysqldump cluster_ohio_v3 \
  -h slurm-accounting-db.cluster-c928g2qkw62o.us-east-2.rds.amazonaws.com \
  -u clusteradmin -p \
  --ssl \
  --single-transaction \
  --routines --triggers --events > backup_cluster_ohio_v3_$(date +%Y%m%d_%H%M).sql
  ```

## VERIFICAR que ninguno está vacío y terminan bien
```bash
ls -lh backup_cluster_ohio_v*.sql

# debe terminar en "-- Dump completed"
tail -5 backup_cluster_ohio_v2_*.sql
tail -5 backup_cluster_ohio_v3_*.sql
```

## Realizar una copia de seguridad del estado de SLURM y del Job ID

Comprobar la ubicación en la que SLURM almacena su estado:

```bash
scontrol show config | grep -i StateSaveLocation
```

Crear el directorio de copia de seguridad:

```bash
sudo mkdir slurm.state.backup
```

Copiar el contenido del directorio de estado de SLURM:

```bash
sudo cp -a /var/spool/slurm.state/ slurm.state.backup/
```

## Cambiar los nombres de las tablas de `v2` a `v3`

Reemplazar todas las referencias a `cluster-ohio-v2` por `cluster-ohio-v3` dentro del archivo SQL:

```bash
sed -i.bak 's/cluster-ohio-v2/cluster-ohio-v3/g' \
  backup_cluster_ohio_v2_20260723_1149.sql
```

El comando genera una copia del archivo original con la extensión `.bak`.

## Detener los servicios de SLURM

Detener primero el controlador de SLURM:

```bash
sudo systemctl stop slurmctld
```

Detener el servicio de base de datos de SLURM:

```bash
sudo systemctl stop slurmdbd
```

## Eliminar y volver a crear la base de datos de `v3`

> **Advertencia:** este comando elimina completamente la base de datos `cluster_ohio_v3` y todos sus datos.

Eliminar y volver a crear la base de datos:

```bash
mysql \
  -h slurm-accounting-db.cluster-c928g2qkw62o.us-east-2.rds.amazonaws.com \
  -u clusteradmin \
  -p \
  --ssl \
  -e "DROP DATABASE cluster_ohio_v3; CREATE DATABASE cluster_ohio_v3;"
```

Conectarse a la nueva base de datos:

```bash
mysql cluster_ohio_v3 \
  -h slurm-accounting-db.cluster-c928g2qkw62o.us-east-2.rds.amazonaws.com \
  -u clusteradmin \
  -p \
  --ssl
```

## Importar la base de datos con los nombres modificados

Importar el archivo SQL en la base de datos `cluster_ohio_v3`:

```bash
mysql \
  -h slurm-accounting-db.cluster-c928g2qkw62o.us-east-2.rds.amazonaws.com \
  -u clusteradmin \
  -p \
  --ssl \
  cluster_ohio_v3 < archivo.sql
```

Sustituir `archivo.sql` por el nombre real del archivo SQL modificado. Por ejemplo:

```bash
mysql \
  -h slurm-accounting-db.cluster-c928g2qkw62o.us-east-2.rds.amazonaws.com \
  -u clusteradmin \
  -p \
  --ssl \
  cluster_ohio_v3 < backup_cluster_ohio_v2_20260723_1149.sql
```
---

# Modificar el siguiente JobID en Slurm (AWS ParallelCluster)

Procedimiento seguido para forzar que el siguiente JobID continúe desde un número
concreto (`FirstJobId`) tras migrar una nueva base de datos de Slurm al cluster.

- **Cluster:** `cluster-ohio-v3`
- **Versión de Slurm:** 25.11.4
- **StateSaveLocation:** `/var/spool/slurm.state`

> **Idea de fondo:** el contador del siguiente JobID **no** vive en la base de datos
> de accounting, sino en el fichero `job_state` dentro del `StateSaveLocation`.
> Para cambiarlo hay que fijar `FirstJobId` en la configuración **y** eliminar ese
> contador para que el nuevo valor surta efecto.

---

## Paso 1 — Calcular el número de partida

Consultar el último JobID registrado en la base de datos migrada y sumarle 1 para
no solapar con el historial:

```sql
SELECT MAX(id_job)+1 FROM `cluster-ohio-v3_job_table`;
```

El resultado es el valor de `FirstJobId`.

## Paso 2 — Añadir `FirstJobId` a la configuración

En ParallelCluster no se edita el `slurm.conf` principal, sino el fichero de
ajustes personalizados (los otros includes los regenera pcluster):

```bash
# Comprobar que no esté ya definido
grep -n FirstJobId /opt/slurm/etc/pcluster/custom_slurm_settings_include_file_slurm.conf

# Añadirlo (sustituir <numero> por el resultado del Paso 1)
echo "FirstJobId=<numero>" | sudo tee -a /opt/slurm/etc/pcluster/custom_slurm_settings_include_file_slurm.conf
```

> **Nota:** al no tocar el YAML del cluster, este cambio puede perderse en un futuro
> `pcluster update-cluster`. Si se ejecuta un update, revisar que la línea siga presente.

## Paso 3 — Parar el controlador

```bash
sudo systemctl stop slurmctld
sudo systemctl status slurmctld   # debe estar inactive/failed, no active
```

## Paso 4 — Borrar el contador de jobs del estado

```bash
# Copia de seguridad
sudo cp -a /var/spool/slurm.state/job_state /root/job_state.bak

# Borrar el contador y su respaldo automático
sudo rm -f /var/spool/slurm.state/job_state /var/spool/slurm.state/job_state.old
```

> **Importante:** borrar **solo** `job_state` y `job_state.old`. No tocar el resto de
> ficheros del directorio (`node_state`, `part_state`, `assoc_mgr_state`, etc.).

## Paso 5 — Arranque inicial limpio con `-i`

Como el servicio de systemd arranca con `-s` (recuperar estado) y `job_state` ya no
existe, fallaría con `No job state file to recover`. Hay que hacer **un** arranque
manual con `-i` (ignore) para que cree el `job_state` nuevo desde `FirstJobId`:

```bash
sudo -u slurm /opt/slurm/sbin/slurmctld -i
```

Verificar en otra terminal que se creó el fichero:

```bash
ls -l /var/spool/slurm.state/job_state   # debe existir, con fecha reciente
scontrol ping                            # el controlador debe responder UP
```

## Paso 6 — Devolver el control a systemd

Una vez creado `job_state`, pasar al servicio gestionado (ya con `-s`, que ahora
funciona porque el fichero existe):

```bash
# Parar el proceso manual
sudo pkill -f slurmctld
pgrep -af slurmctld               # no debe devolver nada

# Limpiar el estado failed de systemd (por los reintentos previos)
sudo systemctl reset-failed slurmctld

# Arrancar de forma normal
sudo systemctl start slurmctld
sudo systemctl status slurmctld   # debe mostrar active (running)

sudo systemctl start slurmdbd
sudo systemctl status slurmctld   # debe mostrar active (running)
```

## Paso 7 — Verificar el resultado

```bash
scontrol ping
sbatch --parsable --wrap="hostname"   # el JobID devuelto debe ser FirstJobId
scancel <id>                          # cancelar el job de prueba
```

---

## Incidencias resueltas por el camino

| Error | Causa | Solución |
|-------|-------|----------|
| `CLUSTER ID MISMATCH` (882 vs 134) | El estado local tenía el ClusterID viejo y la base migrada otro | Borrar el marcador `clustername` del `StateSaveLocation` para adoptar la identidad de la base migrada |
| `No job state file to recover` | Se borró `job_state` pero systemd arranca con `-s` | Arranque inicial manual con `-i` para regenerarlo |
| `Start request repeated too quickly` | systemd se rinde tras 5 reintentos | `systemctl reset-failed slurmctld` antes de rearrancar |

## Avisos no bloqueantes (opcional limpiar)

- `AccountingStorageUser is defunct` — parámetro obsoleto en la config; conviene eliminarlo.
- `chdir(/var/log): Permission denied` y `MailProg is invalid` — avisos menores, no impiden el arranque.
- `Down nodes: ...-dy-...` — nodos cloud dinámicos suspendidos; comportamiento normal en ParallelCluster.
