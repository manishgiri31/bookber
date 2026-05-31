// Compression middleware - @fastify/compress not installed, disabled for now
// import compression from "@fastify/compress";

export const compressionConfig = {
  encodings: ["gzip", "deflate", "br"],
  threshold: 1024, // Only compress responses larger than 1KB
  zlib: {
    level: 6, // Compression level (1-9)
    chunkSize: 16 * 1024, // 16KB chunks
    windowBits: 15,
    memLevel: 8
  }
};

export async function registerCompressionMiddleware(app: any) {
  // await app.register(compression, compressionConfig);
  // Compression middleware disabled - @fastify/compress not installed
}
