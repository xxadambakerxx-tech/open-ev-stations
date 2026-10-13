const map = document.querySelector("#us-state-map svg.us-state-map");
const countData = document.querySelector("#state-station-counts");
const status = document.querySelector("#selected-state-count");
const stationCounts = JSON.parse(countData.textContent);

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
map.setAttribute("aria-label", "Select a state to view its destination charging station count.");

let selectedState;

function selectState(path) {
  if (selectedState) {
    selectedState.classList.remove("is-selected");
    selectedState.setAttribute("aria-pressed", "false");
  }

  selectedState = path;
  selectedState.classList.add("is-selected");
  selectedState.setAttribute("aria-pressed", "true");

  const code = selectedState.dataset.id;
  const name = stateNames[code];
  const count = stationCounts[code] || 0;
  const locations = new Intl.NumberFormat("en-US").format(count);
  const label = count === 1 ? "location" : "locations";
  status.textContent = `${name}: ${locations} destination charging ${label} in the directory.`;
}

map.querySelectorAll("path[data-id]").forEach((path) => {
  const code = path.dataset.id;
  const name = stateNames[code];
  if (!name) {
    throw new Error(`The state map contains an unrecognized state code: ${code}`);
  }

  const count = stationCounts[code] || 0;
  path.setAttribute("role", "button");
  path.setAttribute("tabindex", "0");
  path.setAttribute("aria-pressed", "false");
  path.setAttribute(
    "aria-label",
    `${name}: ${new Intl.NumberFormat("en-US").format(count)} destination charging locations`
  );
  path.addEventListener("click", () => selectState(path));
  path.addEventListener("keydown", (event) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      selectState(path);
    }
  });
});
