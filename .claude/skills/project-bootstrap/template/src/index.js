/**
 * Worker belépési pont.
 *
 * A statikus fájlok (public/) automatikusan előbb szolgálódnak ki.
 * Ez a kód csak akkor fut le, ha nincs egyező statikus fájl — ezért
 * nem kell külön routing az /api/* útvonalhoz.
 */
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (url.pathname === "/api/health") {
      return Response.json({
        status: "ok",
        time: new Date().toISOString(),
      });
    }

    return new Response("Not found", { status: 404 });
  },
};
