---
description: Build a Crestron SIMPL+ Project
---

This workflow builds a Crestron SIMPL+ project by running the `build-project.ps1` script in the `tools` directory.

// turbo
1. Run the build script for the specified project. When asked to build a project, you must substitute `<ProjectName>` with the actual name of the project folder in `projects/`.

```powershell
.\build-project.ps1 -ProjectName "<ProjectName>"
```

Run this command directly in the `D:\Antigravity\Crestron-Workspace\tools` directory.
