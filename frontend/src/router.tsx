import { createBrowserRouter, Navigate } from "react-router-dom";

import { Root } from "./routes/Root";
import { Live } from "./routes/Live";
import { Settings } from "./routes/Settings";

// Data-router setup keeps route ownership explicit as the app grows.
export const router = createBrowserRouter([
  {
    path: "/",
    element: <Root />,
    children: [
      { index: true, element: <Navigate to="/live" replace /> },
      { path: "live", element: <Live /> },
      { path: "settings", element: <Settings /> },
    ],
  },
]);
