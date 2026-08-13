# Verland_Hrim
Private operations repository for the Verland_Hrim Asheron's Call shard.

## What lives here
- **docs/** - operations doctrine, setup guide, investigation dossiers,
  post-mortems. The doctrine is the master reference.
- **scripts/** - the complete ops & diagnostic tool library (PowerShell
  for the Windows side, bash for the server side).
- **content/** - custom content workspace: SQL deltas, GemForge/SpellForge
  exports, content change log.
- **backups/** - periodic offsite copies of server database dumps
  (large files; committed sparingly).

## What NEVER lives here
- Passwords, keys, credentials of any kind (keyring lives elsewhere)
- DAT files (900MB binaries - covered by snapshots + local masters)

## The server
Production: Vultr, Atlanta - WorldName `Verland_Hrim`
See docs/VerlandHrim_Operations_Doctrine.md for everything.

## Rule 14
A ThwargLauncher entry's name must be byte-identical to the server's
WorldName, or the launcher silently kills the client. This cost two days
to learn. It is not negotiable.
