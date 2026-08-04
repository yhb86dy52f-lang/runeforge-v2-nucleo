# RF_WHATSAPP_META_MESSAGES_TEST_CAPTURE_CURRENT

- Fecha: 2026-06-18 18:27:07
- Estado: RF_WHATSAPP_META_MESSAGES_TEST_CAPTURE_OK
- Field: messages
- Message type: text
- Local status: 200
- Route: chat_local_ai
- Forwarded to core: False
- Real WhatsApp send: NO_REAL_SEND
- Backend: NO_TOCADO
- PM2: NO_TOCADO
- Firewall: NO_TOCADO

## Payload probado
```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "TEST_WABA_ID",
      "changes": [
        {
          "field": "messages",
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "16505551111",
              "phone_number_id": "123456123"
            },
            "contacts": [
              {
                "profile": {
                  "name": "test user name"
                },
                "wa_id": "16315551181",
                "user_id": "US.13491208655302741918"
              }
            ],
            "messages": [
              {
                "id": "ABGGFlA5Fpa",
                "timestamp": "1504902988",
                "from": "16315551181",
                "from_user_id": "US.13491208655302741918",
                "type": "text",
                "text": {
                  "body": "this is a text message"
                }
              }
            ]
          }
        }
      ]
    }
  ]
}
```

## Siguiente
- RF_WHATSAPP_META_TEST_BUTTON_VALIDATE_V1
