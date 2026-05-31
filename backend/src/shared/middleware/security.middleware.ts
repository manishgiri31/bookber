import helmet from "@fastify/helmet";

export const securityConfig = {
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"]
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  referrerPolicy: {
    policy: "no-referrer-when-downgrade"
  },
  xssFilter: true,
  noSniff: true,
  frameguard: {
    action: "sameorigin"
  }
};

export async function registerSecurityMiddleware(app: any) {
  await app.register(helmet, securityConfig);
}
