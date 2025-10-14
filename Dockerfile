# Use official Nginx image as base
FROM nginx:stable-alpine

# Copy your HTML file into Nginx default directory
RUN rm /usr/share/nginx/html/index.html 
COPY index.html /usr/share/nginx/html/index.html
# Expose port 80 inside the container
EXPOSE 80
