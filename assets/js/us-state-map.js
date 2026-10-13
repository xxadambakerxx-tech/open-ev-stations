const map = document.querySelector("#us-state-map svg.us-state-map");
const countData = document.querySelector("#state-station-counts");
const stationCounts = JSON.parse(countData.textContent);
const statePagePrefix = document.querySelector("#us-state-map").dataset.statePagePrefix;

const stateNames = {
  AK: "Alaska",
  AL: "Alabama",
  AR: "Arkansas",
  AZ: "Arizona",
  CA: "California",
  CO: "Colorado",
  CT: "Connecticut",
  DC: "District of Columbia",
  DE: "Delaware",
  FL: "Florida",
  GA: "Georgia",
  HI: "Hawaii",
  IA: "Iowa",
  ID: "Idaho",
  IL: "Illinois",
  IN: "Indiana",
  KS: "Kansas",
  KY: "Kentucky",
  LA: "Louisiana",
  MA: "Massachusetts",
  MD: "Maryland",
  ME: "Maine",
  MI: "Michigan",
  MN: "Minnesota",
  MO: "Missouri",
  MS: "Mississippi",
  MT: "Montana",
  NC: "North Carolina",
  ND: "North Dakota",
  NE: "Nebraska",
  NH: "New Hampshire",
  NJ: "New Jersey",
  NM: "New Mexico",
  NV: "Nevada",
  NY: "New York",
  OH: "Ohio",
  OK: "Oklahoma",
  OR: "Oregon",
  PA: "Pennsylvania",
  RI: "Rhode Island",
  SC: "South Carolina",
  SD: "South Dakota",
  TN: "Tennessee",
  TX: "Texas",
  UT: "Utah",
  VA: "Virginia",
  VT: "Vermont",
  WA: "Washington",
  WI: "Wisconsin",
  WV: "West Virginia",
  WY: "Wyoming"
};

map.setAttribute("role", "group");
map.setAttribute("aria-label", "Select a state to browse its EV charging stations.");

map.querySelectorAll("path[data-id]").forEach((path) => {
  const code = path.dataset.id;
  const name = stateNames[code];
  if (!name) {
    throw new Error(`The state map contains an unrecognized state code: ${code}`);
  }

  const count = stationCounts[code] || 0;
  const pageUrl = `${statePagePrefix}${code.toLowerCase()}/`;
  path.setAttribute("role", "link");
  path.setAttribute("tabindex", "0");
  path.setAttribute(
    "aria-label",
    `${name}: browse ${new Intl.NumberFormat("en-US").format(count)} EV charging stations`
  );
  path.addEventListener("click", () => {
    window.location.assign(pageUrl);
  });
  path.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      window.location.assign(pageUrl);
    }
  });
});
