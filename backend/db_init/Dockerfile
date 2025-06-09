FROM postgres:15-alpine

WORKDIR /app

COPY sql/ /app/sql/
COPY init.sh /app/init.sh

RUN chmod +x /app/init.sh

ENTRYPOINT ["/app/init.sh"]
