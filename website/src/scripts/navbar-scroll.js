import ExecutionEnvironment from '@docusaurus/ExecutionEnvironment';

function updateNavbar() {
  if (!ExecutionEnvironment.canUseDOM) return;

  // Skip on mobile devices
  if (window.innerWidth < 768) return;

  const navbar = document.querySelector('.navbar');
  if (!navbar) return;

  // Check if it's homepage
  // Matches "/" or "/index.html" or localized versions if needed.
  // For now, simple check.
  const path = window.location.pathname.replace(/\/$/, '') || '/';
  const isHomePage =
    path === '/' ||
    path === '/index.html' ||
    /^\/(zh-Hans|en|ja|es|ko)$/.test(path) ||
    /^\/(zh-Hans|en|ja|es|ko)\/index\.html$/.test(path);

  if (isHomePage) {
    navbar.classList.add('navbar-home');
    if (window.scrollY > 100) {
      navbar.classList.add('navbar-scrolled');
    } else {
      navbar.classList.remove('navbar-scrolled');
    }
  } else {
    navbar.classList.remove('navbar-home');
    navbar.classList.remove('navbar-scrolled');
  }
}

function onScroll() {
  // Skip on mobile devices
  if (window.innerWidth < 768) return;

  const navbar = document.querySelector('.navbar');
  if (!navbar || !navbar.classList.contains('navbar-home')) return;

  if (window.scrollY > 100) {
    navbar.classList.add('navbar-scrolled');
  } else {
    navbar.classList.remove('navbar-scrolled');
  }
}

if (ExecutionEnvironment.canUseDOM) {
  window.addEventListener('load', updateNavbar);
  window.addEventListener('scroll', onScroll);
}

export function onRouteUpdate() {
  setTimeout(updateNavbar, 50);
}
