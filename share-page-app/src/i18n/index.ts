import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import en from "./locales/en.json";
import zh from "./locales/zh.json";
import ja from "./locales/ja.json";
import ko from "./locales/ko.json";
import es from "./locales/es.json";

const SUPPORTED = ["en", "zh", "ja", "ko", "es"] as const;

function pickLanguage(): string {
  if (typeof window === "undefined") return "en";
  const saved = localStorage.getItem("i18nextLng");
  if (saved && SUPPORTED.includes(saved as (typeof SUPPORTED)[number])) {
    return saved;
  }
  const nav = navigator.language?.split("-")[0]?.toLowerCase() ?? "en";
  return SUPPORTED.includes(nav as (typeof SUPPORTED)[number]) ? nav : "en";
}

await i18n.use(initReactI18next).init({
  resources: {
    en: { translation: en },
    zh: { translation: zh },
    ja: { translation: ja },
    ko: { translation: ko },
    es: { translation: es },
  },
  lng: pickLanguage(),
  fallbackLng: "en",
  supportedLngs: [...SUPPORTED],
  interpolation: { escapeValue: false },
});

function syncHtmlLang(lng: string) {
  if (typeof document !== "undefined") {
    document.documentElement.lang = lng.split("-")[0] || "en";
  }
}
syncHtmlLang(i18n.language);
i18n.on("languageChanged", syncHtmlLang);

export { SUPPORTED };
export default i18n;
