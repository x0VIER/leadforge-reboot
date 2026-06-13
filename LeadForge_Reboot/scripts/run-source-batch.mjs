import fs from "node:fs/promises";
import path from "node:path";

const rebootRoot = path.resolve(process.cwd());
const archiveRoot = path.resolve(rebootRoot, "..");
const configPath = path.join(rebootRoot, "config", "source-lanes.json");
const outputDir = path.join(rebootRoot, "data", "output");
const runLogDir = path.join(rebootRoot, "data", "run-logs");
const tempDir = path.join(rebootRoot, "data", "tmp");
const recoveredCsvPath = path.join(archiveRoot, "Recovered_Leads_Database.csv");
const agentSharedRoot = path.join(rebootRoot, "agent_shared");
const workingDir = path.join(agentSharedRoot, "working");
const statusDir = path.join(agentSharedRoot, "status");
const doneDir = path.join(agentSharedRoot, "done");
const failedDir = path.join(agentSharedRoot, "failed");
const sharedLogPath = path.join(agentSharedRoot, "shared_activity_log.md");

const today = new Date().toISOString().slice(0, 10);
const stamp = new Date().toISOString().replace(/[:.]/g, "-");
const staleClaimMs = 2 * 60 * 60 * 1000;
const defaultOverpassPauseMs = 5000;
const defaultLanePauseMs = 2000;
const defaultCollectorName = "Hermes";
const overpassEndpoint = "https://overpass-api.de/api/interpreter";

const nicheToOverpassFilters = {
  roofing: ['["craft"="roofer"]', '["craft"="roofing"]'],
  plumbing: ['["craft"="plumber"]'],
  electrician: ['["craft"="electrician"]'],
  hvac: ['["craft"="hvac"]', '["shop"="air_conditioning"]']
};

const stateNameByCode = {
  FL: "Florida",
  NY: "New York"
};

