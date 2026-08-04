async function runGeneralSkill(ctx) {
  return {
    route: 'general',
    reply: {
      text: 'Consulta general procesada.',
      blocks: [
        {
          type: 'header',
          text: 'Consulta general'
        },
        {
          type: 'text',
          text: `Mensaje recibido: ${ctx.message}`
        },
        {
          type: 'text',
          text: 'Rutas sugeridas: system, telemetria'
        }
      ],
      allowedActions: []
    }
  };
}

module.exports = { runGeneralSkill };
