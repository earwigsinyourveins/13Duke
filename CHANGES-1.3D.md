# xDuke -> Duke Nukem 3D v1.3D accuracy merge (work in progress, round 1)

Reference: recovered registered DOS v1.3D sources (APPVER 1.3D, LIBVER_BUILDREV=19960320),
with every #if/#ifdef resolved for the 1.3D build (VOLUMEALL+PLUTOPAK defined; WW2/NAM/EDUKE not).
Switch: Engine/src/duke13d.h (DUKE13D, default 1). Each change is `#if DUKE13D <1.3D> #else <old> #endif`.
Build with -DDUKE13D=0 to get the previous behaviour.  NOT yet compiled with MinGW; syntax-checked
only (no new errors vs. original, on Linux gcc with stubbed Windows headers).

## DONE
Engine/src/cache1d.c  (round 2, found with the supplied demo1.DMO)
- compress()/uncompress(): 1.3D LZW variant (9-bit start, byte-wise bit pointer, width grows at currstr>=oneup).
  xDuke's LZW is a later incompatible variant: it decoded 1.3D demo input into noise, which made the DM demo
  end immediately / crash.  Verified offline: with the 1.3D routine demo1.DMO decodes to exactly 19310 tics x 2
  players consuming the file to the last byte, with sane input (zeros at start, aim bit 23, weapon bits, ...).
  NOTE: this also changes savegame compression to the 1.3D format (old xDuke saves will not load).
Demo format (Game/src/game.c)
- opendemoread / opendemowrite: 1.3D header = reccnt(4), volume, level, skill, m_coop(1 each),
  multimode(2), m_monsters_off(2), 3x respawn(4). No version byte, no GRP CRCs, no m_ffire/playerai/
  names/auto_run/boardname/aim_mode/wchoice. Fields 1.3D lacks are reset to neutral on playback (ffire=1).
- closedemowrite: always back-patches tic count (fseek 0).
sector.c
- ldist: no +1.  isadoorwall: DOORTILE23 removed.  isanunderoperator: lotag 22 removed.
- activatebysector: first activator short-circuits, else operatesectors.  callsound returns sector number.
- operatesectors case 20: door flag from geometry.  operateactivators: no hitag 1/2 filter, no SE18.
- check_activator_motion: SE36 instead of SE18.
- checksectors: lotag>=10000 unbounded; mirror use without 1280 range; FEM10/TOUGHGAL not use-immune.
- checkhitwall: 1.3D fan/vending/tech-wall (W_TECHWALL1-4 only, no breakwall()), no SCREENBREAK14-19, light break w/o rnd().
- checkhitsprite: no PANNEL3/JURYGUY/TRIPODCAMERA/GENERICPOLE2 breaks, CLOCK restored, fixed-position scrap
  (4 TRAND, not 7), no actortype/pal6/cstat&16 special cases, timetosleep=0, 1.3D freezer & knock-back rules.
- animatewalls: SCREENBREAK14-19 removed (they consumed TRAND).
- cheatkeys: whole function replaced by 1.3D version.
player.c: aim() replaced (unconditional autoaim, plain weapon compare; signature kept).
gamedef.c: makeitfall gravity constant 176.   actors.c: friendly fire always on.

## KNOWN / NOT PORTED ON PURPOSE
- Audio/UI-only diffs (FTA 3rd arg, xyzsound z-source).
- operatesectors case 23 `i<0` guard kept (1.3D reads sprite[-1]; cannot be reproduced).
- hitawall return value (unused once the mirror range check is gone).

## TODO (function-level diff list vs 1.3D, in suggested order)
1. player.c: shoot, processinput, displayweapon, getinput (recorded bits must be 1.3D: bits 6/7 = look L/R,
   bit5 = auto_run|Run).
