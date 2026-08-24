# rs-seatbelt

Zelfstandig gordelscript voor de Rico Scripts ESX-stack.

## Functies

- Gordel vast/los met `B` of `/gordel` in auto's
- Motorhelm op/af met dezelfde `B`-toets of `/gordel` op motoren
- Drie meegeleverde helmprops: integraal, cross met bril en open chopperhelm
- Automatische helmkeuze voor sport, offroad, cruiser/chopper en scooter
- Live helm-afstelmodus via `/helmpositie`
- Werkende opzet- en afzetanimatie waarbij de helm halverwege wisselt
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

De positie en rotatie van iedere helmprop zijn instelbaar in `config.lua`.
De integraalhelm gebruikt een CC BY 3.0-bron; zie `CREDITS.txt`.

## Helmpositie afstellen

1. Ga op een motor zitten en zet de helm op met `B`.
2. Gebruik `/helmpositie`.
3. Pijltjes wijzigen X/Y en Page Up/Page Down wijzigt Z.
4. `R` wisselt tussen positie en rotatie; Shift maakt grotere stappen.
5. `Enter` kopieert het volledige objectblok en schrijft het ook naar F8.
6. `Backspace` annuleert en herstelt de oorspronkelijke waarden.

Plak het gekopieerde objectblok in het bijpassende profiel in `config.lua`.
