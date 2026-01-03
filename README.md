## Custom Environment Setup (C-MOOR)

This repository follows the original setup instructions provided in the  
[C-MOOR AnVIL workspace](https://anvil.terra.bio/#workspaces/c-moor-wcc-fa25/miniCURE-RNA-seq-wcc-2025).

### Custom Environment via Docker Image

The base environment is provided using the following Docker image:

```
docker pull us.gcr.io/broad-dsp-gcr-public/anvil-rstudio-bioconductor:3.19.1
```

### To save my changes
```
git add <script name>
git status  # this will show you what has been modified/added/deleted
git commit -m "add your message here"
git push
```