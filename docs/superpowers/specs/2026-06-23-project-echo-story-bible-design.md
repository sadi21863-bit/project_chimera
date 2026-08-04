# Project Echo — Story Bible & Design (v1)

> Status: draft for review. Names marked *(rename)* are placeholders.
> This is the narrative + high-level systems design. A separate implementation plan follows.

## Logline

A dorm. A rich, influential student is found dead. The police call it an accident; the
grieving residents move on by the next day. But the dead student's powerful family overrules
the police and brings in **you** — a detective nobody asked for — to prove it was murder.
The deeper you dig, the guiltier everyone looks. You build a case, accuse, and the police
take someone away. Then a flashback shows you the truth: **it was always an accident.** No
murder, no magic — just one student's hidden secret and a chain of small, innocent human
failures. You were the only thing that turned a tragedy into a crime. And you can't take it back.

## Themes

- **The detective is the intrusion.** A death barely changes ordinary lives — people grieve a
  day and move on. It's the investigation that tears the community open.
- **Confirmation bias as tragedy.** Pile up enough "evidence" and any innocent looks guilty.
- **Institutions distort truth.** The family, the police, and the media each bend the story to
  their own interests.
- **Strictly grounded.** Every uncanny element (the "ghost," the anonymous hint-giver) has a
  mundane, human explanation. No real supernatural — that's what makes the ending land.

## Pillars

1. The living dorm (autonomous sim) is the world; the detective is the intruder.
2. Grounded truth: it was an accident; every clue has an innocent explanation.
3. The investigation manufactures a culprit; all "murder" endings are wrong; the flashback reveals it.
4. Family, police, and media each distort the truth.

---

## The Victim — Daniel Crestwood *(rename)*

The heir of the **Crestwood family**, the donors the dorm (**Crestwood Hall**) is named after.
This single fact powers the plot: it's why the family can overrule the police and lean on the
university, and why Daniel was secretly living "like a normal student" in the building bearing
his name — to prove (to family/himself) he wasn't a spoiled heir.

His secret is one tangled web, not three loose threads:
- **Double life** — hiding the Crestwood name and the family-image pressure.
- **A quiet scheme** — to fund/protect the double life he ran something (money, favors, hushed
  arrangements) that entangled several dormmates (they owe, they pay, they hide it).
- **Self-medication** — stimulants to keep up the flawless façade, straining a heart he never
  had checked.

He died **alone, doing something hidden tied to all three**, impaired — see the true timeline.
Every layer the detective peels back looks like a fresh motive for someone to kill him. None is.

---

## The True Timeline — what actually happened *(canonical truth; refine freely)*

The cause of death: while secretly handling his scheme late at night in a low-traffic spot
(e.g. a maintenance/utility nook or a window ledge), impaired by stimulants + a hidden cardiac
strain, Daniel collapsed/fell. A purely accidental death.

What made it look like murder — **the chain of innocent acts**, one per suspect:

1. **Riley** earlier gave Daniel something harmless for a "headache"/insomnia (or noticed he
   looked unwell and said nothing). → Later reads as "Riley medicated him."
2. **Sam** had been tampering with the building wiring/cameras for a secret app — which disabled
   the one camera that would've shown the accident and left odd marks near the scene. → Reads as
   "evidence tampering / cover-up."
3. **Alex** (RA) used master keys that night for a mundane reason (quietly checking records about
   his failed semester / chasing a noise complaint). → Reads as "Alex had access and let himself in."
4. **Jordan**, rehearsing alone in the hallway, saw Daniel stumble, assumed he was drunk or that
   it was nothing, and walked on — then lied about being there (anxiety/embarrassment). → Reads as
   "last person seen with the victim, and he lied."
5. **Morgan** (early riser) found the body first and, panicking / to avoid involvement, moved one
   object (pills, a bottle, the phone) before the "official" discovery. → Reads as "staging the scene."
6. **Casey** (paints at odd hours) glimpsed fragments through a window and half-captured them in a
   sketch. → Reads as "a stalker-witness who knew too much."

No one intended harm. Combined, their small acts erased the accident and manufactured a murder.
**The flashback replays this night and recolors every clue above as innocent.**

---

## The Cast

### Core suspects — the six residents of Crestwood Hall
Each suspect = one real secret → one innocent act that night → the false motive it creates →
their distinct wrong-accusation ending. (Adapted from the existing `docs/crestwood-hall.md`.)

