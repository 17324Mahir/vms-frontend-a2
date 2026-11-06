import {
  Activity, ArrowDown, ArrowRight, ArrowUpRight, CarFront,
  ChartNoAxesCombined, Check, ChevronDown, CircleGauge, ClipboardCheck,
  Fuel, Gauge, LayoutDashboard, MapPin, Menu, Route, ShieldCheck, Users,
  Wrench,
} from "lucide-react";
import { TruckHero } from "./truck-hero";
import { MotionEffects } from "./motion-effects";

const workspace = "/workspace.html";
const login = "/workspace.html#/login";
const register = "/workspace.html#/register";
const features = [
  { name: "GPS tracking", text: "See how a connected fleet could surface vehicle positions and route activity.", icon: MapPin, concept: true },
  { name: "Fleet management", text: "Search your registry, update vehicle status and keep documents and renewals in view.", icon: CarFront },
  { name: "Maintenance scheduling", text: "Use service history, mileage and cost records to plan the next workshop visit.", icon: Wrench },
  { name: "Fuel monitoring", text: "Explore how fuel usage and cost trends could fit into the fleet dashboard.", icon: Fuel, concept: true },
  { name: "Driver management", text: "Manage licenses and availability, then assign drivers to vehicles as needs change.", icon: Users },
  { name: "Fleet analytics", text: "See operational status, maintenance spend and upcoming document renewals at a glance.", icon: ChartNoAxesCombined },
];

const benefits = [
  { icon: Wrench, title: "Reduce avoidable downtime" },
  { icon: CircleGauge, title: "Improve fleet visibility" },
  { icon: ShieldCheck, title: "Centralize records and renewals" },
  { icon: Activity, title: "Coordinate daily operations" },
];

const plans = [
  { name: "Starter", price: "19", note: "For small teams getting organized.", items: ["Vehicle and driver registry", "Document management", "Service history"] },
  { name: "Operations", price: "49", note: "For teams coordinating a growing fleet.", items: ["Everything in Starter", "Vehicle and driver assignments", "Renewal alerts and cost summaries"], featured: true },
  { name: "Enterprise", price: "99", note: "For larger fleet operations.", items: ["Everything in Operations", "Fleet overview and reporting", "Multi-team rollout planning"] },
];

function Brand() {
  return <a className="brand" href="/" aria-label="Stark Fleet home"><span className="brand-icon"><Route size={21} /></span>STARK<span className="brand-light">FLEET</span></a>;
}

function SectionLabel({ number, children }: { number: string; children: React.ReactNode }) {
  return <div className="section-label"><span>{number}</span>{children}</div>;
}

