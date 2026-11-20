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
- global.c FindDistance2D: added the two 1.3D zero-axis returns (iy==0 -> ix, ix==0 -> iy), as in MACT mathutil.c.
  Without them axis-aligned distances came out ~4% short (affects ldist, targeting, radius checks).
  FindDistance3D already matched 1.3D. Thanks to HellFire aka reu for pointers.
- game.c vglass(): 3 TRAND per glass piece in the order xvel, ang, tile (GAME.S vglass_), no z jitter.
  (xDuke drew a 4th TRAND per piece -> RNG diverged at every window shatter.)
- game.c domovethings: xDuke "multiflag" save/load block (input bit 17) disabled under DUKE13D.
- game.c: Win32 crash logger (13duke_crash.txt).  First report resolved with the supplied exe's symbols:
  fault = drawrooms+0xd91, POV player cursectnum == -1 (squished out of the map by a door).
- engine.c drawrooms(): when the view sector is invalid (-1) render from the last valid sector instead of
  indexing sector[-1] (DOS read harmless garbage there; on Windows the garbage wallptr faults).  Render-only.
