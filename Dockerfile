FROM node:20.2-alpine3.16

RUN mkdir -p /home/fullstack-nextjs-app-template-1

WORKDIR /home/fullstack-nextjs-app-template-1

COPY . /home/fullstack-nextjs-app-template-1

RUN npm install \
     && npm run build
     
CMD ["npm", "start"]
