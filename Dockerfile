FROM debian:bookworm

# File Author / Maintainer
MAINTAINER Francisco Camara Ferreira <francisco.camara@cnag.eu> 

ARG GENEID_VER=1.4.5

# Update the system and install all required updates
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y -q \
     curl \
     gawk \
     vim\
     perl \
     perl-doc \
     procps \
     gcc \
     vim \
     make \ 
     cpanminus \
     libexpat1-dev \
     pkg-config \
     libgd-perl \
     libgd-dev \
     apt-file \
     ghostscript \
     dumb-init \
     libxml2-dev 
     




# Install BioPerl using cpan
RUN cpan CJFIELDS/BioPerl-1.7.8.tar.gz

# Run cpan to get some modules required by the in-house modules/perl wrapper 
RUN cpan Data::Dumper \ 
Getopt::Long \ 
File::Path \
File::Basename \ 
XML::Parser 


RUN cpan -f Bio::DB::Fasta


RUN curl -L https://github.com/guigolab/geneid/archive/v${GENEID_VER}.tar.gz | \
    tar xz && \
    cd geneid-${GENEID_VER} && \
    make BIN=/build
    

# Copy local scripts to image
RUN mkdir -p /scripts_geneid

WORKDIR /scripts_geneid

# these are C programs and need to be compiled
COPY scripts/pictogram.tar.gz ./
COPY scripts/SSgff.tgz ./
COPY scripts/Evaluation.tgz ./


# compile pictogram.tar.gz binary will be in /scripts_geneid/pictogram
RUN tar -xzvf pictogram.tar.gz && cd pictogram && make pictogram

# compile SSgff.tgz binary will be in /scripts_geneid/SSgff/bin/
RUN tar -xzvf SSgff.tgz && cd SSgff && cd objects/ && rm *.o && cd ../ && make

# compile Evaluation.tgz binary will be in /scripts_geneid/Evaluation/bin
RUN tar -xzvf Evaluation.tgz && cd Evaluation && cd objects/ && rm *.o && cd ../ && make

##remove source code
RUN rm ./Evaluation.tgz ./SSgff.tgz ./pictogram.tar.gz

#copy these gawk programs required by geneidTRAINer1_14DockerTesting.pl
COPY scripts/*.awk scripts/cds2gff scripts/gff2cds scripts/gff2ps scripts/FastaToTbl scripts/TblToFasta ./

# copy PERL modules required by the trainer program to scripts_geneid directory 
COPY scripts/Geneid/ Geneid/

#these are files required by the the wrapper perl script geneidTRAINer1_14DockerTesting.pl
COPY scripts/genetic.code scripts/.gff2psrcNEW scripts/genetic.code.thermophila ./

##set path for evaluation, pictogram and SSgff
ENV PATH="/build:/scripts_geneid:/scripts_geneid/pictogram:/scripts_geneid/SSgff/bin:/scripts_geneid/Evaluation/bin:$PATH"

##set PERL5LIB
ENV PERL5LIB="/scripts_geneid/:${PERL5LIB}"

COPY scripts/geneidTRAINer4docker.pl ./

ENTRYPOINT ["/usr/bin/dumb-init", "/scripts_geneid/geneidTRAINer4docker.pl" ]
##ENTRYPOINT [ "/bin/bash" ]


# Clean cache
RUN apt-get clean
RUN set -x; rm -rf /var/lib/apt/lists/*
