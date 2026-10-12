---
layout: default
title: EV charging stops worth knowing
description: Discover destination chargers, RV-friendly EV hookups, and charging stops for the road ahead.
---

<section class="mx-auto max-w-[1440px] px-4 pb-12 pt-7 sm:px-6 lg:px-8">
  <div class="mb-5">
    <div>
      <p class="mb-2 text-xs font-bold uppercase tracking-[0.24em] text-cyan-300">The EV charging station directory</p>
      <h1 class="text-2xl font-bold uppercase tracking-wide text-white sm:text-3xl">Find a better place to plug in.</h1>
      <p class="mt-2 max-w-2xl text-sm leading-6 text-slate-400 sm:text-base">Explore the hotels, RV parks, and welcoming stops that make an electric road trip easier.</p>
    </div>
  </div>

  <div class="grid gap-4 lg:grid-cols-[230px_minmax(0,1fr)]">
    <aside class="rounded-xl border border-slate-700/80 bg-[#0d1c2b] p-4 sm:p-5" aria-label="Browse charging categories">
      <div class="flex items-center justify-between border-b border-slate-700/80 pb-3">
        <h2 class="text-xs font-bold uppercase tracking-[0.16em] text-slate-200">Browse categories</h2>
        <svg viewBox="0 0 20 20" fill="currentColor" class="size-4 text-slate-500" aria-hidden="true">
          <path fill-rule="evenodd" d="M5.22 7.47a.75.75 0 0 1 1.06 0L10 11.19l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 8.53a.75.75 0 0 1 0-1.06Z" clip-rule="evenodd" />
        </svg>
      </div>

      <nav class="mt-4 space-y-5">
        <div>
          <h3 class="mb-2 text-[10px] font-bold uppercase tracking-[0.18em] text-slate-500">Destination types</h3>
          <div class="space-y-1">
            {% for category in site.data.station_categories %}
              <a href="{{ '/categories/' | relative_url }}{{ category.id | escape }}/" class="flex items-center justify-between gap-2 rounded-md px-2 py-2 text-sm text-slate-300 transition hover:bg-slate-800 hover:text-cyan-200">
                <span>{{ category.name | escape }}</span><span class="shrink-0 text-xs tabular-nums text-slate-500">{{ category.count }}</span>
              </a>
            {% endfor %}
          </div>
        </div>
      </nav>

      <div class="mt-5 rounded-lg border border-cyan-300/15 bg-cyan-300/[0.06] p-3">
        <p class="text-xs font-semibold text-cyan-100">Built for the stops between stops.</p>
        <p class="mt-1 text-xs leading-5 text-slate-400">A focused guide to charging where you stay, explore, and travel.</p>
      </div>
    </aside>

    <section class="relative min-h-[330px] overflow-hidden rounded-xl border border-slate-700/80 bg-[#071522] sm:min-h-[390px]" aria-labelledby="network-preview-title">
      <div class="absolute inset-0 opacity-40" aria-hidden="true" style="background-image: linear-gradient(rgba(89, 156, 177, .08) 1px, transparent 1px), linear-gradient(90deg, rgba(89, 156, 177, .08) 1px, transparent 1px); background-size: 34px 34px;"></div>
      <div class="absolute inset-0 bg-[radial-gradient(ellipse_at_55%_55%,rgba(15,109,135,0.2),transparent_68%)]" aria-hidden="true"></div>

      <svg class="absolute inset-0 h-full w-full" viewBox="0 0 1000 500" preserveAspectRatio="xMidYMid meet" role="img" aria-labelledby="map-title map-description">
        <title id="map-title">Illustrative outline of the contiguous United States</title>
        <desc id="map-description">A decorative map illustration with a dotted route. It does not show live charging station locations.</desc>
        <defs>
          <linearGradient id="land" x1="0" x2="1" y1="0" y2="1">
            <stop offset="0" stop-color="#17394a" />
            <stop offset="1" stop-color="#0c2535" />
          </linearGradient>
          <filter id="glow">
            <feGaussianBlur stdDeviation="5" result="blur" />
            <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
          </filter>
        </defs>
        <path d="m129 160 31-21 38 7 23-19 37 11 30-14 24 14 31-7 28 17 28-3 25 16 32-4 25 11 28-8 31 18 30-4 21 16 28-10 30 15 26-2 20 15 33-3 24 17 29-3 14 15 27 1 15 13 27-2 9 18-14 13-2 26-21 15-10 24-24 9-14 27-17 8-12 22-16-5-12-23-21-8-13-25-21-13-14-23-22-3-13-15-31 2-18-13-23 9-20-7-28 8-18-10-26 12-28-3-21 13-31-7-22 14-29-9-17 13-30-7-17 14-27-12-19 8-24-18-17-5-13-29-16-10-3-31-14-16 4-26-15-15 3-25-12-16 8-27 16-17 1-26 18-16 10-29 24-13 7-28 20-13 11-26 23-12 6-19 21-9 8-21 20-6Z" fill="url(#land)" stroke="#387087" stroke-width="2" />
        <path d="M174 247c87 41 152-12 226 24s132 16 195 33 105-12 148 23 61 39 92 37" fill="none" stroke="#30d8e6" stroke-dasharray="5 12" stroke-linecap="round" stroke-width="3" opacity=".65" />
        <path d="M248 192c52 20 69 80 132 83s99-28 145-14 83 52 133 41 81-37 121-25" fill="none" stroke="#f8a55e" stroke-dasharray="4 13" stroke-linecap="round" stroke-width="2" opacity=".6" />
        <g fill="#57e8f0" filter="url(#glow)">
          <circle cx="174" cy="247" r="5" /><circle cx="256" cy="263" r="4" /><circle cx="337" cy="267" r="5" /><circle cx="400" cy="271" r="4" />
          <circle cx="501" cy="304" r="5" /><circle cx="595" cy="315" r="4" /><circle cx="675" cy="337" r="5" /><circle cx="835" cy="364" r="5" />
          <circle cx="248" cy="192" r="4" /><circle cx="380" cy="275" r="5" /><circle cx="525" cy="261" r="4" /><circle cx="658" cy="302" r="5" />
        </g>
        <g fill="#ffad65" filter="url(#glow)">
          <circle cx="324" cy="284" r="4" /><circle cx="467" cy="288" r="4" /><circle cx="606" cy="331" r="4" /><circle cx="757" cy="352" r="4" />
        </g>
      </svg>

      <div class="absolute inset-x-0 top-0 flex flex-wrap items-center justify-between gap-3 border-b border-white/10 bg-[#071522]/70 px-4 py-3 backdrop-blur-sm sm:px-5">
        <div>
          <h2 id="network-preview-title" class="text-xs font-bold uppercase tracking-[0.17em] text-white sm:text-sm">A coast-to-coast directory</h2>
          <p class="mt-1 text-xs text-slate-400">Hotels, RV parks &amp; road-trip-friendly charging</p>
        </div>
        <span class="inline-flex items-center gap-2 rounded-full border border-slate-600/80 bg-slate-950/70 px-3 py-1.5 text-[10px] font-semibold uppercase tracking-wider text-slate-300">
          <span class="size-1.5 rounded-full bg-amber-400"></span>
          Directory preview
        </span>
      </div>

      <div class="absolute bottom-4 left-4 right-4 flex flex-wrap items-end justify-between gap-3 sm:bottom-5 sm:left-5 sm:right-5">
        <div class="rounded-lg border border-white/10 bg-[#071522]/85 px-3 py-2 backdrop-blur-sm">
          <p class="text-xs font-semibold text-white">The right stop changes the whole trip.</p>
          <p class="mt-1 text-[11px] text-slate-400">Verified destination listings are coming soon.</p>
        </div>
        <p class="text-[10px] font-medium text-slate-500">Illustrative graphic · Not a live map</p>
      </div>
    </section>
  </div>
