export function buildWhatsAppTextPayload(to, body) {
  return {
    messaging_product: "whatsapp",
    to,
    type: "text",
    text: { body }
  };
}

export function buildDryRunRequest(phoneNumberId, payload) {
  return {
    method: "POST",
    graph_api_path: `/${phoneNumberId}/messages`,
    headers: {
      Authorization: "Bearer ***REDACTED***",
      "Content-Type": "application/json"
    },
    body: payload,
    real_send: "NO_REAL_SEND"
  };
}

export function validateDryRunPayload(payload) {
  const ok = payload && payload.messaging_product === "whatsapp" && payload.to && payload.type === "text" && payload.text && payload.text.body;
  return { ok: Boolean(ok), policy: "DRYRUN_ONLY_NO_NETWORK" };
}