| Suspect | Real secret (innocent) | Innocent act that night | False motive (what you'll "prove") | If wrongly accused |
|--------|------------------------|-------------------------|-----------------------------------|--------------------|
| **Alex — the RA** | Failed last semester quietly; crush on Jordan | Used master keys for a mundane errand | Access + a secret the heir could expose | Loses the RA post + future; the one with "authority" falls |
| **Jordan — the Actor** | Audition anxiety; writes poetry about Riley | Rehearsing in the hallway; saw Daniel stumble, walked on, then lied | "Last seen with him, and he lied about it" | A promising future erased over stage fright |
| **Sam — the Hacker** | Building a secret app; owes Alex a favor | Touched the wiring/cameras; disabled the proof | "Tampered with evidence; entangled in the scheme" | The introvert branded a mastermind |
| **Riley — Pre-Med** | Considering dropping pre-med; hides care for Casey | Gave Daniel something harmless / stayed silent about symptoms | "Knew exactly how an overdose works" | A healer's career ended for an act of care |
| **Morgan — the Athlete** | Hidden injury; leadership rivalry with Alex | Found the body, moved one object in panic | Strength + bad blood + "staged the scene" | The loyal one destroyed for a moment of panic |
| **Casey — the Artist** | Secret portraits; "knows everyone's secrets" | Glimpsed the night through a window, sketched it | "Knew too much; the portraits look like stalking" | **The cruelest:** believed *because* they only watched |

> Casey doubles as the primary **hint-giver** (sees everything on campus) — see subplots.

### Supporting cast (lighter; not full murder-arcs)
- **The Crestwood family** — hired you, push hard for "murder," yet secretly bury Daniel's double
  life (it shames the name). They obstruct the parts that would reveal the accident.
- **Police** — a chief who was overruled (quietly helps), 1–2 detectives who resent you
  (antagonists), 1 ally who comes to believe you. They plant a watcher (the "spy," grounded).
- **University** — a dean / Daniel's advisor tied to the double life and the scheme.
- **News reporters** — turn a private accident into a public murder-circus; amplify your
  accusations until the accused are ruined publicly (a pressure/consequence system).
- **Background residents** — other students who simply *live* (the autonomous-sim crowd:
  grieve, then move on — the theme in motion).

---

## Subplots

- **Family & police interference (uncovered).** Both sides manipulate the investigation; exposing
  their interference is core investigation content and feeds the theme.
- **The ghost-master (grounded).** A person with a hidden agenda *hires someone to impersonate
  Daniel's ghost* to sow confusion/chaos. A self-contained red-herring arc that ends in the
  impersonator and the master being caught — never breaks the "no real magic" rule.
- **The hint-giver(s).** Anonymous tips that nudge you. Sources vary and are grounded: someone
  with guilty knowledge, a past victim of Daniel's bullying, or Casey (who "knows everything").
- **Student grudges.** The rivalries/secrets among residents — these *are* the false motives.

---

## Locations

- **Crestwood Hall (dorm)** — home base; the living sim; most suspects and daily routines.
- **Police station** — allies vs. antagonists; where accusations are weighed and arrests made.
- **University / college** — the dean, the advisor, the scheme's paper trail, the double life.

---

## Player Experience & Systems (summary)

Detailed mechanics → separate implementation plan. The spine:

- **Roam & find people.** A controllable detective avatar across the three locations. NPCs live
  on schedules (the sim), so locating someone — and *watching* where they go — is gameplay and
  evidence. (Reuses scheduler, navigation, day/night.)
- **Hybrid interrogation.** Approach a character → bring up a **topic/evidence** (keeps a small
  local model coherent) and/or **type a free-text question**. Responses are LLM-driven but
  **fenced by that character's authored knowledge, secret, mood, and trust in you.** They never
  volunteer the truth. (Ideal job for the local model; occasional fallback lines are harmless.)
- **Physical clues.** Examine rooms/objects → evidence, each with a hidden innocent true-meaning.
- **The notebook / case board.** Evidence + testimony assemble into **threads**, each a damning
  finger built from real-but-innocent facts.
- **Standing & relationships.** Factions/individuals start hostile or skeptical; earn their trust
  and they come to believe in you — which makes the wrong accusation hurt more. (Reuses the
  relationship system.)
- **Evidence-gated accusation.** Each suspect has a **case strength** that rises with evidence.
  Below the bar, the police refuse and your standing drops; only a sufficient case lets an
  accusation **stick → arrest → ending.** Stacking evidence against an innocent makes the wrong
  case *more* convincing.
- **Accusations wound relationships.** Suspecting/accusing someone tanks your standing with them
  **and their friends** (relationship web). Truth-seeking damages the community.

---

## Structure & Endings

- **The Call** — death ruled accidental; the dorm grieves and moves on; the family overrules the
  police and hires you.
- **The First Choice** — after seeing the evidence: **call it an accident** → short ending, the
  dorm heals, credits *(secretly the only "correct" outcome — the player won't know yet)*. Or
  **call it murder** → the investigation begins.
- **Act 1 — Intrusion** — you investigate; dorm + police resent you; you find first allies; peel
  Daniel's first secret layer; the "ghost" haunting begins.
- **Act 2 — The Web** — family/police interference, grudges, the scheme, the media circus; you
  expose the ghost-master; everyone looks guiltier.
- **Act 3 — The Accusation** — build a case to the bar, then name someone. **Each suspect = a
  distinct wrong ending,** scaled by how much you destroy.
- **The Flashback** — the true night replays; every clue recolors as innocent; you were wrong; no undo.

**Ending map:** one ending per accusable suspect (six), plus the **accident ending** at the First
Choice. The accident ending is the only non-tragic one — its meaning only lands on reflection/replay.

---

## Open questions (to resolve before/within the implementation plan)

1. **Victim's exact cause of death** — pick the precise accident (fall / cardiac collapse /
   electrocution via Sam's wiring) so the physical clues are concrete.
2. **Case-strength model** — how many evidence threads per suspect, and the accusation bar.
3. **Free-text fencing** — how strictly the LLM is constrained to authored knowledge (prompt
   guardrails + the existing rule-based fallback) given the intermittent local model.
4. **Scope for a first playable slice** — likely one location (the dorm), the First Choice, 2–3
   suspects, the core loop end-to-end — before expanding to all six + the station + university.
5. **Player identity/arc** — does the detective have their own backstory/stake, or are they a blank lens?
