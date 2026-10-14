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
              <a href="{{ '/category/' | relative_url }}{{ category.id | escape }}/" class="flex items-center justify-between gap-2 rounded-md px-2 py-2 text-sm text-slate-300 transition hover:bg-slate-800 hover:text-cyan-200">
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
      <div class="absolute inset-0 opacity-35" aria-hidden="true" style="background-image: radial-gradient(#1e7490 0.7px, transparent 0.7px); background-size: 22px 22px;"></div>
      <div class="relative z-10 flex items-center justify-between gap-3 border-b border-white/10 bg-[#071522]/75 px-4 py-3 backdrop-blur-sm sm:px-5">
        <div>
          <h2 id="network-preview-title" class="text-xs font-bold uppercase tracking-[0.17em] text-white sm:text-sm">The U.S. charging network</h2>
          <p class="mt-1 text-xs text-slate-400">Destination charging, from coast to coast</p>
        </div>
        <span class="inline-flex items-center gap-2 rounded-full border border-cyan-300/20 bg-slate-950/80 px-3 py-1.5 text-[10px] font-semibold uppercase tracking-wider text-cyan-100">
          <span class="size-1.5 rounded-full bg-cyan-300"></span>
          Nationwide directory
        </span>
      </div>

      <div class="relative mx-auto flex min-h-[270px] max-w-4xl items-center justify-center px-5 py-5 sm:min-h-[320px] sm:px-10">
        <div id="us-state-map" data-state-page-prefix="{{ '/state/' | relative_url }}" class="w-full max-w-[760px] drop-shadow-[0_0_24px_rgba(34,211,238,0.12)]" aria-label="Interactive map of the United States. Select a state to browse its EV charging stations." role="group">
          {% include us-state-map.svg %}
        </div>
      </div>
      <div class="relative z-10 flex flex-col items-center gap-1 px-4 pb-4 text-center">
        <p class="text-xs font-semibold text-cyan-100">Select a state to browse its EV charging stations.</p>
      </div>
      {% assign stations_by_state = site.data.destination_chargers | group_by_exp: "station", "station.state" %}
      <script id="state-station-counts" type="application/json">
        {
          {% for state_group in stations_by_state %}
            {{ state_group.name | jsonify }}: {{ state_group.items.size }}{% unless forloop.last %},{% endunless %}
          {% endfor %}
        }
      </script>
      <script src="{{ '/assets/js/us-state-map.js' | relative_url }}" defer></script>
    </section>
  </div>
</section>

<section id="glove-box" class="mx-auto max-w-[1440px] px-4 pb-12 sm:px-6 lg:px-8" aria-labelledby="glove-box-heading">
  <div class="mb-4">
    <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-cyan-300">For the glove box</p>
    <h2 id="glove-box-heading" class="mt-1 text-lg font-bold uppercase tracking-wide text-white">EV road-trip guides</h2>
    <p class="mt-1 text-sm text-slate-400">Practical advice for charging, planning, and making the most of the road.</p>
  </div>

  {% assign recent_posts = site.posts | slice: 0, 3 %}
  {% if recent_posts.size > 0 %}
    {% include post_cards.html posts=recent_posts %}
    <nav class="mt-5 flex flex-wrap items-center justify-between gap-3" aria-label="Guide feed navigation">
      <a href="{{ '/blog/' | relative_url }}" class="inline-flex items-center gap-2 text-sm font-semibold text-cyan-200 transition hover:text-cyan-100">
        All guides
        <span aria-hidden="true">&rarr;</span>
      </a>
      {% if site.posts.size > 6 %}
        <a href="{{ '/blog/page/2/' | relative_url }}" class="inline-flex items-center gap-2 rounded-lg border border-slate-600/80 px-4 py-2 text-sm font-semibold text-cyan-200 transition hover:border-cyan-300/40 hover:bg-cyan-300/5">
          Older posts
          <span aria-hidden="true">&rarr;</span>
        </a>
      {% endif %}
    </nav>
  {% else %}
    <div class="rounded-xl border border-slate-700/80 bg-gradient-to-r from-[#0d1c2b] via-[#102433] to-[#0d1c2b] p-5 sm:p-7">
      <h3 class="text-sm font-bold uppercase tracking-wide text-white">Guides are in the works</h3>
      <p class="mt-2 max-w-2xl text-sm leading-6 text-slate-400">Charging explainers and practical electric road-trip advice will appear here as they are published.</p>
    </div>
  {% endif %}
</section>
