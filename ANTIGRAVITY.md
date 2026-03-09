# Antigravity Crestron Workspace Memory

This workspace is a standardized environment for Crestron SIMPL+ and SIMPL Window development, emphasizing modularity, visual professionality, and automated build processes.

## Environment & Tools
- **OS**: Windows 11 with WSL installed (Ubuntu/Debian).
- **Primary IDE**: VS Code with Antigravity.
- **Build Tool**: `tools/build-project.ps1`.
  - **Function**: Reconciles `projects/PROJECT_NAME/dependencies.json`.
  - **Logic**: Copies modular assets (.usp, .ush, .umc, .clz) from `modules/simpl` to the project's logic folder and then compiles local project logic.
  - **Critical Rule**: Dependencies are **copy-only**. We do not auto-recompile modular drivers during a project build to prevent `.ush` header corruption.

## Workspace Architecture

### 1. `modules/simpl` (The Modular Library)
Global, reusable drivers for hardware.
- **Cisco_ExternalSource_v2.0**: Parameter-driven SSH driver for Webex Codecs.
  - *Status*: Stabilized. Legacy `v1.0` decommissioned.
- **NvxRouteManager**: Centralized NVX directory.
- **PlanarDisplay / ShureMxw / ShureMxa920 / SonosControl**: Verified hardware drivers.

### 2. `projects/` (Project Instances)
Project-specific logic and configuration. Each folder follows `ClientName_ProjectDelineation(ProjectID)` naming.
- **LocktonDunning_GranitePark(JT022716)**:
  - **Headless Training Logic**: Refactored `Lockton_Training_Logic.usp` to operate automatically via Cisco feedback (Standby -> Power, Source -> Routing). No touchpanels in this room.
  - **Break Room / Restroom**: Traditional SIMPL logic modules.

## Coding Standards (The Bible: `SIMPL+Context.md`)
- **Hungarian Notation**:
  - `_b`: Digital (Boolean)
  - `_n`: Analog (Number/Integer)
  - `_s`: Serial (String)
  - `_fb`: Feedback
  - `p_`: Parameter
- **Visual Alignment**:
  - Use `_SKIP_` on I/O pins to maintain horizontal parity in SIMPL Windows symbols.
  - Use `_SKIP_` in Parameter blocks to push hardware attributes to the bottom of the symbol.

## Critical Lessons Learned (The 9999 Rule)
> [!IMPORTANT]
> **Signal Handle Collisions**
> SIMPL Windows `(144) Invalid Data [9999]` errors happen when multiple `.umc` modules use the same `H=9999` placeholder for unused/skip signals.
> **Fix**: Every module MUST have unique internal handle ranges for unused signals:
> - Cisco v1: 7901+
> - NVX: 8001+
> - Planar: 8101+
> - Shure MXA: 8201+
> - Shure MXW: 8301+
> - Sonos: 8401+

## Hardware Context
- **Cisco**: SSH/API control. Tracks Standby ("Off", "Halfwake", "Standby") and Active Source strings.
- **NVX**: Multicast routing via specialized RouteManager.
- **Planar**: Display control via serial/CEC.
- **Shure**: MXA920 (Ceiling) and MXW (Wireless) mic mute synchronization.

## Active Work & Next Steps
- **Status**: Clean baseline established. All project logic compiles with 0 errors.
- **Next**: Final deployment verification and system testing for Lockton Dunning.
