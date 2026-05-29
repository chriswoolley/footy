import { useEffect, useState } from "react";
import { api, type PaperTalkRow } from "../api";

export default function PaperTalk() {
  const [items, setItems] = useState<PaperTalkRow[]>([]);

  useEffect(() => {
    api.get<PaperTalkRow[]>("/api/paper-talk").then(setItems);
  }, []);

  return (
    <div>
      <h2 className="text-lg font-bold mb-3">Paper Talk</h2>
      {items.length === 0 ? (
        <p className="text-sm text-slate-500">Nothing happening yet.</p>
      ) : (
        <ul className="space-y-2">
          {items.map((it) => (
            <li
              key={it.id}
              className="bg-white p-3 rounded border border-slate-200 shadow-sm flex justify-between gap-3"
            >
              <div>
                <div className="font-medium">
                  {it.player ? `${it.player} ` : ""}
                  {it.team ? <span className="text-slate-500">({it.team})</span> : null}
                </div>
                <div className="text-sm text-slate-700">
                  {it.reason}
                  {it.bid != null && (
                    <> · <span className="text-slate-500">£{it.bid.toFixed(1)}m</span></>
                  )}
                </div>
                {it.manager && (
                  <div className="text-xs text-slate-400 mt-1">by {it.manager}</div>
                )}
              </div>
              <div className="text-xs text-slate-400 whitespace-nowrap">
                {new Date(it.when).toLocaleString()}
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
