import { useMemo, useState } from "react";

type SortDir = "asc" | "desc";
type Extractor<T> = (row: T) => number | string | Date | null | undefined;

/**
 * Generic sortable-table helper. Pass the rows + a stable map of column-key
 * → value extractor. Returns the sorted rows plus header helpers for the JSX.
 *
 *   const cols = useMemo(() => ({
 *     teamName: (r) => r.teamName,
 *     squadCount: (r) => r.squadCount,
 *   }), []);
 *   const { sorted, toggle, indicator } = useSorted(rows, cols);
 *
 *   <th onClick={() => toggle("teamName")} className="cursor-pointer">
 *     Team{indicator("teamName")}
 *   </th>
 */
export function useSorted<T>(
  rows: T[],
  columns: Record<string, Extractor<T>>,
  initial?: { key: string; dir?: SortDir },
) {
  const [sortKey, setSortKey] = useState<string | null>(initial?.key ?? null);
  const [dir, setDir] = useState<SortDir>(initial?.dir ?? "asc");

  const sorted = useMemo(() => {
    if (!sortKey || !columns[sortKey]) return rows;
    const get = columns[sortKey];
    const direction = dir === "asc" ? 1 : -1;
    return [...rows].sort((a, b) => {
      const av = get(a);
      const bv = get(b);
      if (av == null && bv == null) return 0;
      if (av == null) return 1; // nulls last
      if (bv == null) return -1;
      if (typeof av === "string" && typeof bv === "string") {
        return av.localeCompare(bv) * direction;
      }
      const an = av instanceof Date ? av.getTime() : (av as number);
      const bn = bv instanceof Date ? bv.getTime() : (bv as number);
      if (an < bn) return -1 * direction;
      if (an > bn) return 1 * direction;
      return 0;
    });
  }, [rows, sortKey, dir, columns]);

  function toggle(key: string) {
    if (!columns[key]) return;
    if (sortKey === key) {
      setDir((d) => (d === "asc" ? "desc" : "asc"));
    } else {
      setSortKey(key);
      setDir("asc");
    }
  }

  function indicator(key: string): string {
    if (sortKey !== key) return "";
    return dir === "asc" ? " ▲" : " ▼";
  }

  return { sorted, toggle, indicator, sortKey, dir };
}

/**
 * Convenience headerProps factory — spread onto a <th> to make it sortable.
 * Pass any caller-side base classes (e.g. "text-left p-1") as the third arg;
 * the helper merges them with the sortable styling so they aren't clobbered
 * by the JSX-spread.
 */
export function sortableHeaderProps(
  toggle: (key: string) => void,
  key: string,
  baseClass = "",
): {
  onClick: () => void;
  className: string;
  style: { userSelect: "none" };
} {
  const sortable = "cursor-pointer hover:bg-slate-100";
  return {
    onClick: () => toggle(key),
    className: baseClass ? `${baseClass} ${sortable}` : sortable,
    style: { userSelect: "none" },
  };
}
