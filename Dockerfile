FROM openlistteam/openlist:latest-lite

USER root
COPY start.sh /start.sh
RUN chmod +x /start.sh && chown openlist:openlist /start.sh
USER openlist

ENTRYPOINT ["/start.sh"]
