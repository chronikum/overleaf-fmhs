FROM overleafcep/sharelatex:6.1.2-ext-v4.1

RUN tlmgr option repository https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2025/tlnet-final \
    && tlmgr install \
        biber \
        collection-bibtexextra \
        collection-fontsrecommended \
        collection-langgerman \
        collection-latexextra \
        collection-latexrecommended

RUN tlmgr install \
        algorithmicx \
        algorithms \
        dirtree \
        struktex

ENV PATH="/usr/local/texlive/2025/bin/x86_64-linux:${PATH}"