function Dashboard() {
  return <div className="dashboard" aria-label="Illustrative fleet dashboard">
    <div className="dash-top"><span className="dash-logo"><Route size={15} /> Stark Fleet</span><span className="sample"><i /> SAMPLE DATA</span></div>
    <div className="dash-body">
      <div className="dash-side" aria-hidden="true"><LayoutDashboard /><CarFront /><Users /><Wrench /><ClipboardCheck /></div>
      <div className="dash-content">
        <div className="dash-title"><div><small>OPERATIONS / OVERVIEW</small><h3>Fleet overview</h3></div><span className="dash-date">Last 7 days <ChevronDown size={12} /></span></div>
        <div className="dash-metrics">
          {[["Total vehicles", "48", "+4 this month"], ["Active vehicles", "39", "81% of fleet"], ["In maintenance", "6", "3 due soon"]].map(([title, amount, detail]) =>
            <div key={title}><small>{title}</small><b>{amount}</b><span>{detail}</span></div>)}
        </div>
        <div className="dash-panels">
          <div className="dash-panel"><h4>Fleet map <span>Concept</span></h4>
            <svg viewBox="0 0 420 180" role="img" aria-label="Sample map with four vehicle locations" preserveAspectRatio="xMidYMid slice">
              <rect width="420" height="180" fill="#edf1f8"/>
              <path d="M280-10C284 35 232 45 254 84s90 48 90 105" fill="none" stroke="#cfe0ff" strokeWidth="28"/>
              <path d="M-10 30 430 130M-10 105 430 39M15 190 140-10M140 190 244-10M315 185 391-10M-10 157 430 154M-10 67 430 90M67 190 57-10M197 190 187-10M385 190 410-10" fill="none" stroke="white" strokeWidth="5"/>
              <path d="M80 129 121 77 180 93 228 70 351 52" fill="none" stroke="#6994ff" strokeWidth="3" strokeDasharray="5 5"/>
              {[[80,129],[121,77],[228,70],[351,52]].map(([x,y])=><g key={x}><circle cx={x} cy={y} r="11" fill="#265bf5" opacity=".2"/><circle cx={x} cy={y} r="5" fill="#265bf5" stroke="#fff" strokeWidth="2"/></g>)}
            </svg>
          </div>
          <div className="dash-panel"><h4>Fleet activity <span>7 days</span></h4><div className="bars" aria-label="Sample weekly activity bar chart" role="img">{[44,70,55,85,67,95,74].map((height,i)=><div key={i}><i style={{height: height+"%"}}/><small>{"MTWTFSS"[i]}</small></div>)}</div></div>
        </div>
        <div className="dash-activity"><Activity size={15} /> <b>Recent activity</b><span>Vehicle SG-042 returned to active service</span><small>12 min ago</small></div>
      </div>
    </div>
  </div>;
}

