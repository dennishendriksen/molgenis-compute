#!/bin/bash
#SBATCH --job-name=${project}_${taskId}
#SBATCH --output=${taskId}.out
#SBATCH --error=${taskId}.err
#SBATCH --partition=${queue}
#SBATCH --time=${walltime}
#SBATCH --cpus-per-task ${ppn}
#SBATCH --mem ${mem}
#SBATCH --nodes ${nodes}
#SBATCH --open-mode=append
#SBATCH --export=NONE
#SBATCH --get-user-env=L

ENVIRONMENT_DIR="."
set -e
set -u
#-%j

function errorExitandCleanUp()
{
        echo "TRAPPED"
	failedFile="/groups/${groupname}/${tmpName}/logs/${project}.pipeline.failed"
	printf "${taskId}\n" > ${failedFile}
	if [ -f ${taskId}.err ]
	then
		printf "Last 50 lines of ${taskId}.err :\n" >> ${failedFile}
		tail -50 ${taskId}.err >> ${failedFile}
		printf "\nLast 50 lines of ${taskId}.out: \n" >> ${failedFile}
		tail -50 ${taskId}.out >> ${failedFile}
	fi
	rm -rf /groups/${groupname}/${tmpName}/tmp/${project}/*/tmp_${taskId}*
}

declare MC_tmpFolder="tmpFolder"
declare MC_tmpFile="tmpFile"

function makeTmpDir {
        base=$(basename $1)
        dir=$(dirname $1)
        echo "dir $dir"
        echo "base $base"
        if [[ -d $1 ]]
        then
            	dir=$dir/$base
        fi
	myMD5=$(md5sum $0)
        IFS=' ' read -a myMD5array <<< "$myMD5"
        MC_tmpFolder=$dir/tmp_${taskId}_$myMD5array/
        mkdir -p $MC_tmpFolder
        if [[ -d $1 ]]
        then
            	MC_tmpFile="$MC_tmpFolder"
        else
            	MC_tmpFile="$MC_tmpFolder/$base"
        fi
}

trap "errorExitandCleanUp" HUP INT QUIT TERM EXIT ERR

# For bookkeeping how long your task takes
MOLGENIS_START=$(date +%s)

touch ${taskId}.sh.started
