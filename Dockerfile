FROM nginx:alpine

# copy the front end 
COPY frontend/. /usr/share/nginx/html

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8000
