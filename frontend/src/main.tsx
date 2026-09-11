import { createRoot } from "react-dom/client";
import { RouterProvider } from "react-router-dom";

import { router } from "./router";
import "./styles/tokens.css";
import "./styles/app.css";

// React Router owns navigation while FastAPI owns all live audio actions.
createRoot(document.getElementById("root")!).render(
  <RouterProvider router={router} />,
);
