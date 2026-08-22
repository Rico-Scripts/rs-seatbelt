# rs-seatbelt

Zelfstandig gordelscript voor de Rico Scripts ESX-stack.

## Functies

- Gordel vast/los met `B` of `/gordel`
- Voorkomt uitstappen zolang de gordel vastzit
- Uitslingeren en schade bij een zware botsing zonder gordel
- Werkt voor bestuurder en passagiers
- Slaat motoren, fietsen, boten, vliegtuigen en helikopters automatisch over
- Deelt de gordelstatus via `LocalPlayer.state.seatbelt`
- Koppelt automatisch met `rs-needs-hud`
- Centrale loggingcompatibiliteit via `rs_discordlogs`

Start `rs-seatbelt` vóór `rs-needs-hud`.
