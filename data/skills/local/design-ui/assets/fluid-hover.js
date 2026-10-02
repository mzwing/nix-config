const ACTIVATOR = "a[href], button, [role='button'], [role='link'], [role='menuitem'], [role='menuitemcheckbox'], [role='menuitemradio'], [role='option'], [role='tab'], [role='radio'], [role='checkbox'], [tabindex]";
const CONTROL = `${ACTIVATOR}, input, select, textarea, label, summary, [contenteditable='true']`;
const DISABLED = "[aria-disabled='true'], [data-disabled], :disabled";

export function fluidHover(container, highlight, { axis = "y", items = "[data-fluid-item]", gapClick = true, from } = {}) {
  let nodes = [];
  let rects = [];
  let lit = null;
  let pointer = null;
  let frame = 0;
  const observed = new Set();
  const resize = new ResizeObserver(schedule);
  const mutation = new MutationObserver(schedule);

  function schedule() {
    cancelAnimationFrame(frame);
    frame = requestAnimationFrame(measure);
  }

  function measure() {
    const before = lit && rects[nodes.indexOf(lit)];
    nodes = [...container.querySelectorAll(items)];
    rects = nodes.map(offsetWithin);
    for (const node of observed) {
      if (!nodes.includes(node)) {
        resize.unobserve(node);
        observed.delete(node);
      }
    }
    for (const node of nodes) {
      if (!observed.has(node)) {
        resize.observe(node);
        observed.add(node);
      }
    }
    const after = lit && rects[nodes.indexOf(lit)];
    if (lit && !after) light(null);
    else if (lit && ["x", "y", "width", "height"].some((key) => after[key] !== before?.[key])) place(lit, true);
  }

  function offsetWithin(el) {
    if (!el.offsetParent) return null;
    let x = 0;
    let y = 0;
    for (let node = el; node !== container; node = node.offsetParent) {
      x += node.offsetLeft;
      y += node.offsetTop;
      if (node.offsetParent !== container) {
        x += node.offsetParent.clientLeft;
        y += node.offsetParent.clientTop;
      }
    }
    return { x, y, width: el.offsetWidth, height: el.offsetHeight };
  }

  function local(event) {
    const box = container.getBoundingClientRect();
    const scaleX = box.width / container.offsetWidth || 1;
    const scaleY = box.height / container.offsetHeight || 1;
    return {
      x: (event.clientX - box.left) / scaleX - container.clientLeft + container.scrollLeft,
      y: (event.clientY - box.top) / scaleY - container.clientTop + container.scrollTop,
    };
  }

  function pick(point) {
    let nearest = null;
    let nearestDistance = Infinity;
    for (let i = 0; i < nodes.length; i++) {
      const rect = rects[i];
      if (!rect || nodes[i].matches(DISABLED)) continue;
      const dx = point.x - rect.x - rect.width / 2;
      const dy = point.y - rect.y - rect.height / 2;
      const insideX = Math.abs(dx) <= rect.width / 2;
      const insideY = Math.abs(dy) <= rect.height / 2;
      if ((axis === "y" || insideX) && (axis === "x" || insideY)) return nodes[i];
      const distance = axis === "x" ? Math.abs(dx) : axis === "y" ? Math.abs(dy) : Math.hypot(dx, dy);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = nodes[i];
      }
    }
    return nearest;
  }

  function place(node, instant) {
    const rect = rects[nodes.indexOf(node)];
    if (instant) highlight.dataset.instant = "";
    highlight.style.transform = `translate(${rect.x}px, ${rect.y}px)`;
    highlight.style.width = `${rect.width}px`;
    highlight.style.height = `${rect.height}px`;
    if (instant) {
      // Commit the jump before transitions come back on.
      highlight.getBoundingClientRect();
      delete highlight.dataset.instant;
    }
  }

  function light(node) {
    if (node === lit) return;
    if (lit) delete lit.dataset.lit;
    lit = node;
    if (!node) {
      delete highlight.dataset.visible;
      return;
    }
    node.dataset.lit = "";
    if (!("visible" in highlight.dataset)) {
      const start = from?.();
      place(start && rects[nodes.indexOf(start)] ? start : node, true);
      highlight.dataset.visible = "";
    }
    place(node, false);
  }

  function gapDistance(point) {
    const rect = rects[nodes.indexOf(lit)];
    const dx = Math.max(rect.x - point.x, 0, point.x - rect.x - rect.width);
    const dy = Math.max(rect.y - point.y, 0, point.y - rect.y - rect.height);
    return Math.hypot(dx, dy);
  }

  function onMove(event) {
    if (event.pointerType !== "mouse") return;
    pointer = event;
    light(pick(local(event)));
  }

  function onLeave(event) {
    if (event.pointerType !== "mouse") return;
    pointer = null;
    light(null);
  }

  function onScroll() {
    if (pointer) light(pick(local(pointer)));
  }

  function onClick(event) {
    if (!gapClick || !lit) return;
    const hit = event.target.closest(`${items}, ${CONTROL}`);
    if (hit && hit !== container && container.contains(hit)) return;
    if (typeof gapClick === "number" && gapDistance(local(event)) > gapClick) return;
    (lit.matches(ACTIVATOR) ? lit : (lit.querySelector(ACTIVATOR) ?? lit)).click();
  }

  container.addEventListener("pointermove", onMove);
  container.addEventListener("pointerleave", onLeave);
  container.addEventListener("scroll", onScroll, { passive: true });
  container.addEventListener("click", onClick);
  resize.observe(container);
  mutation.observe(container, { childList: true, subtree: true });

  return {
    light,
    destroy() {
      cancelAnimationFrame(frame);
      resize.disconnect();
      mutation.disconnect();
      container.removeEventListener("pointermove", onMove);
      container.removeEventListener("pointerleave", onLeave);
      container.removeEventListener("scroll", onScroll);
      container.removeEventListener("click", onClick);
    },
  };
}
