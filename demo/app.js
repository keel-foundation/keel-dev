const config = window.KEELTUBE_CONFIG || {};
const MODE = config.mode === "remote" ? "remote" : "mock";
const API_BASE = (config.apiBaseUrl || "/api").replace(/\/$/, "");
const MOD_BASE = (config.moderationBaseUrl || "/moderation").replace(/\/$/, "");

const FALLBACK_VIDEO = {
  id: "vid_demo_001",
  title: "The Last Lighthouse",
  channel_id: "ch_demo",
  status: "published",
  playback: { mp4_url: "/sample.mp4" }
};

const FALLBACK_SRC = "/sample.mp4";

const elements = {
  app: document.getElementById("app"),
  modeBadge: document.getElementById("mode-badge"),
  error: document.getElementById("error"),
  statusBadge: document.getElementById("status-badge"),
  policyLabel: document.getElementById("policy-label"),
  videoTitle: document.getElementById("video-title"),
  video: document.getElementById("video"),
  issue: document.getElementById("issue-button"),
  appeal: document.getElementById("appeal-button"),
  reverse: document.getElementById("reverse-button"),
  reset: document.getElementById("reset-button"),
  decision: document.getElementById("decision"),
  ledger: document.getElementById("ledger"),
  ledgerCount: document.getElementById("ledger-count"),
  verifyButton: document.getElementById("verify-button"),
  verifyBadge: document.getElementById("verify-badge"),
  verifyDetail: document.getElementById("verify-detail"),
  exportButton: document.getElementById("export-button"),
  footerNote: document.getElementById("footer-note"),
  openapiLine: document.getElementById("openapi-line"),
  openapiLink: document.getElementById("openapi-link")
};

let busy = false;
let lastState = null;
let lastVideo = FALLBACK_VIDEO;

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (character) => {
    const entities = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;"
    };
    return entities[character];
  });
}

function clone(value) {
  return value == null ? value : JSON.parse(JSON.stringify(value));
}

function now() {
  return new Date().toISOString();
}

function newId(prefix) {
  const bytes = new Uint8Array(6);
  crypto.getRandomValues(bytes);
  return `${prefix}_${Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join("")}`;
}

function stable(value) {
  if (Array.isArray(value)) return `[${value.map(stable).join(",")}]`;
  if (value && typeof value === "object") {
    const keys = Object.keys(value).sort();
    return `{${keys.map((key) => `${JSON.stringify(key)}:${stable(value[key])}`).join(",")}}`;
  }
  return JSON.stringify(value);
}

