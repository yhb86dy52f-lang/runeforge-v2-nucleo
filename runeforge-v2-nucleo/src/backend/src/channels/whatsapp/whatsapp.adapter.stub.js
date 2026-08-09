export function normalizeWhatsAppInbound(payload) {
  return {
    rf_schema: "rf.whatsapp.inbound_message.v1",
    received_at: new Date().toISOString(),
    channel: "whatsapp",
    from_hash: "PENDING_HASH",
    message_id: "PENDING_MESSAGE_ID",
    type: "text",
    text: "PENDING_TEXT",
    route: "blocked",
    trace_id: "PENDING_TRACE_ID",
    policy: "DRYRUN_ONLY_NO_SHELL"
  };
}

export function buildDryRunTextReply(to, body) {
  return {
    messaging_product: "whatsapp",
    to,
    type: "text",
    text: { body }
  };
}
