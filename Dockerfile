# 1. Use official Node runtime as a parent image
FROM node:18-alpine

# 2. Set working directory inside the container
WORKDIR /usr/src/app

# 3. Copy app code into the container
COPY ./app ./app

# 4. Expose port 3000 for the container
EXPOSE 3000

# 5. Command to run the server
CMD ["node", "./app/server.js"]

