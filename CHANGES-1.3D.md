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
