/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "standalone",
  // Disable SWC minify for cross-platform Docker builds (QEMU compatibility)
  swcMinify: false,
  // Use experimental turbo for faster builds when available
  experimental: {
    // Workaround for QEMU SIGILL in cross-platform builds
    cpus: 1,
  },
};

export default nextConfig;
