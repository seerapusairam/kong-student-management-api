FROM kong:latest

# Copy your custom plugin inside Kong’s plugin directory
COPY ./kong-plugins/custom-plugin /usr/local/share/lua/5.1/kong/plugins/custom-plugin