async function sha256Hex(text) {
  if (!crypto.subtle) {
    throw new Error("This demo requires a secure context. Run it with `make demo` and open localhost.");
  }
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

function dateLabel(value) {
  if (!value) return "—";
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString();
}

function shortHash(value) {
  return value ? `${value.slice(0, 18)}…` : "—";
}

function setError(message) {
  elements.error.hidden = !message;
  elements.error.textContent = message || "";
}

function setBusy(value) {
  busy = value;
  elements.app.setAttribute("aria-busy", String(value));
  applyDisabled();
}

function applyDisabled() {
  const action = lastState?.action;
  const appeal = lastState?.appeal;
  const canAppeal = Boolean(
    action && action.status === "active" && (!appeal || appeal.status === "decided")
  );
  const pending = Boolean(appeal && appeal.status === "pending");
  elements.issue.disabled = busy || Boolean(action && action.status === "active");
  elements.appeal.disabled = busy || !canAppeal;
  elements.reverse.disabled = busy || !pending;
  elements.reset.disabled = busy;
  elements.verifyButton.disabled = busy;
  elements.exportButton.disabled = busy;
}

function renderMode() {
  if (MODE === "remote") {
    elements.modeBadge.textContent = "stage mode";
    elements.modeBadge.className = "badge stage";
    elements.footerNote.textContent =
      "Stage mode: the local demo server proxies requests to the configured stage services. The token stays server-side.";
  } else {
    elements.modeBadge.textContent = "mock mode";
    elements.modeBadge.className = "badge clear";
    elements.footerNote.textContent =
      "Mock mode: all state is simulated in your browser. No backend is required.";
  }
  if (config.openapiUrl) {
    elements.openapiLine.hidden = false;
    elements.openapiLink.href = config.openapiUrl;
    elements.openapiLink.textContent = config.openapiUrl;
  }
}

function renderDecision(state) {
  const action = state.action;
  const appeal = state.appeal;
  const caseRecord = state.case;
  const appeals = state.appeals || [];

  if (!action) {
    elements.decision.innerHTML =
      '<p class="muted">No action. The video is live. Issue a false positive to begin.</p>';
    return;
  }

  const statement = action.statement_of_reasons || {};
  const evidence = statement.evidence_refs || [];
  const signals = (caseRecord?.signals || [])
    .map(
      (signal) =>
        `<dt>Signal</dt><dd>${escapeHtml(signal.signal_type)} · ${escapeHtml(
          signal.source
        )}${signal.confidence !== undefined ? ` · ${escapeHtml(signal.confidence)}` : ""}</dd>`
    )
    .join("");

  const caseHtml = caseRecord
    ? `<h3>Case and signal</h3>
       <dl class="facts">
         <dt>Case</dt><dd class="mono">${escapeHtml(caseRecord.id)}</dd>
         <dt>Subject</dt><dd class="mono">${escapeHtml(caseRecord.subject?.type)}:${escapeHtml(
           caseRecord.subject?.id
         )}</dd>
         <dt>Severity</dt><dd>${escapeHtml(caseRecord.severity)}</dd>
         ${signals}
       </dl>`
    : "";

  const appealHtml = appeal
    ? `<h3>Appeal</h3>
       <dl class="facts">
         <dt>Appeal</dt><dd class="mono">${escapeHtml(appeal.id)}</dd>
         <dt>Grounds</dt><dd>${escapeHtml(appeal.grounds)}</dd>
         <dt>Submitted</dt><dd>${escapeHtml(dateLabel(appeal.submitted_at))}</dd>
         <dt>Status</dt><dd>${escapeHtml(appeal.status)}</dd>
         <dt>Reviewer</dt><dd>${escapeHtml(appeal.reviewer || "not yet assigned")}</dd>
         <dt>Decision</dt><dd>${escapeHtml(appeal.decision || "—")}</dd>
       </dl>
       <p>${escapeHtml(appeal.statement)}</p>
       ${appeal.reasoning ? `<p>${escapeHtml(appeal.reasoning)}</p>` : ""}`
    : "";

  const historyHtml =
    appeals.length > 1
      ? `<h3>Appeal history</h3><ul class="evidence">${appeals
          .map(
            (item) =>
              `<li><span class="mono">${escapeHtml(item.id)}</span> · ${escapeHtml(
                item.grounds
              )} · ${escapeHtml(item.status)}${
                item.decision ? ` · ${escapeHtml(item.decision)}` : ""
              }</li>`
          )
          .join("")}</ul>`
      : "";

  elements.decision.innerHTML = `
    <dl class="facts">
      <dt>Action</dt><dd class="mono">${escapeHtml(action.id)}</dd>
      <dt>Case</dt><dd class="mono">${escapeHtml(action.case_id)}</dd>
      <dt>Type</dt><dd>${escapeHtml(action.action_type)} · ${escapeHtml(action.scope)}</dd>
      <dt>Reviewer</dt><dd>${escapeHtml(action.human_reviewer)}</dd>
      <dt>Policy</dt><dd class="mono">${escapeHtml(action.policy_clause)}</dd>
      <dt>Version</dt><dd class="mono">${escapeHtml(statement.policy_version)}</dd>
      <dt>Effective</dt><dd>${escapeHtml(dateLabel(action.effective_at))}</dd>
      <dt>Deadline</dt><dd>${escapeHtml(dateLabel(action.appeal_deadline))}</dd>
      <dt>Reason</dt><dd>${escapeHtml(statement.summary)}</dd>
      <dt>Audit hash</dt><dd class="mono break">${escapeHtml(action.audit_record_hash)}</dd>
      ${
        action.reversal_record_hash
          ? `<dt>Reversal</dt><dd class="mono break">${escapeHtml(
              action.reversal_record_hash
            )}</dd>`
          : ""
      }
    </dl>
    <h3>Evidence</h3>
    <ul class="evidence">${evidence
      .map((item) => `<li>${escapeHtml(item)}</li>`)
      .join("")}</ul>
    ${caseHtml}
    ${appealHtml}
    ${historyHtml}`;
}

function renderLedger(state) {
  const records = state.ledger || [];
  const verification = state.verification || {
    valid: true,
    records: records.length,
    first_broken: null,
    reason: null
  };
  elements.ledgerCount.textContent = `${records.length} records`;
  elements.verifyBadge.textContent = verification.valid ? "chain valid" : "chain invalid";
  elements.verifyBadge.className = `badge ${verification.valid ? "clear" : "active"}`;
  elements.verifyDetail.hidden = verification.valid;
  elements.verifyDetail.textContent = verification.valid
    ? ""
    : `Broken at record ${verification.first_broken}: ${verification.reason}`;

  if (!records.length) {
    elements.ledger.innerHTML = '<li class="muted">No records yet.</li>';
    return;
  }

  elements.ledger.innerHTML = records
    .map(
      (record) =>
        `<li>
           <span class="mono">#${escapeHtml(record.seq)}</span>
           <span>${escapeHtml(record.type)}</span>
           <span class="mono muted ledger-hash" title="${escapeHtml(record.prev_hash)}">${escapeHtml(
             shortHash(record.prev_hash)
           )}</span>
           <span class="mono ledger-hash" title="${escapeHtml(record.hash)}">${escapeHtml(
             shortHash(record.hash)
           )}</span>
         </li>`
    )
    .join("");
}

function render(state, video) {
  lastState = state;
  lastVideo = video || FALLBACK_VIDEO;
  const action = state.action;
  elements.statusBadge.textContent = action ? action.status : "published";
  elements.statusBadge.className = `badge ${action ? action.status : "clear"}`;
  elements.policyLabel.textContent = action ? action.policy_clause : "no enforcement action";
  elements.videoTitle.textContent = lastVideo.title || FALLBACK_VIDEO.title;
  const source = lastVideo.playback?.mp4_url || FALLBACK_SRC;
  if (elements.video.getAttribute("src") !== source) {
    elements.video.setAttribute("src", source);
  }
  renderDecision(state);
  renderLedger(state);
  applyDisabled();
}

async function load() {
  const state = await adapter.getState();
  let video = null;
  try {
    video = await adapter.getVideo();
  } catch {
    video = null;
  }
  render(state, video);
}

async function mutate(operation) {
  setBusy(true);
  setError(null);
  try {
    await operation();
    await load();
  } catch (error) {
    setError(error instanceof Error ? error.message : "The demo request failed.");
  } finally {
    setBusy(false);
  }
}

function download(filename, text) {
  const blob = new Blob([text], { type: "application/x-ndjson" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

const mockBackend = (() => {
  let action = null;
  let caseRecord = null;
  let appeals = [];
  let ledger = [];

  async function append(type, payload) {
    const seq = ledger.length + 1;
    const prevHash = ledger.length ? ledger[ledger.length - 1].hash : "GENESIS";
    const record = {
      seq,
      type,
      at: now(),
      payload: clone(payload),
      prev_hash: prevHash
    };
    record.hash = `sha256:${await sha256Hex(stable(record))}`;
    ledger.push(record);
    return record;
  }

  async function verify() {
    let previous = "GENESIS";
    for (let index = 0; index < ledger.length; index += 1) {
      const record = ledger[index];
      if (record.seq !== index + 1) {
        return {
          valid: false,
          records: ledger.length,
          head: previous,
          first_broken: index + 1,
          reason: "sequence number mismatch"
        };
      }
      if (record.prev_hash !== previous) {
        return {
          valid: false,
          records: ledger.length,
          head: previous,
          first_broken: index + 1,
          reason: "previous hash mismatch"
        };
      }
      const withoutHash = { ...record };
      delete withoutHash.hash;
      const expected = `sha256:${await sha256Hex(stable(withoutHash))}`;
      if (record.hash !== expected) {
        return {
          valid: false,
          records: ledger.length,
          head: previous,
          first_broken: index + 1,
          reason: "record hash mismatch"
        };
      }
      previous = record.hash;
    }
    return {
      valid: true,
      records: ledger.length,
      head: previous,
      first_broken: null,
      reason: null
    };
  }

  async function getState() {
    return {
      action: clone(action),
      appeal: appeals.length ? clone(appeals[appeals.length - 1]) : null,
      appeals: clone(appeals),
      case: clone(caseRecord),
      ledger: clone(ledger),
      policy: { policy_version: "demo-0.1" },
      verification: await verify()
    };
  }

  async function reset() {
    await append("demo.reset", {});
    action = null;
    caseRecord = null;
    appeals = [];
    return getState();
  }

  async function createAction(input) {
    if (action && action.status === "active") {
      throw new Error("An active demo action already exists. Reset the demo first.");
    }
    const createdAt = now();
    const caseId = newId("case");
    const actionId = newId("act");
    const statement = {
      summary: input.reason,
      policy_version: "demo-0.1",
      evidence_refs: input.evidence
    };
    const createdAction = {
      id: actionId,
      case_id: caseId,
      action_type: "label",
      scope: "video",
      policy_clause: input.policy_clause,
      statement_of_reasons: statement,
      human_reviewer: "demo-reviewer",
      status: "active",
      effective_at: createdAt,
      appeal_deadline: new Date(Date.now() + 365 * 86400 * 1000).toISOString(),
      audit_record_hash: "",
      created_at: createdAt
    };
    const createdCase = {
      id: caseId,
      subject: { type: "video", id: input.video_id },
      status: "decided",
      severity: "medium",
      policy_refs: [input.policy_clause],
      signals: [
        {
          id: newId("sig"),
          source: "automated",
          signal_type: "spam",
          confidence: 0.91,
          model_version: "spam-v0.1",
          evidence_ref: "model:spam-v0.1",
          created_at: createdAt
        }
      ],
      evidence: input.evidence.map((ref) => ({ kind: "other", ref })),
      assignee: "demo-reviewer",
      reviewer: "demo-reviewer",
      decision_action_id: actionId,
      created_at: createdAt,
      updated_at: createdAt
    };
    await append("moderation_case.opened", createdCase);
    const record = await append("enforcement_action.created", createdAction);
    createdAction.audit_record_hash = record.hash;
    action = createdAction;
    caseRecord = createdCase;
    appeals = [];
    return clone(createdAction);
  }

  async function fileAppeal(actionId, input) {
    if (!action || action.id !== actionId) throw new Error("Action not found");
    if (action.status !== "active") throw new Error("Only an active action can be appealed.");
    if (Date.now() > Date.parse(action.appeal_deadline)) {
      throw new Error("The appeal window has closed.");
    }
    const last = appeals[appeals.length - 1];
    if (last && last.status === "pending") throw new Error("An appeal is already pending.");
    if (
      last &&
      last.status === "decided" &&
      !["new_evidence", "procedural_error"].includes(input.grounds)
    ) {
      throw new Error("A second appeal requires new evidence or a procedural error.");
    }
    const appeal = {
      id: newId("apl"),
      action_id: actionId,
      appellant: "creator:demo",
      grounds: input.grounds,
      statement: input.statement,
      submitted_at: now(),
      status: "pending",
      reviewer: null,
      decision: null,
      reasoning: null,
      decided_at: null
    };
    appeals.push(appeal);
    await append("appeal.filed", appeal);
    return clone(appeal);
  }

  async function decideAppeal(appealId, input) {
    const appeal = appeals.find((item) => item.id === appealId);
    if (!appeal) throw new Error("Appeal not found");
    if (appeal.status !== "pending") throw new Error("Appeal already decided");
    if (!action) throw new Error("No action to update");
    const decidedAt = now();
    appeal.status = "decided";
    appeal.decision = input.decision;
    appeal.reasoning = input.reasoning;
    appeal.reviewer = "demo-appeals-reviewer";
    appeal.decided_at = decidedAt;
    await append("appeal.decided", appeal);
    if (input.decision === "reverse") {
      action.status = "reversed";
      const record = await append("enforcement_action.reversed", {
        action_id: action.id,
        appeal_id: appealId,
        decision: input.decision,
        reasoning: input.reasoning,
        reviewer: "demo-appeals-reviewer",
        decided_at: decidedAt
      });
      action.reversal_record_hash = record.hash;
    } else {
      await append("enforcement_action.upheld", {
        action_id: action.id,
        appeal_id: appealId,
        decision: input.decision,
        reasoning: input.reasoning,
        reviewer: "demo-appeals-reviewer",
        decided_at: decidedAt
      });
    }
    return getState();
  }

  async function verifyLedger() {
    return verify();
  }

  function exportLedger() {
    return {
      filename: "ledger.jsonl",
      text: ledger.map((record) => JSON.stringify(record)).join("\n") + (ledger.length ? "\n" : "")
    };
  }

  async function getVideo() {
    return clone(FALLBACK_VIDEO);
  }

  return {
    getState,
    reset,
    createAction,
    fileAppeal,
    decideAppeal,
    verifyLedger,
    exportLedger,
    getVideo
  };
})();

async function request(base, path, options = {}) {
  const headers = { Accept: "application/json" };
  if (options.body !== undefined) headers["Content-Type"] = "application/json";
  const response = await fetch(`${base}${path}`, {
    method: options.method || "GET",
    headers,
    body: options.body !== undefined ? JSON.stringify(options.body) : undefined
  });
  const text = await response.text();
  let data = null;
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = null;
    }
  }
  if (!response.ok) {
    throw new Error(data?.detail || `Request failed (${response.status})`);
  }
  return data;
}

const remoteBackend = {
  async getState() {
    return request(MOD_BASE, "/v1/demo/state");
  },
  async reset() {
    return request(MOD_BASE, "/v1/demo/reset", { method: "POST" });
  },
  async createAction(input) {
    return request(MOD_BASE, "/v1/actions", { method: "POST", body: input });
  },
  async fileAppeal(actionId, input) {
    return request(MOD_BASE, `/v1/actions/${encodeURIComponent(actionId)}/appeal`, {
      method: "POST",
      body: input
    });
  },
  async decideAppeal(appealId, input) {
    return request(MOD_BASE, `/v1/appeals/${encodeURIComponent(appealId)}/decide`, {
      method: "POST",
      body: input
    });
  },
  async verifyLedger() {
    return request(MOD_BASE, "/v1/ledger/verify");
  },
  async exportLedger() {
    const response = await fetch(`${MOD_BASE}/v1/ledger/export?format=jsonl`);
    if (!response.ok) throw new Error(`Export failed (${response.status})`);
    return { filename: "ledger.jsonl", text: await response.text() };
  },
  async getVideo() {
    return request(API_BASE, "/v1/videos/demo");
  }
};

const adapter = MODE === "remote" ? remoteBackend : mockBackend;

elements.reset.addEventListener("click", () => {
  void mutate(() => adapter.reset());
});

elements.issue.addEventListener("click", () => {
  void mutate(() =>
    adapter.createAction({
      video_id: lastVideo.id || "vid_demo_001",
      policy_clause: "spam.mass_production",
      reason:
        "Demo: an automated classifier flagged an original documentary as mass-produced spam.",
      evidence: ["model: spam-v0.1", "confidence: 0.91", "signal: upload cadence"]
    })
  );
});

elements.appeal.addEventListener("click", () => {
  const action = lastState?.action;
  if (!action) return;
  const lastAppeal = lastState?.appeal;
  const second = lastAppeal && lastAppeal.status === "decided";
  void mutate(() =>
    adapter.fileAppeal(action.id, {
      grounds: second ? "new_evidence" : "policy_misapplication",
      statement: second
        ? "New production files and edit history are attached. Please review the second appeal."
        : "Original documentary. All footage is owned, scripted, and edited by the creator. No mass production."
    })
  );
});

elements.reverse.addEventListener("click", () => {
  const appeal = lastState?.appeal;
  if (!appeal) return;
  void mutate(() =>
    adapter.decideAppeal(appeal.id, {
      decision: "reverse",
      reasoning:
        "Human review confirmed original production. The pattern match was a false positive."
    })
  );
});

elements.verifyButton.addEventListener("click", () => {
  void mutate(() => adapter.verifyLedger());
});

elements.exportButton.addEventListener("click", () => {
  void mutate(async () => {
    const file = await adapter.exportLedger();
    download(file.filename, file.text);
  });
});

elements.video.addEventListener("error", () => {
  if (elements.video.getAttribute("src") !== FALLBACK_SRC) {
    elements.video.setAttribute("src", FALLBACK_SRC);
  }
});

renderMode();
if (MODE === "remote" && config.configured === false) {
  setError(
    "Stage mode is enabled but KEELTUBE_API_BASE_URL and KEELTUBE_MODERATION_BASE_URL are not both set."
  );
}
setBusy(true);
load()
  .catch((error) => setError(error instanceof Error ? error.message : "Unable to load the demo."))
  .finally(() => setBusy(false));
