## Use a tag instead of "latest" for reproducibility
## I'm using lateest so this keeps up-to-date with each package
FROM rocker/binder:latest

## Declares build arguments
ENV NB_USER rstudio
ENV NB_UID 1000
ENV VENV_DIR /srv/venv

ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

ENV PATH ${VENV_DIR}/bin:$PATH


## Copies your repo files into the Docker Container
USER root
COPY . ${HOME}
## Enable this to copy files from the binder subdirectory
## to the home, overriding any existing files.
## Useful to create a setup on binder that is different from a
## clone of your repository
## COPY binder ${HOME}
RUN chown -R ${NB_USER} ${HOME}

RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron
RUN echo "export PATH=${PATH}" >> ${HOME}/.profile

ENV LD_LIBRARY_PATH /usr/local/lib/R/lib

WORKDIR ${HOME}

RUN apt-get update && \
    apt-get -y install python3-venv python3-dev && \
    apt-get purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${VENV_DIR} && chown -R ${NB_USER} ${VENV_DIR}

## Become normal user again
USER ${NB_USER}

RUN python3 -m venv ${VENV_DIR} && \
    # Explicitly install a new enough version of pip
    pip3 install pip==20.1.1 && \
    pip3 install --no-cache-dir \
         jupyter-rsession-proxy

RUN R --quiet -e "devtools::install_github('hrbrmstr/streamgraph')"

RUN R --quiet -e "devtools::install_github('IRkernel/IRkernel')" && \
    R --quiet -e "IRkernel::installspec(prefix='${VENV_DIR}')"

## Run an install.R script, if it exists.
RUN if [ -f install.R ]; then R --quiet -f install.R; fi

CMD jupyter notebook --ip 0.0.0.0
