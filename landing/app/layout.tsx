import type { Metadata } from "next";
import "./site.css";

export const metadata: Metadata = {
  title: "Stark Fleet | Vehicle Management System",
  description: "Manage vehicles, drivers, service records and renewals from one fleet workspace.",
  openGraph: {
    title: "Stark Fleet | Vehicle Management System",
    description: "One workspace for your fleet operations.",
    type: "website",
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
