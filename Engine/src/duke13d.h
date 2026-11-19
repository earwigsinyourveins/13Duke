/* duke13d.h -- master switch for Duke Nukem 3D v1.3D (registered DOS) accuracy.
 *
 * When DUKE13D is 1 the simulation, engine behaviour and demo format follow the
 * recovered 1.3D executable instead of the 1.5 Atomic code that xDuke derives
 * from.  Every changed site is wrapped as
 *
 *     #if DUKE13D
 *         ...1.3D behaviour...
 *     #else
 *         ...original xDuke / 1.5 code...
 *     #endif
 *
 * so the original behaviour can be recovered by building with -DDUKE13D=0.
 */
#ifndef DUKE13D_H
#define DUKE13D_H
#ifndef DUKE13D
#define DUKE13D 1
#endif
#endif
