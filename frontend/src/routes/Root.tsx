import { Outlet, NavLink } from "react-router-dom";
import { Settings, SlidersHorizontal } from "lucide-react";

export function Root() {
  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand-mark">
          <span className="brand-logo-frame" aria-hidden="true">
            <img className="brand-logo" src="/on-live-logo-mark.png?v=transparent" alt="" />
          </span>
          <div>
            <strong>OnLive 音</strong>
          </div>
        </div>
        <nav className="topnav" aria-label="Primary">
          <NavLink to="/live">
            <SlidersHorizontal size={17} aria-hidden />
            Live
          </NavLink>
          <NavLink to="/settings">
            <Settings size={17} aria-hidden />
            System
          </NavLink>
        </nav>
      </header>
      <Outlet />
    </div>
  );
}
