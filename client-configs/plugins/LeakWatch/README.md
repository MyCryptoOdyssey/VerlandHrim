# LeakWatch

Memory monitor and lag-death guardian for Asheron's Call clients.

The AC client is a 32-bit program that slowly consumes memory as you play and
never fully releases it - an original-engine limitation. As usage climbs, the
game hitches, stutters, and eventually hangs or crashes ("lag death").
LeakWatch shows each client's memory pressure at a glance, warns you in chat
as it climbs, and can automatically recall and/or log the character out
before the engine starves.

## What it shows

A small panel on the **Virindi bar** (heart icon) with a live percentage:

| Display | Meaning |
|---|---|
| **Green** (below 70%) | Healthy |
| **Yellow** (70-85%) | Getting low - plan a relog |
| **Red** (85%+) | Danger - relog soon |

The percentage is measured against the client's *practical* memory ceiling,
not the theoretical maximum - **100% means the client is done**, so the
number never understates the danger. Chat warnings fire once at 75% and
again at 90%.

## Protection options

| Auto-Recall | Auto-Logout | At 90% |
|---|---|---|
| checked | - | Recalls to **Lifestone**, stays logged in |
| - | checked | Logs out in place (frees the memory) |
| checked | checked | Recalls first, then logs out once the cast lands |
| - | - | Warnings only |

Notes:
- The recall used is **Lifestone recall** (`/lifestone`) - every character
  has it, no spell or components required.
- Before any action, LeakWatch disables VTank combat so the recall cast
  isn't interrupted.
- Logging out is the only thing that actually frees the leaked memory;
  recalling just parks the character somewhere safe.
- Actions fire at most once per 3 minutes.

## Requirements

| Component | Notes |
|---|---|
| Asheron's Call client | end-of-retail, Windows 10/11 |
| Decal 2.9.8.2+ | decaldev.com |
| Virindi View Service | part of the Virindi bundle (virindi.net) |
| VTank | only needed for the combat-disable step of auto actions |

## Install

**Before you start:** close all AC clients and ThwargLauncher. Plugin
registration can fail while a client is running.

1. Create folder: `C:\Games\Decal Plugins\LeakWatch\`
2. Put `LeakWatch.dll` (from Releases) in it.
3. Right-click `LeakWatch.dll` > Properties > if an **Unblock** checkbox
   appears, check it > OK.
4. Decal > **Add** > **Browse** > `LeakWatch.dll` > Save.
5. Launch clients with injection on. The heart icon appears on the
   **Virindi bar**.

## Recommended practice

- Yellow means "finish what you're doing", not "someday" - performance
  degradation begins before the red band on many systems.
- On long sessions, relog clients every 4-6 hours even if LeakWatch is
  quiet - fresh sessions are smooth sessions.
- For unattended/multibox characters, check both boxes: a character that
  recalls and logs itself out beats one that lag-deaths in a dungeon.

## Build from source

Files: `LeakWatchPlugin.cs`, `view.xml`, `build.bat`. Edit the Decal/VVS
paths at the top of `build.bat` if needed, run it. Uses the C# compiler
included with Windows. Output: `LeakWatch.dll`.

## Credits

Decal team - the platform. Virindi - View Service UI. The ACEmulator
project and server communities keeping Dereth alive.

*Asheron's Call is a trademark of its respective owners. Fan-made tool, no
game assets distributed, not affiliated with or endorsed by the rights
holders.*
