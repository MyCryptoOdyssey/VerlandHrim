# GemForge - custom gem icon pipeline (Phase 1: extraction)

Proven in sandbox: create/read/write dats, byte-identical roundtrips,
existing entries untouched by injection, iteration auto-bumped for DDD.

## One-time setup (server PC)
Unzip this kit anywhere, e.g. C:\GemForge\
The ACE server already uses .NET 8, so `dotnet` exists. Verify:
    dotnet --version

## STEP 0 - BACKUP (do not skip)
    Copy-Item C:\ACE\Dats\client_portal.dat C:\ACE\Dats\client_portal.dat.PRE-GEMFORGE.bak

## STEP 1 - sanity check the tool against your dat (read-only)
    cd C:\GemForge
    dotnet GemForge.dll info C:\ACE\Dats\client_portal.dat
Expect: Type=Portal Iteration=2072 (matches your server log line).

## STEP 2 - extract the Town Network gem icon (read-only)
Icon d_i_d 100674858 = hex 0x06002D2A:
    dotnet GemForge.dll extract C:\ACE\Dats\client_portal.dat 06002D2A tngem
    python rgba_png.py topng tngem
(needs Python + `pip install pillow`; if no Python on that PC, just send
 tngem.rgba + tngem.json to Claude instead - same result)

## STEP 3 - paste tngem.png into the Claude chat
Claude recolors it 8 ways with exact hex values and returns a palette
proof-sheet for approval BEFORE anything is injected.

## Later phases (Claude will walk each): inject 8 icons as IDs
0x06F00001-0x06F00008, enable DDD in Config.js, update gem weenie d_i_d 8
values via a sandbox-tested SQL card, restart, one-client verification.