</section>

<section id="destinations" class="mx-auto max-w-[1440px] scroll-mt-6 px-4 pb-10 sm:px-6 lg:px-8">
  <div class="grid gap-5 xl:grid-cols-[minmax(0,1fr)_320px]">
    <div>
      <div class="mb-4 flex items-end justify-between gap-4">
        <div>
          <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-cyan-300">Where to plug in</p>
          <h2 class="mt-1 text-lg font-bold uppercase tracking-wide text-white">Explore the directory</h2>
        </div>
      </div>

      <section id="station-listings" class="mt-8 scroll-mt-6" aria-labelledby="station-listings-heading">
        {% if site.data.station_categories.size > 0 %}
          <div class="space-y-5">
            {% for category in site.data.station_categories %}
              <section id="category-{{ category.id }}" class="scroll-mt-6 rounded-xl border border-slate-700/80 bg-[#0d1c2b] p-4">
                <div class="mb-3 flex flex-wrap items-baseline justify-between gap-2">
                  <h4 class="text-sm font-bold text-white"><a href="{{ '/categories/' | relative_url }}{{ category.id | escape }}/" class="transition hover:text-cyan-200">{{ category.name | escape }}</a></h4>
                  <span class="text-xs tabular-nums text-slate-500">{{ category.count }} stations</span>
                </div>
                <ul class="grid gap-2 sm:grid-cols-2">
                  {% for station in category.stations limit: 4 %}
                    <li>
                      <a href="{{ '/chargers/' | relative_url }}{{ station.slug | escape }}/" class="flex h-full items-center justify-between gap-3 rounded-lg border border-slate-700/80 bg-slate-950/30 px-3 py-2.5 transition hover:border-cyan-300/40 hover:bg-[#102433]">
                        <span class="min-w-0">
                          <span class="block truncate text-sm font-semibold text-white">{{ station.station_name | escape }}</span>
                          <span class="mt-1 block truncate text-xs text-slate-400">
                            {% if station.city %}{{ station.city | escape }}{% endif %}{% if station.city and station.state %}, {% endif %}{% if station.state %}{{ station.state | escape }}{% endif %}
                            {% unless station.city or station.state %}Location not specified{% endunless %}
                          </span>
                        </span>
                        <svg viewBox="0 0 20 20" fill="currentColor" class="size-4 shrink-0 text-cyan-300" aria-hidden="true">
                          <path fill-rule="evenodd" d="M7.21 14.77a.75.75 0 0 1 .02-1.06L10.94 10 7.23 6.29a.75.75 0 1 1 1.06-1.06l4.24 4.24a.75.75 0 0 1 0 1.06l-4.24 4.24a.75.75 0 0 1-1.08 0Z" clip-rule="evenodd" />
                        </svg>
                      </a>
                    </li>
                  {% endfor %}
                </ul>
                {% if category.count > 4 %}
                  <p class="mt-3 text-xs text-slate-500">Showing 4 of {{ category.count }} locations · <a href="{{ '/categories/' | relative_url }}{{ category.id | escape }}/" class="font-semibold text-cyan-200 hover:text-cyan-100">View all</a></p>
                {% endif %}
              </section>
            {% endfor %}
          </div>
        {% else %}
          <p class="rounded-lg border border-dashed border-slate-700 bg-[#0d1c2b]/60 px-4 py-5 text-sm text-slate-400">No station data has been imported yet.</p>
        {% endif %}
      </section>
    </div>

    <aside id="community" class="scroll-mt-6 rounded-xl border border-slate-700/80 bg-[#0d1c2b] p-4 sm:p-5">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-cyan-300">Community</p>
          <h2 class="mt-1 text-sm font-bold uppercase tracking-wide text-white">Built together</h2>
        </div>
        <span class="flex size-9 items-center justify-center rounded-full border border-cyan-300/20 bg-cyan-300/10 text-cyan-200" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" class="size-5" stroke="currentColor" stroke-width="1.7">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16 20v-1.5a3.5 3.5 0 0 0-3.5-3.5h-5A3.5 3.5 0 0 0 4 18.5V20m14-9a3 3 0 1 0-2-5.65M20 20v-1.5a3.5 3.5 0 0 0-2.5-3.36M10 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z" />
          </svg>
        </span>
      </div>
      <p class="mt-4 text-sm leading-6 text-slate-300">The best charging tips come from people who have been there.</p>
      <div class="mt-4 rounded-lg border border-slate-700/70 bg-slate-950/40 p-3">
        <p class="text-xs font-semibold text-white">Community updates are on the roadmap.</p>
        <p class="mt-1 text-xs leading-5 text-slate-400">Station listings and review tools will be added as the directory grows. Every listing will be informational and reviewed before publication.</p>
      </div>
      <a href="https://github.com/xxadambakerxx-tech/open-ev-stations" class="mt-4 inline-flex w-full items-center justify-center gap-2 rounded-lg border border-cyan-300/35 bg-cyan-300/10 px-3 py-2.5 text-xs font-bold uppercase tracking-wide text-cyan-100 transition hover:bg-cyan-300/15 focus:outline-none focus:ring-2 focus:ring-cyan-300">
        Follow the project
        <svg viewBox="0 0 20 20" fill="currentColor" class="size-4" aria-hidden="true">
          <path fill-rule="evenodd" d="M5.22 7.47a.75.75 0 0 1 1.06 0L10 11.19l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 8.53a.75.75 0 0 1 0-1.06Z" clip-rule="evenodd" />
        </svg>
      </a>
    </aside>
  </div>
