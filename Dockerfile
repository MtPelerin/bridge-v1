FROM ethereum/solc:stable
LABEL name=mtpelerin-protocol

RUN apk add --update bash vim less sudo openssh \
     nodejs yarn git openssl g++ tar python make curl
RUN yarn global add npm truffle ganache-cli

RUN adduser -D -s /bin/bash -h /home/node -u 1000 node
USER node
RUN mkdir /home/node/project
WORKDIR /home/node/project

RUN git clone https://github.com/tomlion/vim-solidity.git ~/.vim/
COPY .vimrc /home/node

EXPOSE 3000
EXPOSE 3001
EXPOSE 8080
EXPOSE 9545
ENTRYPOINT ["/bin/bash"]

