import { useTranslation } from "react-i18next";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { SharePageView } from "./pages/SharePageView";

/** Dev fallback when visiting /share or root without a full share path */
function DevFallback() {
  const { t } = useTranslation();
  const demoUrl =
    "/share/b257e209-6777-4efc-a4f5-b2a4853cce2d/191B33A9";
  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-slate-50">
      <div className="max-w-md text-center space-y-4">
        <h1 className="text-xl font-semibold text-slate-800">
          {t("dev.title")}
        </h1>
        <p className="text-sm text-slate-600">
          {t("dev.useFullLink")}{" "}
          <code className="bg-slate-200 px-1 rounded">
            /share/:deviceId/:shareCode
          </code>
        </p>
        <p className="text-sm text-slate-500">{t("dev.debugVisit")}</p>
        <a
          href={demoUrl}
          className="inline-block py-2 px-4 rounded-lg bg-indigo-600 text-white text-sm font-medium hover:opacity-90"
        >
          {demoUrl}
        </a>
      </div>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter basename="/share">
      <Routes>
        <Route path="/:deviceId/:shareCode" element={<SharePageView />} />
        <Route path="/" element={<DevFallback />} />
      </Routes>
    </BrowserRouter>
  );
}
