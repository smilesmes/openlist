FROM openlistteam/openlist:latest-lite

USER root

COPY start.sh /start.sh
RUN chmod 755 /start.sh && \
    chown openlist:openlist /start.sh

USER openlist

EXPOSE 5244

ENTRYPOINT ["/start.sh"]
