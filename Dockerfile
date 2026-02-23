# Use Ubuntu as base
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install Lua + dependencies
RUN apt-get update && \
    apt-get install -y lua5.3 luarocks git curl build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install LuaRocks modules
RUN luarocks install http && \
    luarocks install cqueues && \
    luarocks install uuid

# Set working directory
WORKDIR /app

# Copy files
COPY server.lua .
COPY catnapdumper.lua .

# Expose Render dynamic port
EXPOSE 10000

# Start server
CMD ["lua", "server.lua"]
