// Temporary banner announcing the one-off accelerated bidding schedule.
// Auto-hides after the boost day ends (UK). Keep the date in sync with
// AUCTION_BOOST_DATE in src/server/scheduler.ts.
const HIDE_AFTER = Date.parse("2026-06-11T23:00:00Z"); // end of 11 Jun in UK (BST = UTC+1)

export function ScheduleNotice() {
  if (Date.now() >= HIDE_AFTER) return null;
  return (
    <div className="bg-amber-100 border-b border-amber-300 text-amber-900 text-sm px-4 py-2 text-center">
      📣 <strong>Special bidding schedule for 11 June:</strong> the auction runs at{" "}
      <strong>10:00</strong>, then <strong>every 2 hours until midnight</strong> (UK time). After
      that it returns to the usual <strong>midnight</strong> auction.
    </div>
  );
}
