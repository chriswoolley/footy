/**
 * Drop the four lablogic carousel slide layers + navy overlay into any
 * element styled with `.brand-bg`. The CSS in index.css crossfades them so
 * the parent acts as an animated hero background.
 */
export function BrandBgLayers() {
  return (
    <>
      <div className="brand-bg-slide s0" aria-hidden />
      <div className="brand-bg-slide s1" aria-hidden />
      <div className="brand-bg-slide s2" aria-hidden />
      <div className="brand-bg-slide s3" aria-hidden />
      <div className="brand-bg-overlay" aria-hidden />
    </>
  );
}
