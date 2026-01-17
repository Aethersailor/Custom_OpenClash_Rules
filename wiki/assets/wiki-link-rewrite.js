(() => {
  const INTERNAL_PAGE_RE = /^(?:\\d+)\\.(.+)$/;

  const buildPageMap = () => {
    const map = new Map();
    const links = document.querySelectorAll("a[href]");

    links.forEach((link) => {
      const rawHref = link.getAttribute("href");
      if (!rawHref) {
        return;
      }

      if (/^(mailto|tel|javascript):/i.test(rawHref)) {
        return;
      }

      let url;
      try {
        url = new URL(rawHref, window.location.href);
      } catch {
        return;
      }

      if (url.origin !== window.location.origin) {
        return;
      }

      const segments = url.pathname.split("/").filter(Boolean);
      if (!segments.length) {
        return;
      }

      let last = segments[segments.length - 1];
      if (last.endsWith(".html")) {
        last = last.slice(0, -5);
      }

      const decoded = decodeURIComponent(last);
      const match = decoded.match(INTERNAL_PAGE_RE);
      if (!match) {
        return;
      }

      const pageName = match[1];
      if (!map.has(pageName)) {
        map.set(pageName, rawHref);
      }
    });

    return map;
  };

  const rewriteWikiLinks = () => {
    const pageMap = buildPageMap();
    if (!pageMap.size) {
      return;
    }

    const links = document.querySelectorAll("a[href]");
    links.forEach((link) => {
      const rawHref = link.getAttribute("href");
      if (!rawHref || !/^https?:\/\//i.test(rawHref)) {
        return;
      }

      let url;
      try {
        url = new URL(rawHref);
      } catch {
        return;
      }

      if (url.hostname !== "github.com") {
        return;
      }

      const parts = url.pathname.split("/").filter(Boolean);
      if (parts.length < 4 || parts[2] !== "wiki") {
        return;
      }

      const pageSlug = decodeURIComponent(parts.slice(3).join("/"));
      if (!pageSlug) {
        return;
      }

      const target = pageMap.get(pageSlug);
      if (!target) {
        return;
      }

      link.setAttribute("href", `${target}${url.hash || ""}`);
    });
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", rewriteWikiLinks);
  } else {
    rewriteWikiLinks();
  }
})();
