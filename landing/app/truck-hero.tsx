import Image from "next/image";

export function TruckHero() {
  return <div className="truck-hero" aria-hidden="true">
    <Image src="/fleet-truck-hero.jpg" alt="" fill preload unoptimized sizes="100vw" />
  </div>;
}