</section>

<section id="gear" class="mx-auto max-w-[1440px] scroll-mt-6 px-4 pb-12 sm:px-6 lg:px-8">
  <div class="flex flex-col gap-4 rounded-xl border border-slate-700/80 bg-gradient-to-r from-[#0d1c2b] via-[#102433] to-[#0d1c2b] p-5 sm:flex-row sm:items-center sm:justify-between sm:px-7">
    <div class="flex items-center gap-4">
      <span class="flex size-11 shrink-0 items-center justify-center rounded-lg border border-cyan-300/20 bg-cyan-300/10 text-cyan-200" aria-hidden="true">
        <svg viewBox="0 0 24 24" fill="none" class="size-6" stroke="currentColor" stroke-width="1.7">
          <path stroke-linecap="round" stroke-linejoin="round" d="m13.5 2.75-6.75 10.5h5l-1.25 8.25 6.75-10.25h-5l1.25-8.5Z" />
        </svg>
      </span>
      <div>
        <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-cyan-300">For the glove box</p>
        <h2 class="mt-1 text-sm font-bold uppercase tracking-wide text-white">EV adapters &amp; road-trip gear guides</h2>
        <p class="mt-1 text-xs text-slate-400">Practical charging explainers are in the works. No product endorsements or affiliate links yet.</p>
      </div>
    </div>
    <span class="inline-flex w-fit items-center gap-2 rounded-full border border-slate-600/80 px-3 py-1.5 text-[10px] font-semibold uppercase tracking-wider text-slate-400">
      <span class="size-1.5 rounded-full bg-slate-500"></span>
      Coming in a future release
    </span>
  </div>
</section>
