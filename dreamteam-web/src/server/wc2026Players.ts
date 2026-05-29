/**
 * Hand-curated World Cup 2026 squad data. Free public APIs for full rosters
 * either require an API key (BALLDONTLIE, API-Football, SportsDataIO) or do
 * not publish player-level data (openfootball). This file is the stop-gap.
 *
 * Replace any team's array with real data once an API key is available.
 *
 * Position codes:   GK | DEF | MID | FWD   (mapped to 1..4 in DB)
 * Values are in £m, matching the existing FPL price convention.
 */
export type WcPlayer = {
  name: string;
  position: "GK" | "DEF" | "MID" | "FWD";
  value: number;
};

export type WcSquads = Record<string, WcPlayer[]>;

// ── Marquee squads (real names where confidently public) ────────────────
// Keyed by FIFA 3-letter code (matches Team.shortName below).
export const MARQUEE_SQUADS: WcSquads = {
  ARG: [
    { name: "E. Martínez", position: "GK", value: 5.0 },
    { name: "Romero", position: "DEF", value: 5.5 },
    { name: "Tagliafico", position: "DEF", value: 5.0 },
    { name: "Mac Allister", position: "MID", value: 7.5 },
    { name: "Fernández", position: "MID", value: 7.0 },
    { name: "Messi", position: "FWD", value: 11.0 },
    { name: "L. Martínez", position: "FWD", value: 9.0 },
    { name: "J. Álvarez", position: "FWD", value: 9.5 },
  ],
  BRA: [
    { name: "Alisson", position: "GK", value: 5.5 },
    { name: "Marquinhos", position: "DEF", value: 6.0 },
    { name: "Militão", position: "DEF", value: 5.5 },
    { name: "Casemiro", position: "MID", value: 6.5 },
    { name: "Vini Jr.", position: "FWD", value: 11.5 },
    { name: "Rodrygo", position: "FWD", value: 9.0 },
    { name: "Raphinha", position: "FWD", value: 8.5 },
    { name: "Endrick", position: "FWD", value: 7.5 },
  ],
  FRA: [
    { name: "Maignan", position: "GK", value: 5.5 },
    { name: "Saliba", position: "DEF", value: 6.5 },
    { name: "Upamecano", position: "DEF", value: 5.5 },
    { name: "T. Hernández", position: "DEF", value: 5.5 },
    { name: "Tchouaméni", position: "MID", value: 6.5 },
    { name: "Camavinga", position: "MID", value: 6.0 },
    { name: "Griezmann", position: "MID", value: 8.5 },
    { name: "Mbappé", position: "FWD", value: 13.0 },
    { name: "Dembélé", position: "FWD", value: 8.5 },
  ],
  ENG: [
    { name: "Pickford", position: "GK", value: 5.0 },
    { name: "Stones", position: "DEF", value: 5.5 },
    { name: "Saliba", position: "DEF", value: 6.0 },
    { name: "T. Alexander-Arnold", position: "DEF", value: 6.5 },
    { name: "Rice", position: "MID", value: 7.5 },
    { name: "Bellingham", position: "MID", value: 11.0 },
    { name: "Foden", position: "MID", value: 8.5 },
    { name: "Saka", position: "MID", value: 9.5 },
    { name: "Kane", position: "FWD", value: 10.5 },
    { name: "Palmer", position: "FWD", value: 9.0 },
  ],
  ESP: [
    { name: "Unai Simón", position: "GK", value: 4.5 },
    { name: "Le Normand", position: "DEF", value: 4.5 },
    { name: "Cubarsí", position: "DEF", value: 5.5 },
    { name: "Carvajal", position: "DEF", value: 5.5 },
    { name: "Rodri", position: "MID", value: 8.0 },
    { name: "Pedri", position: "MID", value: 7.5 },
    { name: "Gavi", position: "MID", value: 6.5 },
    { name: "Yamal", position: "FWD", value: 10.0 },
    { name: "Nico Williams", position: "FWD", value: 8.5 },
    { name: "Morata", position: "FWD", value: 7.0 },
  ],
  GER: [
    { name: "ter Stegen", position: "GK", value: 5.0 },
    { name: "Rüdiger", position: "DEF", value: 5.5 },
    { name: "Tah", position: "DEF", value: 5.0 },
    { name: "Kimmich", position: "MID", value: 7.0 },
    { name: "Wirtz", position: "MID", value: 9.5 },
    { name: "Musiala", position: "MID", value: 9.5 },
    { name: "Gnabry", position: "FWD", value: 7.0 },
    { name: "Havertz", position: "FWD", value: 7.5 },
    { name: "Füllkrug", position: "FWD", value: 6.0 },
  ],
  POR: [
    { name: "Diogo Costa", position: "GK", value: 4.5 },
    { name: "Rúben Dias", position: "DEF", value: 6.0 },
    { name: "Cancelo", position: "DEF", value: 5.5 },
    { name: "B. Fernandes", position: "MID", value: 9.5 },
    { name: "Vitinha", position: "MID", value: 6.5 },
    { name: "Bernardo Silva", position: "MID", value: 7.5 },
    { name: "Leão", position: "FWD", value: 8.0 },
    { name: "Ronaldo", position: "FWD", value: 9.0 },
    { name: "Félix", position: "FWD", value: 7.0 },
  ],
  NED: [
    { name: "Verbruggen", position: "GK", value: 4.5 },
    { name: "Van Dijk", position: "DEF", value: 6.0 },
    { name: "De Vrij", position: "DEF", value: 4.5 },
    { name: "Dumfries", position: "DEF", value: 5.5 },
    { name: "Frenkie de Jong", position: "MID", value: 7.0 },
    { name: "Reijnders", position: "MID", value: 6.0 },
    { name: "Gakpo", position: "MID", value: 7.5 },
    { name: "Depay", position: "FWD", value: 7.0 },
    { name: "Simons", position: "FWD", value: 8.0 },
  ],
  BEL: [
    { name: "Casteels", position: "GK", value: 4.5 },
    { name: "Castagne", position: "DEF", value: 5.0 },
    { name: "De Cuyper", position: "DEF", value: 4.5 },
    { name: "Tielemans", position: "MID", value: 6.0 },
    { name: "De Bruyne", position: "MID", value: 10.0 },
    { name: "Doku", position: "MID", value: 7.5 },
    { name: "Lukaku", position: "FWD", value: 7.5 },
    { name: "Trossard", position: "FWD", value: 7.0 },
  ],
  CRO: [
    { name: "Livaković", position: "GK", value: 4.5 },
    { name: "Gvardiol", position: "DEF", value: 6.0 },
    { name: "Modrić", position: "MID", value: 7.0 },
    { name: "Kovačić", position: "MID", value: 5.5 },
    { name: "Pašalić", position: "MID", value: 5.5 },
    { name: "Kramarić", position: "FWD", value: 6.5 },
    { name: "Petković", position: "FWD", value: 5.5 },
  ],
  USA: [
    { name: "M. Turner", position: "GK", value: 4.5 },
    { name: "Robinson", position: "DEF", value: 5.0 },
    { name: "Richards", position: "DEF", value: 4.5 },
    { name: "T. Adams", position: "MID", value: 5.5 },
    { name: "McKennie", position: "MID", value: 6.0 },
    { name: "Musah", position: "MID", value: 5.0 },
    { name: "Pulisic", position: "FWD", value: 8.5 },
    { name: "Reyna", position: "FWD", value: 6.5 },
    { name: "Balogun", position: "FWD", value: 6.5 },
  ],
  MEX: [
    { name: "Ochoa", position: "GK", value: 4.5 },
    { name: "Araujo", position: "DEF", value: 5.0 },
    { name: "Edson Álvarez", position: "MID", value: 5.5 },
    { name: "L. Chávez", position: "MID", value: 5.0 },
    { name: "Antuna", position: "MID", value: 4.5 },
    { name: "Lozano", position: "FWD", value: 7.0 },
    { name: "Giménez", position: "FWD", value: 7.5 },
    { name: "Jiménez", position: "FWD", value: 6.0 },
  ],
  URU: [
    { name: "Rochet", position: "GK", value: 4.5 },
    { name: "Giménez", position: "DEF", value: 5.5 },
    { name: "Araújo", position: "DEF", value: 6.0 },
    { name: "Valverde", position: "MID", value: 8.0 },
    { name: "Bentancur", position: "MID", value: 5.5 },
    { name: "Pellistri", position: "MID", value: 5.0 },
    { name: "Núñez", position: "FWD", value: 8.0 },
    { name: "Cavani", position: "FWD", value: 6.0 },
  ],
  COL: [
    { name: "Vargas", position: "GK", value: 4.5 },
    { name: "D. Sánchez", position: "DEF", value: 4.5 },
    { name: "Mojica", position: "DEF", value: 5.0 },
    { name: "James", position: "MID", value: 7.5 },
    { name: "Lerma", position: "MID", value: 5.0 },
    { name: "Cuadrado", position: "MID", value: 5.5 },
    { name: "Luis Díaz", position: "FWD", value: 8.5 },
    { name: "Borré", position: "FWD", value: 5.5 },
  ],
  MAR: [
    { name: "Bono", position: "GK", value: 4.5 },
    { name: "Hakimi", position: "DEF", value: 6.5 },
    { name: "Saiss", position: "DEF", value: 4.5 },
    { name: "Mazraoui", position: "DEF", value: 5.0 },
    { name: "Amrabat", position: "MID", value: 5.0 },
    { name: "Ounahi", position: "MID", value: 5.0 },
    { name: "Ziyech", position: "MID", value: 6.5 },
    { name: "En-Nesyri", position: "FWD", value: 6.5 },
  ],
  JPN: [
    { name: "Suzuki", position: "GK", value: 4.5 },
    { name: "Itakura", position: "DEF", value: 5.0 },
    { name: "Tomiyasu", position: "DEF", value: 5.0 },
    { name: "Endo", position: "MID", value: 5.5 },
    { name: "Kubo", position: "MID", value: 7.5 },
    { name: "Mitoma", position: "MID", value: 7.5 },
    { name: "Kamada", position: "MID", value: 6.0 },
    { name: "Ueda", position: "FWD", value: 5.5 },
  ],
  SEN: [
    { name: "É. Mendy", position: "GK", value: 4.5 },
    { name: "K. Koulibaly", position: "DEF", value: 5.5 },
    { name: "Mendy", position: "DEF", value: 4.5 },
    { name: "Pape Gueye", position: "MID", value: 5.0 },
    { name: "Mané", position: "FWD", value: 7.5 },
    { name: "Sarr", position: "FWD", value: 6.5 },
    { name: "Diatta", position: "FWD", value: 5.5 },
  ],
};

// Filler positions for the placeholder rosters of non-marquee teams.
// 2 GK + 3 DEF + 3 MID + 2 FWD = 10 per team is plenty of variety while
// still being lightweight to draft from.
const FILLER_POSITIONS: Array<{ position: WcPlayer["position"]; baseValue: number }> = [
  { position: "GK", baseValue: 4.0 },
  { position: "GK", baseValue: 4.0 },
  { position: "DEF", baseValue: 4.0 },
  { position: "DEF", baseValue: 4.5 },
  { position: "DEF", baseValue: 4.0 },
  { position: "MID", baseValue: 5.0 },
  { position: "MID", baseValue: 4.5 },
  { position: "MID", baseValue: 4.5 },
  { position: "FWD", baseValue: 5.5 },
  { position: "FWD", baseValue: 5.0 },
];

export function fillerSquadFor(teamCode: string): WcPlayer[] {
  return FILLER_POSITIONS.map((slot, idx) => ({
    name: `${teamCode} ${slot.position}${
      FILLER_POSITIONS.slice(0, idx + 1).filter((s) => s.position === slot.position).length
    }`,
    position: slot.position,
    value: slot.baseValue,
  }));
}
