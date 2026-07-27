# Accessing the Open OnDemand Portal

This guide explains how to configure access to CESGA's **Open OnDemand** portal and start using it. You only need to complete this process once: the script generates your SSH key pair, after which you can access the portal from your web browser.

## Prerequisites

Before you begin, you will need:

- A CESGA **LDAP account** (the same account you use to access CESGA systems).
- Terminal access to your home directory (`$HOME`).

## Step 1 — Download and Upload the Script to Your `$HOME`

First, download the `activar_acceso.sh` script to your local computer. You must then copy it to your home directory (`$HOME`) on the CESGA cluster. The available methods depend on your operating system.

### Option A — Linux or macOS (`scp` Command)

Open a terminal on your computer, navigate to the folder where you downloaded the script, and copy it using `scp`. Because access to the cluster uses a private key, specify it with the `-i` option—the same key you already use to connect to the cluster via SSH. Replace `PRIVATE_KEY_PATH` with the path to your private key and `YOUR_USERNAME` with your LDAP username:

```bash
scp -i PRIVATE_KEY_PATH activar_acceso.sh YOUR_USERNAME@hpc-compute.dataspace.cesga.es:~/
```

For example, if your private key is stored at `~/.ssh/id_rsa`:

```bash
scp -i ~/.ssh/id_rsa activar_acceso.sh YOUR_USERNAME@hpc-compute.dataspace.cesga.es:~/
```

The final `~/` indicates that the file will be copied directly to your `$HOME` directory.

### Option B — Windows

You can use either of the following methods:

- **MobaXterm** or **WinSCP:** connect to `hpc-compute.dataspace.cesga.es` using your LDAP username and specify your **private key** in the session settings—the same file you use to access the cluster via SSH. Once connected, drag the `activar_acceso.sh` file into your home directory.
- **Command line (PowerShell or CMD):** if `scp` is available, use the same command as in Option A, specifying your private key with `-i` and the local path to the file:

  ```bash
  scp -i PRIVATE_KEY_PATH C:\path\to\activar_acceso.sh YOUR_USERNAME@hpc-compute.dataspace.cesga.es:~/
  ```

### Verify That the Script Is in Your `$HOME`

After uploading the script, connect to the cluster and verify that the file is in your home directory:

```bash
cd ~
ls -l activar_acceso.sh
```

If the file appears in the output, proceed to Step 2.

## Step 2 — Run the Script

Run the script to generate your SSH key pair:

```bash
./activar_acceso.sh
```

If you receive a permissions error (`Permission denied`), grant the script execute permission and run it again:

```bash
chmod +x activar_acceso.sh
./activar_acceso.sh
```

The script automatically generates your public and private keys, stores the private key under its default name in `~/.ssh/`, and adds the public key to your `~/.ssh/authorized_keys` file. No further manual configuration is required.

## Step 3 — Verify Access to the Portal

Open a web browser and go to:

**https://hpc2.dataspace.cesga.es**

Sign in using your CESGA **LDAP username** and password. If your credentials are correct, the Open OnDemand main dashboard will appear.

## Step 4 — Test the Connection

Once you are signed in to the portal, you can begin working. You can verify that everything is functioning correctly in either of the following ways:

- **Shell:** open a terminal on the cluster directly from your browser using the portal's *Shell* access menu.
- **Project Manager:** submit a job to the cluster using Open OnDemand's *Project Manager*.

If either option works, your access has been configured correctly.

## Troubleshooting

The following are common issues and their solutions:

- **You cannot upload the script using `scp` (permission denied or authentication failure):** make sure you specify your private key with the `-i` option—the same key you use to connect to the cluster via SSH—use your LDAP username, and connect to `hpc-compute.dataspace.cesga.es`. On Windows, if the `scp` command is unavailable, use MobaXterm or WinSCP as described in Step 1 and configure your private key in the session settings.
- **The script returns a permissions error:** run `chmod +x activar_acceso.sh` before executing it, as described in Step 2.
- **You cannot sign in to the portal:** verify that you are using your CESGA LDAP username and that your password is correct.
- **The shell does not connect:** confirm that Step 2 completed without errors. If the script did not generate the keys or stopped before completing, run it again.

If the issue persists, contact the CESGA support team and provide your username and a description of the error.
