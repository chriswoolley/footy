import { Link } from "react-router-dom";
import { BrandBgLayers } from "../components/BrandBgLayers";

/**
 * Public rules / help page — reachable without logging in (see the route in
 * App.tsx, which sits outside <RequireAuth>). Pure static content, no API calls.
 */
export default function HowItWorks() {
  return (
    <div className="brand-bg min-h-screen relative">
      <BrandBgLayers />
      <div className="relative max-w-3xl mx-auto px-4 py-10">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="flex items-baseline justify-center gap-1 font-bold text-3xl tracking-wider text-white">
            <span>DREAM</span>
            <span className="text-brand-cyan">TEAM</span>
          </div>
          <p className="text-xs text-white/70 mt-1 uppercase tracking-widest">
            How the auction league works
          </p>
        </div>

        <div className="bg-white rounded-lg shadow-2xl border-t-4 border-brand-cyan p-6 sm:p-8 space-y-8 text-slate-700">
          {/* The basics */}
          <section>
            <h2 className="text-lg font-bold text-brand-navy mb-2">The basics</h2>
            <p>
              You manage a team in a fantasy football <strong>auction</strong> league. Instead of
              everyone being able to pick the same players, you <strong>bid real budget</strong> to
              sign them — so a player can only ever belong to one manager at a time.
            </p>
            <ul className="list-disc pl-5 mt-3 space-y-1">
              <li>
                You start with a transfer budget of <strong>£150m</strong> — deliberately generous,
                so you can afford to overpay in a bidding war.
              </li>
              <li>
                Your squad can hold up to <strong>20 players</strong>.
              </li>
              <li>
                Players come in four positions:{" "}
                <strong>GK</strong> (goalkeeper), <strong>DEF</strong> (defender),{" "}
                <strong>MID</strong> (midfielder) and <strong>FWD</strong> (forward).
              </li>
              <li>
                Each week you pick a <strong>starting XI</strong> from your squad — only your
                starters score points.
              </li>
            </ul>
          </section>

          {/* Bidding */}
          <section>
            <h2 className="text-lg font-bold text-brand-navy mb-2">How bidding works</h2>
            <p>
              You sign players from the <strong>Market</strong> by placing a bid. A few rules apply
              to every bid:
            </p>
            <ul className="list-disc pl-5 mt-3 space-y-1">
              <li>
                The <strong>minimum bid is £0.1m</strong> (£100k).
              </li>
              <li>
                A bid must be at least the player's <strong>book price</strong> (their current
                market value). You can pay over the odds to outbid rivals, but never under book.
              </li>
              <li>
                You can't bid more than your <strong>available budget</strong>. Any bids you've
                already placed are reserved against your balance until they're settled, so you can't
                accidentally over-commit.
              </li>
              <li>
                You can't bid on a player you already own, and you can't bid once your squad is{" "}
                <strong>full (20)</strong> — sell someone first.
              </li>
            </ul>

            <h3 className="font-semibold text-brand-navy mt-5 mb-1">Sealed-bid auction</h3>
            <p>
              Bidding is a <strong>sealed-bid auction</strong>. Your bids are{" "}
              <strong>secret</strong> and don't settle straight away — several managers can bid for
              the same player without seeing each other's offers. At each <strong>bid run</strong>{" "}
              all pending bids are resolved together: for each player the{" "}
              <strong>highest bid wins</strong>, and a tie goes to whoever bid{" "}
              <strong>first</strong>. Losing bids are returned to your budget, so you're free to
              chase someone else.
            </p>
          </section>

          {/* Selling */}
          <section>
            <h2 className="text-lg font-bold text-brand-navy mb-2">Selling players</h2>
            <p>
              Selling a player refunds their <strong>current book price</strong> — not what you
              originally paid. So if you overpaid in a bidding war, you take the difference as a
              loss; if the player has risen in value, you can profit. Choose your overbids wisely.
            </p>
          </section>

          {/* Picking your team */}
          <section>
            <h2 className="text-lg font-bold text-brand-navy mb-2">
              Picking your team &amp; positions
            </h2>
            <p>
              From your <strong>Squad</strong> you choose a <strong>formation</strong> and slot
              players onto the pitch. The formation decides how many of each position start:
            </p>
            <ul className="list-disc pl-5 mt-3 space-y-1">
              <li>
                <strong>4-4-2</strong> — 1 GK, 4 DEF, 4 MID, 2 FWD
              </li>
              <li>
                <strong>4-3-3</strong> — 1 GK, 4 DEF, 3 MID, 3 FWD
              </li>
            </ul>
            <p className="mt-3">
              Either way you field <strong>11 starters</strong>; everyone else sits on the bench.
              Each slot on the pitch is tied to a position — you can only place a{" "}
              <strong>defender in a defender slot</strong>, a forward in a forward slot, and so on.
              Drag a player onto a matching slot to start them, or send them to the bench.
            </p>
            <p className="mt-3">
              Team changes don't take effect immediately — they're <strong>locked in at the next
              01:00 UTC deadline</strong> (the same cut-off as bid resolution). Until then you'll see
              them listed as <strong>pending</strong> on your Squad page and can cancel them.
            </p>
          </section>

          {/* Scoring */}
          <section>
            <h2 className="text-lg font-bold text-brand-navy mb-2">Scoring</h2>
            <p>
              Only the points scored by your <strong>starting XI</strong> count towards your total.
              Points from benched players, or from players on a day you didn't own them, are not
              credited. Keep your best XI on the pitch before each deadline to climb the{" "}
              <strong>Standings</strong>.
            </p>
          </section>

          <div className="pt-2 border-t border-slate-200 text-center">
            <Link
              to="/login"
              className="inline-block bg-brand-cyan text-white px-5 py-2 rounded font-medium hover:bg-brand-cyanDark transition-colors"
            >
              Back to login
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
