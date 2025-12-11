export const handler = (req: Request) => {
  return new Response(JSON.stringify({
    status: 'healthy',
    version: '1.0.0',
    database: 'healthy',
    cache: 'healthy'
  }), {
    headers: { "Content-Type": "application/json" },
  });
};
