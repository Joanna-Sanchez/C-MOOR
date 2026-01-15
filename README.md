# Reproducing the C-MOOR RNA-seq Tutorial Locally with Docker (macOS)

This repository shows how to reproduce the C-MOOR DESeq2 +
clusterProfiler RNA-seq tutorial locally on macOS using Docker.

No SciServer or [AnVIL](https://anvil.terra.bio/#workspaces/c-moor-wcc-fa25/miniCURE-RNA-seq-wcc-2025) account is required.

---

## Requirements

- macOS (Intel or Apple Silicon)
- Docker Desktop

### How to check Docker installation on Terminal 

You will need to use the macOS **Terminal** application to run Docker commands.

A. Use Spotlight
   1. Press **Command + Space**
   2. Type 'Terminal'
   3. Press **Enter**
   4. A Terminal window will open
 

Check Docker installation:

```
docker --version
```
<img width="422" height="257" alt="Image" src="https://github.com/user-attachments/assets/cb22d3b8-dddf-46cb-8ef9-388110261319" />

If you don’t already have Docker installed, download it from [the official Docker Desktop download page](https://docs.docker.com/desktop/setup/install/mac-install/) and follow the instruction there. 

To verify the installation, run:

```
docker --version
```
from your terminal.

## 1. Clone this repository

```
git clone https://github.com/Joanna-Sanchez/C-MOOR.git cmoor-rnaseq-docker
cd cmoor-rnaseq-docker
```

## 2. Start the Docker container

```
docker run -it \
  --name cmoor_rnaseq \
  -v $(pwd):/home/rstudio \
  us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.19.1 \
```

This mounts the repository into the container at `/home/rstudio`.

## 3. Then you are now in the docker container, and can see something like
```
root@cc9ae92081c6:/#
```
from your terminal.

## 4. Now, let's clone the [C-MOOR cure-rnaseq reqpository](https://github.com/C-MOOR/cure-rnaseq).
```
cd /home/rstudio/
git clone https://github.com/C-MOOR/cure-rnaseq.git
```

## 5. To finish the remaining setup for the cloned repository,
```
cd /home/rstudio/cure-rnaseq
chmod +x anvil/C-MOOR_Startup_Script.sh
bash anvil/C-MOOR_Startup_Script.sh
```
If you see
```
fatal: destination path '/home/rstudio/cure-rnaseq' already exists and is not an empty directory.
```
just ignore.


## 6. Let's see if all packages were installed correctly. Start R inside the container
```
R
```

Verify packages:
```
library(DESeq2)
library(MarianesMidgutData)
data("midgut", package = "MarianesMidgutData")
midgut
```
Then you'll be able to see
```
class: DESeqDataSet
dim: 17559 30
metadata(1): version
assays(4): counts mu H cooks
rownames(17559): FBgn0000003 FBgn0000008 ... FBgn0267794 FBgn0267795
rowData names(54): baseMean baseVar ... deviance maxCooks
colnames(30): am1 am2 ... am29 am30
colData names(2): condition sizeFactor
```

To further navigate, see [exercise](https://github.com/Joanna-Sanchez/C-MOOR/tree/main/exercise).

## 7. To rerun the docker container we created:
```
docker ps -a
```
and check if there is running docker image.
```
CONTAINER ID   IMAGE                                                              COMMAND                  CREATED      STATUS      PORTS      NAMES
cc9ae92081c6   us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.19.1   "/opt/nvidia/nvidia_…"   2 days ago   Up 2 days   8787/tcp   cmoor_rnaseq
```

using `NAMES`
```
docker exec -it cmoor_rnaseq bash
```

### To save my changes
```
git add <script name>
git status  # this will show you what has been modified/added/deleted
git commit -m "add your message here"
git push
```