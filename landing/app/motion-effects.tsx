"use client";

import { motion, useReducedMotion, useScroll, useTransform } from "framer-motion";
import { useEffect } from "react";
import { CarFront } from "lucide-react";

export function MotionEffects() {
  const { scrollYProgress } = useScroll();
  const marker = useTransform(scrollYProgress, [0, 1], ["0%", "100%"]);
  const reduced = useReducedMotion();

  useEffect(() => {
    const menu = document.querySelector<HTMLDetailsElement>(".mobile-menu");
    function closeMenu(event: MouseEvent) {
      if (event.target instanceof Element && event.target.closest("a")) menu?.removeAttribute("open");
    }
    menu?.addEventListener("click", closeMenu);
    if (location.hash.startsWith("#/") && location.hash !== "#/") {
      location.replace("/workspace.html" + location.hash);
    }
    return () => menu?.removeEventListener("click", closeMenu);
  }, []);

  useEffect(() => {
    if (reduced) return;
    const observer = new IntersectionObserver(entries => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        entry.target.classList.add("arrive");
        observer.unobserve(entry.target);
      }
    }, { threshold: 0.2 });
    document.querySelectorAll("[data-reveal]").forEach(node => observer.observe(node));
    return () => observer.disconnect();
  }, [reduced]);

  return <aside className="road-progress" aria-hidden="true">
    <span>ROUTE</span>
    <div className="road-track"><motion.i style={{ top: marker }}><CarFront size={13}/></motion.i></div>
    <span>END</span>
  </aside>;
}
