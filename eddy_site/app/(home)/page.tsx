import Header from "../../components/home/Header";
import Hero from "../../components/home/Hero";
import ProductShowcase from "../../components/home/ProductShowcase";
import Features from "../../components/home/Features";
import UseCases from "../../components/home/UseCases";
import HowItWorks from "../../components/home/HowItWorks";
import Pricing from "../../components/home/Pricing";
import Footer from "../../components/home/Footer";

export default function HomePage() {
  return (
    <main className="flex flex-col min-h-screen bg-white text-slate-900 font-sans">
      <Header />
      <Hero />
      <ProductShowcase />
      <Features />
      <UseCases />
      <HowItWorks />
      <Pricing />
      <Footer />
    </main>
  );
}
