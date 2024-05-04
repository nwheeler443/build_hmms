#! /usr/bin/env bash

#####################################################################
# build_hmms.sh builds an HMM database from a FASTA file of sequences
#####################################################################
#Usage: build_hmms.sh -f file.fasta -n db_name

#Get options from user
while getopts "f:n:" OPTION
    do 
        case $OPTION in
            f)
                FILE=$OPTARG
                ;;
            n) 
                DBNAME=$OPTARG
                ;;
            \?)
                echo "Usage: build_hmms.sh -f FILE -n DBNAME"
                echo "  FILE            path to fasta file to build the database from (required)"
                echo "  DBNAME          name of the database (required)"
                exit
                ;;  
        esac 
    done

#Check for values
if [ "$FILE" == "" ] && [ "$DBNAME" == "" ]
then
    echo "Usage: build_hmms.sh -f FILE -n DBNAME"
    echo "  FILE            path to fasta file to build the database from (required)"
    echo "  DBNAME          name of the database (required)"
    exit 1
fi

# check if an existing database will interfere
if test -f ${DBNAME}_db_h.dbtype; then
    echo "Existing mmseqs database will interfere with build process - will delete the old database first before proceeding"
    # add yes/no option for user
    read -p "Do you want to proceed? (yes/no) " yn

    case $yn in 
	yes ) echo ok, we will proceed;;
	no ) echo exiting...;
		exit;;
	* ) echo invalid response;
		exit 1;;
    esac

    rm -r cluster_seqs
    rm ${DBNAME}_db*
    rm ${DBNAME}.hmm.h*
fi

mmseqs createdb ${FILE} ${DBNAME}_db
mmseqs cluster ${DBNAME}_db ${DBNAME}_db_clust tmp
mmseqs createseqfiledb ${DBNAME}_db ${DBNAME}_db_clust ${DBNAME}_db_clust_seq 
mmseqs result2flat ${DBNAME}_db ${DBNAME}_db ${DBNAME}_db_clust_seq ${DBNAME}_db_clust.fasta
mmseqs createsubdb ${DBNAME}_db_clust_seq ${DBNAME}_db ${DBNAME}_db_clust_rep
mmseqs convert2fasta ${DBNAME}_db_clust_rep ${DBNAME}_db_clust_rep.fasta

mkdir cluster_seqs

parse_mmseqs_clusters.pl ${DBNAME}_db_clust.fasta

echo "Aligning sequences for each cluster with mafft"
bar=""; for i in cluster_seqs/*.fasta; do bar=$bar-; done; for i in cluster_seqs/*.fasta; do mafft $i > ${i//fasta/afa} 2>/dev/null; bar=${bar/-/=}; printf "%s\r" $bar; done


echo "Building HMMs for each cluster"

# run hmmbuild on each cluster and include a progress bar

bar=""; for i in cluster_seqs/*.afa; do bar=$bar-; done

tput sc
for i in cluster_seqs/*.afa; do 
    tput ed
    hmmbuild ${i//afa/hmm} $i >/dev/null
    bar=${bar/-/=}
    printf "%s\r" $bar
    tput rc
done

cat cluster_seqs/*hmm > ${DBNAME}.hmm
