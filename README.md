# rs-seatbelt

Zelfstandig gordelscript voor de Rico Scripts ESX-stack.

## Functies

- Gordel vast/los met `B` of `/gordel` in auto's
- Motorhelm op/af met dezelfde `B`-toets of `/gordel` op motoren
- Voorkomt dat GTA automatisch een helm opzet bij het motorrijden
- Verwijdert de handmatig gekozen helm bij het afstappen
- Voorkomt uitstappen zolang de gordel vastzit
- Uitslingeren en schade bij een zware botsing zonder gordel
- Werkt voor bestuurder en passagiers
- Slaat fietsen, boten, vliegtuigen en helikopters automatisch over
- Deelt de gordelstatus via `LocalPlayer.state.seatbelt`
- Deelt de helmstatus via `LocalPlayer.state.motorcycleHelmet`
- Koppelt automatisch met `rs-needs-hud`
- Centrale loggingcompatibiliteit via `rs_discordlogs`

Start `rs-seatbelt` vóór `rs-needs-hud`.