function parseCsv(text) {
  const rows = [];
  let field = "";
  let row = [];
  let inQuotes = false;
  for (let i = 0; i < text.length; i += 1) {
    const ch = text[i];
    const next = text[i + 1];
    if (ch === "\"") {
      if (inQuotes && next === "\"") {
        field += "\"";
        i += 1;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch === "," && !inQuotes) {
      row.push(field);
      field = "";
    } else if ((ch === "\n" || ch === "\r") && !inQuotes) {
      if (ch === "\r" && next === "\n") {
        i += 1;
      }
      row.push(field);
      if (row.some((value) => value.length > 0)) {
        rows.push(row);
      }
      field = "";
      row = [];
    } else {
      field += ch;
    }
  }
  if (field.length > 0 || row.length > 0) {
    row.push(field);
    rows.push(row);
  }
  const [header, ...body] = rows;
  return body.map((line) => Object.fromEntries(header.map((key, index) => [key, line[index] ?? ""])));
}

function toCsv(rows) {
  if (!rows.length) {
    return "";
  }
  const headers = Object.keys(rows[0]);
  const escape = (value) => {
    const text = String(value ?? "");
    if (/[",\n]/.test(text)) {
      return `"${text.replaceAll("\"", "\"\"")}"`;
    }
    return text;
  };
  return [headers.join(","), ...rows.map((row) => headers.map((header) => escape(row[header])).join(","))].join("\n");
}

function normalizeName(value) {
  return (value || "").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
}

function normalizeHost(urlString) {
  try {
    return new URL(urlString).hostname.replace(/^www\./, "").toLowerCase();
  } catch {
    return "";
  }
}

function pickFirst(...values) {
  return values.find((value) => value && String(value).trim()) || "";
}

function absolutize(baseUrl, href) {
  try {
    return new URL(href, baseUrl).toString();
  } catch {
    return "";
  }
}

function unique(values) {
  return [...new Set(values.filter(Boolean))];
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function isThirdPartyContactUrl(urlString) {
  const host = normalizeHost(urlString);
  return [
    "facebook.com",
    "instagram.com",
    "x.com",
    "twitter.com",
    "linkedin.com",
    "youtube.com",
    "tiktok.com",
    "housecallpro.com"
  ].some((domain) => host === domain || host.endsWith(`.${domain}`));
}

async function safeReadJson(filePath) {
  try {
    return JSON.parse(await fs.readFile(filePath, "utf8"));
  } catch {
    return null;
  }
}

function sanitizeSlug(value) {
  return String(value || "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function laneKey(lane, niche) {
  return `${lane.city}, ${lane.state} / ${niche}`;
}

async function appendSharedLog(message) {
  const line = `- ${new Date().toISOString()} ${message}\n`;
  await fs.appendFile(sharedLogPath, line, "utf8");
}

async function writeStatus(fileName, payload) {
  await fs.writeFile(path.join(statusDir, fileName), JSON.stringify(payload, null, 2), "utf8");
}

async function moveClaim(claimPath, targetDir, status, extra = {}) {
  const claim = await safeReadJson(claimPath);
  const payload = {
    ...(claim || {}),
    ...extra,
    status,
    updatedAt: new Date().toISOString()
  };
  const destination = path.join(targetDir, path.basename(claimPath));
  await fs.writeFile(destination, JSON.stringify(payload, null, 2), "utf8");
  await fs.rm(claimPath, { force: true });
  return destination;
}

async function acquireCollectorClaim(config) {
  await fs.mkdir(workingDir, { recursive: true });
  await fs.mkdir(doneDir, { recursive: true });
  await fs.mkdir(failedDir, { recursive: true });
  await fs.mkdir(statusDir, { recursive: true });

  const now = Date.now();
  const files = await fs.readdir(workingDir).catch(() => []);
  for (const name of files) {
    if (!name.endsWith(".json")) {
      continue;
    }
    const existingPath = path.join(workingDir, name);
    const existing = await safeReadJson(existingPath);
    if (!existing || existing.workflow !== "source-batch") {
      continue;
    }

    const startedAtMs = Date.parse(existing.startedAt || "");
    if (Number.isFinite(startedAtMs) && now - startedAtMs <= staleClaimMs) {
      throw new Error(
        `Collector already claimed by ${existing.owner || "another agent"} at ${existing.startedAt}. Active claim: ${name}`
      );
    }

    await moveClaim(existingPath, failedDir, "stale_recovered", {
      failureReason: "Recovered stale collector claim before starting a new run."
    });
    await appendSharedLog(`Recovered stale collector claim ${name} before starting a new source batch.`);
  }

  const claimName = `${stamp}-collector-${sanitizeSlug(config.batchName)}.json`;
  const claimPath = path.join(workingDir, claimName);
  const claim = {
    workflow: "source-batch",
    owner: config.collectorName || defaultCollectorName,
    batchName: config.batchName,
    startedAt: new Date().toISOString(),
    status: "running",
    maxOutputRows: config.maxOutputRows,
    lanes: config.lanes.map((lane) => ({
      city: lane.city,
      state: lane.state,
      niches: lane.niches
    }))
  };

  await fs.writeFile(claimPath, JSON.stringify(claim, null, 2), { encoding: "utf8", flag: "wx" });
  await appendSharedLog(`Collector claim opened for ${config.batchName} by ${claim.owner}.`);
  return { claimPath, claim };
}

function isLikelyEmail(value) {
  const text = String(value || "").trim().toLowerCase();
  if (!text.includes("@")) {
    return false;
  }
  const blockedSuffixes = [".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".css", ".js", ".ico"];
  const blockedDomains = ["company.com", "example.com", "email.com"];
  const domain = text.split("@")[1] || "";
  return !blockedSuffixes.some((suffix) => text.endsWith(suffix)) && !blockedDomains.includes(domain);
}

function isAcceptedEmailForSite(email, siteUrl) {
  const text = String(email || "").trim().toLowerCase();
  if (!isLikelyEmail(text)) {
    return false;
  }

  const domain = text.split("@")[1] || "";
  const host = normalizeHost(siteUrl);
  const commonMailDomains = new Set([
    "gmail.com",
    "outlook.com",
    "hotmail.com",
    "live.com",
    "yahoo.com",
    "icloud.com",
    "aol.com",
    "proton.me",
    "protonmail.com"
  ]);

  if (commonMailDomains.has(domain)) {
    return true;
  }

  return Boolean(host) && (domain === host || domain.endsWith(`.${host}`) || host.endsWith(`.${domain}`));
}

async function readExistingRows() {
  const seen = new Set();
  for (const filePath of [recoveredCsvPath, ...await listOutputCsvs()]) {
    try {
      const text = await fs.readFile(filePath, "utf8");
      for (const row of parseCsv(text)) {
        const key = dedupeKey(row);
        if (key) {
          seen.add(key);
        }
      }
    } catch {
      // Ignore missing or unreadable historical files.
    }
  }
  return seen;
}

async function listOutputCsvs() {
  try {
    const names = await fs.readdir(outputDir);
    return names.filter((name) => name.endsWith(".csv")).map((name) => path.join(outputDir, name));
  } catch {
    return [];
  }
}

function dedupeKey(row) {
  const host = normalizeHost(row.website);
  if (host) {
    return `host:${host}`;
  }
  const name = normalizeName(row.business_name);
  if (!name) {
    return "";
  }
  return `name:${name}|${(row.city || "").toLowerCase()}|${(row.state || "").toLowerCase()}`;
}

async function fetchJson(url) {
  let lastError = null;
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    const response = await fetch(overpassEndpoint, {
      method: "POST",
      headers: { "User-Agent": "LeadForge-Reboot/1.0 (public business research)" },
      body: `data=${encodeURIComponent(url)}`,
      redirect: "follow"
    });
    if (response.ok) {
      return response.json();
    }
    lastError = new Error(`HTTP ${response.status} for query on attempt ${attempt}`);
    if (![429, 504].includes(response.status) || attempt === 4) {
      throw lastError;
    }
    await sleep(4000 * attempt);
  }
  throw lastError;
}

async function fetchText(url) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetch(url, {
      headers: { "User-Agent": "LeadForge-Reboot/1.0 (public business research)" },
      redirect: "follow",
      signal: controller.signal
    });
    if (!response.ok) {
      return { url, html: "" };
    }
    const html = (await response.text()).slice(0, 350000);
    return { url: response.url, html };
  } catch {
    return { url, html: "" };
  } finally {
    clearTimeout(timer);
  }
}

async function getWebsiteSignals(website) {
  if (!website) {
    return { publicEmail: "", contactUrl: "", evidenceBits: [], keywordFlags: {}, phoneMentions: 0 };
  }

  const home = await fetchText(website);
  if (!home.html) {
    return { publicEmail: "", contactUrl: "", evidenceBits: ["Website did not return readable HTML during this run."], keywordFlags: {}, phoneMentions: 0 };
  }

  const emailRegex = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi;
  const hrefRegex = /href=["']([^"'#]+)["']/gi;
  const emails = unique([...(home.html.match(emailRegex) || [])].filter((email) => isAcceptedEmailForSite(email, home.url)));
  const hrefs = [...home.html.matchAll(hrefRegex)].map((match) => match[1]);
  const contactCandidate = hrefs.find((href) => {
    if (!/(contact|estimate|quote|book|schedule)/i.test(href)) {
      return false;
    }
    return !/\.(css|js|png|jpg|jpeg|svg|webp|gif|ico)(\?|$)/i.test(href);
  });
  const contactUrl = contactCandidate ? absolutize(home.url, contactCandidate) : "";
  const acceptedContactUrl = isThirdPartyContactUrl(contactUrl) ? "" : contactUrl;

  let contactEmails = [];
  let keywordSource = home.html;
  if (acceptedContactUrl && normalizeHost(acceptedContactUrl) === normalizeHost(home.url) && acceptedContactUrl !== home.url) {
    const contact = await fetchText(acceptedContactUrl);
    keywordSource += ` ${contact.html}`;
    contactEmails = unique([...(contact.html.match(emailRegex) || [])].filter((email) => isAcceptedEmailForSite(email, home.url)));
  }

  const keywordFlags = {
    estimate: /(estimate|inspection|quote|book now|schedule)/i.test(keywordSource),
    financing: /financing/i.test(keywordSource),
    emergency: /24\/7|emergency/i.test(keywordSource)
  };

  const phoneMentions = (keywordSource.match(/\+?1?[-.\s]?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}/g) || []).length;
  const publicEmail = pickFirst(...contactEmails, ...emails);
  const evidenceBits = [];
  if (publicEmail) {
    evidenceBits.push(`Public website exposed email ${publicEmail}.`);
  }
  if (acceptedContactUrl) {
    evidenceBits.push(`Website exposed a contact path at ${acceptedContactUrl}.`);
  } else if (contactUrl) {
    evidenceBits.push("Website linked to a third-party contact surface instead of a first-party contact path.");
  }
  if (keywordFlags.estimate) {
    evidenceBits.push("Website mentions estimate, quote, inspection, or scheduling language.");
  }

  return { publicEmail, contactUrl: acceptedContactUrl, evidenceBits, keywordFlags, phoneMentions };
}

function inferGapAndOffer({ niche, website, publicEmail, contactUrl, keywordFlags, phoneMentions }) {
  if (!website) {
    return {
      visibleGap: "Public business listing is present, but no website was surfaced for a clear conversion path.",
      offerAngle: `Website launch and ${niche} intake cleanup`,
      riskScore: "4"
    };
  }
  if (!contactUrl) {
    return {
      visibleGap: "Website is live, but no obvious contact or estimate path was detected on the public page sweep.",
      offerAngle: `${capitalize(niche)} contact-path cleanup`,
      riskScore: "2"
    };
  }
  if (!publicEmail) {
    return {
      visibleGap: "Public contact path appears to rely on phone-first routing without a clearly exposed email fallback.",
      offerAngle: `${capitalize(niche)} lead-capture follow-up setup`,
      riskScore: "2"
    };
  }
  if (!keywordFlags.estimate) {
    return {
      visibleGap: "Contact path exists, but the site did not clearly expose estimate or booking language in the public sweep.",
      offerAngle: `${capitalize(niche)} estimate CTA upgrade`,
      riskScore: "1"
    };
  }
  if (phoneMentions > 2) {
    return {
      visibleGap: "Multiple public phone mentions may split the primary conversion path instead of pushing one clean estimate flow.",
      offerAngle: `${capitalize(niche)} primary-call routing cleanup`,
      riskScore: "1"
    };
  }
  return {
    visibleGap: "Public contact path is present, but the follow-up funnel could likely be tightened for faster estimate handling.",
    offerAngle: `${capitalize(niche)} estimate funnel cleanup`,
    riskScore: "1"
  };
}

function capitalize(text) {
  return text.charAt(0).toUpperCase() + text.slice(1);
}

function buildEvidence(element, websiteSignals) {
  const tags = element.tags || {};
  const bits = [];
  if (tags.phone || tags["contact:phone"]) {
    bits.push("Public business record listed a phone number.");
  }
  if (tags.website || tags["contact:website"]) {
    bits.push("Public business record listed a website.");
  }
  bits.push(...websiteSignals.evidenceBits);
  return bits.join(" ");
}

function buildValidationStatus(row) {
  const signalCount = [row.website, row.public_phone, row.public_email].filter(Boolean).length;
  if (signalCount >= 2) {
    return "validated_public_business_source";
  }
  if (signalCount === 1) {
    return "partial_public_business_source";
  }
  return "needs_manual_review";
}

function buildPriorityTier(riskScore, validationStatus) {
  if (validationStatus === "validated_public_business_source" && Number(riskScore) <= 2) {
    return "P0_offer_ready_review";
  }
  if (validationStatus === "partial_public_business_source") {
    return "P1_manual_enrichment";
  }
  return "P2_low_signal_review";
}

async function queryLane(city, state, niche, limit) {
  const stateName = stateNameByCode[state] || state;
  const filters = nicheToOverpassFilters[niche] || [`["craft"="${String(niche).replaceAll(" ", "_")}"]`];
  const queryBody = filters.map((filter) => `  nwr${filter}(area.searchArea);`).join("\n");
  const query = `
[out:json][timeout:25];
area["name"="${stateName}"]["boundary"="administrative"]["admin_level"="4"]->.stateArea;
rel(area.stateArea)["name"="${city}"]["boundary"="administrative"]["admin_level"~"8|9|10"];
map_to_area->.searchArea;
(
${queryBody}
);
out center ${Math.max(limit * 2, limit + 2)};
  `.trim();
  const payload = await fetchJson(query);
  return (payload.elements || []).slice(0, limit * 3).map((element) => ({ ...element, _city: city, _state: state, _niche: niche }));
}

async function main() {
  await fs.mkdir(outputDir, { recursive: true });
  await fs.mkdir(runLogDir, { recursive: true });
  await fs.mkdir(tempDir, { recursive: true });
  await fs.mkdir(agentSharedRoot, { recursive: true });

  const config = JSON.parse(await fs.readFile(configPath, "utf8"));
  const overpassPauseMs = Number(config.overpassPauseMs || defaultOverpassPauseMs);
  const lanePauseMs = Number(config.lanePauseMs || defaultLanePauseMs);
  const claimState = await acquireCollectorClaim(config);
  const seen = await readExistingRows();
  const freshRows = [];
  const laneStats = [];
  const status = {
    workflow: "source-batch",
    batchName: config.batchName,
    startedAt: claimState.claim.startedAt,
    owner: claimState.claim.owner,
    state: "running",
    activeLane: "",
    rowsWritten: 0,
    maxOutputRows: config.maxOutputRows,
    claimFile: path.basename(claimState.claimPath),
    outputCsv: "",
    latestLog: "",
    lanes: []
  };

  await writeStatus("CURRENT_STATUS.json", status);

  try {
    for (const lane of config.lanes) {
      for (const niche of lane.niches) {
        if (freshRows.length >= config.maxOutputRows) {
          break;
        }

        status.activeLane = laneKey(lane, niche);
        await writeStatus("CURRENT_STATUS.json", { ...status, lanes: laneStats, rowsWritten: freshRows.length });

        let addedForLane = 0;
        let scanned = 0;
        let rejected = 0;
        let elements = [];
        let note = "";
        try {
          elements = await queryLane(lane.city, lane.state, niche, lane.perNicheLimit);
        } catch (error) {
          note = `query failed: ${error.message}`;
          laneStats.push({
            city: lane.city,
            state: lane.state,
            niche,
            scanned: 0,
            added: 0,
            rejected: 0,
            note
          });
          await appendSharedLog(`Lane failed for ${laneKey(lane, niche)} with ${error.message}.`);
          await sleep(overpassPauseMs);
          continue;
        }

        for (const element of elements) {
          if (freshRows.length >= config.maxOutputRows || addedForLane >= lane.perNicheLimit) {
            break;
          }

          scanned += 1;
          const tags = element.tags || {};
          const businessName = pickFirst(tags.name, tags.operator, tags.brand);
        const website = pickFirst(tags.website, tags["contact:website"], tags.url);
        const publicPhone = pickFirst(tags.phone, tags["contact:phone"]);

        if (!businessName) {
          rejected += 1;
          continue;
        }

        if (!website && !publicPhone) {
          rejected += 1;
          continue;
        }

          const provisionalRow = {
            business_name: businessName,
            city: lane.city,
            state: lane.state,
            website
          };
          const key = dedupeKey(provisionalRow);
          if (key && seen.has(key)) {
            rejected += 1;
            continue;
          }

          const websiteSignals = await getWebsiteSignals(website);
          const analysis = inferGapAndOffer({
            niche,
            website,
            publicEmail: websiteSignals.publicEmail,
            contactUrl: websiteSignals.contactUrl,
            keywordFlags: websiteSignals.keywordFlags,
            phoneMentions: websiteSignals.phoneMentions
          });

          const row = {
            lead_id: `LFR-${today.replaceAll("-", "")}-${String(freshRows.length + 1).padStart(4, "0")}`,
            business_name: businessName,
            niche,
            city: lane.city,
            state: lane.state,
            website,
            public_phone: publicPhone,
            public_email: websiteSignals.publicEmail,
            contact_url: websiteSignals.contactUrl,
            owner_name: "",
            owner_title: "",
            owner_source: "",
            source_type: "overpass_public_business_record",
            source_query: `${lane.city} ${lane.state} ${niche} public business listing`,
            source_evidence: buildEvidence(element, websiteSignals),
            visible_gap: analysis.visibleGap,
            offer_angle: analysis.offerAngle,
            risk_score_1_5: analysis.riskScore,
            validation_status: "",
            priority_tier: "",
            last_checked: today
          };

          row.validation_status = buildValidationStatus(row);
          row.priority_tier = buildPriorityTier(row.risk_score_1_5, row.validation_status);

          const rowKey = dedupeKey(row);
          if (rowKey && seen.has(rowKey)) {
            rejected += 1;
            continue;
          }

          freshRows.push(row);
          if (rowKey) {
            seen.add(rowKey);
          }
          addedForLane += 1;
        }

        laneStats.push({
          city: lane.city,
          state: lane.state,
          niche,
          scanned,
          added: addedForLane,
          rejected,
          note
        });
        await writeStatus("CURRENT_STATUS.json", { ...status, lanes: laneStats, rowsWritten: freshRows.length });
        await sleep(addedForLane > 0 ? lanePauseMs : overpassPauseMs);
      }
    }

    if (!freshRows.length) {
      status.state = "complete_no_rows";
      status.activeLane = "";
      await writeStatus("CURRENT_STATUS.json", { ...status, lanes: laneStats, rowsWritten: 0 });
      await moveClaim(claimState.claimPath, doneDir, "complete_no_rows", { rowsWritten: 0, lanes: laneStats });
      await appendSharedLog(`Collector finished for ${config.batchName} with no fresh rows.`);
      console.log("No fresh leads were produced. Adjust config/source-lanes.json and rerun.");
      return;
    }

    const csvName = `${stamp}-${config.batchName}-fresh-leads.csv`;
    const logName = `${stamp}-${config.batchName}-run-log.json`;
    const tempCsvPath = path.join(tempDir, `${csvName}.partial`);
    const tempLogPath = path.join(tempDir, `${logName}.partial`);
    const finalCsvPath = path.join(outputDir, csvName);
    const finalLogPath = path.join(runLogDir, logName);

    await fs.writeFile(tempCsvPath, toCsv(freshRows), "utf8");
    await fs.writeFile(tempLogPath, JSON.stringify({
      createdAt: new Date().toISOString(),
      config: config.batchName,
      recoveredCsvPath,
      outputCsv: csvName,
      rowsWritten: freshRows.length,
      lanes: laneStats
    }, null, 2));
    await fs.rename(tempCsvPath, finalCsvPath);
    await fs.rename(tempLogPath, finalLogPath);

    status.state = "complete";
    status.activeLane = "";
    status.rowsWritten = freshRows.length;
    status.outputCsv = csvName;
    status.latestLog = logName;
    status.lanes = laneStats;
    await writeStatus("CURRENT_STATUS.json", status);
    await fs.writeFile(path.join(statusDir, "LAST_SUCCESS.json"), JSON.stringify(status, null, 2), "utf8");
    await moveClaim(claimState.claimPath, doneDir, "complete", {
      rowsWritten: freshRows.length,
      outputCsv: csvName,
      runLog: logName,
      lanes: laneStats
    });
    await appendSharedLog(`Collector finished ${config.batchName} with ${freshRows.length} rows into ${csvName}.`);

    console.log(`Wrote ${freshRows.length} fresh leads to data/output/${csvName}`);
    console.log(`Run log: data/run-logs/${logName}`);
    for (const stat of laneStats) {
      console.log(`${stat.city}, ${stat.state} / ${stat.niche}: scanned=${stat.scanned} added=${stat.added} rejected=${stat.rejected}${stat.note ? ` (${stat.note})` : ""}`);
    }
  } catch (error) {
    await writeStatus("CURRENT_STATUS.json", {
      ...status,
      state: "failed",
      error: error.message,
      activeLane: status.activeLane,
      lanes: laneStats,
      rowsWritten: freshRows.length
    });
    await moveClaim(claimState.claimPath, failedDir, "failed", {
      error: error.message,
      rowsWritten: freshRows.length,
      lanes: laneStats
    });
    await appendSharedLog(`Collector failed for ${config.batchName}: ${error.message}`);
    throw error;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