2. actors.c: moveeffectors, moveactors, movestandables, movetransports, moveexplosions, movefallers,
   moveweapons, checkavailweapon, addweapon, hitradius, ifhitbyweapon, movesprite, ifsquished, guts ...
   (also xDuke's 13 RANDOMSCRAP uses: 1.3D draws 3 fewer TRAND per scrap).
3. game.c: spawn, domovethings, getpackets, moveloop, checksync, faketimerhandler, badguy tables.
4. premap.c: resetpspritevars, enterlevel, newgame, prelevel, resetplayerstats (aim_mode reset on demo/solo).
5. gamedef.c parse/parsecommand (1.3D CON has 99 keywords), menues.c/sounds.c deltas.
6. Engine: engine.c (Build 19960320 vs later: clipmove, hitscan, updatesector...), mmulti.c.
RISK: argument evaluation order of EGS(...TRAND()...) differs between Watcom and gcc; verify against GAME.S/ACTORS.S.

## ROUND 3 (engine first, then player/actors/game/premap/CON)
Engine/src/engine.c  (reference: Build LIBVER 19960320)
- nsqrtasm/initksqrt: 1.3D square root = BSR-normalised lookup in a 2048-word table (xDuke uses a later 4096-word/shlookup one).
  Affects ksqrt(), slope z, hitscan/neartag slope handling, clipmove radius.
- getceilzofslope/getflorzofslope: 1.3D formula (divscale15 + dmulscale23).
- clipmove: no updatesector() on the "squeezed through a wall" early return.
- pushmove: 1.3D version (walls/sectors only; xDuke additionally pushes away from sprites).
- inside(), cansee(): 1.3D arithmetic.
- loadboard: no memset of sprite/sector/wall (stale data from previous level stays, as in 1.3D).
Game/src/player.c
- processinput(): whole 1.3D function (jump/gravity/lava/boots/knock-back/weapon state machine; look L/R from recorded bits).
- shoot(): whole 1.3D function (no GROWSPARK; 1.3D ammo, clipdist, OOZ and water-splash rules).
- getinput(): bits 6/7 are look-left/right again (xDuke overwrote them with autoaim/autoswitch); medkit bit unfiltered.
- weapon_tiles[] added.
Game/src/actors.c: movesprite, insertspriteq (fixed 64-entry decal queue), ifsquished, moveplayers, movedummyplayers, movefta,
  ifhitbyweapon, addweapon, movefallers, guts, hitradius, moveweapons, moveexplosions, movetransports, movestandables,
  moveactors, moveeffectors, checkavailweapon -> 1.3D versions.
Game/src/game.c: spawn(), badguy(), badguypic() -> 1.3D (monster lists, laser/frame-effect/clock/blimp rules, RNG order).
Game/src/gamedef.c: parse() -> 1.3D CON semantics (size change steps, weapreccnt 256, debris RNG, ifspawnedby, quickkick...).
Game/src/premap.c: pickrandomspot, resetplayerstats, resettimevars -> 1.3D; player colour assignment (ud.player_color added);
  aim_mode reset in newgame(); no SCREENBREAK14-19 animwalls.
Game/src/duke3d.h: TICRATE=120, TICSPERFRAME=4 fixed under DUKE13D.

## NOT DONE / UNVERIFIED
- Nothing was run: only gcc -fsyntax-only on Linux against the original (no new errors).
- moveeffectors/actors: recovered C for the effector loop is only partly verified; GAME.S/ACTORS.S is the authority.
- gamedef.c parsecommand (CON compiler) left as xDuke (1.3D differences are mostly xDuke-only extra commands).
- game.c: getpackets, domovethings, fakedomovethings, faketimerhandler, checksync, nonsharedkeys/cheats (net/UI/cheat paths) not compared in depth.
- Argument evaluation order of EGS(...TRAND()...) (Watcom vs gcc) not yet checked against the assembly.
- displayweapon/menu/sound/config code deliberately untouched (render/UI).

## ROUND 5 (merged onto the user's 13Duke-1.1 tree: timer/tic counter + demo playback controls kept as-is)
- global.c FindDistance2D: added the two 1.3D zero-axis returns (iy==0 -> ix, ix==0 -> iy), as in MACT mathutil.c. Without them axis-aligned distances came out ~4% short (affects ldist, targeting, radius checks). FindDistance3D already matched 1.3D. Thanks to HellFire aka reu for pointers.
- game.c vglass(): 3 TRAND per glass piece in the order xvel, ang, tile (GAME.S vglass_), no z jitter.
  (xDuke drew a 4th TRAND per piece -> RNG diverged at every window shatter.)
- game.c domovethings: xDuke "multiflag" save/load block (input bit 17) disabled under DUKE13D.
- game.c: Win32 crash logger (13duke_crash.txt).  First report resolved with the supplied exe's symbols:
  fault = drawrooms+0xd91, POV player cursectnum == -1 (squished out of the map by a door).
- engine.c drawrooms(): when the view sector is invalid (-1) render from the last valid sector instead of
  indexing sector[-1] (DOS read harmless garbage there; on Windows the garbage wallptr faults).  Render-only.

## ROUND 6
- CRASH ROOT CAUSE (door squish, POV player 1, ~15 s into the Hollywood demo): engine.c cansee() faulted on
  `sub edx,[ecx+_wall]` = wall[wal->point2].x, with ecx=0xA9B40 -> address 0x70B460 exactly = the reported fault
  address.  cansee() was called with the POV player's cursectnum == -1 (player squished out of the map); DOS reads
  harmless garbage from sector[-1], here the garbage wall index is far outside wall[].
  (Identified by locating the code shift between the supplied exe and the crashing build via call-site alignment of the
  logged return addresses, then disassembling the fault instruction.  The r5 drawrooms() guard was a wrong lead; it is
  harmless render-only code and was left in.)
- engine.c cansee(): returns 0 when either sector is not a valid sector index.
- Crash logger now also writes: the faulting function name (read from the exe's own COFF symbol table), a function
  name for every stack return-address candidate, and the raw code bytes around the fault.  Needs an exe that still
  has its symbols (do not strip).
- Desync at ~13:40 (tic ~24600): NOT yet explained.  Observation from the demo input stream: the only rare input in
  that window is P1 pressing "use inventory" (bit 30) together with weapon-3 select and jump (0x40000301) at tic 24608
  (= 13:40.3).  P0 holds bits 16/24/29 (medkit/holo/open) continuously for long stretches.
  Suggested experiment: play the demo with POV = player 1 the whole time (the crash is fixed now) to rule out the
  POV switch as a cause.

## ROUND 7 (merged onto the user's 13Duke-1.3 tree: icon/resource build + menues.c changes kept)
- game.c displayrest(): automap "visited sectors" update is skipped when the POV player's cursectnum is invalid.
  Second crash of the door-squish sequence (after cansee): sector[-1] garbage wallnum led to sector[27325].lotag.
  Found from the improved crash log: "fault in function: _displayrest+0xAA" and the decoded code bytes
  (cmp word [esi+0x22],0x7FFF = sector[i].lotag == 32767).
- NEW diagnostic simulation trace (game.c Duke13D_Trace): create an empty file 13duke_trace.on next to the exe,
  run a demo, and 13duke_trace.csv is written, one line per simulation tic BEFORE it is simulated:
    tic, time(s), randomseed, hash_sprites, hash_sectors, hash_walls,
    then for every player: avel, horz, fvel, svel, bits(hex), x, y, z, ang, sector, health, weapon, zvel
  Use: compare two builds' traces with a diff tool -> the first differing line is the first diverging tic, and the hash
  columns say whether sprites, sectors or walls diverged first.  A new "# new demo" comment line marks each demo start.
- Verified: gcc (-m32 -O2) evaluates the random draws inside EGS(...) argument lists right-to-left, the same as Watcom
  (checked against ACTORS.S guts_ and GAME.S vglass_), so those statements agree between the two compilers.
- Verified: the 1.3D simulation code does not read the wall clock (totalclock); demo playback pace cannot change results.
- HFIOD2 (E1L8) demo notes: input stream freezes (identical input for ~60 tics) at tics 2817-2873 = DOS recording stalled
  for ~2 s at ~94-96 s; desync is reported shortly before the first pause at tic 3007 (100.2 s).

## ROUND 8
- Merged user's config.c (BFullScreen = 0).
- Makefile: OPT variable (default -O2).  Test with:  make clean  &&  make OPT="-O0 -g"
- quickkill() is now traced: the trace CSV gets "# EVENT tic=N QUICKKILL player=P at file:line sect pos zvel hp falling on_ground"
  for every kill, so the exact killing code path of any death is recorded.
- Analysis of the HFIOD2 trace (user-supplied, 0-86 s):
  * ksqrt port verified numerically (0 mismatches vs an independent model of the original asm over 388,943 values).
  * pushmove (byte-verified against the 1.3D exe by the recovered project) returns OK at P0's death position for
    all eye heights -> pushmove is NOT what killed P0 at tic 1628.
  * P0's death at 54.3 s (hp 80 -> 0 right after P1 fired a shotgun) looks legitimate: the human's recorded input
    switches from steady running to erratic dead-player flailing, exactly like the uncontested death at 16.5 s.
    So the simulation is believed in sync up to at least ~57 s; the desync lies later.
  * No other anomaly found by input/behaviour analysis in 57-86 s (one 1.3 s stall at (8023,-11995) while the human
    presses open/quick-kick, consistent with a door).

## ROUND 9
- GRP policy (1.3D only): only the Shareware 1.3D and Full 1.3D base GRPs are recognised (crc32lookup / MAX_KNOWN_GRP = 2).
  A Plutonium 1.4 or Atomic 1.5 base GRP (or the 1.5 DC pack) is now a fatal error with an explanatory message.
  Unknown/modified base GRPs still get the existing warn-and-confirm prompt.
- Autoaim is not configurable any more (1.3D has no such option; aim() was already the unconditional 1.3D version):
  options-menu item removed (menu re-indexed, Parental Lock moved up), config AutoAim not read/written (always 2),
  in-game toggle key and /disableautoaim command-line switch disabled.  (The key still appears in the key-binding list
  but does nothing.)
- Trace: "# EVENT RESPAWN player=P spot=I of N pos=... seed_after=..." is logged for every spawn-spot choice.
- HFIOD2 findings (traces 13duke_trace.csv / _1.csv, DOS kill counts 2/3 vs ours 1/2 at the pause):
  * Same build, same demo, two playbacks (one with fast-forward + POV switching): seed, sectors, walls and all player
    state identical for all 2592 shared tics; only one sprite's data differs from tic 1098.  Gameplay does not depend on
    POV or playback speed.
  * Our deaths: P1 at 9.9 s, P0 at 16.5 s and 54.3 s (P0 3rd respawn at tic 1735, spawn spot 2 of 8).
    Aim alignment of both shooters is near-perfect until ~56 s and lost after P0's 3rd respawn -> the divergence is at or
    just before that respawn (spawn spot = TRAND % numplayersprites, i.e. RNG-sequence dependent).