export default function Home() {
  return <>
    <a className="skip-link" href="#main">Skip to content</a>
    <header className="site-header"><div className="wrap nav"><Brand />
      <nav className="nav-links" aria-label="Main navigation"><a href="#features">Features</a><a href="#solutions">Solutions</a><a href="#pricing">Pricing</a><a href="#contact">Contact</a></nav>
      <div className="nav-actions"><a className="login" href={login}>Login</a><a className="button button-blue" href={register}>Get started <ArrowUpRight size={15} /></a></div>
      <details className="mobile-menu"><summary aria-label="Navigation menu"><Menu size={23}/></summary><nav aria-label="Mobile navigation"><a href="#features">Features</a><a href="#solutions">Solutions</a><a href="#pricing">Pricing</a><a href="#contact">Contact</a><a href={login}>Login</a></nav></details>
    </div></header>
    <MotionEffects />
    <main id="main">
      <section className="hero" aria-labelledby="hero-title">
        <TruckHero />
        <div className="wrap hero-layout">
          <div className="hero-copy">
            <p className="hero-kicker"><i /> VEHICLE MANAGEMENT SYSTEM</p>
            <h1 id="hero-title">Smarter Vehicle<br className="desktop-break"/> Management <em>Starts Here.</em></h1>
            <p className="hero-description">Manage vehicles, drivers and service records from one workspace. See what’s moving, what’s due and what needs your attention.</p>
            <div className="hero-actions"><a href={register} className="button button-blue">Get started <ArrowUpRight size={18}/></a><a href="#solutions" className="button button-outline">Explore platform <ArrowDown size={16}/></a></div>
          </div>
          <div className="hero-art">
            <div className="telemetry telemetry-top"><div className="telemetry-icon"><Activity size={17}/></div><div><span>SAMPLE VEHICLE STATUS</span><strong><i /> Operational</strong></div></div>
            <div className="telemetry telemetry-bottom"><div className="telemetry-icon"><Gauge size={17}/></div><div><span>SAMPLE ODOMETER</span><strong>12,840 <small>km</small></strong></div></div>
          </div>
        </div>
        <div className="wrap hero-foot"><a href="#features"><ArrowDown size={14}/> SCROLL TO EXPLORE</a><span>VEHICLES <i/> DRIVERS <i/> OPERATIONS</span></div>
      </section>

      <section id="features" className="section wrap">
        <div className="section-intro" data-reveal><SectionLabel number="01">PLATFORM FEATURES</SectionLabel><h2>Everything your fleet needs<br className="desktop-break"/> to stay on course.</h2><p>Keep the details that drive daily operations together, from a vehicle’s first registration to its next service.</p></div>
        <div className="feature-grid">{features.map(({name,text,icon:Icon,concept},i)=><article className="feature-card" data-reveal key={name}><div className="feature-top"><span className="feature-icon"><Icon size={23}/></span><span>{concept ? "CONCEPT" : "0"+(i+1)}</span></div><h3>{name}</h3><p>{text}</p></article>)}</div>
      </section>

      <section id="solutions" className="solution-section section">
        <div className="wrap"><div className="section-intro split" data-reveal><div><SectionLabel number="02">OPERATIONS OVERVIEW</SectionLabel><h2>See the whole fleet<br className="desktop-break"/> at a glance.</h2></div><p>Check vehicle status, maintenance spend and renewal priorities before deciding where to act. This illustrative preview shows how connected data could sit alongside those tools.</p></div>
        <Dashboard /></div>
      </section>

      <section className="section wrap" id="workflow">
        <div className="section-intro" data-reveal><SectionLabel number="03">HOW IT WORKS</SectionLabel><h2>From setup to daily operations.</h2></div>
        <div className="steps">{[
          ["Add vehicles", "Register your fleet, add documents and assign available drivers."],
          ["Monitor operations", "Review vehicle status, maintenance history and document expiry."],
          ["Optimize performance", "Use spend and service records to prioritize the work that keeps your fleet moving."],
        ].map(([title,text],i)=><article data-reveal key={title}><div className="step-no">0{i+1} <ArrowRight size={20}/></div><h3>{title}</h3><p>{text}</p></article>)}</div>
      </section>

      <section className="benefits section"><div className="wrap benefits-inner" data-reveal><div><SectionLabel number="04">FLEET BENEFITS</SectionLabel><h2>More time on the road.</h2><p>Give your team a shared view of what’s happening across the fleet and what comes next.</p></div>
      <div className="benefit-list">{benefits.map(({icon: Icon,title})=><div key={title}><Icon size={22}/><strong>{title}</strong></div>)}</div></div></section>

      <section id="pricing" className="section wrap">
        <div className="section-intro" data-reveal><SectionLabel number="05">PRICING CONCEPT</SectionLabel><h2>Room for every fleet.</h2><p>Illustrative plans and sample prices. The Assignment 2 workspace opens without a billing step.</p></div>
        <div className="pricing-grid">{plans.map(({name,price,note,items,featured})=><article data-reveal key={name} className={`plan ${featured ? "plan-featured" : ""}`}><span className="plan-label">{featured ? "FEATURED CONCEPT" : "ILLUSTRATIVE PLAN"}</span><h3>{name}</h3><p>{note}</p><div className="price">{"$"}{price}<small> / month</small></div><ul>{items.map(item=><li key={item}><Check size={16}/>{item}</li>)}</ul><a href={register} className={`button ${featured ? "button-blue" : "button-light"}`}>Try the workspace <ArrowUpRight size={16}/></a></article>)}</div>
      </section>

      <section id="contact" className="final-cta"><div className="wrap final-inner" data-reveal><SectionLabel number="06">START HERE</SectionLabel><h2>Get your fleet in gear.</h2><p>Set up your workspace and bring your vehicles, drivers and service records together.</p><div className="hero-actions"><a className="button button-blue" href={register}>Create an account <ArrowUpRight size={17}/></a><a className="button button-outline" href={workspace}>Open workspace <ArrowRight size={17}/></a></div></div></section>
    </main>
    <footer className="wrap footer"><Brand /><nav aria-label="Footer navigation"><a href="#features">Features</a><a href="#solutions">Solutions</a><a href="#pricing">Pricing</a><a href={login}>Login</a></nav><span>© {new Date().getFullYear()} Stark Group</span></footer>
  </>;
}
