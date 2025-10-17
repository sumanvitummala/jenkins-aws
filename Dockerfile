# Use official Nginx image as base
FROM nginx:stable-alpine

# Remove default index.html
RUN rm /usr/share/nginx/html/index.html

# Copy custom HTML file
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 inside container
EXPOSE 80
